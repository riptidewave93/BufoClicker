"""Every manager facade is compared with its existing named operation and state effect."""
import json,pathlib,subprocess,sys,os,shlex
p=subprocess.Popen(shlex.split(os.environ['API_RUNNER']) if 'API_RUNNER' in os.environ else [str(pathlib.Path(sys.argv[1]).resolve())],stdin=subprocess.PIPE,stdout=subprocess.PIPE,text=True)
calls=0

def call(op,args={}):
 global calls
 calls+=1;p.stdin.write(json.dumps(dict(operation=op,args=args,now=1000000,random=[.99]*500))+'\n');p.stdin.flush()
 line=p.stdout.readline();assert line,(op,p.poll())
 value=json.loads(line);assert value.get('ok'),(op,args,value)
 return value.get('result',{'$void':True})
try:
 call('init')
 baseline=call('getState')
 upgrade=call('upgrade.getAllUpgrades')[0]
 achievement=call('achievement.getAllAchievements')[0]
 boss=call('model.boss.findBoss',{'id':'furious_froglet'})
 sample={'generatorType':'tadpole','totalBufos':1000,'quantity':2,'availableBufos':1000,'seconds':10,'multiplier':2,'boostId':'api-boost','source':'API routing','active':False,
 'state':baseline,'generatorCounts':{'tadpole':20},'upgradeId':upgrade['id'],'currentBufos':1000,'upgrade':upgrade,'upgrades':[upgrade],
 'silentLoad':True,'category':achievement['category'],'achievementId':achievement['id'],'achievementIds':[achievement['id']],'count':123,'events':{'api-event':True},'eventName':'api-event',
 'boss':boss,'amount':12,'id':999,'delta':.125,'area':'Pond','action':'attack','statName':'attack'}
 rows=json.loads(pathlib.Path('tests/api/manager-signatures.json').read_text())
 for row in rows:
  values=[sample[k] for k in row['arguments']]
  call('save.reset'); expected=call(row['operation'],dict(zip(row['arguments'],values))); expected_state=call('getState')
  call('save.reset'); actual=call('api',{'path':row['path'].split('.'),'values':values}); actual_state=call('getState')
  assert actual==expected,(row['path'],actual,expected)
  assert actual_state==expected_state,(row['path'],'state effect differs')
 print(f'API manager mapping passed: {len(rows)} methods, {calls} calls, exact result and state parity')
finally:
 p.stdin.close();assert p.wait(timeout=10)==0
