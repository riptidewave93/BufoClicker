identification division.
program-id. BUFO-ACHIEVEMENTS recursive.
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
01 achievements-node usage pointer.
01 achievement-node usage pointer.
01 unlocked-node usage pointer.
01 reward-node usage pointer.
01 requirement-node usage pointer.
01 check-data usage pointer.
01 input-args usage pointer.
01 new-list usage pointer.
01 ai usage binary-long.
01 ac usage binary-long.
01 manager-mode usage binary-long.
01 is-met usage binary-long.
01 silent-mode usage binary-long.
01 permanent-only usage binary-long.
01 did-unlock usage binary-long.
01 achievement-id pic x(256).
01 category-name pic x(64).
01 target-id pic x(256).
01 field-name pic x(64).
linkage section.
01 request usage pointer.
01 context usage pointer.
01 response usage pointer.
procedure division using by value request context response.
call static "j_get_into" using by value request by reference z'args' args end-call
call static "j_get_into" using by value context by reference z'state' state-node end-call
move function J-STR(request, 'operation') to op
call static "j_set_boolean" using by value response by reference z'ok' by value 1 end-call
call static "j_get_into" using by value context by reference z'catalog.achievements' achievements-node end-call
call static "j_get_into" using by value state-node by reference z'achievements.unlocked' unlocked-node end-call
move function J-STR(args, 'achievementId') to achievement-id
if achievement-id = spaces move function J-STR(args, 'id') to achievement-id end-if
move 0 to silent-mode permanent-only
move 1 to manager-mode
if op(1:18) = 'model.achievement.'
    move 0 to manager-mode
call static "j_get_into" using by value args by reference z'achievement' achievement-node end-call
else perform find-achievement end-if
evaluate op
when 'model.achievement.initializeAchievements'
call static "j_get_into" using by value context by reference z'catalog.achievements' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
when 'model.achievement.checkAchievementRequirement'
call static "j_get_into" using by value args by reference z'gameState' check-data end-call
perform requirement-met
call static "j_set_boolean" using by value response by reference z'result' by value is-met end-call

when 'model.achievement.getCategoryIcon'
    move function J-STR(args, 'category') to category-name
    perform category-icon
move text-value to sv
call static "j_set_string" using by value response by reference z'result' sv by value function length(function trim(sv trailing)) end-call

when 'model.achievement.getAchievementIcon'
    move function J-STR(achievement-node, 'iconPath') to text-value
    if text-value = spaces
        move function J-STR(achievement-node, 'category') to category-name
        perform category-icon
    end-if
move text-value to sv
call static "j_set_string" using by value response by reference z'result' sv by value function length(function trim(sv trailing)) end-call

when 'achievement.unlockAchievement' when 'achievement.silentUnlockAchievement'
    if op = 'achievement.silentUnlockAchievement' move 1 to silent-mode end-if
    perform unlock-achievement
call static "j_set_boolean" using by value response by reference z'result' by value did-unlock end-call

when 'achievement.restoreUnlockedAchievements'
call static "j_get_into" using by value args by reference z'achievementIds' new-list end-call
call static "j_size" using by value new-list by reference x'00' returning ac end-call
perform varying ai from 0 by 1 until ai >= ac
call static "j_at_into" using by value new-list ai by reference node end-call
move function J-STR(node, '') to achievement-id
perform find-achievement
if achievement-node not = null
    move achievement-id to text-value
    set list-node to unlocked-node
    perform array-contains
    if found = 0
call static "j_get_into" using by value achievement-node by reference z'id' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_append" using by value unlocked-node cp end-call
end-if
end-if
end-perform
perform reapply-rewards
when 'achievement.reapplyAllAchievementRewards'
    perform reapply-rewards
when 'achievement.checkAllAchievements'
    perform check-all
when 'achievement.checkAchievementCategory'
call static "j_size" using by value achievements-node by reference x'00' returning ac end-call
move 0 to flag
perform varying ai from 0 by 1 until ai >= ac
call static "j_at_into" using by value achievements-node ai by reference achievement-node end-call
if function J-STR(achievement-node, 'category') = function J-STR(args, 'category')
    set list-node to unlocked-node
    move function J-STR(achievement-node, 'id') to text-value
    perform array-contains
    if found = 0 move 1 to flag end-if
end-if
end-perform
if flag = 1 perform check-all end-if
when 'achievement.initialize'
call static "j_boolean" using by value args by reference z'silentLoad' returning flag end-call
if flag = 0 perform check-all end-if
when 'achievement.getAllAchievements'
call static "j_clone_into" using by value achievements-node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call

when 'achievement.getUnlockedAchievements' when 'achievement.getVisibleLockedAchievements'
call static "j_array_into" using by reference result-node end-call
call static "j_size" using by value achievements-node by reference x'00' returning ac end-call
perform varying ai from 0 by 1 until ai >= ac
call static "j_at_into" using by value achievements-node ai by reference achievement-node end-call
move function J-STR(achievement-node, 'id') to text-value
set list-node to unlocked-node
perform array-contains
call static "j_boolean" using by value achievement-node by reference z'secret' returning flag end-call
if (op = 'achievement.getUnlockedAchievements' and found = 1) or
   (op = 'achievement.getVisibleLockedAchievements' and found = 0 and flag = 0)
call static "j_clone_into" using by value achievement-node by reference cp end-call
call static "j_append" using by value result-node cp end-call
end-if
end-perform
call static "j_set" using by value response by reference z'result' by value result-node end-call

when 'achievement.getAchievementDetails'
    if achievement-node not = null
call static "j_clone_into" using by value achievement-node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
end-if
when 'achievement.getAchievementProgress'
call static "j_get_into" using by value state-node by reference z'achievements.progress' node end-call
move low-values to path-z
string function trim(achievement-id) x'00' into path-z end-string
call static "j_get_into" using by value node by reference path-z node2 end-call
move function J-NUM(node2, '') to n
move n to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'achievement.isAchievementUnlocked'
    move achievement-id to text-value
    set list-node to unlocked-node
    perform array-contains
call static "j_set_boolean" using by value response by reference z'result' by value found end-call

when 'achievement.getTotalAchievementCount'
call static "j_size" using by value achievements-node by reference x'00' returning ac end-call
move ac to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'achievement.getUnlockedCount'
call static "j_size" using by value unlocked-node by reference x'00' returning ac end-call
move ac to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'achievement.getClickCount'
    move function J-NUM(state-node, 'achievements.clickCount') to n
move n to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'achievement.setClickCount'
    move function J-NUM(args, 'count') to n
move n to nv
call static "j_set_number" using by value state-node by reference z'achievements.clickCount' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
perform check-all
when 'achievement.setCustomEvents'
call static "j_get_into" using by value args by reference z'events' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_set" using by value state-node by reference z'achievements.customEvents' by value cp end-call

when 'achievement.getCustomEvents' when 'achievement.getAllCustomEvents'
call static "j_get_into" using by value state-node by reference z'achievements.customEvents' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call

when 'achievement.hasCustomEventOccurred'
call static "j_get_into" using by value state-node by reference z'achievements.customEvents' node end-call
move function J-STR(args, 'eventName') to text-value
move low-values to path-z
string function trim(text-value) x'00' into path-z end-string
call static "j_get_into" using by value node by reference path-z node2 end-call
call static "j_boolean" using by value node2 by reference x'00' returning flag end-call
call static "j_set_boolean" using by value response by reference z'result' by value flag end-call

when 'achievement.triggerCustomEvent'
call static "j_get_into" using by value state-node by reference z'achievements.customEvents' node end-call
move function J-STR(args, 'eventName') to text-value
move low-values to path-z
string function trim(text-value) x'00' into path-z end-string
call static "j_get_into" using by value node by reference path-z node2 end-call
call static "j_boolean" using by value node2 by reference x'00' returning flag end-call
if flag = 0
call static "j_object_into" using by reference item end-call
call static "j_set_boolean" using by value item by reference z'value' by value 1 end-call
call static "j_get_into" using by value item by reference z'value' node2 end-call
call static "j_clone_into" using by value node2 by reference cp end-call
move low-values to path-z
string function trim(text-value) x'00' into path-z end-string
call static "j_set" using by value node by reference path-z by value cp end-call
call static "j_delete" using by value item end-call
perform check-all end-if
when 'achievement.markConsoleOpened'
call static "j_set_boolean" using by value context by reference z'runtime.achievement.consoleOpened' by value 1 end-call
perform check-all
when 'achievement.reset'
call static "j_array_into" using by reference cp end-call
call static "j_set" using by value state-node by reference z'achievements.unlocked' by value cp end-call
call static "j_object_into" using by reference cp end-call
call static "j_set" using by value state-node by reference z'achievements.progress' by value cp end-call
call static "j_object_into" using by reference cp end-call
call static "j_set" using by value state-node by reference z'achievements.customEvents' by value cp end-call
move 0 to nv
call static "j_set_number" using by value state-node by reference z'achievements.clickCount' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'achievement.saveToState' continue
when other
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
move 'Unknown achievement operation' to sv
call static "j_set_string" using by value response by reference z'error' sv by value function length(function trim(sv trailing)) end-call
end-evaluate
goback.
find-achievement.
    set achievement-node to null
call static "j_size" using by value achievements-node by reference x'00' returning count-items end-call
perform varying i from 0 by 1 until i >= count-items
call static "j_at_into" using by value achievements-node i by reference item end-call
if function J-STR(item, 'id') = achievement-id set achievement-node to item end-if
end-perform.
category-icon.
    evaluate category-name
    when 'generators' move '🏭' to text-value
    when 'production' move '💰' to text-value
    when 'clicks' move '👆' to text-value
    when 'special' move '🎮' to text-value
    when other move '🏆' to text-value
    end-evaluate.
requirement-met.
    move 0 to is-met
call static "j_get_into" using by value achievement-node by reference z'requirement' requirement-node end-call
move function J-STR(requirement-node, 'target') to target-id
move function J-STR(requirement-node, 'type') to field-name
move function J-NUM(requirement-node, 'value') to n
evaluate field-name
when 'totalBufos' when 'bufosPerSecond' when 'totalGenerators' when 'clickCount'
when 'bossesDefeated' when 'transcendences' when 'prestigePoints'
move low-values to path-z
string function trim(field-name) x'00' into path-z end-string
call static "j_get_into" using by value check-data by reference path-z node end-call
if (function J-NUM(node, '') - n) >= 0 move 1 to is-met end-if
when 'upgradeCount'
    if (function J-NUM(check-data, 'upgradesPurchased') - n) >= 0 move 1 to is-met end-if
when 'explorationCount'
    if (function J-NUM(check-data, 'explorationsCompleted') - n) >= 0 move 1 to is-met end-if
when 'generatorType'
call static "j_get_into" using by value check-data by reference z'generatorCounts' node end-call
move low-values to path-z
string function trim(target-id) x'00' into path-z end-string
call static "j_get_into" using by value node by reference path-z node2 end-call
if node2 not = null and target-id not = spaces and (function J-NUM(node2, '') - n) >= 0 move 1 to is-met end-if
when 'consoleOpened'
call static "j_boolean" using by value check-data by reference z'consoleOpened' returning is-met end-call

when 'customEvent'
call static "j_get_into" using by value check-data by reference z'customEvents' node end-call
move low-values to path-z
string function trim(target-id) x'00' into path-z end-string
call static "j_get_into" using by value node by reference path-z node2 end-call
call static "j_boolean" using by value node2 by reference x'00' returning is-met end-call
end-evaluate.
check-all.
call static "j_boolean" using by value context by reference z'runtime.achievement.restoring' returning flag end-call
if flag = 1 exit paragraph end-if
call static "j_boolean" using by value context by reference z'runtime.achievement.checking' returning flag end-call
if flag = 1 exit paragraph end-if
call static "j_set_boolean" using by value context by reference z'runtime.achievement.checking' by value 1 end-call
call static "j_object_into" using by reference check-data end-call
move function J-NUM(state-node, 'resources.totalBufos') to n
move n to nv
call static "j_set_number" using by value check-data by reference z'totalBufos' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move function J-NUM(state-node, 'achievements.clickCount') to n
move n to nv
call static "j_set_number" using by value check-data by reference z'clickCount' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move function J-NUM(state-node, 'explorer.explorationsCompleted') to n
move n to nv
call static "j_set_number" using by value check-data by reference z'explorationsCompleted' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move function J-NUM(state-node, 'prestige.transcendences') to n
move n to nv
call static "j_set_number" using by value check-data by reference z'transcendences' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move function J-NUM(state-node, 'prestige.lifetimePoints') to n
move n to nv
call static "j_set_number" using by value check-data by reference z'prestigePoints' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_size" using by value state-node by reference z'bosses.defeated' returning count-items end-call
compute n = count-items + function J-NUM(state-node, 'bosses.lifetimeDefeats')
move n to nv
call static "j_set_number" using by value check-data by reference z'bossesDefeated' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_size" using by value state-node by reference z'upgrades.purchased' returning count-items end-call
move count-items to nv
call static "j_set_number" using by value check-data by reference z'upgradesPurchased' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_boolean" using by value context by reference z'runtime.achievement.consoleOpened' returning flag end-call
call static "j_set_boolean" using by value check-data by reference z'consoleOpened' by value flag end-call
call static "j_get_into" using by value state-node by reference z'achievements.customEvents' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_set" using by value check-data by reference z'customEvents' by value cp end-call
call static "j_get_into" using by value state-node by reference z'generators' list-node end-call
call static "j_object_into" using by reference new-list end-call
call static "j_size" using by value list-node by reference x'00' returning count-items end-call
move 0 to total factor
perform varying i from 0 by 1 until i >= count-items
call static "j_at_into" using by value list-node i by reference item end-call
compute total = total + function J-NUM(item, 'totalProduction')
compute factor = factor + function J-NUM(item, 'count')
move function J-STR(item, 'id') to key-name
call static "j_get_into" using by value item by reference z'count' node end-call
call static "j_clone_into" using by value node by reference cp end-call
move low-values to path-z
string function trim(key-name) x'00' into path-z end-string
call static "j_set" using by value new-list by reference path-z by value cp end-call
end-perform
move total to nv
call static "j_set_number" using by value check-data by reference z'bufosPerSecond' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move factor to nv
call static "j_set_number" using by value check-data by reference z'totalGenerators' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_set" using by value check-data by reference z'generatorCounts' by value new-list end-call
call static "j_size" using by value achievements-node by reference x'00' returning ac end-call
perform varying ai from 0 by 1 until ai >= ac
call static "j_at_into" using by value achievements-node ai by reference achievement-node end-call
move function J-STR(achievement-node, 'id') to achievement-id
move achievement-id to text-value
set list-node to unlocked-node
perform array-contains
if found = 0
    perform requirement-met
    if is-met = 1 perform unlock-achievement end-if
end-if
end-perform
call static "j_delete" using by value check-data end-call
call static "j_set_boolean" using by value context by reference z'runtime.achievement.checking' by value 0 end-call
.
unlock-achievement.
    move 0 to did-unlock
    if achievement-node = null exit paragraph end-if
    move achievement-id to text-value
    set list-node to unlocked-node
    perform array-contains
    if found = 1 exit paragraph end-if
call static "j_get_into" using by value achievement-node by reference z'id' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_append" using by value unlocked-node cp end-call
perform apply-reward
move 1 to did-unlock
if silent-mode = 0
call static "j_object_into" using by reference payload end-call
call static "j_clone_into" using by value achievement-node by reference cp end-call
call static "j_set" using by value payload by reference z'achievement' by value cp end-call
move function J-NUM(context, 'runtime.now') to n
move n to nv
call static "j_set_number" using by value payload by reference z'timestamp' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 'ACHIEVEMENT_UNLOCKED' to event-name
perform emit-event
call static "j_delete" using by value payload end-call
end-if.
reapply-rewards.
    move 1 to permanent-only
call static "j_size" using by value achievements-node by reference x'00' returning ac end-call
perform varying ai from 0 by 1 until ai >= ac
call static "j_at_into" using by value achievements-node ai by reference achievement-node end-call
move function J-STR(achievement-node, 'id') to text-value
set list-node to unlocked-node
perform array-contains
if found = 1 perform apply-reward end-if
end-perform.
apply-reward.
call static "j_get_into" using by value achievement-node by reference z'reward' reward-node end-call
move function J-NUM(reward-node, 'value') to m
evaluate function J-STR(reward-node, 'type')
when 'productionBoost'
    compute n = function J-NUM(state-node, 'resources.productionMultiplier') * m
move n to nv
call static "j_set_number" using by value state-node by reference z'resources.productionMultiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'clickBoost'
    compute n = function J-NUM(state-node, 'resources.clickMultiplier') * m
move n to nv
call static "j_set_number" using by value state-node by reference z'resources.clickMultiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'generatorBoost'
call static "j_object_into" using by reference input-args end-call
move function J-STR(reward-node, 'target') to sv
call static "j_set_string" using by value input-args by reference z'generatorType' sv by value function length(function trim(sv trailing)) end-call
move spaces to text-value
string 'achievement_' function trim(function J-STR(achievement-node, 'id')) into text-value end-string
move text-value to sv
call static "j_set_string" using by value input-args by reference z'boostId' sv by value function length(function trim(sv trailing)) end-call
move spaces to text-value
string 'Achievement: ' function trim(function J-STR(achievement-node, 'name')) into text-value end-string
move text-value to sv
call static "j_set_string" using by value input-args by reference z'source' sv by value function length(function trim(sv trailing)) end-call
move m to nv
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

when 'bufoBonus'
    if permanent-only = 0
        compute n = function J-NUM(state-node, 'resources.bufos') + m
move n to nv
call static "j_set_number" using by value state-node by reference z'resources.bufos' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
compute n = function J-NUM(state-node, 'resources.totalBufos') + m
move n to nv
call static "j_set_number" using by value state-node by reference z'resources.totalBufos' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
end-if
end-evaluate
call static "j_object_into" using by reference rq end-call
move 'recalculate' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-GAME" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_delete" using by value rs end-call
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
end program BUFO-ACHIEVEMENTS.
