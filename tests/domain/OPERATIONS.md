# Domain operations

BUFO-GAME accepts `operation`, `args`, root-owned `runtime.now` milliseconds and request `random` sequence. Values below are named keys in `args`. All operations return `{ok:true,result:value}`; source void/undefined omits result, source null remains JSON null. Unknown operations return `ok:false`.

## Coordinator

`init()` resets domain-owned state/runtime slices. `rebuild(preserveFrenzy=false)` rebuilds permanent effects from purchased/unlocked IDs and retained custom generator boosts. It clears combo and synchronizes the core click counter. It requires full generator records merged from authoritative catalogs. `recalculate()` updates live click power/generator caches without resetting multipliers. `click()` returns `{bufosGained,isCombo,comboMultiplier}`. `registerClick()` increments core/resources/achievement counters without income. `tick(delta,deferChecks=false)` processes golden deadlines, boss countdown and production. By default it then calls `finishTick()`, which checks unlocks/achievements, records `lastTick` and emits the source lowercase `tick` payload. For the application frame and GameCore facade, call `tick` with `deferChecks:true`, update Explorer, then call `finishTick()` so its event includes the new Explorer state. `checkUnlocks()` refreshes generators/upgrades. `buyGenerator(generatorType,quantity=1)` and `buyUpgrade(upgradeId)` charge the bank and return boolean. Only facade `buyUpgrade` enforces prerequisites; manager purchase preserves the source cost-returning behavior.

## Generators

Manager prefix `generator.`:

- `recalculateGenerator(generatorType)` returns generator or undefined; `recalculateAllGenerators()` and `reset()` recalculate all.
- `checkUnlocks(totalBufos)` returns newly unlocked generators; `purchaseGenerator(generatorType,quantity,availableBufos)` returns `{success,cost,generator?,productionIncrease}` without charging bank.
- `getMaxAffordable(generatorType,availableBufos)`, `calculateTotalProduction()`, `calculateProductionForTime(seconds,multiplier=1)` return numbers.
- `getProductionStats()` returns `{totalPerSecond,totalPerMinute,totalPerHour,generatorContributions,activeBonusMultiplier}`.
- `applyBoostToGenerator(generatorType,boostId,multiplier,source,active=true)`, `toggleGeneratorBoost(generatorType,boostId,active)` mutate a boost; `getAllGenerators()` and `getUnlockedGenerators()` return arrays.

Pure prefix `model.generator.`: `initializeGenerators()`, `updateGenerator(currentGenerator,updates)`, `recalculateGenerator(generator,globalMultiplier,additionalBoosts=[])`, `checkGeneratorUnlock(generator,totalBufos,ownedGenerators,unlockedAchievements={},specialConditions={})`, `unlockGenerator` with the same arguments, `calculateTotalProduction(generators)`, `canAffordGenerator(generator,bufos,quantity=1)`, `calculateBulkCost(generator,quantity)`, `calculateMaxAffordable(generator,bufos)`, `createGenerator(id,name,description,baseProduction,baseCost,costMultiplier,unlockRequirements=[{type:bufos,value:0}],category=basic,iconPath?,detailedDescription?)`, `applyBoostToGenerator(generator,boostId,multiplier,source,active=true)`, `toggleBoost(generator,boostId,active)`.

## Upgrades

Manager prefix `upgrade.`: `initialize()`, `checkAvailableUpgrades(state?,generatorCounts?)`, `purchaseUpgrade(upgradeId,currentBufos)`, `applyUpgradeEffects(upgrade)`, `calculateTotalMultiplierForGenerator(generatorType)`, `calculateTotalClickMultiplier()`, `reapplyAllUpgrades()`, `getUpgradeEffects(upgradeId)`, `findUpgradeById(upgradeId)`, `getAvailableUpgrades()`, `getPurchasedUpgrades()`, `isUpgradePurchased(upgradeId)`, `setUpgrades(upgrades)`, `getAllUpgrades()`, `reset()`.

Pure prefix `model.upgrade.`: `initializeUpgrades()`, `findUpgradeById(upgrades,id)`, `meetsUnlockConditions(upgrade,totalBufos,generatorCounts,achievements={},purchasedUpgrades=[])`, `calculateUpgradeEffectForGenerator(upgrade,generatorType)`, `calculateClickMultiplier(upgrades)`, `calculateGlobalMultiplier(upgrades)`.

## Achievements

Manager prefix `achievement.`: `initialize(silentLoad=false)`, `saveToState()`, `checkAllAchievements()`, `checkAchievementCategory(category)`, `unlockAchievement(achievementId)`, `silentUnlockAchievement(achievementId)`, `reapplyAllAchievementRewards()`, `restoreUnlockedAchievements(achievementIds)`, `getAllAchievements()`, `getUnlockedAchievements()`, `getVisibleLockedAchievements()`, `getAchievementProgress(achievementId)`, `isAchievementUnlocked(achievementId)`, `getTotalAchievementCount()`, `getUnlockedCount()`, `getClickCount()`, `setClickCount(count)`, `setCustomEvents(events)`, `triggerCustomEvent(eventName)`, `getCustomEvents()`, `getAllCustomEvents()`, `hasCustomEventOccurred(eventName)`, `getAchievementDetails(achievementId)`, `reset()`. Browser console detection calls added `markConsoleOpened()`.

Pure prefix `model.achievement.`: `initializeAchievements()`, `checkAchievementRequirement(achievement,gameState)` with the source flattened check-state shape, `getCategoryIcon(category)`, `getAchievementIcon(achievement)`.

## Prestige, golden and bosses

Manager `prestige.`: `getPendingPoints()`, `getMultiplier()`, `getState()`, `getBonusPerPoint()`, `getMinTotalBufos()`, `canTranscend()`, `transcend()`, `reset()`. Root must route every facade/manager transcend through candidate persistence before acceptance. Pure `model.prestige.`: `prestigePointsFor(totalBufos)`, `getPrestigeMultiplier(state)`.

Manager `golden.`: `start()`, `stop()`, `isActive()`, `getActiveFrenzies()`, `collect(id?)`, `reset()`, `forceSpawn()`. Added `getActiveSpawn()` returns the spawn for rendering; `tick()` processes deadlines. Runtime fields under `runtime.golden` are running, firstSpawnDone, nextId, active, nextSpawnAt, expiresAt, productionFrenzyEndsAt, clickFrenzyEndsAt. Root stops on hide and starts on resume; no deadline shift needed because stop clears frenzies/spawn.

Manager `boss.`: `getAvailableBoss()`, `getActiveFight()`, `getScaledHealth(boss)`, `getMultiplier()`, `getDefeatedCount()`, `startFight()`, `hit(amount)`, `retreat()`, `pause()`, `resume()`, `reset()`. Added `tick(delta)` accumulates seconds into 100ms source countdown steps. `runtime.boss.fight` has the source fight shape; paused freezes countdown. Root sends `registerClick()` separately for UI boss hits; manager `hit` alone never counts clicks.

Pure `model.boss.`: `findBoss(id)`, `getAvailableBoss(defeated,totalBufos)`, `getBossMultiplier(state)`, `getBossHealth(boss,state)`.
