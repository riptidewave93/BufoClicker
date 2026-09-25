identification division.
program-id. BUFO-BOSSES recursive.
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
01 bosses-node usage pointer.
01 boss-node usage pointer.
01 fight-node usage pointer.
01 defeated-node usage pointer.
01 input-args usage pointer.
01 model-state usage pointer.
01 boss-id pic x(256).
01 bi usage binary-long.
01 bc usage binary-long.
01 arithmetic-a usage comp-2.
01 arithmetic-b usage comp-2.
01 health usage comp-2.
01 max-health usage comp-2.
01 damage usage comp-2.
01 remaining usage comp-2.
01 ticks usage comp-2.
01 total-bufos usage comp-2.
linkage section.
01 request usage pointer.
01 context usage pointer.
01 response usage pointer.
procedure division using by value request context response.
call static "j_get_into" using by value request by reference z'args' args end-call
call static "j_get_into" using by value context by reference z'state' state-node end-call
move function J-STR(request, 'operation') to op
call static "j_set_boolean" using by value response by reference z'ok' by value 1 end-call
call static "j_get_into" using by value context by reference z'catalog.bosses' bosses-node end-call
call static "j_get_into" using by value context by reference z'runtime.boss.fight' fight-node end-call
call static "j_get_into" using by value state-node by reference z'bosses.defeated' defeated-node end-call
set model-state to state-node
move function J-NUM(state-node, 'resources.totalBufos') to total-bufos
evaluate op
when 'model.boss.findBoss'
    move function J-STR(args, 'id') to boss-id
    set boss-node to null
call static "j_size" using by value bosses-node by reference x'00' returning bc end-call
perform varying bi from 0 by 1 until bi >= bc
call static "j_at_into" using by value bosses-node bi by reference node end-call
if function J-STR(node, 'id') = boss-id set boss-node to node end-if
end-perform
if boss-node not = null
call static "j_clone_into" using by value boss-node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
end-if
when 'model.boss.getAvailableBoss' when 'boss.getAvailableBoss'
    if op = 'model.boss.getAvailableBoss'
call static "j_get_into" using by value args by reference z'defeated' defeated-node end-call
move function J-NUM(args, 'totalBufos') to total-bufos end-if
    perform available-boss
    if boss-node = null
call static "j_parse_into" using by reference z'null' by value 4 by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
else
call static "j_clone_into" using by value boss-node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
end-if
when 'model.boss.getBossMultiplier' when 'boss.getMultiplier'
    if op = 'model.boss.getBossMultiplier'
call static "j_get_into" using by value args by reference z'state' model-state end-call
end-if
    perform boss-multiplier
move factor to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'model.boss.getBossHealth' when 'boss.getScaledHealth'
call static "j_get_into" using by value args by reference z'boss' boss-node end-call
if op = 'model.boss.getBossHealth'
call static "j_get_into" using by value args by reference z'state' model-state end-call
end-if
    perform scaled-health
move health to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'boss.getDefeatedCount'
call static "j_size" using by value defeated-node by reference x'00' returning bc end-call
move bc to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'boss.getActiveFight'
    if fight-node = null
call static "j_parse_into" using by reference z'null' by value 4 by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
else
call static "j_clone_into" using by value fight-node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
end-if
when 'boss.startFight'
call static "j_set_boolean" using by value response by reference z'result' by value 0 end-call
if fight-node = null
    perform available-boss
    if boss-node not = null
        perform scaled-health
call static "j_object_into" using by reference fight-node end-call
call static "j_clone_into" using by value boss-node by reference cp end-call
call static "j_set" using by value fight-node by reference z'boss' by value cp end-call
move health to nv
call static "j_set_number" using by value fight-node by reference z'health' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move health to nv
call static "j_set_number" using by value fight-node by reference z'maxHealth' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 30000 to nv
call static "j_set_number" using by value fight-node by reference z'remainingMs' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_set" using by value context by reference z'runtime.boss.fight' by value fight-node end-call
call static "j_set_boolean" using by value context by reference z'runtime.boss.paused' by value 0 end-call
move 0 to nv
call static "j_set_number" using by value context by reference z'runtime.boss.elapsed' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_object_into" using by reference payload end-call
call static "j_clone_into" using by value boss-node by reference cp end-call
call static "j_set" using by value payload by reference z'boss' by value cp end-call
move health to nv
call static "j_set_number" using by value payload by reference z'maxHealth' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 'BOSS_FIGHT_STARTED' to event-name
perform emit-event
call static "j_delete" using by value payload end-call
call static "j_set_boolean" using by value response by reference z'result' by value 1 end-call
end-if
end-if
when 'boss.hit'
    move function J-NUM(args, 'amount') to damage
    if fight-node not = null and damage > 0
        compute health = function max(0, function J-NUM(fight-node, 'health') - damage)
move health to nv
call static "j_set_number" using by value fight-node by reference z'health' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_get_into" using by value fight-node by reference z'boss' boss-node end-call
call static "j_object_into" using by reference payload end-call
call static "j_clone_into" using by value boss-node by reference cp end-call
call static "j_set" using by value payload by reference z'boss' by value cp end-call
move health to nv
call static "j_set_number" using by value payload by reference z'health' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move function J-NUM(fight-node, 'maxHealth') to max-health
move max-health to nv
call static "j_set_number" using by value payload by reference z'maxHealth' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move damage to nv
call static "j_set_number" using by value payload by reference z'damage' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 'BOSS_DAMAGED' to event-name
perform emit-event
call static "j_delete" using by value payload end-call
if health <= 0 perform win-fight end-if
    end-if
    if fight-node = null
call static "j_parse_into" using by reference z'null' by value 4 by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
else
call static "j_clone_into" using by value fight-node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
end-if
when 'boss.tick'
call static "j_boolean" using by value context by reference z'runtime.boss.paused' returning flag end-call
if fight-node not = null and flag = 0
        move function J-NUM(fight-node, 'remainingMs') to remaining
        compute ticks = function J-NUM(context, 'runtime.boss.elapsed') + function J-NUM(args, 'delta') * 1000
        compute n = function mod(ticks, 100)
move n to nv
call static "j_set_number" using by value context by reference z'runtime.boss.elapsed' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
compute ticks = function integer(ticks / 100)
        perform until ticks <= 0 or fight-node = null
            subtract 100 from remaining
move remaining to nv
call static "j_set_number" using by value fight-node by reference z'remainingMs' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_get_into" using by value fight-node by reference z'boss' boss-node end-call
call static "j_object_into" using by reference payload end-call
call static "j_clone_into" using by value boss-node by reference cp end-call
call static "j_set" using by value payload by reference z'boss' by value cp end-call
compute n = function max(0, remaining)
move n to nv
call static "j_set_number" using by value payload by reference z'remainingMs' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 'BOSS_TICK' to event-name
perform emit-event
call static "j_delete" using by value payload end-call
if remaining <= 0 perform lose-fight end-if
            subtract 1 from ticks
        end-perform
    end-if
when 'boss.retreat'
    if fight-node not = null
call static "j_get_into" using by value fight-node by reference z'boss' boss-node end-call
call static "j_object_into" using by reference payload end-call
call static "j_clone_into" using by value boss-node by reference cp end-call
call static "j_set" using by value payload by reference z'boss' by value cp end-call
move 'BOSS_FIGHT_RETREATED' to event-name
perform emit-event
call static "j_delete" using by value payload end-call
perform clear-fight end-if
when 'boss.pause'
call static "j_set_boolean" using by value context by reference z'runtime.boss.paused' by value 1 end-call

when 'boss.resume'
call static "j_set_boolean" using by value context by reference z'runtime.boss.paused' by value 0 end-call

when 'boss.reset' perform clear-fight
when other
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
move 'Unknown boss operation' to sv
call static "j_set_string" using by value response by reference z'error' sv by value function length(function trim(sv trailing)) end-call
end-evaluate
goback.
available-boss.
    set boss-node to null
call static "j_size" using by value bosses-node by reference x'00' returning bc end-call
perform varying bi from 0 by 1 until bi >= bc
call static "j_at_into" using by value bosses-node bi by reference node end-call
move function J-STR(node, 'id') to text-value
set list-node to defeated-node
perform array-contains
if found = 0
    if (total-bufos - function J-NUM(node, 'threshold')) >= 0 set boss-node to node end-if
    exit perform
end-if
end-perform.
boss-multiplier.
call static "j_size" using by value model-state by reference z'bosses.defeated' returning count-items end-call
compute factor = 1 + (count-items + function J-NUM(model-state, 'bosses.lifetimeDefeats')) * .25.
scaled-health.
    perform boss-multiplier
    move function J-NUM(model-state, 'prestige.lifetimePoints') to arithmetic-a
if arithmetic-a < 0 move 0 to arithmetic-a end-if
move .1 to arithmetic-b
call static "h_number_binary" using by value 3 by reference arithmetic-a arithmetic-b arithmetic-a end-call
move 1 to arithmetic-b
call static "h_number_binary" using by value 1 by reference arithmetic-a arithmetic-b arithmetic-a end-call
call static "h_number_binary" using by value 3 by reference factor arithmetic-a factor end-call
move function J-NUM(boss-node, 'baseHealth') to health
call static "h_number_binary" using by value 3 by reference health factor health end-call
call static "h_number_unary" using by value 1 by reference health health end-call
if health < 1 move 1 to health end-if.
clear-fight.
    call static "j_remove" using by value context by reference z'runtime.boss.fight' end-call
    set fight-node to null.
win-fight.
call static "j_object_into" using by reference payload end-call
call static "j_clone_into" using by value boss-node by reference cp end-call
call static "j_set" using by value payload by reference z'boss' by value cp end-call
call static "j_get_into" using by value boss-node by reference z'id' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_append" using by value defeated-node cp end-call
move spaces to text-value
string 'boss_' function trim(function J-STR(boss-node, 'id')) into text-value end-string
call static "j_object_into" using by reference input-args end-call
move text-value to sv
call static "j_set_string" using by value input-args by reference z'eventName' sv by value function length(function trim(sv trailing)) end-call
perform clear-fight
call static "j_object_into" using by reference rq end-call
move 'recalculate' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-GAME" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_delete" using by value rs end-call
call static "j_size" using by value defeated-node by reference x'00' returning bc end-call
move bc to nv
call static "j_set_number" using by value payload by reference z'defeatedCount' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
perform boss-multiplier
move factor to nv
call static "j_set_number" using by value payload by reference z'multiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 'BOSS_DEFEATED' to event-name
perform emit-event
call static "j_delete" using by value payload end-call
call static "j_object_into" using by reference rq end-call
move 'achievement.triggerCustomEvent' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value input-args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-ACHIEVEMENTS" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_delete" using by value rs end-call
call static "j_delete" using by value input-args end-call
.
lose-fight.
call static "j_object_into" using by reference payload end-call
call static "j_clone_into" using by value boss-node by reference cp end-call
call static "j_set" using by value payload by reference z'boss' by value cp end-call
perform clear-fight
move 0 to nv
call static "j_set_number" using by value state-node by reference z'resources.bufos' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 'BOSS_FIGHT_LOST' to event-name
perform emit-event
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
end program BUFO-BOSSES.
