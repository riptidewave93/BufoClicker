"""Exercise public positional facades through the real application dispatcher."""
import json, pathlib, subprocess, sys, os, shlex
binary = str(pathlib.Path(sys.argv[1]).resolve()) if len(sys.argv)>1 else 'build/api-test'
p = subprocess.Popen(shlex.split(os.environ['API_RUNNER']) if 'API_RUNNER' in os.environ else [binary], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
count = 0

def call(op,args=None,ok=True,**extra):
    global count
    count += 1
    p.stdin.write(json.dumps(dict(operation=op,args={} if args is None else args,now=1_000_000,random=[.99]*50,**extra))+'\n'); p.stdin.flush()
    line=p.stdout.readline(); assert line, (op,p.poll())
    r=json.loads(line)
    if ok: assert r.get('ok'),(op,args,r)
    return r

def api(path,*values,**kw): return call('api',dict(path=path.split('.'),values=list(values)),**kw)
def result(path,*values):return api(path,*values).get('result')
try:
    call('init')
    normalized=call('model.upgrade.initializeUpgrades')['result']
    prereqs=[c for u in normalized for c in u['unlockConditions'] if c['type']=='upgrade']
    assert prereqs and all('target' in c and 'id' not in c for c in prereqs)
    assert result('game.getState')['resources']['bufos']==0
    assert result('gameCore.getGeneratorManager')=={'$proxy':['generator']}
    assert len(result('generators.getAllGenerators'))==14
    assert result('game.getMaxAffordable','tadpole')==0
    assert result('resources.add',1000)==1000
    assert result('game.buyGenerator','tadpole',1) is True
    bank=result('resources.get')['bufos']; assert bank<1000
    purchase=result('generators.purchaseGenerator','tadpole',1,1000)
    assert purchase['success'] and result('resources.get')['bufos']==bank
    assert result('time.setTimeScale',7) is None
    assert result('time.getTimeScale')==5
    assert result('gameLoop.setTimeScale',-.5) is None
    assert result('gameLoop.getTimeScale')==.1
    result('gameLoop.setTimeScale',5.000000000000001)
    assert result('gameLoop.getTimeScale')==5
    result('gameLoop.setTimeScale',.09999999999999999)
    assert result('gameLoop.getTimeScale')==.1
    result('gameLoop.setTimeScale',4.999999999999999)
    assert result('gameLoop.getTimeScale')==4.999999999999999
    result('game.toggleAutoSave',False); assert result('game.isAutoSaveEnabled') is False
    assert result('golden.collect')=='No Golden Bufo on screen'
    assert result('golden.spawn')=='Golden Bufo spawned (or already on screen)'
    assert result('golden.collect').startswith('Collected: ')
    assert result('boss.win')=='No active fight'
    assert result('boss.lose')=='No active fight'
    assert result('resources.get')['bufos']>0
    assert result('boss.start')=='No boss available (or one is already active)'
    assert result('gameLoader.verifyGameData')==dict(generatorsLoaded=14,upgradesLoaded=91,isComplete=True)
    assert result('gameLoader.isGameDataLoaded') is True
    assert result('gameLoader.loadGameData')['achievements'] is True
    assert result('storage.saveToStorage','api-test',{'frog':'🐸'}) is True
    assert result('storage.loadFromStorage','api-test',{})=={'frog':'🐸'}
    assert result('storage.hasStorageKey','api-test') is True
    encoded=result('storage.exportToString',{'frog':'🐸'})
    assert result('storage.importFromString',encoded)=={'frog':'🐸'}
    assert result('storage.importFromString','nonsense') is None
    assert result('storage.clearStorage','api-test') is True
    assert result('storage.loadFromStorage','api-test',42)==42
    # Actual manager and debug facade behavior around active fights and prestige.
    result('resources.set',1_000_000)
    assert result('boss.start')=='Fight started'
    fight=result('boss.status'); assert fight['health']>0
    assert result('boss.hit',None)['health']<fight['health']
    assert result('boss.win') is None
    assert result('boss.defeatedCount')==1
    assert result('boss.multiplier')>1
    result('resources.set',1e12)
    assert result('boss.start')=='Fight started'
    assert result('boss.lose')=='Simulated a loss (bufos zeroed, fight cleared)'
    assert result('resources.get')['bufos']==0
    assert result('generator_debug.give','tadpole',2)=='Added 2 Bufo Tadpole generators'
    assert result('generator_debug.unlockAll')=='All generators unlocked'
    assert all(g['unlocked'] for g in result('generators.getAllGenerators'))
    assert result('upgrade_debug.purchase','missing')=='Failed to purchase missing'
    assert result('inspect.upgrades')['purchased']==result('upgrades.getPurchasedUpgrades')
    result('events.on','api-event',{'$callback':'callback-1'})
    assert result('events.getListenerCount','api-event')==1
    emitted=api('events.emit','api-event',{'answer':42})
    assert emitted['commands'][0]['id']=='callback-1'
    result('events.off','api-event',{'$callback':'callback-1'})
    assert result('events.hasListeners','api-event') is False
    measured=api('performance.measure','sample',{'$callback':'measure-callback'})
    assert [c['kind'] for c in measured['commands']]==['log','callback']
    assert measured['continuation']['args']['path']==['performance','complete']
    ended=api('performance.complete','sample',callbackResult={'ok':True,'value':5})
    assert ended['commands'][0]['method']=='timeEnd' and 'result' not in ended
    assert result('help')=='Debug tools help displayed in console'
    # UIManager uses real DOM handles through explicit native transport fixtures.
    notice=api('ui.showNotification',{'message':'Hello','duration':0},domResults=[{'$element':'notice'},None,None,None,None,{'$element':'close'},None,None])
    assert notice['result']=={'$element':'notice'}
    adapter=api('ui.getComponent','shop',domResults=[{'$element':'shop'}])['result']
    assert adapter.get('$component')
    assert result('ui.getComponent','shop')==adapter
    assert result('ui.getComponent','not-a-component') is None
    modal=api('ui.showModal',{'id':'test-modal','title':'Test','content':'<b>Content</b>','buttons':[{'text':'Choose','callback':{'$callback':'choose'}}]},domResults=[None])
    assert modal['continuation']['operation']=='ui.modalResult'
    button=api('ui.customModalButton',0)
    assert button['commands'][0]['id']=='choose'
    assert button['continuation']['operation']=='ui.closeModal'
    assert not api('ui.closeModal',callbackResult={'ok':False,'error':'button failed'},ok=False)['ok']
    api('ui.closeModal',domResults=[None])
    closed=call('ui.modalClosed',['test-modal'])
    assert closed['events'][0]['name']=='UI_MODAL_CLOSED'
    result('gameCore.stop')
    before=result('resources.get')
    result('gameCore.processTick',1)
    assert result('resources.get')==before
    result('gameCore.start')
    tick=api('gameCore.processTick',1)
    assert tick['events'][-1]['name']=='tick'
    assert set(tick['events'][-1]['payload'])=={'state','generators','totalProduction','explorer'}
    current=result('game.getState')
    assert result('saveManager.saveGame',current,current['generators'],current['upgrades']['purchased'],current['explorer']) is True
    loaded=result('saveManager.loadGame'); assert loaded['state']['resources']['bufos']==current['resources']['bufos']
    result('resources.add',13); newer=result('resources.get')['bufos']
    assert result('saveManager.loadGame')['state']['resources']['bufos']!=newer
    assert result('resources.get')['bufos']==newer
    unchanged=result('game.getState')
    assert api('game.reset',domResults=[False])['result'] is False
    assert result('game.getState')==unchanged
    assert not api('nonexistent.method',ok=False)['ok']
    assert result('managers.initializeManagers') is None
    assert result('ui.initUI','app')=={'$proxy':['ui']}
    assert result('ui.updateUI') is None
    loading=api('initialization.createLoadingUI','missing',domResults=[None])['result']
    assert loading['$proxy'][0]=='loadingUI'
    assert result('.'.join(loading['$proxy'])+'.update',{'step':'Waiting','progress':10}) is None
    assert result('.'.join(loading['$proxy'])+'.remove') is None
    loader=api('initialization.createLoadingUI','app',domResults=[{'$element':'app'},{'$element':'loading'},None,None,None,None])['result']
    api('.'.join(loader['$proxy'])+'.update',{'step':'Loading','progress':50},domResults=[{'$element':'bar'},None,{'$element':'status'},None])
    api('.'.join(loader['$proxy'])+'.remove',domResults=[None,None,None])
    initialization=api('initialization.initializeGame','app',{'$callback':'progress'})
    progress=[]
    while True:
        progress.extend(c['args'][0]['progress'] for c in initialization.get('commands',[]) if c['kind']=='callback' and c['id']=='progress')
        if 'continuation' not in initialization: break
        next_call=initialization['continuation']
        initialization=call(next_call['operation'],next_call.get('args'),callbackResult={'ok':True})
    assert initialization['result'] is True,(initialization,progress)
    assert progress==[10,20,40,60,70,80,90,95,100],progress
    assert result('logger.getLogLevel')==3
    # Corrupt storage pauses all public mutation paths while preserving reads/recovery.
    call('storage.setRaw',dict(key='bufo_idle_save_cobol_v1',raw='broken'))
    call('runtime.reset');call('init')
    assert not api('resources.add',1,ok=False)['ok']
    assert not api('game.buyGenerator','tadpole',1,ok=False)['ok']
    assert not api('state.setState',{'resources':{'bufos':99}},ok=False)['ok']
    assert result('game.getState')['resources']['bufos']==0
    assert result('reset.softReset')=='Game state reset'
    assert result('resources.add',1)==1
    assert api('game.reset',domResults=[True])['result'] is True
    assert result('resources.get')['bufos']==0
    print(f'API acceptance passed: {count} public calls')
finally:
    p.stdin.close(); assert p.wait(timeout=10)==0
