identification division.
program-id. BUFO-EXPLORER.
environment division.
configuration section.
repository.
    function J-NUM
    function J-STR
    function all intrinsic.
data division.
local-storage section.
01 compare-a usage comp-2.
01 compare-b usage comp-2.
01 compare-result usage binary-long.
01 power-base usage comp-2.
01 power-exponent usage comp-2.
01 power-result usage comp-2.
01 op pic x(80).
01 args usage pointer.
01 out-node usage pointer.
01 tmp usage pointer.
01 n usage comp-2.
01 now-ms usage comp-2.
01 json-text pic x(4096).
01 flag usage binary-long.
01 ex usage pointer.
01 runtime-node usage pointer.
01 current-enemy usage pointer.
01 current-combat usage pointer.
01 model-result usage pointer.
01 nested-req usage pointer.
01 nested-res usage pointer.
01 event-node usage pointer.
01 payload usage pointer.
01 events-node usage pointer.
01 result-node usage pointer.
01 rewards-node usage pointer.
01 item usage pointer.
01 call-name pic x(80).
01 event-name pic x(80).
01 old-state pic x(16).
01 new-state pic x(16).
01 area-name pic x(64).
01 stat-name pic x(32).
01 action-name pic x(16).
01 delta-seconds usage comp-2.
01 distance-value usage comp-2.
01 max-distance usage comp-2.
01 elapsed-seconds usage comp-2.
01 area-level usage comp-2.
01 effective usage comp-2.
01 health-value usage comp-2.
01 scalar usage comp-2.
01 roll usage comp-2.
01 passed usage binary-long.
01 leveled usage binary-long.
01 valid-area usage binary-long.
linkage section.
01 req usage pointer.
01 ctx usage pointer.
01 res usage pointer.
procedure division using by value req ctx res.
    move function J-STR(req, 'operation') to op
    move function J-NUM(ctx, 'runtime.now') to now-ms
    call static "j_get_into" using by value req
        by reference z'args' args end-call
    call static "j_set_boolean" using by value res
        by reference z'ok' by value 1 end-call
    call static "j_get_into" using by value ctx
        by reference z'state.explorer' tmp end-call
    call static "j_clone_into" using by value tmp
        by reference ex end-call
    call static "j_get_into" using by value ctx
        by reference z'runtime.explorer' runtime-node end-call
    evaluate true
      when op = 'validate' or 'normalize'
        call static 'j_clone_into' using by value req by reference nested-req end-call
        move spaces to call-name
        string 'model.' function trim(op) into call-name end-string
    call static "j_set_string" using by value nested-req
        by reference z'operation' call-name
        by value function length(function trim(call-name)) end-call
        call static 'BUFO-EXPLORER-MODELS' using by value nested-req ctx res end-call
        call static 'j_delete' using by value nested-req end-call
      when op(1:6) = 'model.'
        call static "BUFO-EXPLORER-MODELS" using by value req ctx res end-call
      when op(1:6) = 'enemy.'
        call static "BUFO-ENEMIES" using by value req ctx res end-call
      when op(1:7) = 'combat.'
        call static "BUFO-COMBAT" using by value req ctx res end-call
      when other
        evaluate op
          when 'init'
            move 'model.DEFAULT_EXPLORER_DATA' to call-name perform model-call
            perform replace-ex perform reset-runtime
          when 'rebuild' perform reset-runtime
          when 'reset' perform reset-runtime perform emit-updated
          when 'getExplorer'
    call static "j_clone_into" using by value ex
        by reference out-node end-call
          when 'getCurrentEnemy'
    call static "j_get_into" using by value runtime-node
        by reference z'currentEnemy' tmp end-call
    call static "j_clone_into" using by value tmp
        by reference out-node end-call
            if out-node = null perform null-result end-if
          when 'getCurrentCombat'
    call static "j_get_into" using by value runtime-node
        by reference z'currentCombat' tmp end-call
    call static "j_clone_into" using by value tmp
        by reference out-node end-call
            if out-node = null perform null-result end-if
          when 'getAvailableAreas' perform list-areas
          when 'getExplorerStats' perform derived-stats
          when 'startExploration' perform start-exploration
          when 'upgradeExplorerStat' perform upgrade-stat
          when 'update' perform update-manager
          when 'performCombatAction' perform manual-combat
          when 'autoResolveCombat' perform auto-combat
          when other
            call static "j_set_boolean" using by value res by reference z'ok' by value 0 end-call
    call static "j_set_string" using by value res
        by reference z'error' 'Unknown Explorer operation' by value 26 end-call
        end-evaluate
        if ex not = null
    call static "j_clone_into" using by value ex
        by reference tmp end-call
    call static "j_set" using by value ctx
        by reference z'state.explorer' by value tmp end-call
        end-if
    end-evaluate
    if out-node not = null
    call static "j_set" using by value res
        by reference z'result' by value out-node end-call
    end-if
    call static "j_delete" using by value ex end-call
    call static "j_delete" using by value model-result end-call
    call static "j_delete" using by value result-node end-call
    goback.
null-result.
    call static "j_set_null" using by value res by reference z'result' end-call.
bool-result.
    call static "j_set_boolean" using by value res by reference z'result' by value passed end-call.
reset-runtime.
    move spaces to json-text
    string
        '{"currentCombat":null,"currentEnemy":null,"explorationDistance":0,"maxExplorationDistance":10,"encou'
        'nterChance":0.05,"lastUpdateTime":0}'
        into json-text end-string
    call static "j_parse_into" using by reference json-text
        by value 136 by reference runtime-node end-call
    compute n = now-ms
    call static "j_set_number" using by value runtime-node
        by reference z'lastUpdateTime' n end-call
    call static "j_set" using by value ctx
        by reference z'runtime.explorer' by value runtime-node end-call
.
prepare-call.
    call static "j_delete" using by value model-result end-call
    set model-result to null
    call static "j_clone_into" using by value req
        by reference nested-req end-call
    call static "j_set_string" using by value nested-req
        by reference z'operation' call-name
        by value function length(function trim(call-name)) end-call
    call static "j_clone_into" using by value ex
        by reference tmp end-call
    call static "j_set" using by value nested-req
        by reference z'args.explorer' by value tmp end-call
    call static "j_object_into" using by reference nested-res end-call.
finish-call.
    call static "j_get_into" using by value nested-res
        by reference z'result' tmp end-call
    call static "j_clone_into" using by value tmp
        by reference model-result end-call
    call static "j_delete" using by value nested-req end-call
    call static "j_delete" using by value nested-res end-call.
model-call.
    perform prepare-call
    call static "BUFO-EXPLORER-MODELS" using by value nested-req ctx nested-res end-call
    perform finish-call.
replace-ex.
    call static "j_delete" using by value ex end-call
    call static "j_clone_into" using by value model-result
        by reference ex end-call
.
replace-record-ex.
    call static "j_delete" using by value ex end-call
    call static "j_get_into" using by value model-result
        by reference z'explorer' tmp end-call
    call static "j_clone_into" using by value tmp
        by reference ex end-call
.
new-event.
    call static "j_object_into" using by reference event-node end-call
    call static "j_object_into" using by reference payload end-call
    call static "j_set_string" using by value event-node
        by reference z'name' event-name
        by value function length(function trim(event-name)) end-call
    call static "j_clone_into" using by value ex
        by reference tmp end-call
    call static "j_set" using by value payload
        by reference z'explorer' by value tmp end-call
.
emit-event.
    call static "j_set" using by value event-node
        by reference z'payload' by value payload end-call
    call static "j_get_into" using by value ctx
        by reference z'events' events-node end-call
    call static "j_append" using by value events-node event-node end-call.
emit-updated.
    move 'EXPLORER_UPDATED' to event-name perform new-event perform emit-event.
emit-state-change.
    move 'EXPLORER_STATE_CHANGED' to event-name perform new-event
    call static "j_set_string" using by value payload
        by reference z'previousState' old-state
        by value function length(function trim(old-state)) end-call
    perform emit-event.
list-areas.
    move spaces to json-text
    string
        '["Pond","Creek","Swamp","River","Lake","Forest","Mountains","Dungeon"]'
        into json-text end-string
    call static "j_parse_into" using by reference json-text
        by value 70 by reference out-node end-call
.
lookup-area.
    move 1 to valid-area
    evaluate area-name
      when 'Pond' move 1 to area-level
      when 'Creek' move 2 to area-level
      when 'Swamp' move 3 to area-level
      when 'River' move 4 to area-level
      when 'Lake' move 5 to area-level
      when 'Forest' move 6 to area-level
      when 'Mountains' move 8 to area-level
      when 'Dungeon' move 10 to area-level
      when other move 1 to area-level move 0 to valid-area
    end-evaluate.
derived-stats.
    call static "j_object_into" using by reference out-node end-call
    move 'model.calculatePowerRating' to call-name perform model-call
    move function J-NUM(model-result, ' ') to n
    call static "j_set_number" using by value out-node
        by reference z'powerRating' n end-call
    move 'model.calculateDPS' to call-name perform model-call
    move function J-NUM(model-result, ' ') to n
    call static "j_set_number" using by value out-node
        by reference z'dps' n end-call
    move 'model.calculateSurvivalTime' to call-name perform model-call
    move function J-NUM(model-result, ' ') to n
    call static "j_set_number" using by value out-node
        by reference z'survivalTime' n end-call
    compute n = function J-NUM(ex, 'health') / function J-NUM(ex, 'maxHealth') * 100
    call static "j_set_number" using by value out-node
        by reference z'healthPercent' n end-call
.
start-exploration.
    move 0 to passed
    move function J-STR(args, 'area') to area-name perform lookup-area
    move function J-STR(ex, 'state') to old-state
    if valid-area = 1 and (old-state = 'idle' or 'resting')
    compute n = 0
    call static "j_set_number" using by value runtime-node
        by reference z'explorationDistance' n end-call
        move 'model.startExploration' to call-name perform model-call
        perform replace-ex
        if function J-STR(ex, 'state') not = old-state
            move 1 to passed perform emit-state-change
            move 'EXPLORATION_STARTED' to event-name perform new-event
    call static "j_set_string" using by value payload
        by reference z'area' area-name
        by value function length(function trim(area-name)) end-call
            perform emit-event perform emit-updated
        end-if
    end-if
    perform bool-result.
upgrade-stat.
    move function J-STR(args, 'statName') to stat-name
    move 'model.upgradeExplorerStat' to call-name perform prepare-call
    move function J-NUM(args, 'availableBufos') to n
    call static "j_set_number" using by value nested-req
        by reference z'args.bufos' n end-call
    call static "BUFO-EXPLORER-MODELS" using by value nested-req ctx nested-res end-call
    perform finish-call
    call static "j_boolean" using by value model-result by reference z'success' returning passed end-call
    if passed = 1
        perform replace-record-ex
        move 'EXPLORER_STAT_UPGRADED' to event-name perform new-event
    call static "j_set_string" using by value payload
        by reference z'statName' stat-name
        by value function length(function trim(stat-name)) end-call
        move low-values to json-text
        string function trim(stat-name) '.level' x'00' into json-text end-string
        call static "j_number" using by value ex by reference json-text scalar end-call
    compute n = scalar
    call static "j_set_number" using by value payload
        by reference z'newLevel' n end-call
        perform emit-event perform emit-updated
    end-if
    call static "j_object_into" using by reference out-node end-call
    call static "j_set_boolean" using by value out-node by reference z'success' by value passed end-call
    move function J-NUM(model-result, 'cost') to n
    call static "j_set_number" using by value out-node
        by reference z'cost' n end-call
.
update-manager.
    perform null-result
    move function J-NUM(args, 'delta') to delta-seconds
    if delta-seconds <= 0 exit paragraph end-if
    move function J-STR(ex, 'state') to old-state
    call static "j_get_into" using by value runtime-node
        by reference z'currentCombat' current-combat end-call
    call static "j_type" using by value current-combat by reference x'00' returning flag end-call
    if old-state = 'fighting' and flag = 5 exit paragraph end-if
    if old-state not = 'exploring'
        move 'model.updateExplorer' to call-name perform prepare-call
    compute n = delta-seconds
    call static "j_set_number" using by value nested-req
        by reference z'args.deltaSeconds' n end-call
        call static "BUFO-EXPLORER-MODELS" using by value nested-req ctx nested-res end-call
        perform finish-call perform replace-record-ex
    compute n = now-ms
    call static "j_set_number" using by value runtime-node
        by reference z'lastUpdateTime' n end-call
        if function J-STR(ex, 'state') not = old-state perform emit-state-change end-if
        perform emit-updated exit paragraph
    end-if
    move function J-NUM(runtime-node, 'maxExplorationDistance') to max-distance
    compute distance-value = function J-NUM(runtime-node, 'explorationDistance') + delta-seconds * .2
    compute n = distance-value
    call static "j_set_number" using by value runtime-node
        by reference z'explorationDistance' n end-call
    call static "BUFO-RANDOM" using by value req ctx by reference roll end-call
    move roll to compare-a
    compute compare-b = function J-NUM(runtime-node, 'encounterChance') * delta-seconds
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
    if compare-result < 0
        perform encounter exit paragraph
    end-if
    move distance-value to compare-a
    move max-distance to compare-b
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
    if compare-result >= 0
        perform complete-manager
    compute n = 0
    call static "j_set_number" using by value runtime-node
        by reference z'explorationDistance' n end-call
    call static "j_clone_into" using by value result-node
        by reference out-node end-call
        exit paragraph
    end-if
    compute n = distance-value / max-distance * 100
    call static "j_set_number" using by value ex
        by reference z'explorationProgress' n end-call
    perform emit-updated.
encounter.
    move function J-STR(ex, 'currentArea') to area-name perform lookup-area
    move 'enemy.generateEnemy' to call-name perform prepare-call
    call static "j_set_string" using by value nested-req
        by reference z'args.area' area-name
        by value function length(function trim(area-name)) end-call
    compute n = distance-value / max-distance
    call static "j_set_number" using by value nested-req
        by reference z'args.distanceMultiplier' n end-call
    compute n = area-level
    call static "j_set_number" using by value nested-req
        by reference z'args.areaLevel' n end-call
    call static "BUFO-ENEMIES" using by value nested-req ctx nested-res end-call
    call static "j_boolean" using by value nested-res by reference z'ok' returning flag end-call
    perform finish-call
    if flag = 0 exit paragraph end-if
    call static "j_clone_into" using by value model-result
        by reference current-enemy end-call
    call static "j_set" using by value runtime-node
        by reference z'currentEnemy' by value current-enemy end-call
    call static "j_set_string" using by value ex
        by reference z'state' 'fighting' by value 8 end-call
    move 'combat.initializeCombat' to call-name perform prepare-call
    call static "j_clone_into" using by value current-enemy
        by reference tmp end-call
    call static "j_set" using by value nested-req
        by reference z'args.enemy' by value tmp end-call
    call static "BUFO-COMBAT" using by value nested-req ctx nested-res end-call
    perform finish-call
    call static "j_clone_into" using by value model-result
        by reference current-combat end-call
    call static "j_set" using by value runtime-node
        by reference z'currentCombat' by value current-combat end-call
    perform emit-state-change
    move 'ENEMY_ENCOUNTERED' to event-name perform new-event
    call static "j_clone_into" using by value current-enemy
        by reference tmp end-call
    call static "j_set" using by value payload
        by reference z'enemy' by value tmp end-call
    perform emit-event perform emit-updated.
complete-manager.
    compute elapsed-seconds = (now-ms - function J-NUM(ex, 'stateStartTime')) / 1000
    move function J-STR(ex, 'currentArea') to area-name perform lookup-area
    compute effective = function min(1, function J-NUM(ex, 'level') / area-level)
    call static "j_object_into" using by reference result-node end-call
    call static "j_set_boolean" using by value result-node by reference z'survived' by value 1 end-call
    compute n = elapsed-seconds
    call static "j_set_number" using by value result-node
        by reference z'duration' n end-call
    compute n = function integer(area-level * 50 * effective * (elapsed-seconds / 60) * (1 + function J-NUM(ex, 'luck.value') * function J-NUM(ex, 'luck.multiplier') / 100))
    call static "j_set_number" using by value result-node
        by reference z'bufosGained' n end-call
    compute n = function integer(area-level * 10 * (elapsed-seconds / 60))
    call static "j_set_number" using by value result-node
        by reference z'experienceGained' n end-call
    call static "j_array_into" using by reference tmp end-call
    call static "j_set" using by value result-node
        by reference z'itemsFound' by value tmp end-call
    compute health-value = function max(1, function J-NUM(ex, 'health') - function J-NUM(ex, 'maxHealth') * .05)
    move 'resting' to new-state
    move health-value to compare-a
    compute compare-b = function J-NUM(ex, 'maxHealth') * .2
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
    if compare-result < 0 move 'injured' to new-state end-if
    compute n = health-value
    call static "j_set_number" using by value ex
        by reference z'health' n end-call
    call static "j_set_string" using by value ex
        by reference z'state' new-state
        by value function length(function trim(new-state)) end-call
    compute n = now-ms
    call static "j_set_number" using by value ex
        by reference z'stateStartTime' n end-call
    compute n = function J-NUM(ex, 'experience') + function J-NUM(result-node, 'experienceGained')
    call static "j_set_number" using by value ex
        by reference z'experience' n end-call
    compute n = function J-NUM(ex, 'explorationsCompleted') + 1
    call static "j_set_number" using by value ex
        by reference z'explorationsCompleted' n end-call
    compute n = function J-NUM(ex, 'lifetimeBufosFromExploring') + function J-NUM(result-node, 'bufosGained')
    call static "j_set_number" using by value ex
        by reference z'lifetimeBufosFromExploring' n end-call
    compute n = 0
    call static "j_set_number" using by value ex
        by reference z'explorationProgress' n end-call
    perform level-loop
    if old-state not = new-state perform emit-state-change end-if
    move 'EXPLORATION_COMPLETED' to event-name perform new-event
    call static "j_clone_into" using by value result-node
        by reference tmp end-call
    call static "j_set" using by value payload
        by reference z'result' by value tmp end-call
    perform emit-event.
level-loop.
    move 0 to leveled
    move function J-NUM(ex, 'experience') to compare-a
    move function J-NUM(ex, 'experienceToNextLevel') to compare-b
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
    perform until compare-result < 0
        move 1 to leveled
    compute n = function J-NUM(ex, 'experience') - function J-NUM(ex, 'experienceToNextLevel')
    call static "j_set_number" using by value ex
        by reference z'experience' n end-call
    compute n = function J-NUM(ex, 'level') + 1
    call static "j_set_number" using by value ex
        by reference z'level' n end-call
    compute n = function J-NUM(ex, 'maxHealth') + 20 + function J-NUM(ex, 'defense.level') * 5
    call static "j_set_number" using by value ex
        by reference z'maxHealth' n end-call
    compute power-base = 1.5
    compute power-exponent = function J-NUM(ex, 'level') - 1
    call static 'h_power' using by reference power-base power-exponent power-result end-call
    compute n = 0 - function integer(0 - 100 * power-result)
    call static "j_set_number" using by value ex
        by reference z'experienceToNextLevel' n end-call
        move 'EXPLORER_LEVEL_UP' to event-name perform new-event
    move function J-NUM(ex, 'level') to n
    call static "j_set_number" using by value payload
        by reference z'newLevel' n end-call
        perform emit-event
    move function J-NUM(ex, 'experience') to compare-a
    move function J-NUM(ex, 'experienceToNextLevel') to compare-b
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
    end-perform
    if leveled = 1 perform emit-updated end-if.
combat-ready.
    move 0 to passed
    call static "j_get_into" using by value runtime-node
        by reference z'currentEnemy' current-enemy end-call
    call static "j_get_into" using by value runtime-node
        by reference z'currentCombat' current-combat end-call
    call static "j_type" using by value current-enemy by reference x'00' returning flag end-call
    if flag = 5 and function J-STR(ex, 'state') = 'fighting'
        call static "j_type" using by value current-combat by reference x'00' returning flag end-call
        if flag = 5 move 1 to passed end-if
    end-if.
manual-combat.
    perform combat-ready
    if passed = 0 perform bool-result exit paragraph end-if
    move 'combat.executeCombatAction' to call-name perform prepare-call
    call static "j_clone_into" using by value current-combat
        by reference tmp end-call
    call static "j_set" using by value nested-req
        by reference z'args.state' by value tmp end-call
    call static "BUFO-COMBAT" using by value nested-req ctx nested-res end-call
    perform finish-call
    call static "j_get_into" using by value model-result
        by reference z'newState' tmp end-call
    call static "j_clone_into" using by value tmp
        by reference current-combat end-call
    call static "j_set" using by value runtime-node
        by reference z'currentCombat' by value current-combat end-call
    move function J-NUM(current-combat, 'explorer.health') to n
    call static "j_set_number" using by value ex
        by reference z'health' n end-call
    move 'COMBAT_ACTION' to event-name perform new-event
    call static "j_delete" using by value payload end-call
    call static "j_clone_into" using by value model-result
        by reference payload end-call
    perform emit-event
    if function J-STR(current-combat, 'status') not = 'inProgress'
        move 0 to passed
        if function J-STR(current-combat, 'status') = 'victory'
            move 1 to passed
    call static "j_get_into" using by value model-result
        by reference z'rewards' rewards-node end-call
            if rewards-node not = null perform apply-rewards end-if
        end-if
        perform combat-ended perform finish-combat
    end-if
    move 1 to passed perform bool-result.
auto-combat.
    perform combat-ready
    if passed = 0 perform bool-result exit paragraph end-if
    move 'combat.simulateCombat' to call-name perform prepare-call
    call static "j_clone_into" using by value current-enemy
        by reference tmp end-call
    call static "j_set" using by value nested-req
        by reference z'args.enemy' by value tmp end-call
    call static "j_remove" using by value nested-req by reference z'args.simulationRounds' end-call
    call static "BUFO-COMBAT" using by value nested-req ctx nested-res end-call
    perform finish-call
    move function J-NUM(model-result, 'explorerRemainingHealth') to n
    call static "j_set_number" using by value ex
        by reference z'health' n end-call
    call static "j_boolean" using by value model-result by reference z'victory' returning passed end-call
    set rewards-node to null
    if passed = 1
        call static "j_object_into" using by reference rewards-node end-call
    move function J-NUM(model-result, 'bufosGained') to n
    call static "j_set_number" using by value rewards-node
        by reference z'bufos' n end-call
    move function J-NUM(model-result, 'experienceGained') to n
    call static "j_set_number" using by value rewards-node
        by reference z'experience' n end-call
    call static "j_get_into" using by value model-result
        by reference z'itemsFound' tmp end-call
    call static "j_clone_into" using by value tmp
        by reference item end-call
    call static "j_set" using by value rewards-node
        by reference z'drops' by value item end-call
        perform apply-rewards
    end-if
    perform combat-ended
    call static "j_delete" using by value rewards-node end-call
    perform finish-combat move 1 to passed perform bool-result.
apply-rewards.
    compute n = function J-NUM(ex, 'experience') + function J-NUM(rewards-node, 'experience')
    call static "j_set_number" using by value ex
        by reference z'experience' n end-call
    compute n = function J-NUM(ex, 'lifetimeBufosFromExploring') + function J-NUM(rewards-node, 'bufos')
    call static "j_set_number" using by value ex
        by reference z'lifetimeBufosFromExploring' n end-call
    perform level-loop.
combat-ended.
    move 'COMBAT_ENDED' to event-name perform new-event
    call static "j_clone_into" using by value current-enemy
        by reference tmp end-call
    call static "j_set" using by value payload
        by reference z'enemy' by value tmp end-call
    call static "j_set_boolean" using by value payload by reference z'victory' by value passed end-call
    if passed = 1 and rewards-node not = null
    call static "j_clone_into" using by value rewards-node
        by reference tmp end-call
    call static "j_set" using by value payload
        by reference z'rewards' by value tmp end-call
    end-if
    perform emit-event.
finish-combat.
    move function J-STR(ex, 'state') to old-state
    move 'exploring' to new-state
    move function J-NUM(ex, 'health') to compare-a
    compute compare-b = function J-NUM(ex, 'maxHealth') * .2
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
    if compare-result < 0 move 'injured' to new-state
    else
    move function J-NUM(ex, 'health') to compare-a
    compute compare-b = function J-NUM(ex, 'maxHealth') * .5
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
        if compare-result < 0 move 'resting' to new-state end-if end-if
    call static "j_set_string" using by value ex
        by reference z'state' new-state
        by value function length(function trim(new-state)) end-call
    compute n = now-ms
    call static "j_set_number" using by value ex
        by reference z'stateStartTime' n end-call
    call static "j_set_null" using by value runtime-node by reference z'currentCombat' end-call
    call static "j_set_null" using by value runtime-node by reference z'currentEnemy' end-call
    perform emit-state-change perform emit-updated.
end program BUFO-EXPLORER.
