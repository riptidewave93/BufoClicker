identification division.
program-id. BUFO-API recursive.
environment division.
configuration section.
repository. function J-NUM function J-STR function all intrinsic.
data division.
local-storage section.
01 path-node usage pointer.
01 values-node usage pointer.
01 child usage pointer.
01 arguments-node usage pointer.
01 node usage pointer.
01 temp usage pointer.
01 selector pic x(128).
01 namespace-name pic x(64).
01 method-name pic x(64).
01 module-name pic x(32).
01 text-value pic x(32768).
01 argument-key pic x(64).
01 argument-z pic x(65).
01 argument-index usage binary-long.
01 path-count usage binary-long.
01 path-index usage binary-long.
01 read-only usage binary-long.
01 flag usage binary-long.
01 number-value usage comp-2.
linkage section.
01 req usage pointer.
01 ctx usage pointer.
01 res usage pointer.
procedure division using by value req ctx res.
call static 'j_get_into' using by value req by reference z'args.path' path-node end-call
call static 'j_get_into' using by value req by reference z'args.values' values-node end-call
call static 'j_size' using by value path-node by reference x'00' returning path-count end-call
call static 'j_at_into' using by value path-node 0 by reference node end-call
move function J-STR(node,' ') to namespace-name
compute path-index = path-count - 1
call static 'j_at_into' using by value path-node path-index by reference node end-call
move function J-STR(node,' ') to method-name
if namespace-name = 'debugTools'
 call static 'j_at_into' using by value path-node 1 by reference node end-call
 move function J-STR(node,' ') to namespace-name
end-if
if namespace-name = 'generators' move 'generator' to namespace-name end-if
if namespace-name = 'upgrades' move 'upgrade' to namespace-name end-if
if namespace-name = 'achievements' move 'achievement' to namespace-name end-if
if namespace-name = 'gameCore' and path-count > 2
 call static 'j_at_into' using by value path-node 1 by reference node end-call
 evaluate function J-STR(node,' ')
when 'getGeneratorManager' move 'generator' to namespace-name
when 'getUpgradeManager' move 'upgrade' to namespace-name
when 'getAchievementManager' move 'achievement' to namespace-name
when 'getExplorerManager' move 'explorer' to namespace-name
when 'getPrestigeManager' move 'prestige' to namespace-name
when 'getGoldenBufoManager' move 'goldenManager' to namespace-name
when 'getBossManager' move 'bossManager' to namespace-name
end-evaluate end-if
string function trim(namespace-name) '.' function trim(method-name) into selector end-string
call static 'j_clone_into' using by value req by reference child end-call
call static 'j_clone_into' using by value path-node by reference temp end-call
call static 'j_set' using by value child by reference z'apiPath' by value temp end-call

call static 'j_object_into' using by reference arguments-node end-call
call static 'j_set' using by value child by reference z'args' by value arguments-node end-call
call static 'j_set_boolean' using by value res by reference z'ok' by value 1 end-call
evaluate selector
when 'ui.createResourceDisplay' when 'createResourceDisplay.createResourceDisplay'
move 'component.createResourceDisplay' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-COMPONENTS' to module-name
call static 'j_clone_into' using by value values-node by reference temp end-call
call static 'j_set' using by value child by reference z'args' by value temp end-call
when 'ui.createClickArea' when 'createClickArea.createClickArea'
move 'component.createClickArea' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-COMPONENTS' to module-name
call static 'j_clone_into' using by value values-node by reference temp end-call
call static 'j_set' using by value child by reference z'args' by value temp end-call
when 'ui.createGeneratorList' when 'createGeneratorList.createGeneratorList'
move 'component.createGeneratorList' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-COMPONENTS' to module-name
call static 'j_clone_into' using by value values-node by reference temp end-call
call static 'j_set' using by value child by reference z'args' by value temp end-call
when 'ui.createShop' when 'createShop.createShop'
move 'component.createShop' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-COMPONENTS' to module-name
call static 'j_clone_into' using by value values-node by reference temp end-call
call static 'j_set' using by value child by reference z'args' by value temp end-call
when 'ui.createUpgradeList' when 'createUpgradeList.createUpgradeList'
move 'component.createUpgradeList' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-COMPONENTS' to module-name
call static 'j_clone_into' using by value values-node by reference temp end-call
call static 'j_set' using by value child by reference z'args' by value temp end-call
when 'ui.createProductionStats' when 'createProductionStats.createProductionStats'
move 'component.createProductionStats' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-COMPONENTS' to module-name
call static 'j_clone_into' using by value values-node by reference temp end-call
call static 'j_set' using by value child by reference z'args' by value temp end-call
when 'ui.initializeUI' when 'initializeUI.initializeUI'
move 'component.initializeUI' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-COMPONENTS' to module-name
call static 'j_clone_into' using by value values-node by reference temp end-call
call static 'j_set' using by value child by reference z'args' by value temp end-call
when 'getGameCore.getGameCore' when 'game.getGameCore'
move 1 to read-only
call static 'j_parse_into' using by reference '["gameCore"]' by value 12 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'getGameLoop.getGameLoop' when 'game.getGameLoop'
move 1 to read-only
call static 'j_parse_into' using by reference '["gameLoop"]' by value 12 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'getStateManager.getStateManager' when 'game.getStateManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["state"]' by value 9 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'getEventBus.getEventBus' when 'game.getEventBus'
move 1 to read-only
call static 'j_parse_into' using by reference '["events"]' by value 10 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'getUIManager.getUIManager' when 'game.getUIManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["ui"]' by value 6 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'getSaveManager.getSaveManager' when 'game.getSaveManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["saveManager"]' by value 15 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'getGeneratorManager.getGeneratorManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["generator"]' by value 13 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'getUpgradeManager.getUpgradeManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["upgrade"]' by value 11 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'getAchievementManager.getAchievementManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["achievement"]' by value 15 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'getExplorerManager.getExplorerManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["explorer"]' by value 12 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'getPrestigeManager.getPrestigeManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["prestige"]' by value 12 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'getGoldenBufoManager.getGoldenBufoManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["goldenManager"]' by value 17 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'getBossManager.getBossManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["bossManager"]' by value 15 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'generator.recalculateGenerator'
move 'generator.recalculateGenerator' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'generatorType' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'generator.recalculateAllGenerators'
move 'generator.recalculateAllGenerators' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'generator.checkUnlocks'
move 'generator.checkUnlocks' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'totalBufos' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'generator.purchaseGenerator'
move 'generator.purchaseGenerator' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'generatorType' to argument-key perform named-argument
move 1 to argument-index move 'quantity' to argument-key perform named-argument
move 2 to argument-index move 'availableBufos' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'generator.getMaxAffordable'
move 'generator.getMaxAffordable' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'generatorType' to argument-key perform named-argument
move 1 to argument-index move 'availableBufos' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'generator.calculateTotalProduction'
move 'generator.calculateTotalProduction' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'generator.calculateProductionForTime'
move 'generator.calculateProductionForTime' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'seconds' to argument-key perform named-argument
move 1 to argument-index move 'multiplier' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'generator.getProductionStats'
move 'generator.getProductionStats' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'generator.applyBoostToGenerator'
move 'generator.applyBoostToGenerator' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'generatorType' to argument-key perform named-argument
move 1 to argument-index move 'boostId' to argument-key perform named-argument
move 2 to argument-index move 'multiplier' to argument-key perform named-argument
move 3 to argument-index move 'source' to argument-key perform named-argument
move 4 to argument-index move 'active' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'generator.toggleGeneratorBoost'
move 'generator.toggleGeneratorBoost' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'generatorType' to argument-key perform named-argument
move 1 to argument-index move 'boostId' to argument-key perform named-argument
move 2 to argument-index move 'active' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'generator.getAllGenerators'
move 'generator.getAllGenerators' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'generator.getUnlockedGenerators'
move 'generator.getUnlockedGenerators' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'generator.reset'
move 'generator.reset' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'upgrade.initialize'
move 'upgrade.initialize' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'upgrade.checkAvailableUpgrades'
move 'upgrade.checkAvailableUpgrades' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'state' to argument-key perform named-argument
move 1 to argument-index move 'generatorCounts' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'upgrade.purchaseUpgrade'
move 'upgrade.purchaseUpgrade' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'upgradeId' to argument-key perform named-argument
move 1 to argument-index move 'currentBufos' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'upgrade.applyUpgradeEffects'
move 'upgrade.applyUpgradeEffects' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'upgrade' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'upgrade.calculateTotalMultiplierForGenerator'
move 'upgrade.calculateTotalMultiplierForGenerator' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'generatorType' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'upgrade.calculateTotalClickMultiplier'
move 'upgrade.calculateTotalClickMultiplier' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'upgrade.reapplyAllUpgrades'
move 'upgrade.reapplyAllUpgrades' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'upgrade.getUpgradeEffects'
move 'upgrade.getUpgradeEffects' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'upgradeId' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'upgrade.findUpgradeById'
move 'upgrade.findUpgradeById' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'upgradeId' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'upgrade.getAvailableUpgrades'
move 'upgrade.getAvailableUpgrades' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'upgrade.getPurchasedUpgrades'
move 'upgrade.getPurchasedUpgrades' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'upgrade.isUpgradePurchased'
move 'upgrade.isUpgradePurchased' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'upgradeId' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'upgrade.setUpgrades'
move 'upgrade.setUpgrades' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'upgrades' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'upgrade.getAllUpgrades'
move 'upgrade.getAllUpgrades' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'upgrade.reset'
move 'upgrade.reset' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'achievement.initialize'
move 'achievement.initialize' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'silentLoad' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'achievement.saveToState'
move 'achievement.saveToState' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'achievement.checkAllAchievements'
move 'achievement.checkAllAchievements' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'achievement.checkAchievementCategory'
move 'achievement.checkAchievementCategory' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'category' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'achievement.unlockAchievement'
move 'achievement.unlockAchievement' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'achievementId' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'achievement.silentUnlockAchievement'
move 'achievement.silentUnlockAchievement' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'achievementId' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'achievement.reapplyAllAchievementRewards'
move 'achievement.reapplyAllAchievementRewards' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'achievement.restoreUnlockedAchievements'
move 'achievement.restoreUnlockedAchievements' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'achievementIds' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'achievement.getAllAchievements'
move 'achievement.getAllAchievements' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'achievement.getUnlockedAchievements'
move 'achievement.getUnlockedAchievements' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'achievement.getVisibleLockedAchievements'
move 'achievement.getVisibleLockedAchievements' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'achievement.getAchievementProgress'
move 'achievement.getAchievementProgress' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'achievementId' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'achievement.isAchievementUnlocked'
move 'achievement.isAchievementUnlocked' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'achievementId' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'achievement.getTotalAchievementCount'
move 'achievement.getTotalAchievementCount' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'achievement.getUnlockedCount'
move 'achievement.getUnlockedCount' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'achievement.getClickCount'
move 'achievement.getClickCount' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'achievement.setClickCount'
move 'achievement.setClickCount' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'count' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'achievement.setCustomEvents'
move 'achievement.setCustomEvents' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'events' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'achievement.triggerCustomEvent'
move 'achievement.triggerCustomEvent' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'eventName' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'achievement.getCustomEvents'
move 'achievement.getCustomEvents' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'achievement.getAllCustomEvents'
move 'achievement.getAllCustomEvents' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'achievement.hasCustomEventOccurred'
move 'achievement.hasCustomEventOccurred' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'eventName' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'achievement.getAchievementDetails'
move 'achievement.getAchievementDetails' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'achievementId' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'achievement.reset'
move 'achievement.reset' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'prestige.getPendingPoints'
move 'prestige.getPendingPoints' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'prestige.getMultiplier'
move 'prestige.getMultiplier' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'prestige.getState'
move 'prestige.getState' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'prestige.getBonusPerPoint'
move 'prestige.getBonusPerPoint' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'prestige.getMinTotalBufos'
move 'prestige.getMinTotalBufos' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'prestige.canTranscend'
move 'prestige.canTranscend' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'prestige.transcend'
move 'prestige' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-SAVE' to module-name
when 'prestige.reset'
move 'prestige.reset' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'goldenManager.start'
move 'golden.start' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'goldenManager.stop'
move 'golden.stop' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'goldenManager.isActive'
move 'golden.isActive' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'goldenManager.getActiveFrenzies'
move 'golden.getActiveFrenzies' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'goldenManager.collect'
move 'golden.collect' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'id' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'goldenManager.reset'
move 'golden.reset' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'goldenManager.forceSpawn'
move 'golden.forceSpawn' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'bossManager.getAvailableBoss'
move 'boss.getAvailableBoss' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'bossManager.getActiveFight'
move 'boss.getActiveFight' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'bossManager.getScaledHealth'
move 'boss.getScaledHealth' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'boss' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'bossManager.getMultiplier'
move 'boss.getMultiplier' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'bossManager.getDefeatedCount'
move 'boss.getDefeatedCount' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'bossManager.startFight'
move 'boss.startFight' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'bossManager.hit'
move 'boss.hit' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'amount' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'bossManager.retreat'
move 'boss.retreat' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'bossManager.pause'
move 'boss.pause' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'bossManager.resume'
move 'boss.resume' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'bossManager.reset'
move 'boss.reset' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'explorer.getExplorer'
move 'getExplorer' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-EXPLORER' to module-name
move 1 to read-only
when 'explorer.getCurrentEnemy'
move 'getCurrentEnemy' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-EXPLORER' to module-name
move 1 to read-only
when 'explorer.getCurrentCombat'
move 'getCurrentCombat' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-EXPLORER' to module-name
move 1 to read-only
when 'explorer.update'
move 'update' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'delta' to argument-key perform named-argument
move 'BUFO-EXPLORER' to module-name
when 'explorer.startExploration'
move 'startExploration' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'area' to argument-key perform named-argument
move 'BUFO-EXPLORER' to module-name
when 'explorer.performCombatAction'
move 'performCombatAction' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'action' to argument-key perform named-argument
move 'BUFO-EXPLORER' to module-name
when 'explorer.autoResolveCombat'
move 'autoResolveCombat' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-EXPLORER' to module-name
when 'explorer.upgradeExplorerStat'
move 'upgradeExplorerStat' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'statName' to argument-key perform named-argument
move 1 to argument-index move 'availableBufos' to argument-key perform named-argument
move 'BUFO-EXPLORER' to module-name
when 'explorer.getExplorerStats'
move 'getExplorerStats' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-EXPLORER' to module-name
move 1 to read-only
when 'explorer.getAvailableAreas'
move 'getAvailableAreas' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-EXPLORER' to module-name
move 1 to read-only
when 'explorer.reset'
move 'reset' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-EXPLORER' to module-name
when 'game.click'
move 'click' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'game.buyGenerator'
move 'buyGenerator' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'generatorType' to argument-key perform named-argument
move 1 to argument-index move 'quantity' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'game.buyUpgrade'
move 'buyUpgrade' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'upgradeId' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
when 'game.getGenerators'
move 'generator.getAllGenerators' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'game.getProductionStatistics'
move 'generator.getProductionStats' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'game.getPurchasedUpgrades'
move 'upgrade.getPurchasedUpgrades' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'game.getAvailableUpgrades'
move 'upgrade.checkAvailableUpgrades' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'game.getMaxAffordable'
move 'generator.getMaxAffordable' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'generatorType' to argument-key perform named-argument
move 'BUFO-GAME' to module-name
move 1 to read-only
call static 'j_get_into' using by value ctx by reference z'state.resources.bufos' node end-call
call static 'j_clone_into' using by value node by reference temp end-call
call static 'j_set' using by value arguments-node by reference z'availableBufos' by value temp end-call
when 'game.getExplorer'
move 'getExplorer' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-EXPLORER' to module-name
move 1 to read-only
when 'game.startExploration'
move 'startExploration' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'area' to argument-key perform named-argument
move 'BUFO-EXPLORER' to module-name
when 'game.upgradeExplorerStat'
move 'upgradeExplorerStat' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'statName' to argument-key perform named-argument
move 'BUFO-EXPLORER' to module-name
call static 'j_get_into' using by value ctx by reference z'state.resources.bufos' node end-call
call static 'j_clone_into' using by value node by reference temp end-call
call static 'j_set' using by value arguments-node by reference z'availableBufos' by value temp end-call
when 'game.getExplorerStats'
move 'getExplorerStats' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-EXPLORER' to module-name
move 1 to read-only
when 'game.getAvailableAreas'
move 'getAvailableAreas' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-EXPLORER' to module-name
move 1 to read-only
when 'gameCore.click'
move 'click' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'gameCore.registerClick'
move 'registerClick' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'gameCore.checkUnlocks'
move 'checkUnlocks' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
when 'game.save'
move 'save' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-SAVE' to module-name
move 1 to read-only
when 'game.load'
move 'load' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-SAVE' to module-name
move 1 to read-only
when 'game.exportSave'
move 'export' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-SAVE' to module-name
move 1 to read-only
when 'game.importSave'
move 'import' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'raw' to argument-key perform named-argument
move 'BUFO-SAVE' to module-name
move 1 to read-only
when 'game.reset'
move 'game.reset' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-API-EXTRA' to module-name
move 1 to read-only
call static 'j_clone_into' using by value values-node by reference temp end-call
call static 'j_set' using by value child by reference z'args' by value temp end-call
when 'gameCore.resetState'
move 'reset' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-SAVE' to module-name
move 1 to read-only
when 'save.save'
move 'save' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-SAVE' to module-name
move 1 to read-only
when 'save.load'
move 'load' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-SAVE' to module-name
move 1 to read-only
when 'save.export'
move 'export' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-SAVE' to module-name
move 1 to read-only
when 'save.import'
move 'import' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 0 to argument-index move 'raw' to argument-key perform named-argument
move 'BUFO-SAVE' to module-name
move 1 to read-only
when 'game.getState'
move 'stateManager.getState' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-SERVICES' to module-name
move 1 to read-only
call static 'j_clone_into' using by value values-node by reference temp end-call
call static 'j_set' using by value child by reference z'args' by value temp end-call
when 'state.getState'
move 'stateManager.getState' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-SERVICES' to module-name
move 1 to read-only
call static 'j_clone_into' using by value values-node by reference temp end-call
call static 'j_set' using by value child by reference z'args' by value temp end-call
when 'inspect.state'
move 'stateManager.getState' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-SERVICES' to module-name
move 1 to read-only
call static 'j_clone_into' using by value values-node by reference temp end-call
call static 'j_set' using by value child by reference z'args' by value temp end-call
when 'inspect.generators'
move 'generator.getAllGenerators' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'inspect.production'
move 'generator.getProductionStats' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-GAME' to module-name
move 1 to read-only
when 'inspect.explorer'
move 'getExplorer' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move 'BUFO-EXPLORER' to module-name
move 1 to read-only
when 'gameCore.getGeneratorManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["generator"]' by value 13 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'gameCore.getUpgradeManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["upgrade"]' by value 11 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'gameCore.getExplorerManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["explorer"]' by value 12 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'gameCore.getAchievementManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["achievement"]' by value 15 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'gameCore.getPrestigeManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["prestige"]' by value 12 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'gameCore.getGoldenBufoManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["goldenManager"]' by value 17 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'gameCore.getBossManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["bossManager"]' by value 15 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'game.getGeneratorManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["generator"]' by value 13 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'game.getUpgradeManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["upgrade"]' by value 11 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'game.getExplorerManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["explorer"]' by value 12 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'game.getAchievementManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["achievement"]' by value 15 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'game.getPrestigeManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["prestige"]' by value 12 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'game.getGoldenBufoManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["goldenManager"]' by value 17 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when 'game.getBossManager'
move 1 to read-only
call static 'j_parse_into' using by reference '["bossManager"]' by value 15 by reference temp end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value temp end-call
when other
 evaluate namespace-name
 when 'state' move 'stateManager' to namespace-name
 when 'events' move 'event' to namespace-name
 when 'logging' move 'logger' to namespace-name
  evaluate method-name
  when 'setLevel' move 'setLogLevel' to method-name
  when 'getLevel' move 'getLogLevel' to method-name
  end-evaluate
 when 'dataLoader' move 'data' to namespace-name
 when 'storageUtils' move 'storage' to namespace-name
 end-evaluate
 if namespace-name = 'stateManager' or 'event' or 'logger' or 'data' or 'number' or 'math' or 'utils' or 'validation' or 'gameState'
 move spaces to text-value
 string function trim(namespace-name) '.' function trim(method-name) into text-value end-string
 call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value)) end-call
call static 'j_clone_into' using by value values-node by reference temp end-call
call static 'j_set' using by value child by reference z'args' by value temp end-call
move 'BUFO-SERVICES' to module-name
 if method-name(1:3) = 'get' or method-name(1:2) = 'is' or method-name(1:3) = 'has' or namespace-name = 'number' or 'math' or 'validation' or 'gameState'
 move 1 to read-only end-if
 else
 move spaces to selector
string function trim(namespace-name) '.' function trim(method-name) into selector end-string
move 'BUFO-API-EXTRA' to module-name
call static 'j_clone_into' using by value values-node by reference temp end-call
call static 'j_set' using by value child by reference z'args' by value temp end-call
move selector to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
end-if
end-evaluate
call static 'j_boolean' using by value ctx by reference z'runtime.persistence.blocked' returning flag end-call
if flag = 1 and read-only = 0 and module-name not = 'BUFO-API-EXTRA'
call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
move 'Progress is paused until save recovery succeeds.' to text-value
call static 'j_set_string' using by value res by reference z'error' text-value by value function length(function trim(text-value trailing)) end-call
else
 if module-name not = spaces
 evaluate module-name
when 'BUFO-GAME' call static 'BUFO-GAME' using by value child ctx res end-call
when 'BUFO-EXPLORER' call static 'BUFO-EXPLORER' using by value child ctx res end-call
when 'BUFO-SAVE' call static 'BUFO-SAVE' using by value child ctx res end-call
when 'BUFO-COMPONENTS' call static 'BUFO-COMPONENTS' using by value child ctx res end-call
when 'BUFO-SERVICES' call static 'BUFO-SERVICES' using by value child ctx res end-call
when 'BUFO-API-EXTRA' call static 'BUFO-API-EXTRA' using by value child ctx res end-call
end-evaluate
 end-if
 if selector = 'gameCore.resetState'
 call static 'j_remove' using by value res by reference z'result' end-call
 end-if
 if selector = 'game.upgradeExplorerStat'
 call static 'j_boolean' using by value res by reference z'result.success' returning flag end-call
 if flag = 1
 move function J-NUM(ctx,'state.resources.bufos') to number-value
 compute number-value = number-value - function J-NUM(res,'result.cost')
 call static 'j_set_number' using by value ctx by reference z'state.resources.bufos' number-value end-call
 end-if end-if
end-if
call static 'j_delete' using by value child end-call
goback.
named-argument.
call static 'j_at_into' using by value values-node argument-index by reference node end-call
if node not = null
 call static 'j_clone_into' using by value node by reference temp end-call
 move low-values to argument-z
 string function trim(argument-key) x'00' into argument-z end-string
 call static 'j_set' using by value arguments-node by reference argument-z by value temp end-call
end-if.
end program BUFO-API.
