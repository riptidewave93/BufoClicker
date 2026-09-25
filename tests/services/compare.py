import json, subprocess, sys
from pathlib import Path
prefix={'numberUtils.ts':'number','mathUtils.ts':'math','timeUtils.ts':'time','validationUtils.ts':'validation','index.ts':'utils','stateUtils.ts':'state','gameState.ts':'gameState'}
vectors=[]
for line in Path('tests/services/original-vectors.jsonl').read_text().splitlines():
 v=json.loads(line)
 if v['kind']!='call' or v['module'].split('/')[-1] not in prefix:continue
 if v['operation'] in ('createDefaultState','DEFAULT_GAME_STATE'):continue
 if '$oracle' in json.dumps(v['args']) or 'throws' in v['expected']:continue
 vectors.append(v)
requests=[{'operation':prefix[v['module'].split('/')[-1]]+'.'+v['operation'],'args':v['args'],'now':v['nowMs'],'random':v['random']} for v in vectors]
p=subprocess.run(sys.argv[1:],input=''.join(json.dumps(q)+'\n' for q in requests),capture_output=True,text=True)
if p.returncode: print(p.stderr);sys.exit(p.returncode)
results=[json.loads(s) for s in p.stdout.splitlines()]
def same(a,b):
 if type(a) in (float,int) and type(b) in (float,int):return abs(a-b)<=max(1e-12,abs(b)*1e-12)
 if isinstance(a,list) and isinstance(b,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
 if isinstance(a,dict) and isinstance(b,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
 return a==b
bad=[]
for v,r in zip(vectors,results):
 if not same(r.get('result'),v['expected'].get('returns')):bad.append((v['id'],v['args'],v['expected'],r))
for row in bad[:40]:print(json.dumps(row))
print(f'{len(vectors)-len(bad)}/{len(vectors)} JSON vectors passed; {len(bad)} failed')
sys.exit(bool(bad) or len(results)!=len(vectors))
