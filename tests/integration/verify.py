"""Exercise real COBOL coordinator and storage transactions without browser rendering."""
import json
import pathlib
import subprocess
import sys

KEY = 'bufo_idle_save_cobol_v1'
runner = pathlib.Path(sys.argv[1]).resolve()
proc = subprocess.Popen([str(runner)], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
now = 1_000_000

def call(operation, args=None, *, success=True):
    request = dict(operation=operation, args=args or {}, now=now, random=[.99]*500)
    proc.stdin.write(json.dumps(request)+'\n')
    proc.stdin.flush()
    line = proc.stdout.readline()
    assert line, f'Runner exited during {operation}'
    value = json.loads(line)
    if success:
        assert value.get('ok'), (operation, value)
    return value

def state():
    return call('getState')['result']

def raw():
    return call('storage.getRaw', {'key':KEY})['result']

def envelope(value):
    return json.dumps(dict(format='bufo-clicker-cobol', schemaVersion=1, timestamp=now, state=value))

try:
    call('init')
    initial = state()
    assert initial['resources']['bufos'] == 0
    assert len(initial['generators']) == 14
    assert json.loads(raw())['format'] == 'bufo-clicker-cobol'
    assert call('click')['result']['bufosGained'] == 1
    now += 1000
    assert call('click')['result']['bufosGained'] == 1.1
    call('save.save')
    saved = raw()
    before = state()
    replacement = json.loads(json.dumps(before))
    replacement['resources']['bufos'] = replacement['resources']['totalBufos'] = 1000
    call('storage.fail', {'write':1})
    failed = call('save.import', {'raw':envelope(replacement)}, success=False)
    assert not failed['ok'], failed
    assert state() == before, 'Failed import changed live state'
    assert raw() == saved, 'Failed import changed persisted bytes'
    call('storage.fail', {'write':0})
    call('save.import', {'raw':envelope(replacement)})
    assert state()['resources']['bufos'] == 1000, state()['resources']
    encoded = call('save.export')['result']
    call('save.import', {'raw':encoded})
    assert state()['resources']['bufos'] == 1000, state()['resources']
    current = raw()
    call('storage.setRaw', {'key':KEY,'raw':'broken json'})
    call('runtime.reset')
    call('init')
    assert not call('click', success=False)['ok']
    assert raw() == 'broken json'
    call('storage.fail', {'write':1})
    assert not call('save.reset', success=False)['ok']
    assert raw() == 'broken json'
    call('storage.fail', {'write':0})
    call('save.reset')
    assert state()['resources']['bufos'] == 0
    assert json.loads(raw())['state']['resources']['bufos'] == 0
    call('storage.setRaw', {'key':KEY,'raw':current})
    call('runtime.reset')
    call('init')
    assert state()['resources']['bufos'] == 1000, state()['resources']
    print('PASS coordinator: initial save, clicks, import/export, atomic failures, corrupt recovery, reload')
finally:
    proc.stdin.close()
    proc.wait(timeout=10)
