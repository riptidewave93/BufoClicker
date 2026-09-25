import json, subprocess, sys
from pathlib import Path
vectors=[json.loads(s) for s in Path('tests/services/original-vectors.jsonl').read_text().splitlines()]
original={v['operation']:v for v in vectors if v['kind']=='service'}
p=subprocess.Popen(sys.argv[1:],stdin=subprocess.PIPE,stdout=subprocess.PIPE,text=True)
def call(op,args=None,**extra):
 q={'operation':op,'args':args or [],'now':extra.pop('now',1000),**extra}
 p.stdin.write(json.dumps(q)+'\n');p.stdin.flush()
 line=p.stdout.readline()
 if not line: raise RuntimeError('native service runner terminated')
 r=json.loads(line)
 assert r.get('ok',True), (q,r)
 return r
callbacks={}
def drain(r):
 while True:
  for c in r.get('commands',[]):
   if c['kind']=='callback':
    try: callback_result={'ok':True,'value':callbacks[c['id']](*c.get('args',[]))}
    except RuntimeError as error: callback_result={'ok':False,'error':str(error)}
  if 'continuation' not in r:return r
  q=r['continuation'];q['callbackResult']=callback_result;r=call(q['operation'],q.get('args',[]),**{k:v for k,v in q.items() if k not in ('operation','args')})
def on(name,id):call('event.on',[name,{'$callback':id}])
seen=[]
callbacks['a']=lambda *_:(seen.append('a'),call('event.off',['x',{'$callback':'a'}]))
callbacks['b']=lambda *_:seen.append('b')
on('x','a');on('x','b');drain(call('event.emit',['x']))
first=list(seen);drain(call('event.emit',['x']))
assert {'first':first,'all':seen}==original['mutationDuringEmit']['expected']
call('event.clearAllEvents');seen=[]
callbacks['a']=lambda *_:(seen.append('a'),on('x','b'))
on('x','a');drain(call('event.emit',['x']))
assert seen==original['addDuringEmit']['expected']
call('event.clearAllEvents');seen=[];errors=[]
callbacks['a']=lambda payload:seen.append({'callback':'a','payload':payload})
callbacks['b']=lambda payload:seen.append({'callback':'b','payload':payload})
def throws(*_):errors.append(1);raise RuntimeError('expected')
callbacks['throw']=throws
on('x','a');on('x','a');on('x','throw');on('x','b')
before={'names':call('event.getEventNames')['result'],'count':call('event.getListenerCount',['x'])['result'],'has':call('event.hasListeners',['x'])['result']}
drain(call('event.emit',['x',{'value':1}]))
call('event.off',['x',{'$callback':'a'}]);drain(call('event.emit',['x']))
call('event.clearEvent',['x'])
after={'names':call('event.getEventNames')['result'],'count':call('event.getListenerCount',['x'])['result'],'has':call('event.hasListeners',['x'])['result']}
assert {'before':before,'received':seen,'after':after,'caughtErrors':len(errors)}==original['subscriptions']['expected']
# Clearing the map during emit retains the live old array, while newly registered
# listeners belong to a different array and must wait for the next emission.
seen=[]
callbacks['a']=lambda *_:(seen.append('a'),call('event.clearEvent',['x']),on('x','c'))
callbacks['b']=lambda *_:seen.append('b')
callbacks['c']=lambda *_:seen.append('c')
on('x','a');on('x','b');drain(call('event.emit',['x']));assert seen==['a','b']
drain(call('event.emit',['x']));assert seen==['a','b','c']
base=original['stateTransitions']['input']['initialState']
call('stateManager.loadState',[base],testDefaultState=base)
notifications=[]
callbacks['state']=lambda current,old:notifications.append({'current':current['resources']['bufos'],'old':old['resources']['bufos']})
call('stateManager.subscribe',[{'$callback':'state'}])
copy=call('stateManager.getState')['result'];copy['resources']['bufos']=99
after_copy=call('stateManager.getState')['result']['resources']['bufos']
drain(call('stateManager.setState',[{'resources':{'bufos':10}}]))
call('stateManager.startBatch')
call('stateManager.setState',[{'resources':{'bufos':20}}]);call('stateManager.setState',[{'resources':{'bufos':30}}])
before_end=len(notifications);drain(call('stateManager.endBatch'))
call('stateManager.unsubscribe',[{'$callback':'state'}]);call('stateManager.setState',[{'resources':{'bufos':40}}])
invalid=call('stateManager.loadState',[{}])['result'];bank=call('stateManager.getState')['result']['resources']['bufos']
assert {'afterCopyMutation':after_copy,'beforeEnd':before_end,'notifications':notifications,'invalidAccepted':invalid,'finalBank':bank}==original['stateTransitions']['expected']
call('stateManager.resetState');reset=call('stateManager.getState')['result']
assert reset['resources']['bufos']==0 and 'clickCount' not in reset['resources']
# Execute source-recorded timing steps and compare callback deadlines/arguments.
for mode in ('throttle','debounce'):
 spec=original[mode];pending={};invocations=[];now=1000
 token=call('time.'+mode,[{'$callback':'timer'},100])['result']['$callable']
 def apply(r):
  for c in r.get('commands',[]):
   if c['kind']=='timer':pending[c['token']]=(now+c['delay'],c['generation'])
   elif c['kind']=='timerCancel':pending.pop(c['token'],None)
   elif c['kind']=='callback':invocations.append({'at':now,'arg':c['args'][0],'context':c.get('thisArg',{}).get('name')})
 for step in spec['input']['steps']:
  while pending and min(x[0] for x in pending.values())<=step['at']:
   key,(now,generation)=min(pending.items(),key=lambda x:x[1][0]);pending.pop(key)
   apply(call('time.fire',[key,generation],now=now))
  now=step['at']
  if 'call' in step:apply(call('time.invoke',[token,[step['call']],{'name':'receiver'}],now=now))
 assert {'invocations':invocations,'pendingTimers':len(pending)}==spec['expected'],(mode,invocations)
# An unbound host callable preserves its undefined receiver across transport.
unbound=call('time.throttle',[{'$callback':'timer'},100])['result']['$callable']
command=call('time.invoke',[unbound,['value'],{'$oracle':'undefined'}])['commands'][0]
assert command['kind']=='callback' and command['thisArg']=={'$oracle':'undefined'}
# Delay settles only on its matching generation; cancellation never settles.
delay=call('utils.delay',[25]);token=delay['result']['$promise'];generation=delay['commands'][0]['generation']
assert not call('time.fire',[token,generation+1])['commands']
resolved=call('time.fire',[token,generation]);assert resolved['commands']==[{'kind':'resolve','id':token,'value':{'$oracle':'undefined'}}]
cancel=call('utils.cancellableDelay',[25]);token=cancel['result']['cancel']['$cancel']
call('time.cancel',[token]);assert not call('time.fire',[token,1])['commands']
# Logger gating, context, colors, groups and callback timing use real commands.
assert call('logger.getLogLevel')['result']==3
assert not call('logger.debug',['hidden'])['commands']
call('logger.enableTimestamps',[False]);call('logger.enableConsoleColors',[False]);call('logger.setContext',['Test'])
assert call('logger.info',['hello',{'extra':1}])['commands']==[{'kind':'log','method':'log','args':['[Test] hello',{'extra':1}]}]
call('logger.setLogLevel',[4]);assert call('logger.group',['group'])['commands'][0]['method']=='group'
assert call('logger.groupEnd')['commands'][0]['method']=='groupEnd';assert not call('logger.groupEnd')['commands']
timing=call('logger.time',['work',{'$callback':'fn'}]);assert [c['kind'] for c in timing['commands']]==['log','callback','log']
assert call('logger.timeResult',callbackResult={'ok':True,'value':42})['result']==42
assert call('utils.attemptResult',[{'$callback':'fn'},'fallback'],callbackResult={'ok':False,'error':'fail'})['result']=='fallback'
call('data.updateDataCacheVersion',['catalog','v1']);assert call('data.shouldLoadData',['catalog','v1'])['result'] is False
assert call('data.shouldLoadData',['catalog','v2'])['result'] is True
fetch=call('data.loadMultipleJsonData',[{'good':'/good.json','bad':'/bad.json'}]);assert len(fetch['commands'])==2
loaded=call('data.completeMultiple',commandResults=[{'id':'good','ok':True,'status':200,'text':'{"items":[1]}'},{'id':'bad','ok':False,'status':404,'text':'missing'}])
assert loaded['result']=={'good':{'items':[1]}}
validated=call('validation.validateObject',[{'score':1,'name':''},{'score':'validation.isPositiveNumber','name':'validation.isNonEmptyString'}])
assert validated['result']=={'isValid':False,'invalidProps':['name']}
callbacks['positive']=lambda value:value>0
callbacks['nonempty']=lambda value:len(value)>0
validated=drain(call('validation.validateObject',[{'score':1,'name':''},{'score':{'$callback':'positive'},'name':{'$callback':'nonempty'}}]))
assert validated['result']=={'isValid':False,'invalidProps':['name']}
for decimals in (-1,101):
 p.stdin.write(json.dumps({'operation':'number.formatNumber','args':[1000000,decimals]})+'\n');p.stdin.flush()
 failure=json.loads(p.stdout.readline())
 assert failure.get('ok') is False and failure.get('errorName')=='RangeError',failure
# Non-JSON source cases are rejected explicitly, never interpreted as null.
rejected=0
for v in vectors:
 if v['kind']=='call' and '$oracle' in json.dumps(v['args']):
  p.stdin.write(json.dumps({'operation':'utils.deepClone','args':v['args']})+'\n');p.stdin.flush()
  r=json.loads(p.stdout.readline());assert r['ok'] is False and 'non-JSON' in r['error'];rejected+=1
p.stdin.close();assert p.wait()==0
print(f'Original state/event/timer scenarios and async/logger/data contracts passed; {rejected} non-JSON inputs explicitly rejected')
