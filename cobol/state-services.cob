identification division.
program-id. BUFO-STATE-SERVICES.
environment division.
configuration section.
repository. function J-NUM function J-STR function all intrinsic.
data division.
local-storage section.
01 op pic x(96).
01 key-text pic x(256).
01 field-name pic x(32).
01 a usage pointer.
01 source-node usage pointer.
01 patch usage pointer.
01 target usage pointer.
01 old-state usage pointer.
01 part usage pointer.
01 updates usage pointer.
01 child usage pointer.
01 temp usage pointer.
01 list-node usage pointer.
01 item usage pointer.
01 r usage comp-2.
01 x usage comp-2.
01 y usage comp-2.
01 i usage binary-long.
01 j usage binary-long.
01 cnt usage binary-long.
01 typ usage binary-long.
01 yes usage binary-long.
01 manager-mode usage binary-long.
01 inner-req usage pointer.
01 inner-args usage pointer.
01 event-operation pic x(32).
01 fields.
 02 filler pic x(32) value 'resources'.
 02 filler pic x(32) value 'explorer'.
 02 filler pic x(32) value 'upgrades'.
 02 filler pic x(32) value 'gameSettings'.
 02 filler pic x(32) value 'prestige'.
 02 filler pic x(32) value 'bosses'.
 02 filler pic x(32) value 'achievements'.
01 field-list redefines fields.
 02 field-key pic x(32) occurs 7.
linkage section.
01 req usage pointer.
01 ctx usage pointer.
01 res usage pointer.
procedure division using by value req ctx res.
 move function J-STR(req,'operation') to op
 call static 'j_get_into' using by value req by reference z'args' a end-call
 call static 'j_at_into' using by value a 0 by reference source-node end-call
 call static 'j_at_into' using by value a 1 by reference patch end-call
 move 0 to manager-mode
 if op(1:13) = 'stateManager.' move 1 to manager-mode end-if
 evaluate op
 when 'stateManager.notify'
 call static 'j_get_into' using by value ctx by reference z'state' target end-call
 move source-node to old-state
 call static 'j_boolean' using by value ctx by reference z'runtime.stateBatch' returning typ end-call
 if typ = 1
 compute r = function J-NUM(ctx,'runtime.statePending') + 1
 call static 'j_set_number' using by value ctx by reference z'runtime.statePending' r end-call
 else perform notify-state end-if goback
 when 'stateManager.startBatch'
 call static 'j_set_boolean' using by value ctx by reference z'runtime.stateBatch' by value 1 end-call
 move 0 to r call static 'j_set_number' using by value ctx by reference z'runtime.statePending' r end-call goback
 when 'stateManager.endBatch'
 call static 'j_boolean' using by value ctx by reference z'runtime.stateBatch' returning yes end-call
 if yes = 1 and function J-NUM(ctx,'runtime.statePending') > 0
 call static 'j_get_into' using by value ctx by reference z'state' target end-call
 call static 'j_clone_into' using by value target by reference old-state end-call
 perform notify-state call static 'j_delete' using by value old-state end-call end-if
 call static 'j_set_boolean' using by value ctx by reference z'runtime.stateBatch' by value 0 end-call goback
 when 'stateManager.subscribe' when 'stateManager.unsubscribe'
 perform subscriptions goback
 when 'stateManager.getState'
 call static 'j_get_into' using by value ctx by reference z'state' source-node end-call
 call static 'j_clone_into' using by value source-node by reference target end-call
 perform return-target goback
 when 'state.createDefaultState' when 'stateManager.resetState' when 'gameState.DEFAULT_GAME_STATE'
 call static 'j_get_into' using by value ctx by reference z'runtime.defaultState' source-node end-call
 call static 'j_clone_into' using by value source-node by reference target end-call
 if target = null call static 'j_object_into' using by reference target end-call end-if
 move function J-NUM(req,'now') to r
 call static 'j_set_number' using by value target by reference z'gameSettings.lastTick' r end-call
 call static 'j_set_number' using by value target by reference z'gameSettings.lastSaved' r end-call
 if op not = 'gameState.DEFAULT_GAME_STATE'
 call static 'j_remove' using by value target by reference z'resources.clickCount' end-call end-if
 if manager-mode = 1 perform replace-state else perform return-target end-if goback
 when 'stateManager.loadState'
 perform validate-state
 if yes = 1 call static 'j_clone_into' using by value source-node by reference target end-call perform replace-state end-if
 call static 'j_set_boolean' using by value res by reference z'result' by value yes end-call goback
 when 'state.validateState' when 'gameState.validateState'
 perform validate-state
 call static 'j_set_boolean' using by value res by reference z'result' by value yes end-call goback
 when 'stateManager.setState'
 move source-node to patch
 call static 'j_get_into' using by value ctx by reference z'state' source-node end-call
 end-evaluate
 call static 'j_clone_into' using by value source-node by reference target end-call
 evaluate op
 when 'state.updateState' when 'gameState.updateState' when 'stateManager.setState'
 perform merge-state perform derived-state
 if manager-mode = 1 perform replace-state else perform return-target end-if
 when 'state.calculateDerivedState' when 'gameState.calculateDerivedState'
 perform derived-state perform return-target
 when 'gameState.getProductionStatistics' when 'gameState.getResourceDisplay'
 call static 'j_delete' using by value target end-call
 perform statistics perform return-target
 when other
 call static 'j_delete' using by value target end-call
 call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
 end-evaluate goback.
return-target.
 call static 'j_set' using by value res by reference z'result' by value target end-call.
merge-state.
 perform varying i from 1 by 1 until i > 7
 if i not = 7 or op not = 'gameState.updateState'
 move field-key(i) to field-name
 call static 'j_get_into' using by value patch by reference function concatenate(function trim(field-name),x'00') updates end-call
 if updates not = null
 call static 'j_get_into' using by value target by reference function concatenate(function trim(field-name),x'00') part end-call
 if part = null
 call static 'j_object_into' using by reference part end-call
 call static 'j_set' using by value target by reference function concatenate(function trim(field-name),x'00') by value part end-call end-if
 call static 'j_merge' using by value part updates end-call
 end-if end-if end-perform
 call static 'j_get_into' using by value patch by reference z'generators' updates end-call
 call static 'j_get_into' using by value target by reference z'generators' part end-call
 call static 'j_size' using by value updates by reference x'00' returning cnt end-call
 perform varying i from 0 by 1 until i >= cnt
 call static 'j_at_into' using by value updates i by reference child end-call
 call static 'j_key' using by value child by reference key-text by value 256 end-call
 call static 'j_get_into' using by value part by reference function concatenate(function trim(key-text),x'00') temp end-call
 if temp not = null call static 'j_merge' using by value temp child end-call end-if end-perform.
derived-state.
 compute x = 1 + function max(0,function J-NUM(target,'prestige.lifetimePoints')) * 0.1
 call static 'j_size' using by value target by reference z'bosses.defeated' returning cnt end-call
 compute y = 1 + (cnt + function J-NUM(target,'bosses.lifetimeDefeats')) * 0.25
 move function J-NUM(target,'resources.frenzyClickMultiplier') to r
 call static 'j_type' using by value target by reference z'resources.frenzyClickMultiplier' returning typ end-call
 if typ = 0 move 1 to r end-if
 compute r = function J-NUM(target,'resources.baseClickPower') * function J-NUM(target,'resources.clickMultiplier') * x * y * r
 call static 'j_set_number' using by value target by reference z'resources.clickPower' r end-call.
validate-state.
 move 1 to yes
 call static 'j_get_into' using by value source-node by reference z'resources' temp end-call
 call static 'h_truthy' using by value temp returning typ end-call
 if typ = 0 move 0 to yes end-if
 call static 'j_get_into' using by value source-node by reference z'generators' temp end-call
 call static 'h_truthy' using by value temp returning typ end-call
 if typ = 0 move 0 to yes end-if
 call static 'j_get_into' using by value source-node by reference z'explorer' temp end-call
 call static 'h_truthy' using by value temp returning typ end-call
 if typ = 0 move 0 to yes end-if
 call static 'j_get_into' using by value source-node by reference z'upgrades' temp end-call
 call static 'h_truthy' using by value temp returning typ end-call
 if typ = 0 move 0 to yes end-if
 call static 'j_get_into' using by value source-node by reference z'gameSettings' temp end-call
 call static 'h_truthy' using by value temp returning typ end-call
 if typ = 0 move 0 to yes end-if
 call static 'j_type' using by value source-node by reference z'resources.bufos' returning typ end-call
 if typ not = 2 move 0 to yes end-if
 call static 'j_type' using by value source-node by reference z'resources.totalBufos' returning typ end-call
 if typ not = 2 move 0 to yes end-if
 call static 'j_type' using by value source-node by reference z'resources.clickPower' returning typ end-call
 if typ not = 2 move 0 to yes end-if
 if op not = 'gameState.validateState'
 call static 'j_type' using by value source-node by reference z'resources.clickMultiplier' returning typ end-call
 if typ not = 2 move 0 to yes end-if
 end-if
 if op not = 'gameState.validateState'
 call static 'j_type' using by value source-node by reference z'resources.productionMultiplier' returning typ end-call
 if typ not = 2 move 0 to yes end-if
 end-if
 call static 'j_type' using by value source-node by reference z'upgrades.purchased' returning typ end-call
 if typ not = 4 move 0 to yes end-if
 call static 'j_type' using by value source-node by reference z'upgrades.available' returning typ end-call
 if typ not = 4 move 0 to yes end-if
 call static 'j_has' using by value source-node by reference z'gameSettings.lastSaved' returning typ end-call
 if typ = 0 move 0 to yes end-if
 call static 'j_has' using by value source-node by reference z'gameSettings.lastTick' returning typ end-call
 if typ = 0 move 0 to yes end-if
 call static 'j_has' using by value source-node by reference z'gameSettings.version' returning typ end-call
 if typ = 0 move 0 to yes end-if
 .
replace-state.
 call static 'j_get_into' using by value ctx by reference z'state' old-state end-call
 call static 'j_clone_into' using by value old-state by reference old-state end-call
 call static 'j_set' using by value ctx by reference z'state' by value target end-call
 call static 'j_boolean' using by value ctx by reference z'runtime.stateBatch' returning typ end-call
 if typ = 0 or op not = 'stateManager.setState' perform notify-state
 else compute r = function J-NUM(ctx,'runtime.statePending') + 1
 call static 'j_set_number' using by value ctx by reference z'runtime.statePending' r end-call end-if
 call static 'j_delete' using by value old-state end-call.
subscriptions.
 if op = 'stateManager.subscribe' move 'event.onRepeated' to event-operation else move 'event.off' to event-operation end-if
 perform event-request
 call static 'j_clone_into' using by value source-node by reference temp end-call
 call static 'j_append' using by value inner-args temp end-call
 call static 'BUFO-EVENT-SERVICES' using by value inner-req ctx res end-call
 call static 'j_delete' using by value inner-req end-call
 if op = 'stateManager.subscribe'
 call static 'j_clone_into' using by value source-node by reference target end-call perform return-target end-if.
notify-state.
 move 'event.emitArgs' to event-operation perform event-request
 call static 'j_array_into' using by reference part end-call
 call static 'j_clone_into' using by value target by reference temp end-call
 call static 'j_append' using by value part temp end-call
 call static 'j_clone_into' using by value old-state by reference temp end-call
 call static 'j_append' using by value part temp end-call
 call static 'j_append' using by value inner-args part end-call
 call static 'BUFO-EVENT-SERVICES' using by value inner-req ctx res end-call
 call static 'j_delete' using by value inner-req end-call.
event-request.
 call static 'j_object_into' using by reference inner-req end-call
 call static 'j_set_string' using by value inner-req by reference z'operation' event-operation by value function length(function trim(event-operation)) end-call
 call static 'j_set_string' using by value inner-req by reference z'serviceScope' z'state' by value 5 end-call
 call static 'j_array_into' using by reference inner-args end-call
 call static 'j_parse_into' using by reference z'"state"' by value 7 by reference temp end-call
 call static 'j_append' using by value inner-args temp end-call
 call static 'j_set' using by value inner-req by reference z'args' by value inner-args end-call.
statistics.
 call static 'j_object_into' using by reference target end-call
 call static 'j_array_into' using by reference list-node end-call
 call static 'j_get_into' using by value source-node by reference z'generators' part end-call
 call static 'j_size' using by value part by reference x'00' returning cnt end-call
 move 0 to x
 perform varying i from 0 by 1 until i >= cnt
 call static 'j_at_into' using by value part i by reference child end-call
 move function J-NUM(child,'totalProduction') to r
 if op = 'gameState.getResourceDisplay' or (r > 0 and function J-NUM(child,'count') > 0)
 add r to x
 if op = 'gameState.getProductionStatistics'
 call static 'j_object_into' using by reference item end-call
 call static 'j_set_number' using by value item by reference z'production' r end-call
 move function J-NUM(child,'count') to r
 call static 'j_set_number' using by value item by reference z'count' r end-call
 perform varying j from 1 by 1 until j > 2
 if j = 1 move 'id' to field-name else move 'name' to field-name end-if
 call static 'j_get_into' using by value child by reference function concatenate(function trim(field-name),x'00') temp end-call
 call static 'j_clone_into' using by value temp by reference temp end-call
 call static 'j_set' using by value item by reference function concatenate(function trim(field-name),x'00') by value temp end-call end-perform
 call static 'j_append' using by value list-node item end-call end-if end-if end-perform
 if op = 'gameState.getResourceDisplay'
 call static 'j_set_number' using by value target by reference z'productionRate' x end-call
 move function J-NUM(source-node,'resources.bufos') to r
 call static 'j_set_number' using by value target by reference z'bufos' r end-call
 move function J-NUM(source-node,'resources.totalBufos') to r
 call static 'j_set_number' using by value target by reference z'totalBufos' r end-call
 move function J-NUM(source-node,'resources.clickPower') to r
 call static 'j_set_number' using by value target by reference z'clickPower' r end-call
 call static 'j_delete' using by value list-node end-call
 else
 call static 'j_set_number' using by value target by reference z'currentRate' x end-call
 compute r = x * 60 call static 'j_set_number' using by value target by reference z'perMinute' r end-call
 compute r = x * 3600 call static 'j_set_number' using by value target by reference z'perHour' r end-call
 call static 'j_size' using by value list-node by reference x'00' returning cnt end-call
 perform varying i from 0 by 1 until i >= cnt
 call static 'j_at_into' using by value list-node i by reference item end-call
 compute r = function J-NUM(item,'production') / x * 100
 call static 'j_set_number' using by value item by reference z'percentage' r end-call end-perform
 call static 'j_set' using by value target by reference z'generatorContributions' by value list-node end-call end-if.
end program BUFO-STATE-SERVICES.
