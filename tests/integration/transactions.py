"""Persistence acceptance checks against real coordinator, managers and storage."""
import copy
import json
import subprocess
import sys

KEY='bufo_idle_save_cobol_v1'
LEGACY='bufo_idle_save'
proc=subprocess.Popen([sys.argv[1]],stdin=subprocess.PIPE,stdout=subprocess.PIPE,text=True)
now=1_700_000_000_000

def call(operation,args=None,success=True,random=None):
 proc.stdin.write(json.dumps({'operation':operation,'args':args or {},'now':now,'random':random if random is not None else [.99]*500})+'\n');proc.stdin.flush()
 line=proc.stdout.readline();assert line,operation
 response=json.loads(line)
 if success:assert response.get('ok'),(operation,response)
 return response

def state():return call('getState')['result']
def raw(key=KEY):return call('storage.getRaw',{'key':key})['result']
def envelope(value):return json.dumps({'format':'bufo-clicker-cobol','schemaVersion':1,'timestamp':now,'state':value})
def set_raw(value,key=KEY):call('storage.setRaw',{'key':key,'raw':value})
def reload():call('runtime.reset');call('init')
def seed():
 call('storage.fail',{'write':0,'read':0});call('save.reset')
 value=state();value['resources']['bufos']=value['resources']['totalBufos']=1000
 value['generators']['tadpole']['count']=10
 call('save.import',{'raw':envelope(value)})
 return state()

def close(a,b):assert abs(a-b)<=max(1e-8,abs(b)*1e-12),(a,b)
try:
 call('init');initial=seed();saved=raw();rate=sum(g['totalProduction'] for g in initial['generators'].values())
 assert rate>0
 now+=120_000
 call('storage.fail',{'write':1});reload()
 assert state()['resources']['bufos']==1000,'Failed initial credit must retain the uncredited validated snapshot'
 assert raw()==saved,'Failed initial credit must retain stored bytes'
 assert not call('click',success=False)['ok']
 call('storage.fail',{'write':0});call('save.retry')
 close(state()['resources']['bufos'],1000+rate*120)
 accepted=raw();bank=state()['resources']['bufos'];call('save.retry')
 assert raw()==accepted and state()['resources']['bufos']==bank,'Retry after successful activation must be a no-op'
 # The 60-second load floor and 12-hour cap use permanent cached production.
 for gap,credited in ((59_999,0),(60_000,60),(86_400_000,43_200)):
  initial=seed();rate=sum(g['totalProduction'] for g in initial['generators'].values())
  now+=gap;reload();close(state()['resources']['bufos'],1000+rate*credited)
 # Explicit elapsed resume has no one-minute floor. Failed retry retains one source.
 initial=seed();rate=sum(g['totalProduction'] for g in initial['generators'].values());old=raw()
 now+=20_000;call('storage.fail',{'write':1})
 assert not call('save.resume',success=False)['ok'];assert raw()==old
 assert state()['resources']['bufos']==1000
 assert not call('save.resume',success=False)['ok']
 now+=10_000;call('storage.fail',{'write':0});call('save.retry')
 close(state()['resources']['bufos'],1000+rate*30)
 accepted=raw();call('save.retry');assert raw()==accepted
 # Legacy partial records cannot acquire absent required values from fresh defaults.
 valid=seed();before=state();old=raw();partial=copy.deepcopy(valid);del partial['resources']['bufos']
 response=call('save.import',{'raw':json.dumps({'version':'1.0.0','state':partial})},success=False)
 assert not response['ok'],'Missing legacy currency must be rejected before merging defaults'
 assert state()==before and raw()==old
 assert any(event['name']=='importError' for event in response.get('events',[]))
 # Currency/integer consistency uses exact comparisons, not COBOL float tolerance.
 for path,value in ((('resources','bufos'),1000.0000001),(('generators','tadpole','count'),61923851.1)):
  invalid=copy.deepcopy(valid);node=invalid
  for key in path[:-1]:node=node[key]
  node[path[-1]]=value
  assert not call('save.import',{'raw':envelope(invalid)},success=False)['ok'],path
 # Progress and custom-event maps reject invalid values and unknown IDs.
 for patch in ({'progress':{'bogus':10}},{'progress':{'first_bufo':-1}},{'customEvents':{'boss_furious_froglet':'yes'}}):
  invalid=copy.deepcopy(valid);invalid['achievements'].update(patch)
  assert not call('save.import',{'raw':envelope(invalid)},success=False)['ok'],patch
 # Duplicate boost IDs cannot multiply one saved boost twice.
 invalid=copy.deepcopy(valid)
 boost={'id':'duplicate','multiplier':2,'active':True,'source':'custom'}
 invalid['generators']['tadpole']['boosts']=[boost,copy.deepcopy(boost)]
 assert not call('save.import',{'raw':envelope(invalid)},success=False)['ok']
 # Corrupt current storage cannot be recovered by resume or prestige.
 set_raw('broken');reload()
 assert not call('save.resume',success=False)['ok'] and raw()=='broken'
 assert not call('save.prestige',success=False)['ok'] and raw()=='broken'
 call('save.reset')
 # Duplicate hidden events retain the original idle interval.
 seed();call('visibility',{'hidden':True});hidden=state();bank=hidden['resources']['bufos']
 rate=sum(g['totalProduction'] for g in hidden['generators'].values())
 now+=20_000;call('visibility',{'hidden':True});now+=10_000
 call('visibility',{'hidden':False});close(state()['resources']['bufos'],bank+rate*30)
 # Repeated visibility changes while credit is pending retain one source snapshot.
 initial=seed();rate=sum(g['totalProduction'] for g in initial['generators'].values())
 call('visibility',{'hidden':True});old=raw();hidden=state();bank=hidden['resources']['bufos']
 rate=sum(g['totalProduction'] for g in hidden['generators'].values());now+=20_000
 call('storage.fail',{'write':1});call('visibility',{'hidden':False},success=False)
 now+=10_000;call('visibility',{'hidden':True},success=False);call('visibility',{'hidden':False},success=False)
 assert raw()==old and state()['resources']['bufos']==bank
 call('storage.fail',{'write':0});call('save.retry');close(state()['resources']['bufos'],bank+rate*30)
 accepted=raw();call('save.retry');assert raw()==accepted
 # A successful retry while visible must restart simulation without another visibility event.
 bank=state()['resources']['bufos'];now+=1000;call('frame')
 assert state()['resources']['bufos']>bank,'Visible recovery must resume simulation'
 # Candidate bounds are checked after elapsed credit, before storage writes.
 value=seed();value['generators']['tadpole']['count']=1
 value['generators']['tadpole']['boosts']=[{'id':'large1','multiplier':1e150,'active':True,'source':'custom'},{'id':'large2','multiplier':1e150,'active':True,'source':'custom'}]
 call('save.import',{'raw':envelope(value)});old=raw();now+=60_000;reload()
 assert raw()==old and state()['resources']['bufos']==1000
 assert not call('click',success=False)['ok']
 call('save.reset')
 # A first-launch failed write can recover by retry without importing or resetting.
 call('storage.remove',{'key':KEY});call('storage.remove',{'key':LEGACY})
 call('storage.fail',{'write':1});reload();assert raw() is None
 call('storage.fail',{'write':0});call('save.retry');assert json.loads(raw())['state']['resources']['bufos']==0
 # Resume preserves an active Explorer encounter while its durable save omits it.
 seed();call('explorer.startExploration',{'area':'Pond'})
 call('explorer.update',{'delta':1},random=[0]+[.5]*100)
 assert state()['explorer']['state']=='fighting'
 encounter=call('explorer.getCurrentCombat')['result'];explorer_before=state()['explorer']
 now+=20_000;call('save.resume')
 assert state()['explorer']==explorer_before
 assert call('explorer.getCurrentCombat')['result']==encounter
 assert json.loads(raw())['state']['explorer']['state']!='fighting'
 # Ordinary saves strip frenzy only from their copy, and reload restores permanent production.
 initial=seed();permanent_rate=sum(g['totalProduction'] for g in initial['generators'].values())
 call('golden.forceSpawn',random=[.1,.2,.25,.5]);spawn=call('golden.getActiveSpawn')['result']
 call('golden.collect',{'id':spawn['id']})
 assert state()['resources']['frenzyProductionMultiplier']==7
 permanent_rate=sum(g['totalProduction'] for g in state()['generators'].values())/7
 call('save.save');assert state()['resources']['frenzyProductionMultiplier']==7
 snapshot=json.loads(raw())['state'];assert snapshot['resources']['frenzyProductionMultiplier']==1
 close(sum(g['totalProduction'] for g in snapshot['generators'].values()),permanent_rate)
 reload();assert state()['resources']['frenzyProductionMultiplier']==1
 # Save events distinguish successful imports, manual saves, and failed writes.
 value=seed();response=call('save.import',{'raw':envelope(value)})
 assert any(event['name']=='saveImported' for event in response.get('events',[]))
 response=call('save.save',{'auto':True})
 assert any(event['name']=='GAME_SAVED' and event['payload']['auto'] for event in response.get('events',[]))
 call('storage.fail',{'write':1});response=call('save.save',success=False)
 assert any(event['name']=='saveError' for event in response.get('events',[]))
 call('storage.fail',{'write':0})
 # Repeated restoration never replays the one-time achievement currency reward.
 value=seed();value['achievements']['unlocked']=['first_bufo','click_10000']
 value['resources']['clickCount']=value['achievements']['clickCount']=10000
 value['resources']['totalBufos']=1_000_000_000
 call('save.import',{'raw':envelope(value)});bank=state()['resources']['bufos'];power=state()['resources']['clickPower']
 reload();reload();assert state()['resources']['bufos']==bank;close(state()['resources']['clickPower'],power)
 # Prestige failures retain state and bytes, including all progression and bonuses.
 before=state();old=raw();call('storage.fail',{'write':1})
 assert not call('save.prestige',success=False)['ok'];assert state()==before and raw()==old
 call('storage.fail',{'write':0});response=call('save.prestige')
 assert response['result']==1 and state()['prestige']['lifetimePoints']==1
 assert state()['resources']['bufos']==0
 assert any(event['name']=='PRESTIGE_TRANSCENDED' for event in response.get('events',[]))
 # SaveManager persists supplied snapshots independently of the running game.
 live=seed();supplied=copy.deepcopy(live)
 supplied['resources']['bufos']=supplied['resources']['totalBufos']=777
 assert call('save.saveSupplied',{'state':supplied,'generators':{'external':1},'purchasedUpgrades':['stronger_clicks_1'],'explorer':{'external':True}})['result'] is True
 assert state()==live
 read=call('save.readSaved')['result'];assert read['state']['resources']['bufos']==777
 assert read['upgrades']==['stronger_clicks_1'] and read['explorer']=={'external':True}
 stored_export=call('save.exportSaved')['result'];assert stored_export
 set_raw(json.dumps({'version':'1.0.0','timestamp':now,'state':supplied}),LEGACY)
 set_raw('another application', 'unrelated')
 old=raw();legacy=raw(LEGACY);call('storage.fail',{'write':1})
 assert call('save.clearSaved')['result'] is False
 assert raw()==old and raw(LEGACY)==legacy and state()==live
 call('storage.fail',{'write':0})
 call('save.clearSaved');assert raw() is None and state()==live
 assert raw(LEGACY) is None, 'Clearing a migrated save must also remove its fallback'
 assert raw('unrelated')=='another application'
 assert call('save.readSaved')['result'] is None and call('save.exportSaved')['result']==''
 assert call('save.importSupplied',{'raw':stored_export})['result'] is True
 assert state()==live and json.loads(raw())['state']['resources']['bufos']==777
 old=raw();call('storage.fail',{'write':1})
 assert call('save.saveSupplied',{'state':live})['result'] is False
 assert state()==live and raw()==old
 call('storage.fail',{'write':0})
 # Autosave retries retain the source interval after a failed write.
 seed();now+=60_001;call('storage.fail',{'write':1})
 first=call('frame',success=False)
 assert any(event['name']=='saveError' for event in first.get('events',[]))
 now+=1;second=call('frame',success=False)
 assert second['ok'] and not any(event['name']=='saveError' for event in second.get('events',[])), 'A failed autosave must not retry on the next frame'
 now+=59_999;third=call('frame',success=False)
 assert any(event['name']=='saveError' for event in third.get('events',[]))
 call('storage.fail',{'write':0})
 print('PASS persistence: failed-load snapshot, retry, offline floor/cap, resume, legacy and numeric validation')
finally:
 proc.stdin.close();proc.wait(timeout=10)
