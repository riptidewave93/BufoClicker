"""Exact finite boundary checks against source-generated utility results."""
import json,pathlib,subprocess,sys
vectors=json.loads(pathlib.Path('tests/services/numeric-edges.json').read_text())['cases']
requests=[dict(operation=v['operation'],args=v['args'],random=v['random'],now=1000) for v in vectors]
p=subprocess.run(sys.argv[1:],input=''.join(json.dumps(r)+'\n' for r in requests),capture_output=True,text=True,check=True)
results=[json.loads(line) for line in p.stdout.splitlines()]
bad=[]
for v,r in zip(vectors,results):
 if not r.get('ok') or r.get('result')!=v['expected']:bad.append(dict(input=v,actual=r))
for failure in bad[:30]:print(json.dumps(failure))
print(f'Finite numeric boundaries: {len(vectors)-len(bad)}/{len(vectors)} passed, {len(bad)} failed')
sys.exit(bool(bad) or len(results)!=len(vectors))
