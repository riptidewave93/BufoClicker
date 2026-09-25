import json, math, subprocess, sys
from html.parser import HTMLParser
from pathlib import Path
class Markup(HTMLParser):
    def __init__(self, value):
        super().__init__(convert_charrefs=True); self.nodes=[]; self.feed(value)
    def handle_starttag(self, tag, attrs): self.nodes.append(('start',tag, sorted(attrs)))
    def handle_endtag(self, tag): self.nodes.append(('end',tag))
    def handle_data(self, text):
        if text.strip(): self.nodes.append(('text',' '.join(text.split())))
rows=[json.loads(line) for line in Path('tests/components/original-vectors.jsonl').read_text().splitlines()]
p=subprocess.run([sys.argv[1]],input='\n'.join(json.dumps(r['request']) for r in rows)+'\n',text=True,capture_output=True,check=True)
actual=[json.loads(line) for line in p.stdout.splitlines()]
assert len(actual)==len(rows),(len(actual),len(rows),p.stderr)
for row,result in zip(rows,actual):
    assert result.get('ok'), (row['request'],result)
    a,e=result['result'],row['expected']
    if isinstance(e,(dict,list)): assert a==e,(row,a,e)
    elif isinstance(e,(int,float)): assert math.isclose(a,e,rel_tol=1e-12,abs_tol=1e-12),(row,a,e)
    else: assert Markup(a).nodes==Markup(e).nodes,(row['request'],a,e)
print(f'{len(rows)} original-source template/easing comparisons passed')
