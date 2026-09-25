"""Replay source vectors through the same native COBOL domain modules."""
import json
import math
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[2]
vectors = json.loads((root / 'tests/explorer/vectors.json').read_text())
proc = subprocess.run([str(root / 'build/explorer-native')], input=''.join(json.dumps(v) + '\n' for v in vectors), text=True, capture_output=True, cwd=root)
if proc.returncode:
    raise SystemExit(proc.stderr)
outputs = [json.loads(line) for line in proc.stdout.splitlines()]
assert len(outputs) == len(vectors), (len(outputs), len(vectors), proc.stderr)

def same(actual, expected, path='result'):
    if isinstance(expected, bool) or expected is None or isinstance(expected, str):
        assert type(actual) is type(expected) and actual == expected, (path, actual, expected)
    elif isinstance(expected, (int, float)):
        assert isinstance(actual, (int, float)) and not isinstance(actual, bool), (path, actual, expected)
        assert actual == expected if float(expected).is_integer() else math.isclose(actual, expected, rel_tol=1e-10, abs_tol=1e-12), (path, actual, expected)
    elif isinstance(expected, list):
        assert isinstance(actual, list) and len(actual) == len(expected), (path, actual, expected)
        for i, (a, e) in enumerate(zip(actual, expected)): same(a, e, f'{path}.{i}')
    else:
        assert actual.keys() == expected.keys(), (path, actual.keys(), expected.keys())
        for key in expected: same(actual[key], expected[key], f'{path}.{key}')

failures=[]
for i,(v,out) in enumerate(zip(vectors,outputs)):
    try:
        expected=dict(v['expected'],randomConsumed=v['randomConsumed'])
        if 'explorer' in v: expected.update(explorer=v['explorer'],events=v['events'])
        else:
            out.pop('explorer',None)
            out.pop('events',None)
        same(out, expected)
    except AssertionError as error: failures.append((i,v['input']['operation'],str(error)))
for failure in failures[:20]: print(failure)
print(f'{len(vectors)-len(failures)}/{len(vectors)} original-source vectors passed')
sys.exit(bool(failures))
