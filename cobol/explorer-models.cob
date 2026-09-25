identification division.
program-id. BUFO-EXPLORER-MODELS.
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
01 defaults-node usage pointer.
01 check-node usage pointer.
01 default-item usage pointer.
01 target-node usage pointer.
01 field-name pic x(128).
01 check-path pic x(128).
01 check-type usage binary-long.
01 is-valid usage binary-long.
01 has-field usage binary-long.
01 field-index usage binary-long.
01 nested-index usage binary-long.
01 maximum usage comp-2.
01 minimum usage comp-2.
01 require-integer usage binary-long.
01 strict-mode usage binary-long.
01 ex usage pointer.
01 outcome usage pointer.
01 stat usage pointer.
01 scalar usage comp-2.
01 dps usage comp-2.
01 survival usage comp-2.
01 power-rating usage comp-2.
01 area-level usage comp-2.
01 effective usage comp-2.
01 duration-seconds usage comp-2.
01 elapsed-seconds usage comp-2.
01 health-value usage comp-2.
01 max-health usage comp-2.
01 level-value usage comp-2.
01 cost usage comp-2.
01 roll usage comp-2.
01 old-state pic x(16).
01 new-state pic x(16).
01 area-name pic x(64).
01 stat-name pic x(32).
01 path-z pic x(64).
01 passed usage binary-long.
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
    call static "j_get_into" using by value args
        by reference z'explorer' tmp end-call
    call static "j_clone_into" using by value tmp
        by reference ex end-call
    evaluate op
        when 'model.validate'
            perform validate-explorer
            call static 'j_set_boolean' using by value res
                by reference z'result' by value is-valid end-call
        when 'model.normalize'
            perform normalize-explorer
        when 'model.DEFAULT_EXPLORER_DATA'
            perform defaults
            move ex to out-node
        when 'model.ExplorerState'
            perform enum-state
        when 'model.calculateDPS'
            perform derive-dps move dps to scalar perform number-result
        when 'model.calculateSurvivalTime'
            perform derive-survival move survival to scalar
            perform number-result
        when 'model.calculatePowerRating'
            perform derive-power move power-rating to scalar
            perform number-result
        when 'model.calculateAreaEffectiveness'
            move function J-NUM(args, 'areaLevel') to area-level
            perform derive-effectiveness move effective to scalar
            perform number-result
        when 'model.calculateStatUpgradeCost'
            move function J-NUM(args, 'statLevel') to level-value
            move 50 to cost
            call static "j_has" using by value args
                by reference z'baseCost' returning flag end-call
            if flag = 1 compute cost = function J-NUM(args, 'baseCost') end-if
            perform stat-cost move cost to scalar perform number-result
        when 'model.recalculateExplorerStats'
            perform recalculate move ex to out-node
        when 'model.canLevelUp'
            perform can-level
            call static "j_set_boolean" using by value res
                by reference z'result' by value passed end-call
        when 'model.levelUpExplorer'
            perform level-once move ex to out-node
        when 'model.upgradeExplorerStat'
            perform upgrade-stat
        when 'model.startExploration'
            perform start-exploration move ex to out-node
        when 'model.startCombat'
            if function J-STR(ex, 'state') = 'exploring'
    call static "j_set_string" using by value ex
        by reference z'state' 'fighting' by value 8 end-call
    compute n = now-ms
    call static "j_set_number" using by value ex
        by reference z'stateStartTime' n end-call
            end-if
            move ex to out-node
        when 'model.calculateExplorationResult'
            move function J-NUM(args, 'elapsedSeconds') to elapsed-seconds
            perform exploration-result move outcome to out-node
        when 'model.completeExploration'
    call static "j_get_into" using by value args
        by reference z'result' outcome end-call
            perform complete-exploration move ex to out-node
        when 'model.restExplorer'
            move function J-NUM(args, 'seconds') to elapsed-seconds
            perform rest-explorer move ex to out-node
        when 'model.getAreaLevel'
            move function J-STR(args, 'area') to area-name
            perform lookup-area move area-level to scalar
            perform number-result
        when 'model.updateExplorer'
            perform update-explorer
        when other
            call static "j_set_boolean" using by value res
                by reference z'ok' by value 0 end-call
    call static "j_set_string" using by value res
        by reference z'error' 'Unknown Explorer model operation' by value 32 end-call
    end-evaluate
    if out-node not = null
    call static "j_set" using by value res
        by reference z'result' by value out-node end-call
        if out-node = ex set ex to null end-if
    end-if
    call static "j_delete" using by value ex end-call
    goback.
number-result.
    call static "j_set_number" using by value res
        by reference z'result' scalar end-call.
defaults.
    move spaces to json-text
    string
        '{"name":"Explorer Frog","level":1,"experience":0,"experienceToNextLevel":100,"state":"idle","stateSt'
        'artTime":1000,"health":100,"maxHealth":100,"attack":{"value":10,"level":1,"growthRate":2,"upgradeCos'
        't":50,"multiplier":1},"defense":{"value":5,"level":1,"growthRate":1.5,"upgradeCost":50,"multiplier":'
        '1},"speed":{"value":8,"level":1,"growthRate":1.2,"upgradeCost":50,"multiplier":1},"luck":{"value":5,'
        '"level":1,"growthRate":1,"upgradeCost":50,"multiplier":1},"equipment":{"weapon":null,"armor":null,"a'
        'ccessory":null},"explorationProgress":0,"currentArea":"Pond","explorationsCompleted":0,"lifetimeBufo'
        'sFromExploring":0}'
        into json-text end-string
    call static "j_parse_into" using by reference json-text
        by value 618 by reference ex end-call
    compute n = now-ms
    call static "j_set_number" using by value ex
        by reference z'stateStartTime' n end-call
.
enum-state.
    move spaces to json-text
    string
        '{"Idle":"idle","Exploring":"exploring","Fighting":"fighting","Resting":"resting","Injured":"injured"'
        '}'
        into json-text end-string
    call static "j_parse_into" using by reference json-text
        by value 101 by reference out-node end-call
.
derive-dps.
    compute dps = function J-NUM(ex, 'attack.value') *
        function J-NUM(ex, 'attack.multiplier') * function max(0.5,
        function J-NUM(ex, 'speed.value') *
        function J-NUM(ex, 'speed.multiplier') / 20).
derive-survival.
    compute scalar = (5 + function J-NUM(ex, 'level') * 2) *
        (1 - function min(0.8, function J-NUM(ex, 'defense.value') *
        function J-NUM(ex, 'defense.multiplier') / 100))
    if scalar <= 0 move 999 to survival else
        compute survival = function J-NUM(ex, 'health') / scalar end-if.
derive-power.
    perform derive-dps perform derive-survival
    compute power-rating = function integer(dps * survival / 10 +
        function sqrt(function J-NUM(ex, 'luck.value') *
        function J-NUM(ex, 'luck.multiplier'))).
derive-effectiveness.
    perform derive-power
    move power-rating to compare-a
    compute compare-b = area-level * 25
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
    if compare-result >= 0 move 1 to effective else
        compute effective = power-rating / (area-level * 25) end-if.
stat-cost.
    compute power-base = 1.15
    compute power-exponent = level-value - 1
    call static 'h_power' using by reference power-base power-exponent power-result end-call
    compute cost = function integer(cost * power-result).
recalculate.
    compute max-health = 100 + (function J-NUM(ex, 'level') - 1) * 20 +
        function J-NUM(ex, 'defense.level') * 10
    compute n = max-health
    call static "j_set_number" using by value ex
        by reference z'maxHealth' n end-call
    compute n = function min(function J-NUM(ex, 'health'), max-health)
    call static "j_set_number" using by value ex
        by reference z'health' n end-call
    compute power-base = 1.5
    compute power-exponent = function J-NUM(ex, 'level') - 1
    call static 'h_power' using by reference power-base power-exponent power-result end-call
    compute n = 0 - function integer(0 - 100 * power-result)
    call static "j_set_number" using by value ex
        by reference z'experienceToNextLevel' n end-call
.
can-level.
    move 0 to passed
    move function J-NUM(ex, 'experience') to compare-a
    move function J-NUM(ex, 'experienceToNextLevel') to compare-b
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
    if compare-result >= 0 move 1 to passed end-if.
level-once.
    perform can-level
    if passed = 1
    compute n = function J-NUM(ex, 'level') + 1
    call static "j_set_number" using by value ex
        by reference z'level' n end-call
    compute n = function J-NUM(ex, 'experience') - function J-NUM(ex, 'experienceToNextLevel')
    call static "j_set_number" using by value ex
        by reference z'experience' n end-call
        perform recalculate
    end-if.
upgrade-stat.
    move function J-STR(args, 'statName') to stat-name
    move 0 to passed cost
    if stat-name = 'attack' or 'defense' or 'speed' or 'luck'
        move low-values to path-z
        string function trim(stat-name) x'00' into path-z end-string
        call static "j_get_into" using by value ex
            by reference path-z stat end-call
        move function J-NUM(stat, 'upgradeCost') to cost
    move function J-NUM(args, 'bufos') to compare-a
    move cost to compare-b
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
        if compare-result >= 0
            move 1 to passed
            compute level-value = function J-NUM(stat, 'level') + 1
    compute n = level-value
    call static "j_set_number" using by value stat
        by reference z'level' n end-call
    compute n = function J-NUM(stat, 'value') + function J-NUM(stat, 'growthRate')
    call static "j_set_number" using by value stat
        by reference z'value' n end-call
            move cost to scalar move 50 to cost perform stat-cost
    compute n = cost
    call static "j_set_number" using by value stat
        by reference z'upgradeCost' n end-call
            move scalar to cost perform recalculate
        end-if
    end-if
    call static "j_object_into" using by reference out-node end-call
    call static "j_set_boolean" using by value out-node
        by reference z'success' by value passed end-call
    compute n = cost
    call static "j_set_number" using by value out-node
        by reference z'cost' n end-call
    call static "j_set" using by value out-node
        by reference z'explorer' by value ex end-call
    set ex to null.
start-exploration.
    move function J-STR(ex, 'state') to old-state
    move function J-NUM(ex, 'health') to compare-a
    compute compare-b = function J-NUM(ex, 'maxHealth') * .2
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
    if (old-state = 'idle' or 'resting') and compare-result >= 0
    call static "j_set_string" using by value ex
        by reference z'state' 'exploring' by value 9 end-call
    compute n = now-ms
    call static "j_set_number" using by value ex
        by reference z'stateStartTime' n end-call
    compute n = 0
    call static "j_set_number" using by value ex
        by reference z'explorationProgress' n end-call
        move function J-STR(args, 'area') to area-name
    call static "j_set_string" using by value ex
        by reference z'currentArea' area-name
        by value function length(function trim(area-name)) end-call
    end-if.
lookup-area.
    evaluate area-name
        when 'Creek' move 2 to area-level
        when 'Swamp' move 3 to area-level
        when 'River' move 4 to area-level
        when 'Lake' move 5 to area-level
        when 'Forest' move 6 to area-level
        when 'Mountains' move 8 to area-level
        when 'Dungeon' move 10 to area-level
        when other move 1 to area-level
    end-evaluate.
exploration-result.
    move function J-STR(ex, 'currentArea') to area-name
    perform lookup-area perform derive-effectiveness
    compute duration-seconds = elapsed-seconds * (.5 + .5 * effective)
    call static "BUFO-RANDOM" using by value req ctx by reference roll end-call
    move 0 to passed
    move roll to compare-a
    compute compare-b = function J-NUM(ex, 'health') / function J-NUM(ex, 'maxHealth') * effective
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
    if compare-result < 0 move 1 to passed end-if
    call static "j_object_into" using by reference outcome end-call
    call static "j_set_boolean" using by value outcome
        by reference z'survived' by value passed end-call
    compute n = duration-seconds
    call static "j_set_number" using by value outcome
        by reference z'duration' n end-call
    compute scalar = area-level * 50 * effective * duration-seconds / 60
    if passed = 1 compute scalar = scalar * (1 +
        function J-NUM(ex, 'luck.value') * function J-NUM(ex, 'luck.multiplier') / 100)
    else compute scalar = scalar * .3 end-if
    compute n = function integer(scalar)
    call static "j_set_number" using by value outcome
        by reference z'bufosGained' n end-call
    compute scalar = area-level * 10 * duration-seconds / 60
    if passed = 0 compute scalar = scalar * .5 end-if
    compute n = function integer(scalar)
    call static "j_set_number" using by value outcome
        by reference z'experienceGained' n end-call
    call static "j_array_into" using by reference tmp end-call
    call static "j_set" using by value outcome
        by reference z'itemsFound' by value tmp end-call
.
complete-exploration.
    move function J-NUM(ex, 'maxHealth') to max-health
    call static "j_boolean" using by value outcome
        by reference z'survived' returning passed end-call
    move .1 to scalar if passed = 0 move .4 to scalar end-if
    compute health-value = function max(1, function J-NUM(ex, 'health') - max-health * scalar)
    move 'resting' to new-state
    move health-value to compare-a
    compute compare-b = max-health * .2
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
    compute n = function J-NUM(ex, 'experience') + function J-NUM(outcome, 'experienceGained')
    call static "j_set_number" using by value ex
        by reference z'experience' n end-call
    compute n = function J-NUM(ex, 'explorationsCompleted') + 1
    call static "j_set_number" using by value ex
        by reference z'explorationsCompleted' n end-call
    compute n = function J-NUM(ex, 'lifetimeBufosFromExploring') + function J-NUM(outcome, 'bufosGained')
    call static "j_set_number" using by value ex
        by reference z'lifetimeBufosFromExploring' n end-call
    compute n = 0
    call static "j_set_number" using by value ex
        by reference z'explorationProgress' n end-call
    perform level-once.
rest-explorer.
    move function J-STR(ex, 'state') to old-state new-state
    if old-state = 'resting' or 'injured'
        move .1 to scalar if old-state = 'injured' move .05 to scalar end-if
        move function J-NUM(ex, 'maxHealth') to max-health
        call static 'h_number_binary' using by value 3
            by reference max-health scalar health-value end-call
        move 60 to compare-b
        call static 'h_number_binary' using by value 4
            by reference elapsed-seconds compare-b power-result end-call
        call static 'h_number_binary' using by value 3
            by reference health-value power-result health-value end-call
        move function J-NUM(ex, 'health') to compare-a
        call static 'h_number_binary' using by value 1
            by reference compare-a health-value health-value end-call
    move health-value to compare-a
    move max-health to compare-b
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
        if compare-result > 0 move max-health to health-value end-if
    move health-value to compare-a
    move max-health to compare-b
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
        if compare-result >= 0 move 'idle' to new-state
        else
    move health-value to compare-a
    compute compare-b = max-health * .2
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
            if compare-result >= 0 and old-state = 'injured'
                move 'resting' to new-state end-if end-if
    compute n = health-value
    call static "j_set_number" using by value ex
        by reference z'health' n end-call
    call static "j_set_string" using by value ex
        by reference z'state' new-state
        by value function length(function trim(new-state)) end-call
        if new-state not = old-state
    compute n = now-ms
    call static "j_set_number" using by value ex
        by reference z'stateStartTime' n end-call
        end-if
    end-if.
update-explorer.
    move function J-NUM(args, 'deltaSeconds') to elapsed-seconds
    move function J-STR(ex, 'state') to old-state
    call static "j_object_into" using by reference out-node end-call
    evaluate old-state
      when 'exploring'
        compute scalar = function J-NUM(ex, 'explorationProgress') + elapsed-seconds / 60 * 10
    move scalar to compare-a
    move 100 to compare-b
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
        if compare-result >= 0
            compute elapsed-seconds = (now-ms - function J-NUM(ex, 'stateStartTime')) / 1000
            perform exploration-result perform complete-exploration
    call static "j_set" using by value out-node
        by reference z'result' by value outcome end-call
        else
    compute n = scalar
    call static "j_set_number" using by value ex
        by reference z'explorationProgress' n end-call
        end-if
      when 'resting' when 'injured' perform rest-explorer
    end-evaluate
    call static "j_set" using by value out-node
        by reference z'explorer' by value ex end-call
    set ex to null.
validate-explorer.
    move 1 to is-valid
    call static 'j_type' using by value ex by reference x'00' returning check-type end-call
    if check-type not = 5 move 0 to is-valid exit paragraph end-if

    move 'level' to check-path
    move 1 to minimum move 1000 to maximum
    move 1 to require-integer perform check-number
    move 'experience' to check-path
    move 0 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    move 'experienceToNextLevel' to check-path
    move 1 to minimum move 1.0E+200 to maximum
    move 0 to require-integer perform check-number
    move 'stateStartTime' to check-path
    move 0 to minimum move 9.0E+15 to maximum
    move 0 to require-integer perform check-number
    move 'health' to check-path
    move 0 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    move 'maxHealth' to check-path
    move 1 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    move 'explorationProgress' to check-path
    move 0 to minimum move 100 to maximum
    move 0 to require-integer perform check-number
    move 'explorationsCompleted' to check-path
    move 0 to minimum move 9.0E+15 to maximum
    move 1 to require-integer perform check-number
    move 'lifetimeBufosFromExploring' to check-path
    move 0 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    move function J-NUM(ex, 'health') to compare-a
    move function J-NUM(ex, 'maxHealth') to compare-b
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
    if compare-result > 0 move 0 to is-valid end-if
    move 'name' to check-path perform check-text
    move 'currentArea' to check-path perform check-text
    call static 'j_type' using by value ex by reference z'state' returning check-type end-call
    move function J-STR(ex, 'state') to old-state
    if check-type not = 3 or (old-state not = 'idle' and 'exploring' and 'fighting' and 'resting' and 'injured')
        move 0 to is-valid end-if
    move 'attack.value' to check-path
    move 0 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    move 'attack.level' to check-path
    move 1 to minimum move 1000 to maximum
    move 1 to require-integer perform check-number
    move 'attack.growthRate' to check-path
    move 0 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    move 'attack.upgradeCost' to check-path
    move 0 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    move 'attack.multiplier' to check-path
    move 0 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    move 'defense.value' to check-path
    move 0 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    move 'defense.level' to check-path
    move 1 to minimum move 1000 to maximum
    move 1 to require-integer perform check-number
    move 'defense.growthRate' to check-path
    move 0 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    move 'defense.upgradeCost' to check-path
    move 0 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    move 'defense.multiplier' to check-path
    move 0 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    move 'speed.value' to check-path
    move 0 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    move 'speed.level' to check-path
    move 1 to minimum move 1000 to maximum
    move 1 to require-integer perform check-number
    move 'speed.growthRate' to check-path
    move 0 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    move 'speed.upgradeCost' to check-path
    move 0 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    move 'speed.multiplier' to check-path
    move 0 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    move 'luck.value' to check-path
    move 0 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    move 'luck.level' to check-path
    move 1 to minimum move 1000 to maximum
    move 1 to require-integer perform check-number
    move 'luck.growthRate' to check-path
    move 0 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    move 'luck.upgradeCost' to check-path
    move 0 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    move 'luck.multiplier' to check-path
    move 0 to minimum move 1.0E+100 to maximum
    move 0 to require-integer perform check-number
    call static 'j_type' using by value ex by reference z'equipment' returning check-type end-call
    if check-type not = 5 move 0 to is-valid end-if
    move 'equipment.weapon' to check-path perform check-equipment
    move 'equipment.armor' to check-path perform check-equipment
    move 'equipment.accessory' to check-path perform check-equipment
    .
check-number.
    move low-values to path-z
    string function trim(check-path) x'00' into path-z end-string
    call static 'j_type' using by value ex by reference path-z returning check-type end-call
    if check-type not = 2 move 0 to is-valid exit paragraph end-if
    move function J-NUM(ex, check-path) to n
    move n to compare-a
    move minimum to compare-b
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
    if compare-result < 0 move 0 to is-valid end-if
    move n to compare-a
    move maximum to compare-b
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
    if compare-result > 0 move 0 to is-valid end-if
    move n to compare-a
    compute compare-b = function integer(n)
    call static 'h_number_compare' using by reference compare-a compare-b
        returning compare-result end-call
    if require-integer = 1 and compare-result not = 0 move 0 to is-valid end-if.
check-text.
    move low-values to path-z
    string function trim(check-path) x'00' into path-z end-string
    call static 'j_type' using by value ex by reference path-z returning check-type end-call
    if check-type not = 3 move 0 to is-valid exit paragraph end-if
    move function J-STR(ex, check-path) to json-text
    if function length(function trim(json-text)) = 0 or > 256 move 0 to is-valid end-if.
check-equipment.
    move low-values to path-z
    string function trim(check-path) x'00' into path-z end-string
    call static 'j_has' using by value ex by reference path-z returning has-field end-call
    call static 'j_type' using by value ex by reference path-z returning check-type end-call
    if has-field = 0 or (check-type not = 0 and 3) move 0 to is-valid end-if
    if check-type = 3
        move function J-STR(ex, check-path) to json-text
        if function length(function trim(json-text)) > 256 move 0 to is-valid end-if
    end-if.
normalize-explorer.
    call static 'j_boolean' using by value args by reference z'strict' returning strict-mode end-call
    call static 'j_type' using by value ex by reference x'00' returning check-type end-call
    if check-type not = 5
        perform invalid-normalization exit paragraph
    end-if
    if strict-mode = 0
        move ex to target-node set ex to null perform defaults
        move ex to defaults-node move target-node to ex
        call static 'j_size' using by value defaults-node by reference x'00' returning field-index end-call
        perform until field-index <= 0
            subtract 1 from field-index
            call static 'j_at_into' using by value defaults-node field-index by reference default-item end-call
            call static 'j_key' using by value default-item by reference field-name by value 128 end-call
            move low-values to check-path
            string function trim(field-name) x'00' into check-path end-string
            call static 'j_has' using by value ex by reference check-path returning has-field end-call
            if has-field = 0
                call static 'j_clone_into' using by value default-item by reference tmp end-call
                call static 'j_set' using by value ex by reference check-path by value tmp end-call
            else
                call static 'j_type' using by value default-item by reference x'00' returning check-type end-call
                if check-type = 5 perform fill-nested-defaults end-if
            end-if
        end-perform
        call static 'j_delete' using by value defaults-node end-call
    end-if
    perform validate-explorer
    if is-valid = 0 perform invalid-normalization exit paragraph end-if
    if function J-STR(ex, 'state') = 'fighting'
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
    end-if
    move ex to out-node.
fill-nested-defaults.
    call static 'j_get_into' using by value ex by reference check-path target-node end-call
    call static 'j_type' using by value target-node by reference x'00' returning check-type end-call
    if check-type not = 5 exit paragraph end-if
    call static 'j_size' using by value default-item by reference x'00' returning nested-index end-call
    perform until nested-index <= 0
        subtract 1 from nested-index
        call static 'j_at_into' using by value default-item nested-index by reference check-node end-call
        call static 'j_key' using by value check-node by reference field-name by value 128 end-call
        move low-values to check-path
        string function trim(field-name) x'00' into check-path end-string
        call static 'j_has' using by value target-node by reference check-path returning has-field end-call
        if has-field = 0
            call static 'j_clone_into' using by value check-node by reference tmp end-call
            call static 'j_set' using by value target-node by reference check-path by value tmp end-call
        end-if
    end-perform.
invalid-normalization.
    call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
    call static "j_set_string" using by value res
        by reference z'error' 'Invalid durable Explorer data' by value 29 end-call
.
end program BUFO-EXPLORER-MODELS.
