"""Durable Explorer checks reject bad records before candidate activation."""
import copy
import json
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[2]
default = json.loads((root / 'tests/explorer/vectors.json').read_text())[0]['expected']['result']
cases=[]
def add(label, operation, explorer, expected, strict=False):
    cases.append((label, {'input': {'operation': operation, 'now': 9999, 'args': {'explorer': explorer, 'strict': strict}}}, expected))
add('valid source default','validate',default,True)
for path,value in [
    ('level',0),('level',1.5),('level',1001),('experience',-1),('experienceToNextLevel',0),
    ('stateStartTime',-1),('health',101),('maxHealth',0),('explorationProgress',101),
    ('explorationsCompleted',61923852.5),('explorationsCompleted',.1),('lifetimeBufosFromExploring',-1),('name',''),('name',None),
    ('currentArea',''),('state','invalid'),('attack',None),('defense',[]),('speed.level',0),
    ('luck.growthRate',-1),('attack.multiplier','1'),('defense.upgradeCost',False),
    ('equipment',[]),('equipment.weapon',True),('equipment.armor',123),('equipment.accessory',{}),
]:
    record=copy.deepcopy(default);parts=path.split('.');target=record
    for key in parts[:-1]:target=target[key]
    target[parts[-1]]=value
    add(path,'validate',record,False)
    add(path+' normalize strict','normalize',record,'error',True)
for field in default:
    record=copy.deepcopy(default);del record[field]
    add('missing '+field,'validate',record,False)
add('legacy empty','normalize',{},'default')
add('strict empty','normalize',{},'error',True)
add('legacy partial nested','normalize',{'name':'Keeper','attack':{'value':17},'equipment':{'weapon':'stick'}},'partial')
for health,state in [(1,'injured'),(20,'resting'),(49,'resting'),(50,'exploring'),(100,'exploring')]:
    record=dict(default,state='fighting',health=health)
    add('reconcile fight '+str(health),'normalize',record,state,True)

proc=subprocess.run([str(root/'build/explorer-native')],input=''.join(json.dumps(req)+'\n' for _,req,_ in cases),text=True,capture_output=True,cwd=root,check=True)
outputs=[json.loads(line) for line in proc.stdout.splitlines()]
assert len(outputs)==len(cases)
for (label,_,expected),out in zip(cases,outputs):
    if isinstance(expected,bool):assert out.get('result') is expected,(label,out)
    elif expected=='error':assert out['ok'] is False and 'result' not in out,(label,out)
    else:
        assert out['ok'] is True,(label,out)
        actual=out['result']
        if expected=='default':assert actual==dict(default,stateStartTime=9999),(label,out)
        elif expected=='partial':
            wanted=copy.deepcopy(default);wanted.update(name='Keeper',stateStartTime=9999);wanted['attack']['value']=17;wanted['equipment']['weapon']='stick'
            assert actual==wanted,(label,out)
        else:assert actual['state']==expected and actual['stateStartTime']==9999,(label,out)
print(f'{len(cases)} durable Explorer validation and normalization checks passed')
