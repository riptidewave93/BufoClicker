identification division.
program-id. BUFO-GAME recursive.
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
01 unlocked-result usage pointer.
01 available-result usage pointer.
01 input-args usage pointer.
01 generators-node usage pointer.
01 generator-node usage pointer.
01 boosts-node usage pointer.
01 new-list usage pointer.
01 bi usage binary-long.
01 bc usage binary-long.
01 gi usage binary-long.
01 gc usage binary-long.
01 now-ms usage comp-2.
01 click-count usage comp-2.
01 click-combo usage comp-2.
01 combo-multiplier usage comp-2.
01 gain usage comp-2.
01 old-bank usage comp-2.
01 cost usage comp-2.
01 numeric-limit usage comp-2 value 1.0e300.
01 arithmetic-a usage comp-2.
01 arithmetic-b usage comp-2.
01 random-value usage comp-2.
01 is-combo usage binary-long.
01 preserve-frenzy usage binary-long.
01 module-name pic x(32).
linkage section.
01 request usage pointer.
01 context usage pointer.
01 response usage pointer.
procedure division using by value request context response.
call static "j_get_into" using by value request by reference z'args' args end-call
call static "j_get_into" using by value context by reference z'state' state-node end-call
move function J-STR(request, 'operation') to op
call static "j_set_boolean" using by value response by reference z'ok' by value 1 end-call
move function J-NUM(context, 'runtime.now') to now-ms
move function J-NUM(context, 'runtime.domainDepth') to n
if n = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 0 end-call
end-if
compute n = n + 1
move n to nv
call static "j_set_number" using by value context by reference z'runtime.domainDepth' nv end-call
evaluate true
when op = 'init' perform initialize-game
when op = 'rebuild' perform rebuild-game
when op = 'recalculate' perform recalculate-game
when op = 'registerClick' perform register-click
when op = 'click' perform click-game
when op = 'tick' perform tick-game
when op = 'finishTick' perform finish-tick
when op = 'checkUnlocks' perform check-unlocks
when op = 'buyGenerator' perform buy-generator
when op = 'buyUpgrade' perform buy-upgrade
when op(1:10) = 'generator.' or op(1:16) = 'model.generator.'
    call static "BUFO-GENERATORS" using by value request context response end-call
when op(1:8) = 'upgrade.' or op(1:14) = 'model.upgrade.'
    call static "BUFO-UPGRADES" using by value request context response end-call
when op(1:12) = 'achievement.' or op(1:18) = 'model.achievement.'
    call static "BUFO-ACHIEVEMENTS" using by value request context response end-call
when op(1:9) = 'prestige.' or op(1:15) = 'model.prestige.'
    call static "BUFO-PRESTIGE" using by value request context response end-call
when op(1:7) = 'golden.'
    call static "BUFO-GOLDEN" using by value request context response end-call
when op(1:5) = 'boss.' or op(1:11) = 'model.boss.'
    call static "BUFO-BOSSES" using by value request context response end-call
when other
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
move 'Unknown game operation' to sv
call static "j_set_string" using by value response by reference z'error' sv by value function length(function trim(sv trailing)) end-call
end-evaluate
call static "j_boolean" using by value context by reference z'runtime.game.numericInvalid' returning write-status end-call
if write-status = 1
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
move 'Derived values exceed supported numeric range' to sv
call static "j_set_string" using by value response by reference z'error' sv by value function length(function trim(sv trailing)) end-call
end-if
move function J-NUM(context, 'runtime.domainDepth') to n
compute n = n - 1
move n to nv
call static "j_set_number" using by value context by reference z'runtime.domainDepth' nv end-call
goback.
initialize-game.
call static "j_get_into" using by value context by reference z'catalog.upgrades' list-node end-call
call static "j_size" using by value list-node by reference x'00' returning gc end-call
perform varying gi from 0 by 1 until gi >= gc
call static "j_at_into" using by value list-node gi by reference generator-node end-call
call static "j_get_into" using by value generator-node by reference z'unlockConditions' boosts-node end-call
call static "j_size" using by value boosts-node by reference x'00' returning bc end-call
perform varying bi from 0 by 1 until bi >= bc
call static "j_at_into" using by value boosts-node bi by reference node end-call
call static "j_has" using by value node by reference z'target' returning flag end-call
if flag = 0
call static "j_get_into" using by value node by reference z'id' node2 end-call
if node2 not = null
call static "j_clone_into" using by value node2 by reference cp end-call
call static "j_set" using by value node by reference z'target' by value cp end-call
call static "j_remove" using by value node by reference z'id' end-call
end-if
end-if
end-perform
end-perform
    if state-node = null
call static "j_object_into" using by reference state-node end-call
call static "j_set" using by value context by reference z'state' by value state-node end-call
end-if
call static "j_object_into" using by reference node end-call
call static "j_set" using by value state-node by reference z'resources' by value node end-call
move 0 to nv
call static "j_set_number" using by value state-node by reference z'resources.bufos' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 0 to nv
call static "j_set_number" using by value state-node by reference z'resources.totalBufos' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 0 to nv
call static "j_set_number" using by value state-node by reference z'resources.clickCount' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 1 to nv
call static "j_set_number" using by value state-node by reference z'resources.baseClickPower' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 1 to nv
call static "j_set_number" using by value state-node by reference z'resources.clickPower' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 1 to nv
call static "j_set_number" using by value state-node by reference z'resources.clickMultiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 1 to nv
call static "j_set_number" using by value state-node by reference z'resources.productionMultiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 1 to nv
call static "j_set_number" using by value state-node by reference z'resources.frenzyProductionMultiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 1 to nv
call static "j_set_number" using by value state-node by reference z'resources.frenzyClickMultiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_get_into" using by value context by reference z'catalog.generators' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_set" using by value state-node by reference z'generators' by value cp end-call
call static "j_array_into" using by reference cp end-call
call static "j_set" using by value state-node by reference z'upgrades.purchased' by value cp end-call
call static "j_array_into" using by reference cp end-call
call static "j_set" using by value state-node by reference z'upgrades.available' by value cp end-call
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
move 0 to nv
call static "j_set_number" using by value state-node by reference z'prestige.points' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 0 to nv
call static "j_set_number" using by value state-node by reference z'prestige.lifetimePoints' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 0 to nv
call static "j_set_number" using by value state-node by reference z'prestige.transcendences' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_array_into" using by reference cp end-call
call static "j_set" using by value state-node by reference z'bosses.defeated' by value cp end-call
move 0 to nv
call static "j_set_number" using by value state-node by reference z'bosses.lifetimeDefeats' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_object_into" using by reference cp end-call
call static "j_set" using by value context by reference z'runtime.game' by value cp end-call
call static "j_object_into" using by reference cp end-call
call static "j_set" using by value context by reference z'runtime.golden' by value cp end-call
call static "j_object_into" using by reference cp end-call
call static "j_set" using by value context by reference z'runtime.boss' by value cp end-call
call static "j_object_into" using by reference cp end-call
call static "j_set" using by value context by reference z'runtime.achievement' by value cp end-call
move 1 to nv
call static "j_set_number" using by value context by reference z'runtime.golden.nextId' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
perform recalculate-game.
recalculate-game.
    move function J-NUM(state-node, 'resources.baseClickPower') to n
move function J-NUM(state-node, 'resources.clickMultiplier') to arithmetic-a
call static "h_number_binary" using by value 3 by reference n arithmetic-a n end-call

    compute arithmetic-a = 1 + function max(0, function J-NUM(state-node, 'prestige.lifetimePoints')) * .1
call static "h_number_binary" using by value 3 by reference n arithmetic-a n end-call

call static "j_size" using by value state-node by reference z'bosses.defeated' returning count-items end-call
compute arithmetic-a = 1 + (count-items + function J-NUM(state-node, 'bosses.lifetimeDefeats')) * .25
call static "h_number_binary" using by value 3 by reference n arithmetic-a n end-call

call static "j_has" using by value state-node by reference z'resources.frenzyClickMultiplier' returning flag end-call
if flag = 1
move function J-NUM(state-node, 'resources.frenzyClickMultiplier') to arithmetic-a
call static "h_number_binary" using by value 3 by reference n arithmetic-a n end-call
end-if
call static "h_number_compare" using by reference n numeric-limit returning flag end-call
if flag > 0 or n < 0
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
move 'Click power exceeds supported numeric range' to sv
call static "j_set_string" using by value response by reference z'error' sv by value function length(function trim(sv trailing)) end-call
exit paragraph end-if
move n to nv
call static "j_set_number" using by value state-node by reference z'resources.clickPower' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_object_into" using by reference rq end-call
move 'generator.recalculateAllGenerators' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-GENERATORS" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_boolean" using by value rs by reference z'ok' returning flag end-call
if flag = 0
call static "j_merge" using by value response rs end-call
end-if
call static "j_delete" using by value rs end-call
.
rebuild-game.
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 0 end-call
call static "j_set_boolean" using by value context by reference z'runtime.achievement.restoring' by value 1 end-call
call static "j_boolean" using by value args by reference z'preserveFrenzy' returning preserve-frenzy end-call
if preserve-frenzy = 0
move 1 to nv
call static "j_set_number" using by value state-node by reference z'resources.frenzyProductionMultiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 1 to nv
call static "j_set_number" using by value state-node by reference z'resources.frenzyClickMultiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
end-if
move 1 to nv
call static "j_set_number" using by value state-node by reference z'resources.clickMultiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 1 to nv
call static "j_set_number" using by value state-node by reference z'resources.productionMultiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_get_into" using by value state-node by reference z'generators' generators-node end-call
call static "j_size" using by value generators-node by reference x'00' returning gc end-call
perform varying gi from 0 by 1 until gi >= gc
call static "j_at_into" using by value generators-node gi by reference generator-node end-call
call static "j_get_into" using by value generator-node by reference z'boosts' boosts-node end-call
call static "j_size" using by value boosts-node by reference x'00' returning bc end-call
call static "j_array_into" using by reference new-list end-call
perform varying bi from 0 by 1 until bi >= bc
call static "j_at_into" using by value boosts-node bi by reference node end-call
move function J-STR(node, 'id') to key-name
if key-name(1:8) not = 'upgrade_' and key-name(1:12) not = 'achievement_'
call static "j_clone_into" using by value node by reference cp end-call
call static "j_append" using by value new-list cp end-call
end-if
end-perform
call static "j_set" using by value generator-node by reference z'boosts' by value new-list end-call
end-perform
call static "j_object_into" using by reference rq end-call
move 'upgrade.initialize' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-UPGRADES" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_delete" using by value rs end-call
call static "j_object_into" using by reference rq end-call
move 'achievement.reapplyAllAchievementRewards' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-ACHIEVEMENTS" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_delete" using by value rs end-call
move function J-NUM(state-node, 'resources.clickCount') to n
move n to nv
call static "j_set_number" using by value context by reference z'runtime.game.clickCount' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 0 to nv
call static "j_set_number" using by value context by reference z'runtime.game.combo' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 0 to nv
call static "j_set_number" using by value context by reference z'runtime.game.lastClickTime' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
perform recalculate-game
call static "j_set_boolean" using by value context by reference z'runtime.achievement.restoring' by value 0 end-call
.
register-click.
    compute click-count = function J-NUM(context, 'runtime.game.clickCount') + 1
move click-count to nv
call static "j_set_number" using by value context by reference z'runtime.game.clickCount' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_object_into" using by reference input-args end-call
move click-count to nv
call static "j_set_number" using by value input-args by reference z'count' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_object_into" using by reference rq end-call
move 'achievement.setClickCount' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value input-args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-ACHIEVEMENTS" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_delete" using by value rs end-call
call static "j_delete" using by value input-args end-call
compute n = function J-NUM(state-node, 'resources.clickCount') + 1
move n to nv
call static "j_set_number" using by value state-node by reference z'resources.clickCount' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
.
click-game.
    compute n = now-ms - function J-NUM(context, 'runtime.game.lastClickTime')
move now-ms to nv
call static "j_set_number" using by value context by reference z'runtime.game.lastClickTime' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 0 to is-combo
move 1 to combo-multiplier
move 0 to click-combo
if n < 500
    compute click-combo = function min(10, function J-NUM(context, 'runtime.game.combo') + 1)
    compute combo-multiplier = 1 + click-combo * .05
    move 1 to is-combo
end-if
move click-combo to nv
call static "j_set_number" using by value context by reference z'runtime.game.combo' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
compute n = function max(click-combo, function J-NUM(context, 'runtime.game.maxCombo'))
move n to nv
call static "j_set_number" using by value context by reference z'runtime.game.maxCombo' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
perform register-click
compute gain = function J-NUM(state-node, 'resources.clickPower') * combo-multiplier
compute n = function J-NUM(state-node, 'resources.bufos') + gain
move n to nv
call static "j_set_number" using by value state-node by reference z'resources.bufos' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
compute n = function J-NUM(state-node, 'resources.totalBufos') + gain
move n to nv
call static "j_set_number" using by value state-node by reference z'resources.totalBufos' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
perform check-unlocks
call static "j_object_into" using by reference rq end-call
move 'achievement.checkAllAchievements' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-ACHIEVEMENTS" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_delete" using by value rs end-call
call static "j_object_into" using by reference payload end-call
call static "j_clone_into" using by value state-node by reference cp end-call
call static "j_set" using by value payload by reference z'state' by value cp end-call
move gain to nv
call static "j_set_number" using by value payload by reference z'clickPower' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move click-count to nv
call static "j_set_number" using by value payload by reference z'totalClicks' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move click-combo to nv
call static "j_set_number" using by value payload by reference z'combo' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move combo-multiplier to nv
call static "j_set_number" using by value payload by reference z'comboMultiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_set_boolean" using by value payload by reference z'isCombo' by value is-combo end-call
move 'click' to event-name
perform emit-event
call static "j_delete" using by value payload end-call
call static "j_object_into" using by reference result-node end-call
move gain to nv
call static "j_set_number" using by value result-node by reference z'bufosGained' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move combo-multiplier to nv
call static "j_set_number" using by value result-node by reference z'comboMultiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_set_boolean" using by value result-node by reference z'isCombo' by value is-combo end-call
call static "j_set" using by value response by reference z'result' by value result-node end-call
.
check-unlocks.
call static "j_object_into" using by reference input-args end-call
move function J-NUM(state-node, 'resources.totalBufos') to n
move n to nv
call static "j_set_number" using by value input-args by reference z'totalBufos' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_object_into" using by reference rq end-call
move 'generator.checkUnlocks' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value input-args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-GENERATORS" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_get_into" using by value rs by reference z'result' node end-call
call static "j_clone_into" using by value node by reference unlocked-result end-call
call static "j_delete" using by value rs end-call
call static "j_delete" using by value input-args end-call
call static "j_object_into" using by reference rq end-call
move 'upgrade.checkAvailableUpgrades' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-UPGRADES" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_get_into" using by value rs by reference z'result' node end-call
call static "j_clone_into" using by value node by reference available-result end-call
call static "j_delete" using by value rs end-call
call static "j_size" using by value unlocked-result by reference x'00' returning count-items end-call
call static "j_size" using by value available-result by reference x'00' returning count2 end-call
if count-items > 0 or count2 > 0
call static "j_object_into" using by reference payload end-call
call static "j_clone_into" using by value unlocked-result by reference cp end-call
call static "j_set" using by value payload by reference z'newlyUnlocked' by value cp end-call
call static "j_clone_into" using by value available-result by reference cp end-call
call static "j_set" using by value payload by reference z'availableUpgrades' by value cp end-call
call static "j_object_into" using by reference rq end-call
move 'generator.getUnlockedGenerators' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-GENERATORS" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_get_into" using by value rs by reference z'result' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_set" using by value payload by reference z'generators' by value cp end-call
call static "j_delete" using by value rs end-call
move 'unlocksUpdated' to event-name perform emit-event
call static "j_delete" using by value payload end-call
end-if
call static "j_delete" using by value unlocked-result end-call
call static "j_delete" using by value available-result end-call
.
tick-game.
call static "j_object_into" using by reference rq end-call
move 'golden.tick' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-GOLDEN" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_delete" using by value rs end-call
call static "j_object_into" using by reference rq end-call
move 'boss.tick' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-BOSSES" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_delete" using by value rs end-call
move function J-NUM(args, 'delta') to n
if n >= .001
call static "j_object_into" using by reference rq end-call
move 'generator.calculateTotalProduction' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-GENERATORS" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
compute gain = function J-NUM(rs, 'result') * function J-NUM(args, 'delta')
call static "j_delete" using by value rs end-call
compute n = function J-NUM(state-node, 'resources.bufos') + gain
move n to nv
call static "j_set_number" using by value state-node by reference z'resources.bufos' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
compute n = function J-NUM(state-node, 'resources.totalBufos') + gain
move n to nv
call static "j_set_number" using by value state-node by reference z'resources.totalBufos' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
end-if
call static "j_boolean" using by value args by reference z'deferChecks' returning flag end-call
if flag not = 1 perform finish-tick end-if.
finish-tick.
perform check-unlocks
call static "BUFO-RANDOM" using by value request context by reference random-value end-call
if random-value < .1
call static "j_object_into" using by reference rq end-call
move 'achievement.checkAllAchievements' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-ACHIEVEMENTS" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_delete" using by value rs end-call
end-if
move function J-NUM(context, 'runtime.now') to nv
call static "j_set_number" using by value state-node by reference z'gameSettings.lastTick' nv end-call
call static "j_object_into" using by reference payload end-call
call static "j_clone_into" using by value state-node by reference cp end-call
call static "j_set" using by value payload by reference z'state' by value cp end-call
call static "j_object_into" using by reference rq end-call
move 'generator.getUnlockedGenerators' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-GENERATORS" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_get_into" using by value rs by reference z'result' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_set" using by value payload by reference z'generators' by value cp end-call
call static "j_delete" using by value rs end-call
call static "j_object_into" using by reference rq end-call
move 'generator.calculateTotalProduction' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-GENERATORS" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_get_into" using by value rs by reference z'result' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_set" using by value payload by reference z'totalProduction' by value cp end-call
call static "j_delete" using by value rs end-call
call static "j_get_into" using by value state-node by reference z'explorer' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_set" using by value payload by reference z'explorer' by value cp end-call
move 'tick' to event-name perform emit-event
call static "j_delete" using by value payload end-call
.
buy-generator.
    move function J-NUM(state-node, 'resources.bufos') to old-bank
call static "j_clone_into" using by value args by reference input-args end-call
move old-bank to nv
call static "j_set_number" using by value input-args by reference z'availableBufos' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_has" using by value input-args by reference z'quantity' returning flag end-call
if flag = 0
move 1 to nv
call static "j_set_number" using by value input-args by reference z'quantity' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
end-if
call static "j_object_into" using by reference rq end-call
move 'generator.purchaseGenerator' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value input-args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-GENERATORS" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_delete" using by value input-args end-call
call static "j_boolean" using by value rs by reference z'result.success' returning flag end-call
if flag = 1
    move function J-NUM(rs, 'result.cost') to cost
    compute n = old-bank - cost
move n to nv
call static "j_set_number" using by value state-node by reference z'resources.bufos' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
end-if
call static "j_set_boolean" using by value response by reference z'result' by value flag end-call
call static "j_delete" using by value rs end-call
.
buy-upgrade.
call static "j_set_boolean" using by value response by reference z'result' by value 0 end-call
call static "j_object_into" using by reference rq end-call
move 'upgrade.checkAvailableUpgrades' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-UPGRADES" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_delete" using by value rs end-call
call static "j_get_into" using by value state-node by reference z'upgrades.available' list-node end-call
move function J-STR(args, 'upgradeId') to text-value
perform array-contains
if found = 0 exit paragraph end-if
move function J-NUM(state-node, 'resources.bufos') to old-bank
call static "j_clone_into" using by value args by reference input-args end-call
move old-bank to nv
call static "j_set_number" using by value input-args by reference z'currentBufos' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_object_into" using by reference rq end-call
move 'upgrade.purchaseUpgrade' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value input-args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-UPGRADES" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_delete" using by value input-args end-call
call static "j_boolean" using by value rs by reference z'result.success' returning flag end-call
if flag = 1
    move function J-NUM(rs, 'result.cost') to cost
    compute n = old-bank - cost
move n to nv
call static "j_set_number" using by value state-node by reference z'resources.bufos' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
end-if
call static "j_set_boolean" using by value response by reference z'result' by value flag end-call
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
end program BUFO-GAME.
