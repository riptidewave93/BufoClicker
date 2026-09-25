"""Native acceptance at public model, manager, and economic command boundaries."""
import copy
import json
import math
import os
import shlex
import pathlib
import subprocess
import sys

runner = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'build/domain-test')
command=shlex.split(os.environ['DOMAIN_RUNNER']) if 'DOMAIN_RUNNER' in os.environ else [str(runner.resolve())]
assert 'DOMAIN_RUNNER' in os.environ or runner.is_file(), f'COBOL domain executable missing: {runner}'
proc = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
checks = 0
def call(operation, **args):
    global checks
    checks += 1
    expect_error=args.pop('_expect_error',False)
    request=dict(operation=operation, args=args, now=args.pop('_now',1000000), random=args.pop('_random',[.99]*20))
    proc.stdin.write(json.dumps(request)+'\n'); proc.stdin.flush()
    line=proc.stdout.readline()
    assert line, f'COBOL process exited while handling {operation}'
    result=json.loads(line)
    if expect_error:
        assert not result['ok'],(operation,result)
        return result
    assert result['ok'], (operation,result)
    return result.get('result')
def close(a,b):
    assert math.isclose(a,b,rel_tol=1e-10,abs_tol=1e-12),(a,b)
def state(): return call('test.context')['state']
def replace(value): call('test.replaceState',**value)
def fresh():
    call('init'); return state()

catalog=json.loads(pathlib.Path('assets/data/generators.json').read_text())
upgrades=json.loads(pathlib.Path('assets/data/upgrades.json').read_text())
achievements=json.loads(pathlib.Path('assets/data/achievements.json').read_text())
bosses=json.loads(pathlib.Path('assets/data/bosses.json').read_text())
fresh()
assert call('model.prestige.prestigePointsFor',totalBufos=100000000000)==10
assert call('model.prestige.prestigePointsFor',totalBufos=999999999)==0
assert call('generator.calculateTotalProduction')==0
assert call('click')['bufosGained']==1
close(call('click')['bufosGained'],1.1*1.05)

# Every generator, active/inactive boosts, rounded bulk cost and Max boundary.
for original in catalog.values():
    generator=copy.deepcopy(original)
    generator.update(count=3,boosts=[dict(id='one',multiplier=2,active=True,source='test'),dict(id='two',multiplier=100,active=False,source='test')])
    changed=call('model.generator.recalculateGenerator',generator=generator,globalMultiplier=1.25,additionalBoosts=[dict(id='extra',multiplier=3,active=True,source='test')])
    close(changed['totalProduction'],original['baseProduction']*2*1.25*3*3)
    assert changed['currentCost']==math.ceil(original['baseCost']*original['costMultiplier']**3),(original['id'],changed['currentCost'],math.ceil(original['baseCost']*original['costMultiplier']**3))
    for quantity in [1,10,25]:
        cost=call('model.generator.calculateBulkCost',generator=changed,quantity=quantity)
        expected=changed['currentCost'] if quantity==1 else math.ceil(changed['currentCost']*(1-changed['costMultiplier']**quantity)/(1-changed['costMultiplier']))
        assert cost==expected,(changed['id'],cost,expected)
        assert call('model.generator.calculateMaxAffordable',generator=changed,bufos=cost)==quantity
        assert call('model.generator.calculateMaxAffordable',generator=changed,bufos=(cost-1 if cost<1e15 else cost*(1-1e-12)))==quantity-1, (changed['id'],quantity,cost)
        assert call('model.generator.canAffordGenerator',generator=changed,bufos=(cost-1 if cost<1e15 else cost*(1-1e-12)),quantity=quantity) is False
    assert call('model.generator.updateGenerator',currentGenerator=changed,updates={'enabled':False})['enabled'] is False

# Disabled and locked owned generators produce, while purchases and Max are gated.
for enabled,unlocked in [(False,True),(True,False),(False,False)]:
    current=fresh();current['generators']['tadpole'].update(count=1,enabled=enabled,unlocked=unlocked);replace(current)
    call('generator.recalculateAllGenerators')
    close(call('generator.calculateTotalProduction'),.1)
    assert call('generator.getMaxAffordable',generatorType='tadpole',availableBufos=1000)==0
    assert not call('generator.purchaseGenerator',generatorType='tadpole',quantity=1,availableBufos=1000)['success']

# Manager ownership and facade bank spending are separate contracts.
current=fresh();current['resources']['bufos']=100;replace(current)
purchase=call('generator.purchaseGenerator',generatorType='tadpole',quantity=1,availableBufos=100)
assert purchase['success'] and purchase['cost']==10 and state()['resources']['bufos']==100
assert call('achievement.isAchievementUnlocked',achievementId='first_generator')
assert call('buyGenerator',generatorType='tadpole')
assert state()['resources']['bufos']==88
assert not call('buyGenerator',generatorType='tadpole',quantity=0)

# Prerequisites guard the facade, not the cost-returning manager method.
current=fresh();current['resources'].update(bufos=1e12,totalBufos=1e12);replace(current)
assert call('buyUpgrade',upgradeId='ribbit_resonance') is False
before=state()
assert call('upgrade.purchaseUpgrade',upgradeId='ribbit_resonance',currentBufos=1e12)['success']
after=state()
assert after['resources']['bufos']-before['resources']['bufos']==after['resources']['totalBufos']-before['resources']['totalBufos']
assert not call('upgrade.purchaseUpgrade',upgradeId='ribbit_resonance',currentBufos=1e12)['success']
for upgrade in upgrades:
    multiplier=1
    for effect in upgrade['effects']:
        if effect['type']=='clickMultiplier': multiplier*=effect['multiplier']
    close(call('model.upgrade.calculateClickMultiplier',upgrades=[upgrade]),multiplier)

# Exact source click ordering at reward thresholds, with no combo.
fresh()
for click in range(1,1001):
    result=call('click',_now=1000000+click*1000)
    if click in [1,99,100,1000]:
        close(result['bufosGained'],{1:1,99:1.1,100:1.21,1000:1.815}[click])
assert state()['resources']['clickCount']==1000
assert call('achievement.getClickCount')==1000

# Restoration replays permanent effects once after reset, never currency rewards.
current=fresh();current['resources'].update(bufos=1000,totalBufos=1000)
current['achievements']['unlocked']=['first_bufo','click_100','click_10000'];replace(current)
call('rebuild'); snapshot=state();close(snapshot['resources']['clickMultiplier'],1.21)
assert snapshot['resources']['bufos']==1000
call('rebuild');assert state()==snapshot
current=state();current['resources']['totalBufos']=1e9;replace(current)
assert call('prestige.transcend')==1
current=state();assert current['resources']['bufos']==0
close(current['resources']['clickMultiplier'],1.21)
assert current['prestige']['lifetimePoints']==1

# Boss ladder, scaled health, victory, frozen countdown, retreat and loss.
for boss in bosses:
    for lifetime in [0,5,100]:
        game=dict(prestige=dict(lifetimePoints=lifetime),bosses=dict(defeated=['x'],lifetimeDefeats=3))
        expected=math.ceil(boss['baseHealth']*(1+lifetime*.1)*2)
        assert call('model.boss.getBossHealth',boss=boss,state=game)==expected
current=fresh();current['resources'].update(bufos=10000,totalBufos=10000);replace(current)
assert call('boss.startFight')
fight=call('boss.getActiveFight');assert fight['health']==975
call('boss.pause');call('boss.tick',delta=30);assert call('boss.getActiveFight')['remainingMs']==30000
call('boss.resume');call('boss.tick',delta=.2);assert call('boss.getActiveFight')['remainingMs']==29800
assert call('boss.hit',amount=1000) is None
assert call('boss.getDefeatedCount')==1
close(call('boss.getMultiplier'),1.25)
current=fresh();current['resources'].update(bufos=10000,totalBufos=10000);replace(current)
call('boss.startFight');call('boss.tick',delta=30);assert state()['resources']['bufos']==0

# Golden probability boundaries and stop rebuild of live generator caches.
for roll,reward in [(.4999,'bufo_frenzy'),(.5,'lucky'),(.7999,'lucky'),(.8,'click_frenzy')]:
    current=fresh();current['generators']['tadpole']['count']=1;replace(current);call('rebuild')
    call('golden.forceSpawn',_random=[.1,roll,.25,.5])
    spawn=call('golden.getActiveSpawn');assert spawn['rewardType']==reward
    close(spawn['position']['xPct'],27);close(spawn['position']['yPct'],46)
    assert call('golden.collect',id=spawn['id']+1) is None
    assert call('golden.collect',id=spawn['id'])['rewardType']==reward
    if reward=='bufo_frenzy': close(call('generator.calculateTotalProduction'),.7)
    call('golden.stop');close(call('generator.calculateTotalProduction'),.1)

# Original TypeScript outputs, with source hashes verified at fe02bde.
oracle=json.loads(pathlib.Path('tests/domain/models-oracle.json').read_text())
generator=call('model.generator.createGenerator',id='tadpole',name='Tadpole',description='Test',baseProduction=.1,baseCost=15,costMultiplier=1.15)
assert generator==oracle['generator']
boosted=call('model.generator.applyBoostToGenerator',generator=dict(generator,count=10),boostId='custom',multiplier=3,source='Test')
inactive=call('model.generator.toggleBoost',generator=boosted,boostId='custom',active=False)
for label,value in [('boosted',boosted),('inactive',inactive)]:
    result=call('model.generator.recalculateGenerator',generator=value,globalMultiplier=2)
    close(result['totalProduction'],oracle[label]['totalProduction'])
    assert result['currentCost']==oracle[label]['currentCost']
assert [call('model.generator.calculateBulkCost',generator=generator,quantity=n) for n in [1,10,100]]==oracle['bulk']
assert [call('model.generator.calculateMaxAffordable',generator=generator,bufos=n) for n in [0,15,100,1000]]==oracle['max']
upgrade=dict(id='test',effects=[dict(type='clickMultiplier',multiplier=2),dict(type='globalMultiplier',multiplier=3),dict(type='generatorProduction',target='tadpole',multiplier=5)],unlockConditions=[dict(type='upgrade',target='pre'),dict(type='totalBufos',value=100)])
assert call('model.upgrade.calculateUpgradeEffectForGenerator',upgrade=upgrade,generatorType='tadpole')==oracle['upgrades']['generator']
assert call('model.upgrade.calculateClickMultiplier',upgrades=[upgrade])==oracle['upgrades']['click']
assert call('model.upgrade.calculateGlobalMultiplier',upgrades=[upgrade])==oracle['upgrades']['global']
for ids,expected in [([],False),(['pre'],True)]:
    assert call('model.upgrade.meetsUnlockConditions',upgrade=upgrade,totalBufos=100,generatorCounts={},achievements={},purchasedUpgrades=ids)==expected
assert [call('model.prestige.prestigePointsFor',totalBufos=n) for n in [0,1e9,1e11,1e13]]==oracle['prestige']
assert call('model.achievement.getCategoryIcon',category='special')==oracle['achievement']['icon']

# Every catalog achievement predicate is checked on either side of its threshold.
fields={'totalBufos':'totalBufos','bufosPerSecond':'bufosPerSecond','totalGenerators':'totalGenerators','clickCount':'clickCount','upgradeCount':'upgradesPurchased','explorationCount':'explorationsCompleted','bossesDefeated':'bossesDefeated','transcendences':'transcendences','prestigePoints':'prestigePoints'}
for achievement in achievements:
    requirement=achievement['requirement']; kind=requirement['type']; target=requirement.get('target'); value=requirement.get('value',0)
    check={}
    if kind in fields: check[fields[kind]]=value
    elif kind=='generatorType': check['generatorCounts']={target:value}
    elif kind=='customEvent': check['customEvents']={target:True}
    elif kind=='consoleOpened': check['consoleOpened']=True
    else: raise AssertionError(kind)
    assert call('model.achievement.checkAchievementRequirement',achievement=achievement,gameState=check),(achievement['id'],check)
    if kind in fields: check[fields[kind]]=value-1
    elif kind=='generatorType': check['generatorCounts'][target]=value-1
    elif kind=='customEvent': check['customEvents'][target]=False
    elif kind=='consoleOpened': check['consoleOpened']=False
    assert not call('model.achievement.checkAchievementRequirement',achievement=achievement,gameState=check),(achievement['id'],check)

linear=dict(generator,costMultiplier=1)
assert call('model.generator.calculateBulkCost',generator=linear,quantity=2)=={'$oracle':'number','value':'NaN'}
assert call('model.generator.canAffordGenerator',generator=linear,bufos=100,quantity=2) is False

# Candidate rebuild rejects nonfinite derived production instead of retaining a cache.
current=fresh()
current['generators']['tadpole'].update(count=1,boosts=[dict(id='large-a',active=True,multiplier=1e200,source='test'),dict(id='large-b',active=True,multiplier=1e200,source='test')])
replace(current)
assert call('rebuild',_expect_error=True)['error']

proc.stdin.close();assert proc.wait(timeout=5)==0
target='WASM' if 'DOMAIN_RUNNER' in os.environ else 'native'
print(f'domain {target} acceptance passed: {checks} public calls')
