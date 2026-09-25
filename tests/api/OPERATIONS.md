# Public API facade

`api` accepts `{path: [namespace, method], values: [positional arguments]}`. Manager getters return `{$proxy: [namespace]}`. The host resolves this to its stable callable facade. Save, import, reset and transcend delegate to `BUFO-SAVE`.

| Method | Positional arguments | Module operation |
| --- | --- | --- |
| generator.recalculateGenerator | generatorType | BUFO-GAME: generator.recalculateGenerator |
| generator.recalculateAllGenerators |  | BUFO-GAME: generator.recalculateAllGenerators |
| generator.checkUnlocks | totalBufos | BUFO-GAME: generator.checkUnlocks |
| generator.purchaseGenerator | generatorType quantity availableBufos | BUFO-GAME: generator.purchaseGenerator |
| generator.getMaxAffordable | generatorType availableBufos | BUFO-GAME: generator.getMaxAffordable |
| generator.calculateTotalProduction |  | BUFO-GAME: generator.calculateTotalProduction |
| generator.calculateProductionForTime | seconds multiplier | BUFO-GAME: generator.calculateProductionForTime |
| generator.getProductionStats |  | BUFO-GAME: generator.getProductionStats |
| generator.applyBoostToGenerator | generatorType boostId multiplier source active | BUFO-GAME: generator.applyBoostToGenerator |
| generator.toggleGeneratorBoost | generatorType boostId active | BUFO-GAME: generator.toggleGeneratorBoost |
| generator.getAllGenerators |  | BUFO-GAME: generator.getAllGenerators |
| generator.getUnlockedGenerators |  | BUFO-GAME: generator.getUnlockedGenerators |
| generator.reset |  | BUFO-GAME: generator.reset |
| upgrade.initialize |  | BUFO-GAME: upgrade.initialize |
| upgrade.checkAvailableUpgrades | state generatorCounts | BUFO-GAME: upgrade.checkAvailableUpgrades |
| upgrade.purchaseUpgrade | upgradeId currentBufos | BUFO-GAME: upgrade.purchaseUpgrade |
| upgrade.applyUpgradeEffects | upgrade | BUFO-GAME: upgrade.applyUpgradeEffects |
| upgrade.calculateTotalMultiplierForGenerator | generatorType | BUFO-GAME: upgrade.calculateTotalMultiplierForGenerator |
| upgrade.calculateTotalClickMultiplier |  | BUFO-GAME: upgrade.calculateTotalClickMultiplier |
| upgrade.reapplyAllUpgrades |  | BUFO-GAME: upgrade.reapplyAllUpgrades |
| upgrade.getUpgradeEffects | upgradeId | BUFO-GAME: upgrade.getUpgradeEffects |
| upgrade.findUpgradeById | upgradeId | BUFO-GAME: upgrade.findUpgradeById |
| upgrade.getAvailableUpgrades |  | BUFO-GAME: upgrade.getAvailableUpgrades |
| upgrade.getPurchasedUpgrades |  | BUFO-GAME: upgrade.getPurchasedUpgrades |
| upgrade.isUpgradePurchased | upgradeId | BUFO-GAME: upgrade.isUpgradePurchased |
| upgrade.setUpgrades | upgrades | BUFO-GAME: upgrade.setUpgrades |
| upgrade.getAllUpgrades |  | BUFO-GAME: upgrade.getAllUpgrades |
| upgrade.reset |  | BUFO-GAME: upgrade.reset |
| achievement.initialize | silentLoad | BUFO-GAME: achievement.initialize |
| achievement.saveToState |  | BUFO-GAME: achievement.saveToState |
| achievement.checkAllAchievements |  | BUFO-GAME: achievement.checkAllAchievements |
| achievement.checkAchievementCategory | category | BUFO-GAME: achievement.checkAchievementCategory |
| achievement.unlockAchievement | achievementId | BUFO-GAME: achievement.unlockAchievement |
| achievement.silentUnlockAchievement | achievementId | BUFO-GAME: achievement.silentUnlockAchievement |
| achievement.reapplyAllAchievementRewards |  | BUFO-GAME: achievement.reapplyAllAchievementRewards |
| achievement.restoreUnlockedAchievements | achievementIds | BUFO-GAME: achievement.restoreUnlockedAchievements |
| achievement.getAllAchievements |  | BUFO-GAME: achievement.getAllAchievements |
| achievement.getUnlockedAchievements |  | BUFO-GAME: achievement.getUnlockedAchievements |
| achievement.getVisibleLockedAchievements |  | BUFO-GAME: achievement.getVisibleLockedAchievements |
| achievement.getAchievementProgress | achievementId | BUFO-GAME: achievement.getAchievementProgress |
| achievement.isAchievementUnlocked | achievementId | BUFO-GAME: achievement.isAchievementUnlocked |
| achievement.getTotalAchievementCount |  | BUFO-GAME: achievement.getTotalAchievementCount |
| achievement.getUnlockedCount |  | BUFO-GAME: achievement.getUnlockedCount |
| achievement.getClickCount |  | BUFO-GAME: achievement.getClickCount |
| achievement.setClickCount | count | BUFO-GAME: achievement.setClickCount |
| achievement.setCustomEvents | events | BUFO-GAME: achievement.setCustomEvents |
| achievement.triggerCustomEvent | eventName | BUFO-GAME: achievement.triggerCustomEvent |
| achievement.getCustomEvents |  | BUFO-GAME: achievement.getCustomEvents |
| achievement.getAllCustomEvents |  | BUFO-GAME: achievement.getAllCustomEvents |
| achievement.hasCustomEventOccurred | eventName | BUFO-GAME: achievement.hasCustomEventOccurred |
| achievement.getAchievementDetails | achievementId | BUFO-GAME: achievement.getAchievementDetails |
| achievement.reset |  | BUFO-GAME: achievement.reset |
| prestige.getPendingPoints |  | BUFO-GAME: prestige.getPendingPoints |
| prestige.getMultiplier |  | BUFO-GAME: prestige.getMultiplier |
| prestige.getState |  | BUFO-GAME: prestige.getState |
| prestige.getBonusPerPoint |  | BUFO-GAME: prestige.getBonusPerPoint |
| prestige.getMinTotalBufos |  | BUFO-GAME: prestige.getMinTotalBufos |
| prestige.canTranscend |  | BUFO-GAME: prestige.canTranscend |
| prestige.transcend |  | BUFO-SAVE: prestige |
| prestige.reset |  | BUFO-GAME: prestige.reset |
| goldenManager.start |  | BUFO-GAME: golden.start |
| goldenManager.stop |  | BUFO-GAME: golden.stop |
| goldenManager.isActive |  | BUFO-GAME: golden.isActive |
| goldenManager.getActiveFrenzies |  | BUFO-GAME: golden.getActiveFrenzies |
| goldenManager.collect | id | BUFO-GAME: golden.collect |
| goldenManager.reset |  | BUFO-GAME: golden.reset |
| goldenManager.forceSpawn |  | BUFO-GAME: golden.forceSpawn |
| bossManager.getAvailableBoss |  | BUFO-GAME: boss.getAvailableBoss |
| bossManager.getActiveFight |  | BUFO-GAME: boss.getActiveFight |
| bossManager.getScaledHealth | boss | BUFO-GAME: boss.getScaledHealth |
| bossManager.getMultiplier |  | BUFO-GAME: boss.getMultiplier |
| bossManager.getDefeatedCount |  | BUFO-GAME: boss.getDefeatedCount |
| bossManager.startFight |  | BUFO-GAME: boss.startFight |
| bossManager.hit | amount | BUFO-GAME: boss.hit |
| bossManager.retreat |  | BUFO-GAME: boss.retreat |
| bossManager.pause |  | BUFO-GAME: boss.pause |
| bossManager.resume |  | BUFO-GAME: boss.resume |
| bossManager.reset |  | BUFO-GAME: boss.reset |
| explorer.getExplorer |  | BUFO-EXPLORER: getExplorer |
| explorer.getCurrentEnemy |  | BUFO-EXPLORER: getCurrentEnemy |
| explorer.getCurrentCombat |  | BUFO-EXPLORER: getCurrentCombat |
| explorer.update | delta | BUFO-EXPLORER: update |
| explorer.startExploration | area | BUFO-EXPLORER: startExploration |
| explorer.performCombatAction | action | BUFO-EXPLORER: performCombatAction |
| explorer.autoResolveCombat |  | BUFO-EXPLORER: autoResolveCombat |
| explorer.upgradeExplorerStat | statName availableBufos | BUFO-EXPLORER: upgradeExplorerStat |
| explorer.getExplorerStats |  | BUFO-EXPLORER: getExplorerStats |
| explorer.getAvailableAreas |  | BUFO-EXPLORER: getAvailableAreas |
| explorer.reset |  | BUFO-EXPLORER: reset |


The facade also routes `game`/`gameCore`, `gameLoop`/`time`, `resources`, `inspect`, developer `golden`/`boss`, `generator_debug`/`upgrade_debug`, `state`/`stateManager`/`gameState`, `events`/`eventBus`, `logger`, `data`/`dataLoader`, `storage`/`storageUtils`, `saveManager`, `gameLoader`, `initialization`, `managers`, `performance`, `reset`, and `ui`. Aliases `generators`, `upgrades`, and `achievements` select the corresponding singular manager. Getter paths, such as `gameCore.getGeneratorManager().getAllGenerators()`, resolve to the shared manager context.

`initialization.initializeGame(rootElementId='game-container', statusCallback?)` runs the source stages through callback continuations and resolves to a boolean. `initialization.createLoadingUI(containerId='game-container')` returns a `{$proxy:['loadingUI',id]}` descriptor with `update(status)` and `remove()`. `managers.initializeManagers()` and `resetManagers()` invoke the migrated managers in source order. `gameLoader.loadGameData()` reports the preloaded catalogs separately; `verifyGameData()` returns generator/upgrade counts and completeness. Catalog validation accepts raw and loader-normalized prerequisite records.

`ui.initUI(rootElementId)`, `updateUI(state,generators)`, and the source component factories are available. `ui.getComponent(name)` returns a stable `{$component:id}` descriptor without changing the element. The host resolves component and element descriptors to their live browser objects. UI notifications return the actual created element. `ui.showModal(options)` accepts source button callbacks, returns the live modal element, and schedules `UI_MODAL_CLOSED` after 300ms. A throwing button callback leaves the modal open. The generic browser bridge supplies element handles and timers; these decisions remain in COBOL.

Callbacks cross the transport as `{$callback:id}`. Source undefined omits `result`; explicit null is retained. Nonfinite numbers use `{$oracle:'number',value:'NaN'|'Infinity'|'-Infinity'|'-0'}`. Persistence recovery blocks mutation facades while allowing reads and explicit recovery operations. `Game.reset` retains its browser confirmation. Supplied-data `SaveManager` calls persist/read the supplied snapshot without activating it, while the live game facades use transactional candidate replacement.
