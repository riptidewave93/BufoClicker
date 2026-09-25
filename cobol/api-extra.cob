identification division.
program-id. BUFO-API-EXTRA recursive.
environment division.
configuration section.
repository. function J-NUM function J-STR function all intrinsic.
data division.
local-storage section.
01 op pic x(128).
01 a usage pointer.
01 a0 usage pointer.
01 a1 usage pointer.
01 temp usage pointer.
01 node usage pointer.
01 node2 usage pointer.
01 list-node usage pointer.
01 child usage pointer.
01 child-args usage pointer.
01 child-res usage pointer.
01 command-node usage pointer.
01 commands usage pointer.
01 route-name pic x(128).
01 module-name pic x(32) value 'BUFO-GAME'.
01 text-value pic x(32768).
01 key-name pic x(256).
01 path-z pic x(512).
01 text-small pic x(256).
01 number-text pic -(18)9.9(8).
01 number-value usage comp-2.
01 x usage comp-2.
01 y usage comp-2.
01 i usage binary-long.
01 cnt usage binary-long.
01 flag usage binary-long.
01 blocked usage binary-long.
01 running usage binary-long.
linkage section.
01 req usage pointer.
01 ctx usage pointer.
01 res usage pointer.
procedure division using by value req ctx res.
move function J-STR(req,'operation') to op
call static 'j_get_into' using by value req by reference z'args' a end-call
call static 'j_at_into' using by value a 0 by reference a0 end-call
call static 'j_at_into' using by value a 1 by reference a1 end-call
call static 'j_boolean' using by value ctx by reference z'runtime.persistence.blocked' returning blocked end-call
call static 'j_set_boolean' using by value res by reference z'ok' by value 1 end-call
if blocked = 1 and op not = 'resources.get' and 'inspect.upgrades' and 'game.isAutoSaveEnabled' and 'gameCore.isAutoSaveEnabled' and 'time.getTimeScale' and 'gameLoop.getTimeScale' and 'boss.available' and 'boss.status' and 'boss.multiplier' and 'boss.defeatedCount' and 'game.reset' and 'reset.softReset' and 'reset.hardReset' and 'help.help' and op not = 'initialization.createLoadingUI' and op(1:10) not = 'loadingUI.' and op(1:11) not = 'gameLoader.' and
op(1:3) not = 'ui.' and op(1:8) not = 'storage.' and op(1:12) not = 'saveManager.'
call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
move 'Progress is paused until save recovery succeeds.' to text-value
call static 'j_set_string' using by value res by reference z'error' text-value by value function length(function trim(text-value trailing)) end-call
goback end-if
call static 'j_object_into' using by reference child-args end-call
evaluate op
when 'gameLoader.isGameDataLoaded' when 'gameLoader.loadGameData' when 'gameLoader.verifyGameData'
call static 'j_size' using by value ctx by reference z'catalog.generators' returning cnt end-call
call static 'j_size' using by value ctx by reference z'catalog.upgrades' returning i end-call
call static 'j_size' using by value ctx by reference z'catalog.achievements' returning running end-call
move 0 to flag if cnt > 0 and i > 0 and running > 0 move 1 to flag end-if
evaluate op
when 'gameLoader.isGameDataLoaded'
call static 'j_set_boolean' using by value res by reference z'result' by value flag end-call
when 'gameLoader.loadGameData'
call static 'j_set_boolean' using by value res by reference z'result.isComplete' by value flag end-call
move 0 to flag if cnt > 0 move 1 to flag end-if
call static 'j_set_boolean' using by value res by reference z'result.generators' by value flag end-call
move 0 to flag if i > 0 move 1 to flag end-if
call static 'j_set_boolean' using by value res by reference z'result.upgrades' by value flag end-call
move 0 to flag if running > 0 move 1 to flag end-if
call static 'j_set_boolean' using by value res by reference z'result.achievements' by value flag end-call
when other
move cnt to number-value
call static 'j_set_number' using by value res by reference z'result.generatorsLoaded' number-value end-call
move i to number-value
call static 'j_set_number' using by value res by reference z'result.upgradesLoaded' number-value end-call
call static 'j_set_boolean' using by value res by reference z'result.isComplete' by value flag end-call
end-evaluate
when 'managers.initializeManagers'
move 'model.upgrade.initializeUpgrades' to route-name perform domain-call
call static 'j_get_into' using by value res by reference z'result' node end-call
call static 'j_clone_into' using by value node by reference temp end-call
call static 'j_set' using by value child-args by reference z'upgrades' by value temp end-call
move 'upgrade.setUpgrades' to route-name perform domain-call
move 'generator.recalculateAllGenerators' to route-name perform domain-call
call static 'j_remove' using by value res by reference z'result' end-call
when 'managers.resetManagers'
move 'generator.reset' to route-name perform domain-call
move 'BUFO-EXPLORER' to module-name move 'reset' to route-name perform domain-call
move 'BUFO-GAME' to module-name
move 'upgrade.reset' to route-name perform domain-call
move 'achievement.reset' to route-name perform domain-call
move 'prestige.reset' to route-name perform domain-call
move 'golden.reset' to route-name perform domain-call
move 'boss.reset' to route-name perform domain-call
call static 'j_remove' using by value res by reference z'result' end-call
when 'resources.get'
call static 'j_object_into' using by reference node end-call
move function J-NUM(ctx,'state.resources.bufos') to number-value
call static 'j_set_number' using by value node by reference z'bufos' number-value end-call
move function J-NUM(ctx,'state.resources.totalBufos') to number-value
call static 'j_set_number' using by value node by reference z'totalBufos' number-value end-call
call static 'j_set' using by value res by reference z'result' by value node end-call

when 'resources.add' when 'resources.set'
move function J-NUM(a0,' ') to x
move function J-NUM(ctx,'state.resources.bufos') to y
if op = 'resources.add' call static 'h_number_binary' using by value 1 by reference x y x end-call end-if
move x to number-value
call static 'j_set_number' using by value ctx by reference z'state.resources.bufos' number-value end-call
move x to number-value
call static 'j_set_number' using by value res by reference z'result' number-value end-call
move function J-NUM(ctx,'state.resources.totalBufos') to y
if op = 'resources.add'
move function J-NUM(a0,' ') to x
call static 'h_number_binary' using by value 1 by reference x y x end-call
else
call static 'h_number_compare' using by reference x y returning flag end-call
if flag < 0 move y to x end-if
end-if
move x to number-value
call static 'j_set_number' using by value ctx by reference z'state.resources.totalBufos' number-value end-call

when 'golden.spawn'
move 'golden.forceSpawn' to route-name perform domain-call
move 'Golden Bufo spawned (or already on screen)' to text-value
call static 'j_set_string' using by value res by reference z'result' text-value by value function length(function trim(text-value trailing)) end-call

when 'golden.collect'
move 'golden.collect' to route-name perform domain-call
call static 'j_type' using by value res by reference z'result' returning flag end-call
if flag = 0
move 'No Golden Bufo on screen' to text-value
call static 'j_set_string' using by value res by reference z'result' text-value by value function length(function trim(text-value trailing)) end-call
else
move spaces to text-value
string 'Collected: ' function trim(function J-STR(res,'result.label')) ' - ' function trim(function J-STR(res,'result.detail')) into text-value end-string
call static 'j_set_string' using by value res by reference z'result' text-value by value function length(function trim(text-value)) end-call
end-if
when 'boss.available' move 'boss.getAvailableBoss' to route-name perform domain-call
when 'boss.status' move 'boss.getActiveFight' to route-name perform domain-call
when 'boss.multiplier' move 'boss.getMultiplier' to route-name perform domain-call
when 'boss.defeatedCount' move 'boss.getDefeatedCount' to route-name perform domain-call
when 'boss.start'
move 'boss.startFight' to route-name perform domain-call
call static 'j_boolean' using by value res by reference z'result' returning flag end-call
if flag = 1
move 'Fight started' to text-value
call static 'j_set_string' using by value res by reference z'result' text-value by value function length(function trim(text-value trailing)) end-call
else
move 'No boss available (or one is already active)' to text-value
call static 'j_set_string' using by value res by reference z'result' text-value by value function length(function trim(text-value trailing)) end-call
end-if
when 'boss.hit'
call static 'j_type' using by value a0 by reference x'00' returning flag end-call
if flag = 0
call static 'j_get_into' using by value ctx by reference z'state.resources.clickPower' a0 end-call
end-if
call static 'j_clone_into' using by value a0 by reference temp end-call
call static 'j_set' using by value child-args by reference z'amount' by value temp end-call
move 'boss.hit' to route-name perform domain-call
when 'boss.win'
call static 'j_get_into' using by value ctx by reference z'runtime.boss.fight' node end-call
call static 'j_type' using by value node by reference x'00' returning flag end-call
if flag = 5
call static 'j_get_into' using by value node by reference z'health' node2 end-call
call static 'j_clone_into' using by value node2 by reference temp end-call
call static 'j_set' using by value child-args by reference z'amount' by value temp end-call
move 'boss.hit' to route-name perform domain-call
else
move 'No active fight' to text-value
call static 'j_set_string' using by value res by reference z'result' text-value by value function length(function trim(text-value trailing)) end-call
end-if
when 'boss.lose'
call static 'j_get_into' using by value ctx by reference z'runtime.boss.fight' node end-call
call static 'j_type' using by value node by reference x'00' returning flag end-call
if flag not = 5
move 'No active fight' to text-value
call static 'j_set_string' using by value res by reference z'result' text-value by value function length(function trim(text-value trailing)) end-call
else
move 'boss.retreat' to route-name perform domain-call
move 0 to number-value
call static 'j_set_number' using by value ctx by reference z'state.resources.bufos' number-value end-call
move 'Simulated a loss (bufos zeroed, fight cleared)' to text-value
call static 'j_set_string' using by value res by reference z'result' text-value by value function length(function trim(text-value trailing)) end-call

end-if
when 'time.pause' when 'gameLoop.stop'
call static 'j_set_boolean' using by value ctx by reference z'runtime.loop.running' by value 0 end-call

when 'time.resume' when 'gameLoop.start'
call static 'j_set_boolean' using by value ctx by reference z'runtime.loop.running' by value 1 end-call
move function J-NUM(ctx,'runtime.now') to number-value
call static 'j_set_number' using by value ctx by reference z'runtime.loop.lastFrame' number-value end-call
move 0 to number-value
call static 'j_set_number' using by value ctx by reference z'runtime.loop.accumulator' number-value end-call

when 'time.getTimeScale' when 'gameLoop.getTimeScale'
move function J-NUM(ctx,'runtime.loop.scale') to number-value
call static 'j_set_number' using by value res by reference z'result' number-value end-call

when 'time.setTimeScale' when 'gameLoop.setTimeScale'
move function J-NUM(a0,' ') to x
call static 'j_parse_into' using by reference '0.1' by value 3 by reference node end-call
move function J-NUM(node,' ') to y
call static 'j_delete' using by value node end-call
move 5 to number-value perform clamp-loop-value
move x to number-value
call static 'j_set_number' using by value ctx by reference z'runtime.loop.scale' number-value end-call

when 'gameLoop.setTargetFPS'
move function J-NUM(a0,' ') to x
move 10 to y move 144 to number-value perform clamp-loop-value
move x to number-value
call static 'j_set_number' using by value ctx by reference z'runtime.loop.fps' number-value end-call

when 'game.start' when 'gameCore.start' when 'game.init' when 'gameCore.init'
if op = 'game.init' or 'gameCore.init'
move 'BUFO-SAVE' to module-name move 'load' to route-name perform domain-call
move 'BUFO-GAME' to module-name
move 'checkUnlocks' to route-name perform domain-call
move 'generator.recalculateAllGenerators' to route-name perform domain-call
call static 'j_remove' using by value res by reference z'result' end-call
end-if
call static 'j_set_boolean' using by value ctx by reference z'runtime.game.destroyed' by value 0 end-call
if op = 'game.start' or 'game.init'
call static 'j_set_boolean' using by value ctx by reference z'runtime.loop.running' by value 1 end-call
move function J-NUM(ctx,'runtime.now') to number-value
call static 'j_set_number' using by value ctx by reference z'runtime.loop.lastFrame' number-value end-call
end-if
call static 'j_boolean' using by value ctx by reference z'runtime.game.running' returning running end-call
if running not = 1
call static 'j_set_boolean' using by value ctx by reference z'runtime.game.running' by value 1 end-call
move 'golden.start' to route-name perform domain-call
move 'boss.resume' to route-name perform domain-call
move 'GAME_STARTED' to key-name perform event-empty
end-if
when 'game.stop' when 'gameCore.stop' when 'gameCore.destroy'
if op = 'game.stop'
call static 'j_set_boolean' using by value ctx by reference z'runtime.loop.running' by value 0 end-call
end-if
call static 'j_has' using by value ctx by reference z'runtime.game.running' returning flag end-call
call static 'j_boolean' using by value ctx by reference z'runtime.game.running' returning running end-call
if flag = 0 or running = 1
call static 'j_set_boolean' using by value ctx by reference z'runtime.game.running' by value 0 end-call
move 'golden.stop' to route-name perform domain-call
move 'boss.pause' to route-name perform domain-call
move 'GAME_PAUSED' to key-name perform event-empty
end-if
if op = 'gameCore.destroy'
call static 'j_set_boolean' using by value ctx by reference z'runtime.game.destroyed' by value 1 end-call
end-if
when 'game.toggleAutoSave' when 'gameCore.toggleAutoSave'
call static 'j_boolean' using by value a0 by reference x'00' returning flag end-call
call static 'j_set_boolean' using by value ctx by reference z'state.gameSettings.autoSave' by value flag end-call
call static 'j_object_into' using by reference node2 end-call
call static 'j_set_boolean' using by value node2 by reference z'enabled' by value flag end-call
move 'autoSaveToggled' to key-name perform event-with-payload
call static 'j_delete' using by value node2 end-call
when 'game.isAutoSaveEnabled' when 'gameCore.isAutoSaveEnabled'
call static 'j_boolean' using by value ctx by reference z'state.gameSettings.autoSave' returning flag end-call
call static 'j_set_boolean' using by value res by reference z'result' by value flag end-call

when 'gameCore.processTick'
call static 'j_has' using by value ctx by reference z'runtime.game.running' returning flag end-call
call static 'j_boolean' using by value ctx by reference z'runtime.game.running' returning running end-call
if flag = 0 or running = 1
call static 'j_clone_into' using by value a0 by reference temp end-call
call static 'j_set' using by value child-args by reference z'delta' by value temp end-call
call static 'j_set_boolean' using by value child-args by reference z'deferChecks' by value 1 end-call
move 'tick' to route-name perform domain-call
move 'BUFO-EXPLORER' to module-name move 'update' to route-name perform domain-call
move 'BUFO-GAME' to module-name move 'finishTick' to route-name perform domain-call
call static 'j_remove' using by value res by reference z'result' end-call
end-if
when 'inspect.upgrades'
call static 'j_object_into' using by reference list-node end-call
move 'upgrade.getPurchasedUpgrades' to route-name perform domain-call
call static 'j_get_into' using by value res by reference z'result' node end-call
call static 'j_clone_into' using by value node by reference temp end-call
call static 'j_set' using by value list-node by reference z'purchased' by value temp end-call
move 'upgrade.getAvailableUpgrades' to route-name perform domain-call
call static 'j_get_into' using by value res by reference z'result' node end-call
call static 'j_clone_into' using by value node by reference temp end-call
call static 'j_set' using by value list-node by reference z'available' by value temp end-call
call static 'j_set' using by value res by reference z'result' by value list-node end-call
when 'generator_debug.unlockAll'
call static 'j_get_into' using by value ctx by reference z'state.generators' list-node end-call
call static 'j_size' using by value list-node by reference x'00' returning cnt end-call
perform varying i from 0 by 1 until i >= cnt
call static 'j_at_into' using by value list-node i by reference node end-call
call static 'j_boolean' using by value node by reference z'unlocked' returning flag end-call
if flag not = 1
call static 'j_set_boolean' using by value node by reference z'unlocked' by value 1 end-call
call static 'j_set_boolean' using by value node by reference z'enabled' by value 1 end-call
end-if end-perform
move 'All generators unlocked' to text-value
call static 'j_set_string' using by value res by reference z'result' text-value by value function length(function trim(text-value trailing)) end-call

when 'generator_debug.give'
move function J-STR(a0,' ') to key-name
move low-values to path-z
string 'state.generators.' function trim(key-name) x'00' into path-z end-string
call static 'j_get_into' using by value ctx by reference path-z node end-call
if node = null
move low-values to path-z
string 'catalog.generators.' function trim(key-name) x'00' into path-z end-string
call static 'j_get_into' using by value ctx by reference path-z node end-call
move spaces to text-value
if node not = null
string 'Generator ' function trim(key-name) ' exists in enum but not in state - this is an error' into text-value end-string
else
string 'Generator ' function trim(key-name) ' not found - valid types are: ' into text-value end-string
call static 'j_get_into' using by value ctx by reference z'catalog.generators' list-node end-call
call static 'j_size' using by value list-node by reference x'00' returning cnt end-call
perform varying i from 0 by 1 until i >= cnt
call static 'j_at_into' using by value list-node i by reference node end-call
call static 'j_key' using by value node by reference key-name by value 256 end-call
move function trim(text-value trailing) to text-small
move spaces to text-value
if i = 0
string function trim(text-small) ' ' function trim(key-name) into text-value end-string
else string function trim(text-small) ', ' function trim(key-name) into text-value end-string end-if
end-perform end-if
call static 'j_set_string' using by value res by reference z'result' text-value by value function length(function trim(text-value trailing)) end-call
else
move 1 to x if a1 not = null move function J-NUM(a1,' ') to x end-if
move function J-NUM(node,'count') to y
call static 'h_number_binary' using by value 1 by reference x y y end-call
move y to number-value
call static 'j_set_number' using by value node by reference z'count' number-value end-call
call static 'j_clone_into' using by value a0 by reference temp end-call
call static 'j_set' using by value child-args by reference z'generatorType' by value temp end-call
move function J-STR(node,'name') to text-small
move 'generator.recalculateGenerator' to route-name perform domain-call
call static 'h_decimal' using by reference x by value 8 0 1 by reference key-name by value 256 end-call
move spaces to text-value
string 'Added ' function trim(key-name) ' ' function trim(text-small) ' generators' into text-value end-string
call static 'j_set_string' using by value res by reference z'result' text-value by value function length(function trim(text-value)) end-call
end-if
when 'upgrade_debug.purchase'
call static 'j_clone_into' using by value a0 by reference temp end-call
call static 'j_set' using by value child-args by reference z'upgradeId' by value temp end-call
move 1.0e+300 to number-value
call static 'j_set_number' using by value child-args by reference z'currentBufos' number-value end-call
move 'upgrade.purchaseUpgrade' to route-name perform domain-call
call static 'j_boolean' using by value res by reference z'result.success' returning flag end-call
move spaces to text-value
if flag = 1 string 'Purchased upgrade ' function trim(function J-STR(a0,' ')) into text-value end-string
else string 'Failed to purchase ' function trim(function J-STR(a0,' ')) into text-value end-string end-if
call static 'j_set_string' using by value res by reference z'result' text-value by value function length(function trim(text-value)) end-call
when 'upgrade_debug.unlockAll'
move 'upgrade.getAvailableUpgrades' to route-name perform domain-call
call static 'j_get_into' using by value res by reference z'result' list-node end-call
call static 'j_get_into' using by value ctx by reference z'state.upgrades.available' node2 end-call
call static 'j_size' using by value list-node by reference x'00' returning cnt end-call
perform varying i from 0 by 1 until i >= cnt
call static 'j_at_into' using by value list-node i by reference node end-call
call static 'j_get_into' using by value node by reference z'id' node end-call
call static 'j_clone_into' using by value node by reference temp end-call
call static 'j_append' using by value node2 temp end-call end-perform
move cnt to x
call static 'h_decimal' using by reference x by value 0 0 1 by reference key-name by value 256 end-call
move spaces to text-value string 'Unlocked ' function trim(key-name) ' upgrades' into text-value end-string
call static 'j_set_string' using by value res by reference z'result' text-value by value function length(function trim(text-value)) end-call
when 'game.reset'
call static 'j_object_into' using by reference command-node end-call
move 'confirm' to text-value
call static 'j_set_string' using by value command-node by reference z'kind' text-value by value function length(function trim(text-value trailing)) end-call
move 'Are you sure you want to reset your game? All progress will be lost!' to text-value
call static 'j_set_string' using by value command-node by reference z'message' text-value by value function length(function trim(text-value trailing)) end-call
call static 'h_dom' using by value req command-node by reference node returning flag end-call
call static 'j_delete' using by value command-node end-call
if flag = 0
call static 'j_boolean' using by value node by reference x'00' returning flag end-call
if flag = 1
move 'BUFO-SAVE' to module-name move 'reset' to route-name perform domain-call
else
call static 'j_set_boolean' using by value res by reference z'result' by value 0 end-call
end-if
else
call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
call static 'j_get_into' using by value node by reference z'$error' node2 end-call
call static 'j_clone_into' using by value node2 by reference temp end-call
call static 'j_set' using by value res by reference z'error' by value temp end-call
end-if
call static 'j_delete' using by value node end-call
when 'reset.softReset'
move 'BUFO-SAVE' to module-name move 'reset' to route-name perform domain-call
call static 'j_boolean' using by value res by reference z'ok' returning flag end-call
if flag = 1
move 'Game state reset' to text-value
call static 'j_set_string' using by value res by reference z'result' text-value by value function length(function trim(text-value trailing)) end-call
end-if
when 'events_debug.enableDebug' when 'events_debug.disableDebug'
call static 'j_array_into' using by reference node end-call
move 0 to flag if op = 'events_debug.enableDebug' move 1 to flag end-if
call static 'j_object_into' using by reference node2 end-call
call static 'j_set_boolean' using by value node2 by reference z'value' by value flag end-call
call static 'j_get_into' using by value node2 by reference z'value' temp end-call
call static 'j_clone_into' using by value temp by reference command-node end-call
call static 'j_append' using by value node command-node end-call
call static 'j_delete' using by value node2 end-call
call static 'j_delete' using by value child-args end-call move node to child-args
move 'BUFO-SERVICES' to module-name move 'event.setDebugMode' to route-name perform domain-call
when 'events_debug.listEvents' when 'events_debug.emit' when 'game.on' when 'game.off'
call static 'j_delete' using by value child-args end-call
call static 'j_clone_into' using by value a by reference child-args end-call
move 'BUFO-SERVICES' to module-name
 evaluate op
 when 'events_debug.listEvents' move 'event.getEventNames' to route-name
 when 'events_debug.emit' move 'event.emit' to route-name
 when 'game.on' move 'event.on' to route-name
 when 'game.off' move 'event.off' to route-name end-evaluate
perform domain-call
when 'performance.measure'
call static 'j_array_into' using by reference commands end-call
call static 'j_object_into' using by reference command-node end-call
move 'log' to text-value
call static 'j_set_string' using by value command-node by reference z'kind' text-value by value function length(function trim(text-value trailing)) end-call
move 'time' to text-value
call static 'j_set_string' using by value command-node by reference z'method' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_array_into' using by reference node end-call
call static 'j_clone_into' using by value a0 by reference temp end-call
call static 'j_append' using by value node temp end-call
call static 'j_set' using by value command-node by reference z'args' by value node end-call
call static 'j_append' using by value commands command-node end-call
call static 'j_object_into' using by reference command-node end-call
move 'callback' to text-value
call static 'j_set_string' using by value command-node by reference z'kind' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_get_into' using by value a1 by reference z'$callback' node end-call
call static 'j_clone_into' using by value node by reference temp end-call
call static 'j_set' using by value command-node by reference z'id' by value temp end-call
call static 'j_array_into' using by reference node end-call
call static 'j_set' using by value command-node by reference z'args' by value node end-call
call static 'j_append' using by value commands command-node end-call
call static 'j_set' using by value res by reference z'commands' by value commands end-call
call static 'j_parse_into' using by reference '{"operation":"api","args":{"path":["performance","complete"],"values":[]}}' by value 74 by reference child end-call
call static 'j_get_into' using by value child by reference z'args.values' node end-call
call static 'j_clone_into' using by value a0 by reference temp end-call
call static 'j_append' using by value node temp end-call
call static 'j_set' using by value res by reference z'continuation' by value child end-call
when 'performance.complete'
call static 'j_array_into' using by reference commands end-call
call static 'j_object_into' using by reference command-node end-call
move 'log' to text-value
call static 'j_set_string' using by value command-node by reference z'kind' text-value by value function length(function trim(text-value trailing)) end-call
move 'timeEnd' to text-value
call static 'j_set_string' using by value command-node by reference z'method' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_array_into' using by reference node end-call
call static 'j_clone_into' using by value a0 by reference temp end-call
call static 'j_append' using by value node temp end-call
call static 'j_set' using by value command-node by reference z'args' by value node end-call
call static 'j_append' using by value commands command-node end-call
call static 'j_set' using by value res by reference z'commands' by value commands end-call
call static 'j_boolean' using by value req by reference z'callbackResult.ok' returning flag end-call
if flag = 0
call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
call static 'j_get_into' using by value req by reference z'callbackResult.error' node end-call
call static 'j_clone_into' using by value node by reference temp end-call
call static 'j_set' using by value res by reference z'error' by value temp end-call
end-if
when 'help.help'
call static 'j_array_into' using by reference commands end-call
call static 'j_object_into' using by reference command-node end-call
move 'log' to text-value
call static 'j_set_string' using by value command-node by reference z'kind' text-value by value function length(function trim(text-value trailing)) end-call
move 'info' to text-value
call static 'j_set_string' using by value command-node by reference z'method' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_array_into' using by reference node end-call
call static 'j_object_into' using by reference node2 end-call
move 'Bufo Idle Debug Tools: state, inspect, resources, gameCore, gameLoop, time, save, reset, events, events_debug, logging, performance, generators, generator_debug, upgrades, upgrade_debug, explorer, prestige, golden, boss' to text-value
call static 'j_set_string' using by value node2 by reference z'text' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_get_into' using by value node2 by reference z'text' temp end-call
call static 'j_clone_into' using by value temp by reference list-node end-call
call static 'j_append' using by value node list-node end-call
call static 'j_set' using by value command-node by reference z'args' by value node end-call
call static 'j_delete' using by value node2 end-call
call static 'j_append' using by value commands command-node end-call
call static 'j_set' using by value res by reference z'commands' by value commands end-call
move 'Debug tools help displayed in console' to text-value
call static 'j_set_string' using by value res by reference z'result' text-value by value function length(function trim(text-value trailing)) end-call

when other
 evaluate true
 when op = 'initialization.initializeGame' call static 'BUFO-API-INITIALIZATION' using by value req ctx res end-call
when op(1:10) = 'loadingUI.' or op = 'initialization.createLoadingUI'
call static 'BUFO-API-UI' using by value req ctx res end-call
when op(1:3) = 'ui.' call static 'BUFO-API-UI' using by value req ctx res end-call
 when op(1:8) = 'storage.' or op(1:12) = 'saveManager.' or op = 'reset.hardReset'
 call static 'BUFO-API-STORAGE' using by value req ctx res end-call
 when other
call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
move 'Unknown public API method' to text-value
call static 'j_set_string' using by value res by reference z'error' text-value by value function length(function trim(text-value trailing)) end-call
end-evaluate
end-evaluate
call static 'j_delete' using by value child-args end-call
goback.
clamp-loop-value.
call static 'h_number_compare' using by reference x y returning flag end-call
if flag < 0 move y to x end-if
call static 'h_number_compare' using by reference x number-value returning flag end-call
if flag > 0 move number-value to x end-if.
domain-call.
call static 'j_clone_into' using by value req by reference child end-call
move route-name to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_clone_into' using by value child-args by reference temp end-call
call static 'j_set' using by value child by reference z'args' by value temp end-call
evaluate module-name
when 'BUFO-GAME' call static 'BUFO-GAME' using by value child ctx res end-call
when 'BUFO-EXPLORER' call static 'BUFO-EXPLORER' using by value child ctx res end-call
when 'BUFO-SAVE' call static 'BUFO-SAVE' using by value child ctx res end-call
when 'BUFO-SERVICES' call static 'BUFO-SERVICES' using by value child ctx res end-call
end-evaluate
call static 'j_delete' using by value child end-call.
event-empty.
set node2 to null perform event-with-payload.
event-with-payload.
call static 'j_object_into' using by reference command-node end-call
move key-name to text-value
call static 'j_set_string' using by value command-node by reference z'name' text-value by value function length(function trim(text-value trailing)) end-call
if node2 not = null
call static 'j_clone_into' using by value node2 by reference temp end-call
call static 'j_set' using by value command-node by reference z'payload' by value temp end-call
end-if
call static 'j_get_into' using by value ctx by reference z'events' commands end-call
call static 'j_append' using by value commands command-node end-call.
end program BUFO-API-EXTRA.
