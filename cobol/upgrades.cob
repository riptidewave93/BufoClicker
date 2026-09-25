identification division.
program-id. BUFO-UPGRADES recursive.
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
01 upgrades-node usage pointer.
01 upgrade-node usage pointer.
01 effects-node usage pointer.
01 effect-node usage pointer.
01 conditions-node usage pointer.
01 condition-node usage pointer.
01 purchased-node usage pointer.
01 new-list usage pointer.
01 counts-node usage pointer.
01 achievement-map usage pointer.
01 check-state usage pointer.
01 input-args usage pointer.
01 ui usage binary-long.
01 ei usage binary-long.
01 ci usage binary-long.
01 uc usage binary-long.
01 effect-count usage binary-long.
01 cc usage binary-long.
01 valid-unlock usage binary-long.
01 manager-mode usage binary-long.
01 upgrade-id pic x(256).
01 target-id pic x(256).
01 effect-type pic x(64).
01 effect-value usage comp-2.
01 cost usage comp-2.
linkage section.
01 request usage pointer.
01 context usage pointer.
01 response usage pointer.
procedure division using by value request context response.
call static "j_get_into" using by value request by reference z'args' args end-call
call static "j_get_into" using by value context by reference z'state' state-node end-call
move function J-STR(request, 'operation') to op
call static "j_set_boolean" using by value response by reference z'ok' by value 1 end-call
call static "j_get_into" using by value context by reference z'catalog.upgrades' upgrades-node end-call
call static "j_get_into" using by value context by reference z'runtime.upgrades' node end-call
if node not = null set upgrades-node to node end-if
move function J-STR(args, 'upgradeId') to upgrade-id
if upgrade-id = spaces move function J-STR(args, 'id') to upgrade-id end-if
move 1 to manager-mode
set check-state to state-node
call static "j_get_into" using by value state-node by reference z'upgrades.purchased' purchased-node end-call
if op(1:14) = 'model.upgrade.'
    move 0 to manager-mode
call static "j_get_into" using by value args by reference z'upgrade' upgrade-node end-call
else perform find-upgrade end-if
evaluate op
when 'model.upgrade.initializeUpgrades'
call static "j_get_into" using by value context by reference z'catalog.upgrades' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
when 'model.upgrade.findUpgradeById'
call static "j_get_into" using by value args by reference z'upgrades' upgrades-node end-call
perform find-upgrade
    if upgrade-node not = null
call static "j_clone_into" using by value upgrade-node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
end-if
when 'upgrade.findUpgradeById'
    if upgrade-node not = null
call static "j_clone_into" using by value upgrade-node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
end-if
when 'model.upgrade.meetsUnlockConditions'
    perform check-conditions
call static "j_set_boolean" using by value response by reference z'result' by value valid-unlock end-call

when 'upgrade.checkAvailableUpgrades'
call static "j_get_into" using by value args by reference z'state' check-state end-call
if check-state = null set check-state to state-node end-if
call static "j_array_into" using by reference result-node end-call
call static "j_array_into" using by reference new-list end-call
call static "j_size" using by value upgrades-node by reference x'00' returning uc end-call
perform varying ui from 0 by 1 until ui >= uc
call static "j_at_into" using by value upgrades-node ui by reference upgrade-node end-call
move function J-STR(upgrade-node, 'id') to text-value
set list-node to purchased-node
perform array-contains
if found = 0
    perform check-conditions
    if valid-unlock = 1
call static "j_clone_into" using by value upgrade-node by reference cp end-call
call static "j_append" using by value result-node cp end-call
call static "j_get_into" using by value upgrade-node by reference z'id' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_append" using by value new-list cp end-call
end-if
end-if
end-perform
call static "j_set" using by value state-node by reference z'upgrades.available' by value new-list end-call
call static "j_size" using by value result-node by reference x'00' returning uc end-call
if uc > 0
call static "j_object_into" using by reference payload end-call
call static "j_clone_into" using by value result-node by reference cp end-call
call static "j_set" using by value payload by reference z'upgrades' by value cp end-call
move 'UPGRADES_AVAILABLE' to event-name
perform emit-event
call static "j_delete" using by value payload end-call
end-if
call static "j_set" using by value response by reference z'result' by value result-node end-call

when 'upgrade.purchaseUpgrade'
    perform purchase
when 'upgrade.applyUpgradeEffects'
call static "j_get_into" using by value args by reference z'upgrade' upgrade-node end-call
perform apply-effects
call static "j_set_boolean" using by value response by reference z'result' by value 1 end-call

when 'upgrade.initialize' when 'upgrade.reapplyAllUpgrades'
    if op = 'upgrade.reapplyAllUpgrades'
move 1 to nv
call static "j_set_number" using by value state-node by reference z'resources.productionMultiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_get_into" using by value state-node by reference z'generators' node end-call
call static "j_size" using by value node by reference x'00' returning cc end-call
perform varying ci from 0 by 1 until ci >= cc
call static "j_at_into" using by value node ci by reference node2 end-call
call static "j_array_into" using by reference cp end-call
call static "j_set" using by value node2 by reference z'boosts' by value cp end-call
end-perform
    end-if
call static "j_size" using by value purchased-node by reference x'00' returning uc end-call
perform varying ui from 0 by 1 until ui >= uc
call static "j_at_into" using by value purchased-node ui by reference node end-call
move function J-STR(node, '') to upgrade-id
perform find-upgrade
if upgrade-node not = null perform apply-effects end-if
end-perform
when 'model.upgrade.calculateUpgradeEffectForGenerator'
    move 1 to factor
    perform reduce-effects
move factor to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'model.upgrade.calculateClickMultiplier' when 'model.upgrade.calculateGlobalMultiplier'
call static "j_get_into" using by value args by reference z'upgrades' upgrades-node end-call
move 1 to factor
call static "j_size" using by value upgrades-node by reference x'00' returning uc end-call
perform varying ui from 0 by 1 until ui >= uc
call static "j_at_into" using by value upgrades-node ui by reference upgrade-node end-call
perform reduce-effects
end-perform
move factor to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'upgrade.calculateTotalClickMultiplier' when 'upgrade.calculateTotalMultiplierForGenerator'
    move 1 to factor
call static "j_size" using by value purchased-node by reference x'00' returning uc end-call
perform varying ui from 0 by 1 until ui >= uc
call static "j_at_into" using by value purchased-node ui by reference node end-call
move function J-STR(node, '') to upgrade-id
perform find-upgrade
if upgrade-node not = null perform reduce-effects end-if
end-perform
move factor to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'upgrade.getUpgradeEffects'
    if upgrade-node = null
call static "j_parse_into" using by reference z'null' by value 4 by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
else perform effect-types
call static "j_set" using by value response by reference z'result' by value new-list end-call
end-if
when 'upgrade.getPurchasedUpgrades'
call static "j_clone_into" using by value purchased-node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call

when 'upgrade.isUpgradePurchased'
    set list-node to purchased-node
    move upgrade-id to text-value
    perform array-contains
call static "j_set_boolean" using by value response by reference z'result' by value found end-call

when 'upgrade.getAllUpgrades'
call static "j_clone_into" using by value upgrades-node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call

when 'upgrade.getAvailableUpgrades'
call static "j_array_into" using by reference result-node end-call
call static "j_get_into" using by value state-node by reference z'upgrades.available' list-node end-call
call static "j_size" using by value upgrades-node by reference x'00' returning uc end-call
perform varying ui from 0 by 1 until ui >= uc
call static "j_at_into" using by value upgrades-node ui by reference upgrade-node end-call
move function J-STR(upgrade-node, 'id') to text-value
perform array-contains
if found = 1
call static "j_clone_into" using by value upgrade-node by reference cp end-call
call static "j_append" using by value result-node cp end-call
end-if
end-perform
call static "j_set" using by value response by reference z'result' by value result-node end-call

when 'upgrade.setUpgrades'
call static "j_get_into" using by value args by reference z'upgrades' node end-call
call static "j_size" using by value node by reference x'00' returning uc end-call
if uc > 0
call static "j_clone_into" using by value node by reference cp end-call
call static "j_set" using by value context by reference z'runtime.upgrades' by value cp end-call
end-if
when 'upgrade.reset' continue
when other
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
move 'Unknown upgrade operation' to sv
call static "j_set_string" using by value response by reference z'error' sv by value function length(function trim(sv trailing)) end-call
end-evaluate
goback.
find-upgrade.
    set upgrade-node to null
call static "j_size" using by value upgrades-node by reference x'00' returning count-items end-call
perform varying i from 0 by 1 until i >= count-items
call static "j_at_into" using by value upgrades-node i by reference item end-call
if function J-STR(item, 'id') = upgrade-id set upgrade-node to item end-if
end-perform.
check-conditions.
    move 1 to valid-unlock
call static "j_get_into" using by value upgrade-node by reference z'unlockConditions' conditions-node end-call
call static "j_size" using by value conditions-node by reference x'00' returning cc end-call
perform varying ci from 0 by 1 until ci >= cc
call static "j_at_into" using by value conditions-node ci by reference condition-node end-call
move function J-STR(condition-node, 'target') to target-id
if target-id = spaces move function J-STR(condition-node, 'id') to target-id end-if
move function J-NUM(condition-node, 'value') to n
evaluate function lower-case(function trim(function J-STR(condition-node, 'type')))
when 'totalbufos'
    if manager-mode = 1 move function J-NUM(check-state, 'resources.totalBufos') to m
    else move function J-NUM(args, 'totalBufos') to m end-if
    if (m - n) < 0 move 0 to valid-unlock end-if
when 'generatorcount'
    if target-id = spaces move 0 to valid-unlock
    else
call static "j_get_into" using by value args by reference z'generatorCounts' counts-node end-call
if counts-node not = null
move low-values to path-z
string function trim(target-id) x'00' into path-z end-string
call static "j_get_into" using by value counts-node by reference path-z node end-call
move function J-NUM(node, '') to m
    else
call static "j_get_into" using by value check-state by reference z'generators' node end-call
move low-values to path-z
string function trim(target-id) x'00' into path-z end-string
call static "j_get_into" using by value node by reference path-z node2 end-call
move function J-NUM(node2, 'count') to m
    end-if
    if (m - n) < 0 move 0 to valid-unlock end-if
    end-if
when 'achievements'
    if target-id = spaces move 0 to valid-unlock
    else
        if manager-mode = 1
call static "j_get_into" using by value check-state by reference z'achievements.unlocked' list-node end-call
move target-id to text-value
perform array-contains
if found = 0 move 0 to valid-unlock end-if
        else
call static "j_get_into" using by value args by reference z'achievements' achievement-map end-call
move low-values to path-z
string function trim(target-id) x'00' into path-z end-string
call static "j_get_into" using by value achievement-map by reference path-z node end-call
call static "j_boolean" using by value node by reference x'00' returning flag end-call
if flag = 0 move 0 to valid-unlock end-if
        end-if
    end-if
when 'upgrade'
    if manager-mode = 1 set list-node to purchased-node
    else
call static "j_get_into" using by value args by reference z'purchasedUpgrades' list-node end-call
end-if
    move target-id to text-value
    perform array-contains
    if target-id = spaces or found = 0 move 0 to valid-unlock end-if
when other move 0 to valid-unlock
end-evaluate
end-perform.
reduce-effects.
call static "j_get_into" using by value upgrade-node by reference z'effects' effects-node end-call
call static "j_size" using by value effects-node by reference x'00' returning effect-count end-call
perform varying ei from 0 by 1 until ei >= effect-count
call static "j_at_into" using by value effects-node ei by reference effect-node end-call
move function J-STR(effect-node, 'type') to effect-type
move function J-NUM(effect-node, 'multiplier') to effect-value
evaluate op
when 'model.upgrade.calculateClickMultiplier' when 'upgrade.calculateTotalClickMultiplier'
    if effect-type = 'clickMultiplier' compute factor = factor * effect-value end-if
when 'model.upgrade.calculateGlobalMultiplier'
    if effect-type = 'globalMultiplier' compute factor = factor * effect-value end-if
when other
    if effect-type = 'globalMultiplier' or
        (effect-type = 'generatorProduction' and function J-STR(effect-node, 'target') = function J-STR(args, 'generatorType'))
        compute factor = factor * effect-value
    end-if
end-evaluate
end-perform.
apply-effects.
call static "j_get_into" using by value upgrade-node by reference z'effects' effects-node end-call
call static "j_size" using by value effects-node by reference x'00' returning effect-count end-call
perform varying ei from 0 by 1 until ei >= effect-count
call static "j_at_into" using by value effects-node ei by reference effect-node end-call
move function J-NUM(effect-node, 'multiplier') to effect-value
evaluate function J-STR(effect-node, 'type')
when 'clickMultiplier'
    compute n = function J-NUM(state-node, 'resources.clickMultiplier') * effect-value
move n to nv
call static "j_set_number" using by value state-node by reference z'resources.clickMultiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'globalMultiplier'
    compute n = function J-NUM(state-node, 'resources.productionMultiplier') * effect-value
move n to nv
call static "j_set_number" using by value state-node by reference z'resources.productionMultiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'generatorProduction'
call static "j_object_into" using by reference input-args end-call
move function J-STR(effect-node, 'target') to sv
call static "j_set_string" using by value input-args by reference z'generatorType' sv by value function length(function trim(sv trailing)) end-call
move spaces to text-value
string 'upgrade_' function trim(function J-STR(upgrade-node, 'id')) into text-value end-string
move text-value to sv
call static "j_set_string" using by value input-args by reference z'boostId' sv by value function length(function trim(sv trailing)) end-call
move function J-STR(upgrade-node, 'name') to sv
call static "j_set_string" using by value input-args by reference z'source' sv by value function length(function trim(sv trailing)) end-call
move effect-value to nv
call static "j_set_number" using by value input-args by reference z'multiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_object_into" using by reference rq end-call
move 'generator.applyBoostToGenerator' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value input-args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-GENERATORS" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_delete" using by value rs end-call
call static "j_delete" using by value input-args end-call

end-evaluate
end-perform
call static "j_object_into" using by reference rq end-call
move 'recalculate' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-GAME" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_delete" using by value rs end-call
call static "j_object_into" using by reference rq end-call
move 'generator.calculateTotalProduction' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-GENERATORS" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
move function J-NUM(rs, 'result') to n
call static "j_delete" using by value rs end-call
call static "j_object_into" using by reference payload end-call
move n to nv
call static "j_set_number" using by value payload by reference z'totalProduction' nv end-call
move 'upgrade' to sv
call static "j_set_string" using by value payload by reference z'source' sv by value function length(function trim(sv trailing)) end-call
move function J-STR(upgrade-node, 'id') to sv
call static "j_set_string" using by value payload by reference z'upgradeId' sv by value function length(function trim(sv trailing)) end-call
move 'GENERATOR_PRODUCTION_UPDATED' to event-name
perform emit-event
call static "j_delete" using by value payload end-call
.
effect-types.
call static "j_array_into" using by reference new-list end-call
call static "j_get_into" using by value upgrade-node by reference z'effects' effects-node end-call
call static "j_size" using by value effects-node by reference x'00' returning effect-count end-call
perform varying ei from 0 by 1 until ei >= effect-count
call static "j_at_into" using by value effects-node ei by reference effect-node end-call
call static "j_get_into" using by value effect-node by reference z'type' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_append" using by value new-list cp end-call
end-perform.
purchase.
call static "j_object_into" using by reference result-node end-call
call static "j_set_boolean" using by value result-node by reference z'success' by value 0 end-call
move 0 to nv
call static "j_set_number" using by value result-node by reference z'cost' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_set" using by value response by reference z'result' by value result-node end-call
if upgrade-node = null exit paragraph end-if
move function J-NUM(upgrade-node, 'cost') to cost
move cost to nv
call static "j_set_number" using by value result-node by reference z'cost' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move upgrade-id to text-value
set list-node to purchased-node
perform array-contains
if found = 1 or (function J-NUM(args, 'currentBufos') - cost) < 0 exit paragraph end-if
call static "j_get_into" using by value upgrade-node by reference z'id' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_append" using by value purchased-node cp end-call
call static "j_array_into" using by reference new-list end-call
call static "j_get_into" using by value state-node by reference z'upgrades.available' list-node end-call
call static "j_size" using by value list-node by reference x'00' returning count-items end-call
perform varying i from 0 by 1 until i >= count-items
call static "j_at_into" using by value list-node i by reference node end-call
if function J-STR(node, '') not = upgrade-id
call static "j_clone_into" using by value node by reference cp end-call
call static "j_append" using by value new-list cp end-call
end-if
end-perform
call static "j_set" using by value state-node by reference z'upgrades.available' by value new-list end-call
perform apply-effects
perform effect-types
call static "j_set" using by value result-node by reference z'effects' by value new-list end-call
call static "j_clone_into" using by value upgrade-node by reference cp end-call
call static "j_set" using by value result-node by reference z'upgrade' by value cp end-call
call static "j_set_boolean" using by value result-node by reference z'success' by value 1 end-call
call static "j_object_into" using by reference payload end-call
call static "j_clone_into" using by value upgrade-node by reference cp end-call
call static "j_set" using by value payload by reference z'upgrade' by value cp end-call
move cost to nv
call static "j_set_number" using by value payload by reference z'cost' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_clone_into" using by value new-list by reference cp end-call
call static "j_set" using by value payload by reference z'effects' by value cp end-call
move 'UPGRADE_PURCHASED' to event-name
perform emit-event
call static "j_object_into" using by reference input-args end-call
move 'special' to sv
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
end program BUFO-UPGRADES.
