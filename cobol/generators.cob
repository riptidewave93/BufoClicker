identification division.
program-id. BUFO-GENERATORS recursive.
environment division.
configuration section.
repository.
    function J-NUM
    function J-STR
    function all intrinsic.
data division.
local-storage section.
01 op pic x(96).
01 args usage pointer.
01 state-node usage pointer.
01 node usage pointer.
01 node2 usage pointer.
01 node3 usage pointer.
01 list-node usage pointer.
01 item usage pointer.
01 cp usage pointer.
01 result-node usage pointer.
01 rq usage pointer.
01 rs usage pointer.
01 ev usage pointer.
01 payload usage pointer.
01 events-node usage pointer.
01 event-name pic x(96).
01 write-status usage binary-long.
01 nv usage comp-2.
01 sv pic x(32768).
01 key-name pic x(256).
01 path-z pic x(512).
01 text-value pic x(256).
01 n usage comp-2.
01 m usage comp-2.
01 total usage comp-2.
01 factor usage comp-2.
01 i usage binary-long.
01 j usage binary-long.
01 count-items usage binary-long.
01 count2 usage binary-long.
01 flag usage binary-long.
01 found usage binary-long.
01 boost-event-node usage pointer.
01 input-args usage pointer.
01 arithmetic-a usage comp-2.
01 arithmetic-b usage comp-2.
01 arithmetic-one usage comp-2 value 1.
01 numeric-limit usage comp-2 value 1.0e300.
01 generator-node usage pointer.
01 generators-node usage pointer.
01 boosts-node usage pointer.
01 boost-node usage pointer.
01 requirements-node usage pointer.
01 requirement-node usage pointer.
01 original-node usage pointer.
01 new-list usage pointer.
01 generators-count usage binary-long.
01 gi usage binary-long.
01 ri usage binary-long.
01 requirements-count usage binary-long.
01 production usage comp-2.
01 old-production usage comp-2.
01 global-multiplier usage comp-2.
01 quantity usage comp-2.
01 budget usage comp-2.
01 price usage comp-2.
01 ratio usage comp-2.
01 owned usage comp-2.
01 affordable usage comp-2.
01 total-bufos usage comp-2.
01 generator-id pic x(256).
01 boost-id pic x(256).
01 requirement-type pic x(32).
01 target-id pic x(256).
01 valid-unlock usage binary-long.
01 manager-mode usage binary-long.
01 active-flag usage binary-long.
linkage section.
01 request usage pointer.
01 context usage pointer.
01 response usage pointer.
procedure division using by value request context response.
call static "j_get_into" using by value request by reference z'args' args end-call
call static "j_get_into" using by value context by reference z'state' state-node end-call
move function J-STR(request, 'operation') to op
call static "j_set_boolean" using by value response by reference z'ok' by value 1 end-call
move 0 to manager-mode
if op(1:10) = 'generator.'
    move 1 to manager-mode
call static "j_get_into" using by value state-node by reference z'generators' generators-node end-call
move function J-STR(args, 'generatorType') to generator-id
move low-values to path-z
string function trim(generator-id) x'00' into path-z end-string
call static "j_get_into" using by value generators-node by reference path-z original-node end-call
else
call static "j_get_into" using by value args by reference z'generator' original-node end-call
end-if
call static "j_clone_into" using by value original-node by reference generator-node end-call
if op = 'model.generator.updateGenerator'
call static "j_get_into" using by value args by reference z'currentGenerator' original-node end-call
if original-node not = null
call static "j_delete" using by value generator-node end-call
call static "j_clone_into" using by value original-node by reference generator-node end-call
end-if end-if
evaluate op
when 'model.generator.initializeGenerators'
call static "j_get_into" using by value context by reference z'catalog.generators' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
when 'model.generator.updateGenerator'
call static "j_get_into" using by value args by reference z'updates' node end-call
call static "j_merge" using by value generator-node node end-call
call static "j_clone_into" using by value generator-node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call

when 'model.generator.recalculateGenerator'
    move function J-NUM(args, 'globalMultiplier') to global-multiplier
    perform recalculate
call static "j_clone_into" using by value generator-node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call

when 'generator.recalculateGenerator'
    perform global-factor
    if generator-node not = null
        perform recalculate
        perform store-generator
call static "j_clone_into" using by value generator-node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
end-if
when 'model.generator.calculateBulkCost'
    move function J-NUM(args, 'quantity') to quantity
    perform bulk-cost
if ratio = 1 and quantity not = 1
call static "j_object_into" using by reference cp end-call
move 'number' to sv
call static "j_set_string" using by value cp by reference z'$oracle' sv by value function length(function trim(sv trailing)) end-call
move 'NaN' to sv
call static "j_set_string" using by value cp by reference z'value' sv by value function length(function trim(sv trailing)) end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
else
move price to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
end-if
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'model.generator.canAffordGenerator'
    move function J-NUM(args, 'quantity') to quantity
call static "j_has" using by value args by reference z'quantity' returning flag end-call
if flag = 0 move 1 to quantity end-if
    move function J-NUM(args, 'bufos') to budget
    perform bulk-cost
    if (budget - price) >= 0 and (quantity = 1 or ratio not = 1)
call static "j_set_boolean" using by value response by reference z'result' by value 1 end-call
else
call static "j_set_boolean" using by value response by reference z'result' by value 0 end-call
end-if
when 'model.generator.calculateMaxAffordable' when 'generator.getMaxAffordable'
    if manager-mode = 1
        move function J-NUM(args, 'availableBufos') to budget
    else
        move function J-NUM(args, 'bufos') to budget
    end-if
    perform max-affordable
    if manager-mode = 1
call static "j_boolean" using by value generator-node by reference z'enabled' returning flag end-call
if flag = 0 move 0 to affordable end-if
call static "j_boolean" using by value generator-node by reference z'unlocked' returning flag end-call
if flag = 0 move 0 to affordable end-if
    end-if
move affordable to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'model.generator.checkGeneratorUnlock' when 'model.generator.unlockGenerator'
    move function J-NUM(args, 'totalBufos') to total-bufos
    perform check-unlock
    if op = 'model.generator.unlockGenerator'
call static "j_set_boolean" using by value generator-node by reference z'unlocked' by value valid-unlock end-call
call static "j_clone_into" using by value generator-node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
else
call static "j_set_boolean" using by value response by reference z'result' by value valid-unlock end-call
end-if
when 'model.generator.calculateTotalProduction'
call static "j_get_into" using by value args by reference z'generators' generators-node end-call
perform sum-production
move total to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'generator.calculateTotalProduction' when 'generator.calculateProductionForTime'
    perform sum-production
    if op = 'generator.calculateProductionForTime'
        compute total = total * function J-NUM(args, 'seconds')
call static "j_has" using by value args by reference z'multiplier' returning flag end-call
if flag = 1 compute total = total * function J-NUM(args, 'multiplier') end-if
    end-if
move total to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'model.generator.applyBoostToGenerator' when 'generator.applyBoostToGenerator'
when 'model.generator.toggleBoost' when 'generator.toggleGeneratorBoost'
    if generator-node not = null
        perform apply-boost
        if manager-mode = 1
call static "j_clone_into" using by value generator-node by reference boost-event-node end-call
            perform global-factor
            perform recalculate
            perform store-generator
            perform production-event
call static "j_object_into" using by reference payload end-call
call static "j_clone_into" using by value boost-event-node by reference cp end-call
call static "j_set" using by value payload by reference z'generator' by value cp end-call
move boost-id to sv
call static "j_set_string" using by value payload by reference z'boostId' sv by value function length(function trim(sv trailing)) end-call
call static "j_set_boolean" using by value payload by reference z'active' by value active-flag end-call
move 'BOOST_CHANGED' to event-name
perform emit-event
call static "j_delete" using by value payload end-call
call static "j_delete" using by value boost-event-node end-call
        else
call static "j_clone_into" using by value generator-node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
end-if
    end-if
when 'generator.recalculateAllGenerators' when 'generator.reset'
    perform recalculate-all
    perform production-event
when 'generator.getAllGenerators' when 'generator.getUnlockedGenerators'
call static "j_array_into" using by reference result-node end-call
call static "j_size" using by value generators-node by reference x'00' returning generators-count end-call
perform varying gi from 0 by 1 until gi >= generators-count
call static "j_at_into" using by value generators-node gi by reference node end-call
call static "j_boolean" using by value node by reference z'unlocked' returning flag end-call
if op = 'generator.getAllGenerators' or flag = 1
call static "j_clone_into" using by value node by reference cp end-call
call static "j_append" using by value result-node cp end-call
end-if
end-perform
call static "j_set" using by value response by reference z'result' by value result-node end-call

when 'generator.checkUnlocks'
    move function J-NUM(args, 'totalBufos') to total-bufos
call static "j_array_into" using by reference result-node end-call
call static "j_size" using by value generators-node by reference x'00' returning generators-count end-call
perform varying gi from 0 by 1 until gi >= generators-count
call static "j_delete" using by value generator-node end-call
call static "j_at_into" using by value generators-node gi by reference original-node end-call
call static "j_clone_into" using by value original-node by reference generator-node end-call
move function J-STR(generator-node, 'id') to generator-id
call static "j_boolean" using by value generator-node by reference z'unlocked' returning active-flag end-call
perform check-unlock
    if valid-unlock = 1 and active-flag = 0
call static "j_set_boolean" using by value generator-node by reference z'unlocked' by value 1 end-call
perform store-generator
call static "j_clone_into" using by value generator-node by reference cp end-call
call static "j_append" using by value result-node cp end-call
call static "j_object_into" using by reference payload end-call
call static "j_clone_into" using by value generator-node by reference cp end-call
call static "j_set" using by value payload by reference z'generator' by value cp end-call
move 'GENERATOR_UNLOCKED' to event-name
perform emit-event
call static "j_delete" using by value payload end-call
end-if
end-perform
perform recalculate-all
perform production-event
call static "j_size" using by value result-node by reference x'00' returning count-items end-call
if count-items > 0
call static "j_object_into" using by reference payload end-call
call static "j_set_boolean" using by value payload by reference z'force' by value 1 end-call
move 'refreshUI' to event-name
perform emit-event
call static "j_delete" using by value payload end-call
end-if
call static "j_set" using by value response by reference z'result' by value result-node end-call

when 'generator.purchaseGenerator'
    perform purchase
when 'generator.getProductionStats'
    perform stats
when 'model.generator.createGenerator'
call static "j_object_into" using by reference generator-node end-call
perform create-generator
call static "j_clone_into" using by value generator-node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call

when other
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
move 'Unknown generator operation' to sv
call static "j_set_string" using by value response by reference z'error' sv by value function length(function trim(sv trailing)) end-call
end-evaluate
call static "j_delete" using by value generator-node end-call
goback.
global-factor.
    move function J-NUM(state-node, 'resources.productionMultiplier') to global-multiplier
    compute arithmetic-a = 1 + function max(0, function J-NUM(state-node, 'prestige.lifetimePoints')) * .1
call static "h_number_binary" using by value 3 by reference global-multiplier arithmetic-a global-multiplier end-call

call static "j_size" using by value state-node by reference z'bosses.defeated' returning count-items end-call
compute arithmetic-a = 1 + (count-items + function J-NUM(state-node, 'bosses.lifetimeDefeats')) * .25
call static "h_number_binary" using by value 3 by reference global-multiplier arithmetic-a global-multiplier end-call

call static "j_has" using by value state-node by reference z'resources.frenzyProductionMultiplier' returning flag end-call
if flag = 1
move function J-NUM(state-node, 'resources.frenzyProductionMultiplier') to arithmetic-a
call static "h_number_binary" using by value 3 by reference global-multiplier arithmetic-a global-multiplier end-call
end-if.
recalculate.
    move global-multiplier to factor
call static "j_get_into" using by value generator-node by reference z'boosts' boosts-node end-call
perform boost-factor
    if manager-mode = 0
call static "j_get_into" using by value args by reference z'additionalBoosts' boosts-node end-call
perform boost-factor end-if
    move function J-NUM(generator-node, 'baseProduction') to production
call static "h_number_binary" using by value 3 by reference production factor production end-call

call static "h_number_compare" using by reference production numeric-limit returning flag end-call
if flag > 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
exit paragraph
end-if
move production to nv
call static "j_set_number" using by value generator-node by reference z'currentProduction' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move function J-NUM(generator-node, 'count') to arithmetic-a
call static "h_number_binary" using by value 3 by reference production arithmetic-a production end-call

call static "h_number_compare" using by reference production numeric-limit returning flag end-call
if flag > 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
exit paragraph
end-if
move production to nv
call static "j_set_number" using by value generator-node by reference z'totalProduction' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move function J-NUM(generator-node, 'count') to owned
    move function J-NUM(generator-node, 'baseCost') to price
    if owned not = 0
        move function J-NUM(generator-node, 'costMultiplier') to ratio
call static "h_number_binary" using by value 5 by reference ratio owned arithmetic-a end-call
call static "h_number_binary" using by value 3 by reference price arithmetic-a price end-call
call static "h_number_unary" using by value 1 by reference price price end-call

    end-if
move price to nv
call static "j_set_number" using by value generator-node by reference z'currentCost' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
.
boost-factor.
call static "j_size" using by value boosts-node by reference x'00' returning count-items end-call
perform varying i from 0 by 1 until i >= count-items
call static "j_at_into" using by value boosts-node i by reference boost-node end-call
call static "j_boolean" using by value boost-node by reference z'active' returning flag end-call
if flag = 1
move function J-NUM(boost-node, 'multiplier') to arithmetic-a
call static "h_number_binary" using by value 3 by reference factor arithmetic-a factor end-call
end-if
end-perform.
store-generator.
call static "j_clone_into" using by value generator-node by reference cp end-call
move low-values to path-z
string function trim(generator-id) x'00' into path-z end-string
call static "j_set" using by value generators-node by reference path-z by value cp end-call
.
recalculate-all.
    perform global-factor
call static "j_size" using by value generators-node by reference x'00' returning generators-count end-call
perform varying gi from 0 by 1 until gi >= generators-count
call static "j_delete" using by value generator-node end-call
call static "j_at_into" using by value generators-node gi by reference original-node end-call
call static "j_clone_into" using by value original-node by reference generator-node end-call
move function J-STR(generator-node, 'id') to generator-id
perform recalculate
move low-values to path-z
string function trim(generator-id) x'00' into path-z end-string
call static "j_set" using by value generators-node by reference path-z by value generator-node end-call
move null to generator-node
end-perform.
sum-production.
    move 0 to total
call static "j_size" using by value generators-node by reference x'00' returning generators-count end-call
perform varying gi from 0 by 1 until gi >= generators-count
call static "j_at_into" using by value generators-node gi by reference node end-call
compute total = total + function J-NUM(node, 'totalProduction')
end-perform.
bulk-cost.
    move function J-NUM(generator-node, 'currentCost') to price
    move function J-NUM(generator-node, 'costMultiplier') to ratio
    if quantity not = 1
        if ratio = 1
call static "h_number_binary" using by value 3 by reference price quantity price end-call
else
call static "h_number_binary" using by value 5 by reference ratio quantity arithmetic-a end-call
call static "h_number_binary" using by value 2 by reference arithmetic-one arithmetic-a arithmetic-a end-call
call static "h_number_binary" using by value 3 by reference price arithmetic-a price end-call
call static "h_number_binary" using by value 2 by reference arithmetic-one ratio arithmetic-b end-call
call static "h_number_binary" using by value 4 by reference price arithmetic-b price end-call
end-if
call static "h_number_unary" using by value 1 by reference price price end-call
end-if.
max-affordable.
    move 0 to affordable
    move function J-NUM(generator-node, 'currentCost') to price
    move function J-NUM(generator-node, 'costMultiplier') to ratio
    if price > 0 and (budget - price) >= 0
        if ratio = 1 compute affordable = function integer(budget / price)
        else
            if ratio > 1
                call static "h_number_binary" using by value 2 by reference ratio arithmetic-one arithmetic-a end-call
call static "h_number_binary" using by value 3 by reference budget arithmetic-a arithmetic-a end-call
call static "h_number_binary" using by value 4 by reference arithmetic-a price arithmetic-a end-call
call static "h_number_binary" using by value 1 by reference arithmetic-a arithmetic-one arithmetic-a end-call
call static "h_number_unary" using by value 3 by reference arithmetic-a arithmetic-a end-call
call static "h_number_unary" using by value 3 by reference ratio arithmetic-b end-call
call static "h_number_binary" using by value 4 by reference arithmetic-a arithmetic-b affordable end-call
call static "h_number_unary" using by value 2 by reference affordable affordable end-call

                move affordable to quantity
                perform bulk-cost
                perform until (price - budget) <= 0 or affordable <= 0
                    subtract 1 from affordable
                    move affordable to quantity
                    perform bulk-cost
                end-perform
                compute quantity = affordable + 1
                perform bulk-cost
                perform until (price - budget) > 0
                    add 1 to affordable
                    compute quantity = affordable + 1
                    perform bulk-cost
                end-perform
            end-if
        end-if
    end-if.
check-unlock.
    move 1 to valid-unlock
call static "j_boolean" using by value generator-node by reference z'unlocked' returning flag end-call
if flag = 1 exit paragraph end-if
call static "j_get_into" using by value generator-node by reference z'unlockRequirements' requirements-node end-call
call static "j_size" using by value requirements-node by reference x'00' returning requirements-count end-call
perform varying ri from 0 by 1 until ri >= requirements-count
call static "j_at_into" using by value requirements-node ri by reference requirement-node end-call
move function J-STR(requirement-node, 'type') to requirement-type
move function J-STR(requirement-node, 'target') to target-id
move function J-NUM(requirement-node, 'value') to n
evaluate requirement-type
when 'bufos' if (total-bufos - n) < 0 move 0 to valid-unlock end-if
when 'generators'
    if target-id not = spaces
        if manager-mode = 1
move low-values to path-z
string function trim(target-id) x'00' into path-z end-string
call static "j_get_into" using by value generators-node by reference path-z node end-call
move function J-NUM(node, 'count') to m
        else
call static "j_get_into" using by value args by reference z'ownedGenerators' node end-call
move low-values to path-z
string function trim(target-id) x'00' into path-z end-string
call static "j_get_into" using by value node by reference path-z node2 end-call
move function J-NUM(node2, '') to m
        end-if
        if (m - n) < 0 move 0 to valid-unlock end-if
    end-if
when 'achievement' when 'special'
    if target-id not = spaces
        if manager-mode = 1 move 0 to valid-unlock
        else
            if requirement-type = 'achievement'
call static "j_get_into" using by value args by reference z'unlockedAchievements' node end-call
else
call static "j_get_into" using by value args by reference z'specialConditions' node end-call
end-if
move low-values to path-z
string function trim(target-id) x'00' into path-z end-string
call static "j_get_into" using by value node by reference path-z node2 end-call
call static "j_boolean" using by value node2 by reference x'00' returning flag end-call
if flag = 0 move 0 to valid-unlock end-if
        end-if
    end-if
end-evaluate
end-perform.
apply-boost.
    move function J-STR(args, 'boostId') to boost-id
call static "j_get_into" using by value generator-node by reference z'boosts' boosts-node end-call
call static "j_size" using by value boosts-node by reference x'00' returning count-items end-call
move 0 to found
    perform varying i from 0 by 1 until i >= count-items
call static "j_at_into" using by value boosts-node i by reference boost-node end-call
if function J-STR(boost-node, 'id') = boost-id
        move 1 to found
        perform write-boost
    end-if
    end-perform
    if found = 0 and op not = 'model.generator.toggleBoost' and op not = 'generator.toggleGeneratorBoost'
call static "j_object_into" using by reference boost-node end-call
move boost-id to sv
call static "j_set_string" using by value boost-node by reference z'id' sv by value function length(function trim(sv trailing)) end-call
move function J-STR(args, 'source') to sv
call static "j_set_string" using by value boost-node by reference z'source' sv by value function length(function trim(sv trailing)) end-call
perform write-boost
call static "j_append" using by value boosts-node boost-node end-call
end-if.
write-boost.
call static "j_has" using by value args by reference z'active' returning flag end-call
move 1 to active-flag
if flag = 1
call static "j_boolean" using by value args by reference z'active' returning active-flag end-call
end-if
call static "j_set_boolean" using by value boost-node by reference z'active' by value active-flag end-call
if op not = 'model.generator.toggleBoost' and op not = 'generator.toggleGeneratorBoost'
    move function J-NUM(args, 'multiplier') to n
move n to nv
call static "j_set_number" using by value boost-node by reference z'multiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
end-if.
production-event.
    perform sum-production
call static "j_object_into" using by reference payload end-call
move total to nv
call static "j_set_number" using by value payload by reference z'totalProduction' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 'GENERATOR_PRODUCTION_UPDATED' to event-name
perform emit-event
call static "j_delete" using by value payload end-call
call static "j_object_into" using by reference input-args end-call
move 'production' to sv
call static "j_set_string" using by value input-args by reference z'category' sv by value function length(function trim(sv trailing)) end-call
call static "j_object_into" using by reference rq end-call
move 'achievement.checkAchievementCategory' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value input-args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-ACHIEVEMENTS" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_delete" using by value rs end-call
call static "j_delete" using by value input-args end-call
.
purchase.
call static "j_object_into" using by reference result-node end-call
call static "j_set_boolean" using by value result-node by reference z'success' by value 0 end-call
move 0 to nv
call static "j_set_number" using by value result-node by reference z'cost' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 0 to nv
call static "j_set_number" using by value result-node by reference z'productionIncrease' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
if generator-node not = null
call static "j_clone_into" using by value generator-node by reference cp end-call
call static "j_set" using by value result-node by reference z'generator' by value cp end-call
end-if
call static "j_set" using by value response by reference z'result' by value result-node end-call
call static "j_boolean" using by value generator-node by reference z'enabled' returning flag end-call
if flag = 0 exit paragraph end-if
call static "j_boolean" using by value generator-node by reference z'unlocked' returning flag end-call
if flag = 0 exit paragraph end-if
move function J-NUM(args, 'quantity') to quantity
move function J-NUM(args, 'availableBufos') to budget
if quantity = -1 perform max-affordable move affordable to quantity end-if
if quantity <= 0 or quantity not = function integer(quantity) exit paragraph end-if
perform bulk-cost
if ratio = 1 and quantity not = 1 exit paragraph end-if
if (budget - price) < 0 exit paragraph end-if
move price to nv
call static "j_set_number" using by value result-node by reference z'cost' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_set_boolean" using by value result-node by reference z'success' by value 1 end-call
move function J-NUM(generator-node, 'totalProduction') to old-production
compute owned = function J-NUM(generator-node, 'count') + quantity
move owned to nv
call static "j_set_number" using by value generator-node by reference z'count' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
perform global-factor
perform recalculate
perform store-generator
compute n = function J-NUM(generator-node, 'totalProduction') - old-production
move n to nv
call static "j_set_number" using by value result-node by reference z'productionIncrease' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_clone_into" using by value generator-node by reference cp end-call
call static "j_set" using by value result-node by reference z'generator' by value cp end-call
call static "j_object_into" using by reference payload end-call
call static "j_clone_into" using by value generator-node by reference cp end-call
call static "j_set" using by value payload by reference z'generator' by value cp end-call
move quantity to nv
call static "j_set_number" using by value payload by reference z'quantity' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move function J-NUM(result-node, 'cost') to n
move n to nv
call static "j_set_number" using by value payload by reference z'cost' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 'GENERATOR_PURCHASED' to event-name
perform emit-event
call static "j_object_into" using by reference input-args end-call
move 'generators' to sv
call static "j_set_string" using by value input-args by reference z'category' sv by value function length(function trim(sv trailing)) end-call
call static "j_object_into" using by reference rq end-call
move 'achievement.checkAchievementCategory' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value input-args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-ACHIEVEMENTS" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_delete" using by value rs end-call
call static "j_delete" using by value input-args end-call
call static "j_delete" using by value payload end-call
perform production-event.
stats.
    perform sum-production
call static "j_object_into" using by reference result-node end-call
move total to nv
call static "j_set_number" using by value result-node by reference z'totalPerSecond' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
compute n = total * 60
move n to nv
call static "j_set_number" using by value result-node by reference z'totalPerMinute' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
compute n = total * 3600
move n to nv
call static "j_set_number" using by value result-node by reference z'totalPerHour' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move function J-NUM(state-node, 'resources.productionMultiplier') to n
move n to nv
call static "j_set_number" using by value result-node by reference z'activeBonusMultiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_array_into" using by reference new-list end-call
perform varying gi from 0 by 1 until gi >= generators-count
call static "j_at_into" using by value generators-node gi by reference node end-call
move function J-NUM(node, 'totalProduction') to n
if n > 0 and function J-NUM(node, 'count') > 0
call static "j_object_into" using by reference item end-call
move function J-STR(node, 'id') to sv
call static "j_set_string" using by value item by reference z'id' sv by value function length(function trim(sv trailing)) end-call
move function J-STR(node, 'name') to sv
call static "j_set_string" using by value item by reference z'name' sv by value function length(function trim(sv trailing)) end-call
move n to nv
call static "j_set_number" using by value item by reference z'production' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
compute n = n / total * 100
move n to nv
call static "j_set_number" using by value item by reference z'percentage' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move function J-NUM(node, 'count') to n
move n to nv
call static "j_set_number" using by value item by reference z'count' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_append" using by value new-list item end-call
end-if
end-perform
call static "j_set" using by value result-node by reference z'generatorContributions' by value new-list end-call
call static "j_set" using by value response by reference z'result' by value result-node end-call
.
create-generator.
call static "j_has" using by value args by reference z'id' returning flag end-call
if flag = 1
move function J-STR(args, 'id') to sv
call static "j_set_string" using by value generator-node by reference z'id' sv by value function length(function trim(sv trailing)) end-call
end-if
call static "j_has" using by value args by reference z'name' returning flag end-call
if flag = 1
move function J-STR(args, 'name') to sv
call static "j_set_string" using by value generator-node by reference z'name' sv by value function length(function trim(sv trailing)) end-call
end-if
call static "j_has" using by value args by reference z'description' returning flag end-call
if flag = 1
move function J-STR(args, 'description') to sv
call static "j_set_string" using by value generator-node by reference z'description' sv by value function length(function trim(sv trailing)) end-call
end-if
call static "j_has" using by value args by reference z'iconPath' returning flag end-call
if flag = 1
move function J-STR(args, 'iconPath') to sv
call static "j_set_string" using by value generator-node by reference z'iconPath' sv by value function length(function trim(sv trailing)) end-call
end-if
call static "j_has" using by value args by reference z'detailedDescription' returning flag end-call
if flag = 1
move function J-STR(args, 'detailedDescription') to sv
call static "j_set_string" using by value generator-node by reference z'detailedDescription' sv by value function length(function trim(sv trailing)) end-call
end-if
call static "j_has" using by value args by reference z'category' returning flag end-call
if flag = 1
move function J-STR(args, 'category') to sv
call static "j_set_string" using by value generator-node by reference z'category' sv by value function length(function trim(sv trailing)) end-call
end-if
call static "j_has" using by value args by reference z'category' returning flag end-call
if flag = 0
move 'basic' to sv
call static "j_set_string" using by value generator-node by reference z'category' sv by value function length(function trim(sv trailing)) end-call
end-if
move function J-NUM(args, 'baseProduction') to n
move n to nv
call static "j_set_number" using by value generator-node by reference z'baseProduction' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move function J-NUM(args, 'baseCost') to n
move n to nv
call static "j_set_number" using by value generator-node by reference z'baseCost' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move function J-NUM(args, 'costMultiplier') to n
move n to nv
call static "j_set_number" using by value generator-node by reference z'costMultiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move function J-NUM(args, 'baseProduction') to n
move n to nv
call static "j_set_number" using by value generator-node by reference z'currentProduction' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move function J-NUM(args, 'baseCost') to n
move n to nv
call static "j_set_number" using by value generator-node by reference z'currentCost' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 0 to nv
call static "j_set_number" using by value generator-node by reference z'count' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 0 to nv
call static "j_set_number" using by value generator-node by reference z'totalProduction' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_set_boolean" using by value generator-node by reference z'enabled' by value 1 end-call
call static "j_array_into" using by reference cp end-call
call static "j_set" using by value generator-node by reference z'boosts' by value cp end-call
call static "j_get_into" using by value args by reference z'unlockRequirements' node end-call
if node = null
call static "j_array_into" using by reference node end-call
call static "j_object_into" using by reference item end-call
move 'bufos' to sv
call static "j_set_string" using by value item by reference z'type' sv by value function length(function trim(sv trailing)) end-call
move 0 to nv
call static "j_set_number" using by value item by reference z'value' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_append" using by value node item end-call
call static "j_set" using by value generator-node by reference z'unlockRequirements' by value node end-call
else
call static "j_clone_into" using by value node by reference cp end-call
call static "j_set" using by value generator-node by reference z'unlockRequirements' by value cp end-call
end-if
call static "j_size" using by value node by reference x'00' returning count-items end-call
call static "j_at_into" using by value node 0 by reference item end-call
move 0 to flag
if count-items = 1 and function J-STR(item, 'type') = 'bufos' and function J-NUM(item, 'value') = 0 move 1 to flag end-if
call static "j_set_boolean" using by value generator-node by reference z'unlocked' by value flag end-call
.
emit-event.
call static "j_object_into" using by reference ev end-call
move event-name to sv
call static "j_set_string" using by value ev by reference z'name' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value payload by reference cp end-call
call static "j_set" using by value ev by reference z'payload' by value cp end-call
call static "j_get_into" using by value context by reference z'events' events-node end-call
call static "j_append" using by value events-node ev end-call
.
array-contains.
    move 0 to found
call static "j_size" using by value list-node by reference x'00' returning count2 end-call
perform varying j from 0 by 1 until j >= count2
call static "j_at_into" using by value list-node j by reference node3 end-call
if function J-STR(node3, '') = text-value
    move 1 to found
end-if
end-perform.
end program BUFO-GENERATORS.
