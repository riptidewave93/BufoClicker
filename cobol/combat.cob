identification division.
program-id. BUFO-COMBAT.
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
01 battle usage pointer.
01 ex usage pointer.
01 enemy usage pointer.
01 logs usage pointer.
01 reward-node usage pointer.
01 nested-req usage pointer.
01 nested-res usage pointer.
01 array-node usage pointer.
01 item usage pointer.
01 action-name pic x(16).
01 ex-name pic x(256).
01 enemy-name pic x(256).
01 message-text pic x(2048).
01 action-message pic x(2048).
01 drop-name pic x(256).
01 amount-text pic Z(19)9.
01 amount2-text pic Z(19)9.
01 string-pos usage binary-long.
01 i usage binary-long.
01 item-count usage binary-long.
01 round-count usage binary-long.
01 max-rounds usage comp-2.
01 attack-value usage comp-2.
01 defense-value usage comp-2.
01 min-factor usage comp-2.
01 max-factor usage comp-2.
01 damage usage comp-2.
01 damage-enemy usage comp-2.
01 damage-ex usage comp-2.
01 multiplier usage comp-2.
01 roll usage comp-2.
01 victory usage binary-long.
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
    evaluate op
      when 'combat.CombatStatus'
    move spaces to json-text
    string
        '{"InProgress":"inProgress","Victory":"victory","Defeat":"defeat"}'
        into json-text end-string
    call static "j_parse_into" using by reference json-text
        by value 65 by reference out-node end-call
      when 'combat.CombatActionType'
    move spaces to json-text
    string
        '{"Attack":"attack","Defend":"defend","Flee":"flee"}'
        into json-text end-string
    call static "j_parse_into" using by reference json-text
        by value 51 by reference out-node end-call
      when 'combat.initializeCombat' perform initialize-battle
      when 'combat.executeCombatAction' perform execute-action
      when 'combat.simulateCombat' perform simulate-battle
      when other
        call static "j_set_boolean" using by value res by reference z'ok' by value 0 end-call
    call static "j_set_string" using by value res
        by reference z'error' 'Unknown combat operation' by value 24 end-call
    end-evaluate
    if out-node not = null
    call static "j_set" using by value res
        by reference z'result' by value out-node end-call
    end-if
    goback.
load-names.
    move function J-STR(ex, 'name') to ex-name
    move function J-STR(enemy, 'name') to enemy-name.
initialize-battle.
    call static "j_object_into" using by reference battle end-call
    call static "j_get_into" using by value args
        by reference z'explorer' tmp end-call
    call static "j_clone_into" using by value tmp
        by reference ex end-call
    call static "j_set" using by value battle
        by reference z'explorer' by value ex end-call
    call static "j_get_into" using by value args
        by reference z'enemy' tmp end-call
    call static "j_clone_into" using by value tmp
        by reference enemy end-call
    call static "j_set" using by value battle
        by reference z'enemy' by value enemy end-call
    call static "j_set_string" using by value battle
        by reference z'status' 'inProgress' by value 10 end-call
    compute n = 1
    call static "j_set_number" using by value battle
        by reference z'round' n end-call
    compute n = now-ms
    call static "j_set_number" using by value battle
        by reference z'startTime' n end-call
    compute n = now-ms
    call static "j_set_number" using by value battle
        by reference z'lastActionTime' n end-call
    call static "j_array_into" using by reference logs end-call
    call static "j_set" using by value battle
        by reference z'combatLog' by value logs end-call
    perform load-names
    move spaces to message-text
    string function trim(ex-name) ' encounters ' function trim(enemy-name) '!'
        into message-text end-string
    perform append-log move battle to out-node.
append-log.
    call static "j_object_into" using by reference tmp end-call
    call static "j_set_string" using by value tmp
        by reference z'text' message-text
        by value function length(function trim(message-text)) end-call
    call static "j_get_into" using by value tmp
        by reference z'text' item end-call
    call static "j_clone_into" using by value item
        by reference array-node end-call
    call static "j_append" using by value logs array-node end-call
    call static "j_delete" using by value tmp end-call.
calculate-damage.
    call static "BUFO-RANDOM" using by value req ctx by reference roll end-call
    if min-factor < .85
        compute roll = .8 + roll * .4
    else compute roll = .9 + roll * .2 end-if
    compute damage = function max(1, attack-value - defense-value * .5) * roll
    compute damage = function integer(damage + .5).
enemy-attack.
    compute attack-value = function J-NUM(enemy, 'attack') * multiplier
    compute defense-value = function J-NUM(ex, 'defense.value') * function J-NUM(ex, 'defense.multiplier')
    move .9 to min-factor move 1.1 to max-factor perform calculate-damage
    move damage to damage-ex
    compute n = function max(0, function J-NUM(ex, 'health') - damage)
    call static "j_set_number" using by value ex
        by reference z'health' n end-call
    move damage to amount-text move spaces to message-text
    string function trim(enemy-name) ' attacks ' function trim(ex-name) ' for '
        function trim(amount-text) ' damage!' into message-text end-string
    perform append-log.
calculate-rewards.
    call static "j_object_into" using by reference nested-req end-call
    call static "j_object_into" using by reference nested-res end-call
    call static "j_set_string" using by value nested-req
        by reference z'operation' 'enemy.calculateEnemyRewards' by value 27 end-call
    call static "j_clone_into" using by value enemy
        by reference tmp end-call
    call static "j_set" using by value nested-req
        by reference z'args.enemy' by value tmp end-call
    call static "j_get_into" using by value req
        by reference z'random' tmp end-call
    call static "j_clone_into" using by value tmp
        by reference item end-call
    if item not = null
    call static "j_set" using by value nested-req
        by reference z'random' by value item end-call
    end-if
    call static "BUFO-ENEMIES" using by value nested-req ctx nested-res end-call
    call static "j_get_into" using by value nested-res
        by reference z'result' tmp end-call
    call static "j_clone_into" using by value tmp
        by reference reward-node end-call
    call static "j_delete" using by value nested-req end-call
    call static "j_delete" using by value nested-res end-call.
execute-action.
    call static "j_get_into" using by value args
        by reference z'state' tmp end-call
    call static "j_clone_into" using by value tmp
        by reference battle end-call
    call static "j_get_into" using by value battle
        by reference z'explorer' ex end-call
    call static "j_get_into" using by value battle
        by reference z'enemy' enemy end-call
    call static "j_get_into" using by value battle
        by reference z'combatLog' logs end-call
    compute n = function J-NUM(battle, 'round') + 1
    call static "j_set_number" using by value battle
        by reference z'round' n end-call
    compute n = now-ms
    call static "j_set_number" using by value battle
        by reference z'lastActionTime' n end-call
    perform load-names
    move function J-STR(args, 'action') to action-name
    move 0 to damage-enemy damage-ex victory
    move spaces to action-message
    evaluate action-name
      when 'attack'
        compute attack-value = function J-NUM(ex, 'attack.value') * function J-NUM(ex, 'attack.multiplier')
        move function J-NUM(enemy, 'defense') to defense-value
        move .8 to min-factor move 1.2 to max-factor perform calculate-damage
        move damage to damage-enemy amount-text
    compute n = function max(0, function J-NUM(enemy, 'health') - damage)
    call static "j_set_number" using by value enemy
        by reference z'health' n end-call
        string function trim(ex-name) ' attacks ' function trim(enemy-name) ' for '
            function trim(amount-text) ' damage!' into action-message end-string
        move action-message to message-text perform append-log
        if function J-NUM(enemy, 'health') <= 0
            move 1 to victory
    call static "j_set_string" using by value battle
        by reference z'status' 'victory' by value 7 end-call
            move spaces to message-text
            string function trim(enemy-name) ' is defeated!' into message-text end-string
            perform append-log perform calculate-rewards
            compute n = function J-NUM(reward-node, 'bufos') move n to amount-text
            compute n = function J-NUM(reward-node, 'experience') move n to amount2-text
            move spaces to message-text
            string 'Gained ' function trim(amount-text) ' bufos and '
                function trim(amount2-text) ' experience!' into message-text end-string
            perform append-log perform log-drops
        else move 1 to multiplier perform enemy-attack end-if
      when 'defend'
        move .5 to multiplier perform enemy-attack
        string function trim(ex-name) ' defends against ' function trim(enemy-name)
            "'s attack!" into action-message end-string
        move action-message to message-text perform append-log
      when 'flee'
        compute n = function min(.75, .5 + (function J-NUM(ex, 'speed.value') *
            function J-NUM(ex, 'speed.multiplier') - function J-NUM(enemy, 'speed')) / 20)
        call static "BUFO-RANDOM" using by value req ctx by reference roll end-call
    move roll to compare-a
    move n to compare-b
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
        if compare-result < 0
            string function trim(ex-name) ' successfully fled from the battle!'
                into action-message end-string
            move action-message to message-text perform append-log
    call static "j_set_string" using by value battle
        by reference z'status' 'defeat' by value 6 end-call
            move 2 to victory
        else
            string function trim(ex-name) ' failed to escape!' into action-message end-string
            move action-message to message-text perform append-log
            move 1.2 to multiplier perform enemy-attack
        end-if
    end-evaluate
    if victory = 0 and function J-NUM(ex, 'health') <= 0
    call static "j_set_string" using by value battle
        by reference z'status' 'defeat' by value 6 end-call
        move spaces to message-text
        string function trim(ex-name) ' has been defeated!' into message-text end-string
        perform append-log
    end-if
    call static "j_object_into" using by reference out-node end-call
    call static "j_set" using by value out-node
        by reference z'newState' by value battle end-call
    compute n = damage-enemy
    call static "j_set_number" using by value out-node
        by reference z'damageToEnemy' n end-call
    compute n = damage-ex
    call static "j_set_number" using by value out-node
        by reference z'damageToExplorer' n end-call
    call static "j_set_string" using by value out-node
        by reference z'actionMessage' action-message
        by value function length(function trim(action-message)) end-call
    if victory = 1
    call static "j_set" using by value out-node
        by reference z'rewards' by value reward-node end-call
    end-if.
log-drops.
    call static "j_get_into" using by value reward-node
        by reference z'drops' array-node end-call
    call static "j_size" using by value array-node by reference x'00' returning item-count end-call
    if item-count > 0
        move spaces to message-text move 1 to string-pos
        string 'Found items: ' into message-text pointer string-pos end-string
        perform varying i from 0 by 1 until i >= item-count
            call static "j_at_into" using by value array-node i by reference item end-call
            if i > 0 string ', ' into message-text pointer string-pos end-string end-if
            move function J-STR(item, ' ') to drop-name
            string function trim(drop-name) into message-text pointer string-pos end-string
        end-perform
        string '!' into message-text pointer string-pos end-string
        perform append-log
    end-if.
simulate-battle.
    call static "j_get_into" using by value args
        by reference z'explorer' tmp end-call
    call static "j_clone_into" using by value tmp
        by reference ex end-call
    call static "j_get_into" using by value args
        by reference z'enemy' tmp end-call
    call static "j_clone_into" using by value tmp
        by reference enemy end-call
    move 10 to max-rounds
    call static "j_has" using by value args by reference z'simulationRounds' returning flag end-call
    if flag = 1 compute max-rounds = function J-NUM(args, 'simulationRounds') end-if
    move 0 to round-count
    perform until round-count >= max-rounds or function J-NUM(ex, 'health') <= 0 or function J-NUM(enemy, 'health') <= 0
        add 1 to round-count
        compute attack-value = function J-NUM(ex, 'attack.value') * function J-NUM(ex, 'attack.multiplier')
        move function J-NUM(enemy, 'defense') to defense-value
        move .9 to min-factor move 1.1 to max-factor perform calculate-damage
    compute n = function max(0, function J-NUM(enemy, 'health') - damage)
    call static "j_set_number" using by value enemy
        by reference z'health' n end-call
        if function J-NUM(enemy, 'health') > 0
            move function J-NUM(enemy, 'attack') to attack-value
            compute defense-value = function J-NUM(ex, 'defense.value') * function J-NUM(ex, 'defense.multiplier')
            perform calculate-damage
    compute n = function max(0, function J-NUM(ex, 'health') - damage)
    call static "j_set_number" using by value ex
        by reference z'health' n end-call
        end-if
    end-perform
    move 0 to victory
    if function J-NUM(enemy, 'health') <= 0 move 1 to victory end-if
    call static "j_object_into" using by reference out-node end-call
    call static "j_set_boolean" using by value out-node by reference z'victory' by value victory end-call
    move function J-NUM(ex, 'health') to n
    call static "j_set_number" using by value out-node
        by reference z'explorerRemainingHealth' n end-call
    compute n = round-count
    call static "j_set_number" using by value out-node
        by reference z'rounds' n end-call
    if victory = 1
        perform calculate-rewards
    move function J-NUM(reward-node, 'experience') to n
    call static "j_set_number" using by value out-node
        by reference z'experienceGained' n end-call
    move function J-NUM(reward-node, 'bufos') to n
    call static "j_set_number" using by value out-node
        by reference z'bufosGained' n end-call
    call static "j_get_into" using by value reward-node
        by reference z'drops' tmp end-call
    call static "j_clone_into" using by value tmp
        by reference item end-call
        call static "j_delete" using by value reward-node end-call
    else
    compute n = 0
    call static "j_set_number" using by value out-node
        by reference z'experienceGained' n end-call
    compute n = 0
    call static "j_set_number" using by value out-node
        by reference z'bufosGained' n end-call
        call static "j_array_into" using by reference item end-call
    end-if
    call static "j_set" using by value out-node
        by reference z'itemsFound' by value item end-call
    call static "j_delete" using by value ex end-call
    call static "j_delete" using by value enemy end-call.
end program BUFO-COMBAT.
