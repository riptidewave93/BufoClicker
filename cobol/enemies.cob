identification division.
program-id. BUFO-ENEMIES.
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
01 templates usage pointer.
01 candidate usage pointer.
01 template-node usage pointer.
01 array-node usage pointer.
01 item usage pointer.
01 drops usage pointer.
01 table-node usage pointer.
01 i usage binary-long.
01 j usage binary-long.
01 count-value usage binary-long.
01 valid-count usage binary-long.
01 selected usage binary-long.
01 type-index usage binary-long.
01 area-name pic x(64).
01 type-name pic x(16).
01 name-value pic x(256).
01 base-name pic x(128).
01 id-value pic x(256).
01 time-text pic Z(19)9.
01 reward-factor usage comp-2.
01 health-factor usage comp-2.
01 attack-factor usage comp-2.
01 defense-factor usage comp-2.
01 speed-factor usage comp-2.
01 area-level usage comp-2.
01 effective-level usage comp-2.
01 roll usage comp-2.
01 total-weight usage comp-2.
01 scalar usage comp-2.
01 base-stat usage comp-2.
01 scaling usage comp-2.
01 factor usage comp-2.
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
      when 'enemy.BASE_DROP_ITEMS'
    call static "j_get_into" using by value ctx
        by reference z'catalog.enemies.BASE_DROP_ITEMS' tmp end-call
    call static "j_clone_into" using by value tmp
        by reference out-node end-call
      when 'enemy.INITIAL_ENEMY_TEMPLATES'
    call static "j_get_into" using by value ctx
        by reference z'catalog.enemies.INITIAL_ENEMY_TEMPLATES' tmp end-call
    call static "j_clone_into" using by value tmp
        by reference out-node end-call
      when 'enemy.EnemyType'
    move spaces to json-text
    string
        '{"Normal":"normal","Elite":"elite","Boss":"boss"}'
        into json-text end-string
    call static "j_parse_into" using by reference json-text
        by value 49 by reference out-node end-call
      when 'enemy.generateEnemy' perform generate-enemy
      when 'enemy.calculateEnemyRewards' perform rewards
      when 'enemy.calculateRelativeDifficulty' perform difficulty
      when other
        call static "j_set_boolean" using by value res
            by reference z'ok' by value 0 end-call
    call static "j_set_string" using by value res
        by reference z'error' 'Unknown enemy operation' by value 23 end-call
    end-evaluate
    if out-node not = null
    call static "j_set" using by value res
        by reference z'result' by value out-node end-call
    end-if
    goback.
random-number.
    call static "BUFO-RANDOM" using by value req ctx by reference roll end-call.
generate-enemy.
    move function J-STR(args, 'area') to area-name
    move function J-NUM(args, 'areaLevel') to area-level
    compute effective-level = area-level + function J-NUM(args, 'distanceMultiplier') * .5
    call static "j_get_into" using by value ctx
        by reference z'catalog.enemies.INITIAL_ENEMY_TEMPLATES' templates end-call
    call static "j_size" using by value templates by reference x'00' returning count-value end-call
    move 0 to valid-count
    perform varying i from 0 by 1 until i >= count-value
        perform valid-template
        if flag = 1 add 1 to valid-count end-if
    end-perform
    if valid-count = 0
        call static "j_set_boolean" using by value res by reference z'ok' by value 0 end-call
        move spaces to name-value
        move area-level to time-text
        string 'No valid enemy templates for area ' function trim(area-name)
          ' at level ' function trim(time-text) into name-value end-string
    call static "j_set_string" using by value res
        by reference z'error' name-value
        by value function length(function trim(name-value)) end-call
        exit paragraph
    end-if
    perform random-number
    compute selected = function integer(roll * valid-count)
    move 0 to valid-count
    perform varying i from 0 by 1 until i >= count-value
        perform valid-template
        if flag = 1
            if valid-count = selected move candidate to template-node end-if
            add 1 to valid-count
        end-if
    end-perform
    call static "j_get_into" using by value template-node
        by reference z'typeWeights' array-node end-call
    call static "j_size" using by value array-node by reference x'00' returning count-value end-call
    move 0 to total-weight
    perform varying i from 0 by 1 until i >= count-value
        call static "j_at_into" using by value array-node i by reference item end-call
        compute total-weight = total-weight + function J-NUM(item, ' ')
    end-perform
    perform random-number compute scalar = roll * total-weight
    move 0 to type-index flag
    perform varying i from 0 by 1 until i >= count-value or flag = 1
        call static "j_at_into" using by value array-node i by reference item end-call
        compute scalar = scalar - function J-NUM(item, ' ')
        if scalar <= 0 move i to type-index move 1 to flag end-if
    end-perform
    call static "j_get_into" using by value template-node
        by reference z'possibleTypes' array-node end-call
    call static "j_at_into" using by value array-node type-index by reference item end-call
    move function J-STR(item, ' ') to type-name
    move 1 to health-factor attack-factor defense-factor speed-factor reward-factor
    evaluate type-name
      when 'elite' move 2.5 to health-factor reward-factor
        move 1.8 to attack-factor move 1.5 to defense-factor move 1.2 to speed-factor
      when 'boss' move 5 to health-factor reward-factor
        move 3 to attack-factor move 2.5 to defense-factor move 1.5 to speed-factor
    end-evaluate
    call static "j_object_into" using by reference out-node end-call
    move function J-NUM(template-node, 'baseMaxHealth') to base-stat
    move function J-NUM(template-node, 'healthScaling') to scaling
    move health-factor to factor perform scaled-stat
    compute n = scalar
    call static "j_set_number" using by value out-node
        by reference z'maxHealth' n end-call
    compute n = scalar
    call static "j_set_number" using by value out-node
        by reference z'health' n end-call
    move function J-NUM(template-node, 'baseAttack') to base-stat
    move function J-NUM(template-node, 'attackScaling') to scaling
    move attack-factor to factor perform scaled-stat
    compute n = scalar
    call static "j_set_number" using by value out-node
        by reference z'attack' n end-call
    move function J-NUM(template-node, 'baseDefense') to base-stat
    move function J-NUM(template-node, 'defenseScaling') to scaling
    move defense-factor to factor perform scaled-stat
    compute n = scalar
    call static "j_set_number" using by value out-node
        by reference z'defense' n end-call
    move function J-NUM(template-node, 'baseSpeed') to base-stat
    move function J-NUM(template-node, 'speedScaling') to scaling
    move speed-factor to factor perform scaled-stat
    compute n = scalar
    call static "j_set_number" using by value out-node
        by reference z'speed' n end-call
    move function J-STR(template-node, 'baseId') to base-name
    move now-ms to time-text move spaces to id-value
    string function trim(base-name) '_' function trim(area-name) '_'
        function trim(time-text) into id-value end-string
    call static "j_set_string" using by value out-node
        by reference z'id' id-value
        by value function length(function trim(id-value)) end-call
    move function J-STR(template-node, 'nameTemplate') to base-name
    move spaces to name-value
    evaluate type-name
      when 'elite' string 'Elite ' function trim(base-name) into name-value end-string
      when 'boss' string function trim(base-name) ' Boss' into name-value end-string
      when other move base-name to name-value
    end-evaluate
    call static "j_set_string" using by value out-node
        by reference z'name' name-value
        by value function length(function trim(name-value)) end-call
    call static "j_set_string" using by value out-node
        by reference z'type' type-name
        by value function length(function trim(type-name)) end-call
    call static "j_set_string" using by value out-node
        by reference z'area' area-name
        by value function length(function trim(area-name)) end-call
    compute n = effective-level
    call static "j_set_number" using by value out-node
        by reference z'difficultyLevel' n end-call
    move function J-STR(template-node, 'colorTheme') to name-value
    call static "j_set_string" using by value out-node
        by reference z'colorTheme' name-value
        by value function length(function trim(name-value)) end-call
    move function J-STR(template-node, 'spriteRef') to name-value
    call static "j_set_string" using by value out-node
        by reference z'spriteRef' name-value
        by value function length(function trim(name-value)) end-call
    call static "j_get_into" using by value template-node
        by reference z'baseDropTable' tmp end-call
    call static "j_clone_into" using by value tmp
        by reference table-node end-call
    compute power-base = 1.1
    compute power-exponent = effective-level
    call static 'h_power' using by reference power-base power-exponent power-result end-call
    compute n = function integer(function J-NUM(table-node, 'baseBufos') * power-result * reward-factor + .5)
    call static "j_set_number" using by value table-node
        by reference z'baseBufos' n end-call
    compute power-base = 1.1
    compute power-exponent = effective-level
    call static 'h_power' using by reference power-base power-exponent power-result end-call
    compute n = function integer(function J-NUM(table-node, 'baseExperience') * power-result * reward-factor + .5)
    call static "j_set_number" using by value table-node
        by reference z'baseExperience' n end-call
    call static "j_set" using by value out-node
        by reference z'dropTable' by value table-node end-call
.
valid-template.
    call static "j_at_into" using by value templates i by reference candidate end-call
    move 0 to flag
    if function J-NUM(candidate, 'minAreaLevel') <= area-level
    call static "j_get_into" using by value candidate
        by reference z'areas' array-node end-call
        call static "j_size" using by value array-node by reference x'00' returning j end-call
        perform until j <= 0
            subtract 1 from j
            call static "j_at_into" using by value array-node j by reference item end-call
            if function J-STR(item, ' ') = area-name move 1 to flag end-if
        end-perform
    end-if.
scaled-stat.
    perform random-number
    compute power-base = scaling
    compute power-exponent = function sqrt(effective-level)
    call static 'h_power' using by reference power-base power-exponent power-result end-call
    compute scalar = function integer(base-stat * power-result * factor * (.9 + roll * .2) + .5).
rewards.
    call static "j_get_into" using by value args
        by reference z'enemy.dropTable' table-node end-call
    call static "j_object_into" using by reference out-node end-call
    perform random-number
    compute n = function max(1, function integer(function J-NUM(table-node, 'baseBufos') * (.8 + roll * .4) + .5))
    call static "j_set_number" using by value out-node
        by reference z'bufos' n end-call
    perform random-number
    compute n = function max(1, function integer(function J-NUM(table-node, 'baseExperience') * (.8 + roll * .4) + .5))
    call static "j_set_number" using by value out-node
        by reference z'experience' n end-call
    call static "j_array_into" using by reference drops end-call
    call static "j_get_into" using by value table-node
        by reference z'guaranteedDrops' array-node end-call
    call static "j_size" using by value array-node by reference x'00' returning count-value end-call
    perform varying i from 0 by 1 until i >= count-value
        call static "j_at_into" using by value array-node i by reference item end-call
    call static "j_clone_into" using by value item
        by reference tmp end-call
        call static "j_append" using by value drops tmp end-call
    end-perform
    call static "j_get_into" using by value table-node
        by reference z'possibleDrops' array-node end-call
    call static "j_size" using by value array-node by reference x'00' returning count-value end-call
    perform varying i from 0 by 1 until i >= count-value
        call static "j_at_into" using by value array-node i by reference item end-call
        perform random-number
    move roll to compare-a
    move function J-NUM(item, 'dropRate') to compare-b
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
        if compare-result < 0
    call static "j_get_into" using by value item
        by reference z'id' candidate end-call
    call static "j_clone_into" using by value candidate
        by reference tmp end-call
            call static "j_append" using by value drops tmp end-call
        end-if
    end-perform
    call static "j_set" using by value out-node
        by reference z'drops' by value drops end-call
.
difficulty.
    call static "j_get_into" using by value args
        by reference z'enemyStats' item end-call
    perform power-value move scalar to total-weight
    call static "j_get_into" using by value args
        by reference z'explorerStats' item end-call
    perform power-value
    if scalar = 0
        call static "j_set_boolean" using by value res by reference z'ok' by value 0 end-call
    call static "j_set_string" using by value res
        by reference z'error' 'Relative difficulty requires nonzero explorer power' by value 51 end-call
    else
    compute n = total-weight / scalar
    call static "j_set_number" using by value res
        by reference z'result' n end-call
    end-if.
power-value.
    compute scalar = function J-NUM(item, 'attack') * 1.5 + function J-NUM(item, 'defense') +
        function J-NUM(item, 'health') * .2 + function J-NUM(item, 'speed') * .8.
end program BUFO-ENEMIES.
