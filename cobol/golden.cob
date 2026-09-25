identification division.
program-id. BUFO-GOLDEN recursive.
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
01 active-node usage pointer.
01 spawn-node usage pointer.
01 input-args usage pointer.
01 reward-node usage pointer.
01 now-ms usage comp-2.
01 random-value usage comp-2.
01 spawn-id usage comp-2.
01 ends-at usage comp-2.
01 arithmetic-a usage comp-2.
01 arithmetic-b usage comp-2.
01 gain usage comp-2.
01 running-flag usage binary-long.
01 reward-type pic x(32).
01 formatted pic x(256).
01 detail-text pic x(512).
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
call static "j_get_into" using by value context by reference z'runtime.golden.active' active-node end-call
call static "j_boolean" using by value context by reference z'runtime.golden.running' returning running-flag end-call
evaluate op
when 'golden.start'
    if running-flag = 0
call static "j_set_boolean" using by value context by reference z'runtime.golden.running' by value 1 end-call
perform schedule-spawn end-if
when 'golden.stop'
    perform stop-golden
when 'golden.reset'
    perform stop-golden
call static "j_set_boolean" using by value context by reference z'runtime.golden.firstSpawnDone' by value 0 end-call

when 'golden.isActive'
    if active-node = null
call static "j_set_boolean" using by value response by reference z'result' by value 0 end-call
else
call static "j_set_boolean" using by value response by reference z'result' by value 1 end-call
end-if
when 'golden.getActiveSpawn'
    if active-node = null
call static "j_parse_into" using by reference z'null' by value 4 by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
else
call static "j_clone_into" using by value active-node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
end-if
when 'golden.getActiveFrenzies'
call static "j_object_into" using by reference result-node end-call
call static "j_parse_into" using by reference z'null' by value 4 by reference cp end-call
call static "j_set" using by value result-node by reference z'production' by value cp end-call
call static "j_parse_into" using by reference z'null' by value 4 by reference cp end-call
call static "j_set" using by value result-node by reference z'click' by value cp end-call
move function J-NUM(context, 'runtime.golden.productionFrenzyEndsAt') to ends-at
    if (ends-at - now-ms) > 0
call static "j_object_into" using by reference node end-call
move 7 to nv
call static "j_set_number" using by value node by reference z'multiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move ends-at to nv
call static "j_set_number" using by value node by reference z'endsAt' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_set" using by value result-node by reference z'production' by value node end-call
end-if
    move function J-NUM(context, 'runtime.golden.clickFrenzyEndsAt') to ends-at
    if (ends-at - now-ms) > 0
call static "j_object_into" using by reference node end-call
move 7 to nv
call static "j_set_number" using by value node by reference z'multiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move ends-at to nv
call static "j_set_number" using by value node by reference z'endsAt' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_set" using by value result-node by reference z'click' by value node end-call
end-if
call static "j_set" using by value response by reference z'result' by value result-node end-call

when 'golden.forceSpawn'
    if running-flag = 0
call static "j_set_boolean" using by value context by reference z'runtime.golden.running' by value 1 end-call
perform schedule-spawn end-if
move 0 to nv
call static "j_set_number" using by value context by reference z'runtime.golden.nextSpawnAt' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
if active-node = null perform spawn-golden end-if
when 'golden.collect'
call static "j_parse_into" using by reference z'null' by value 4 by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
if active-node not = null
call static "j_has" using by value args by reference z'id' returning flag end-call
move function J-NUM(active-node, 'id') to spawn-id
    if flag = 0 or function J-NUM(args, 'id') = spawn-id
        move function J-STR(active-node, 'rewardType') to reward-type
        call static "j_remove" using by value context by reference z'runtime.golden.active' end-call
        set active-node to null
        perform apply-reward
call static "j_clone_into" using by value reward-node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call
call static "j_clone_into" using by value reward-node by reference payload end-call
move spawn-id to nv
call static "j_set_number" using by value payload by reference z'id' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 'GOLDEN_BUFO_COLLECTED' to event-name
perform emit-event
call static "j_delete" using by value payload end-call
call static "j_delete" using by value reward-node end-call
call static "j_object_into" using by reference input-args end-call
move 'golden_bufo_caught' to sv
call static "j_set_string" using by value input-args by reference z'eventName' sv by value function length(function trim(sv trailing)) end-call
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
perform schedule-spawn
    end-if
end-if
when 'golden.tick'
    perform expire-frenzies
    if running-flag = 1
        move function J-NUM(context, 'runtime.golden.expiresAt') to ends-at
        if active-node not = null and (now-ms - ends-at) >= 0
            perform expire-spawn
            perform schedule-spawn
        end-if
        move function J-NUM(context, 'runtime.golden.nextSpawnAt') to ends-at
        if active-node = null and ends-at > 0 and (now-ms - ends-at) >= 0
            perform spawn-golden
        end-if
    end-if
when other
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
move 'Unknown golden operation' to sv
call static "j_set_string" using by value response by reference z'error' sv by value function length(function trim(sv trailing)) end-call
end-evaluate
goback.
random-number.
    call static "BUFO-RANDOM" using by value request context by reference random-value end-call.
schedule-spawn.
call static "j_boolean" using by value context by reference z'runtime.golden.running' returning flag end-call
if flag = 0 exit paragraph end-if
perform random-number
call static "j_boolean" using by value context by reference z'runtime.golden.firstSpawnDone' returning flag end-call
if flag = 1 compute n = now-ms + 90000 + random-value * 100000
else compute n = now-ms + 45000 + random-value * 45000 end-if
move n to nv
call static "j_set_number" using by value context by reference z'runtime.golden.nextSpawnAt' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
.
spawn-golden.
    perform random-number
    evaluate true
    when random-value < .5 move 'bufo_frenzy' to reward-type
    when random-value < .8 move 'lucky' to reward-type
    when other move 'click_frenzy' to reward-type
    end-evaluate
    move function J-NUM(context, 'runtime.golden.nextId') to spawn-id
    if spawn-id < 1 move 1 to spawn-id end-if
call static "j_object_into" using by reference active-node end-call
move spawn-id to nv
call static "j_set_number" using by value active-node by reference z'id' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move reward-type to sv
call static "j_set_string" using by value active-node by reference z'rewardType' sv by value function length(function trim(sv trailing)) end-call
move 13000 to nv
call static "j_set_number" using by value active-node by reference z'ttl' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
perform random-number
compute n = 8 + random-value * 76
move n to nv
call static "j_set_number" using by value active-node by reference z'position.xPct' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
perform random-number
compute n = 14 + random-value * 64
move n to nv
call static "j_set_number" using by value active-node by reference z'position.yPct' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_set" using by value context by reference z'runtime.golden.active' by value active-node end-call
compute n = spawn-id + 1
move n to nv
call static "j_set_number" using by value context by reference z'runtime.golden.nextId' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
compute n = now-ms + 13000
move n to nv
call static "j_set_number" using by value context by reference z'runtime.golden.expiresAt' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_set_boolean" using by value context by reference z'runtime.golden.firstSpawnDone' by value 1 end-call
move 0 to nv
call static "j_set_number" using by value context by reference z'runtime.golden.nextSpawnAt' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
set payload to active-node
move 'GOLDEN_BUFO_SPAWNED' to event-name
perform emit-event.
expire-spawn.
    if active-node = null exit paragraph end-if
    move function J-NUM(active-node, 'id') to spawn-id
call static "j_object_into" using by reference payload end-call
move spawn-id to nv
call static "j_set_number" using by value payload by reference z'id' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 'GOLDEN_BUFO_EXPIRED' to event-name
perform emit-event
call static "j_delete" using by value payload end-call
call static "j_remove" using by value context by reference z'runtime.golden.active' end-call
set active-node to null.
stop-golden.
call static "j_set_boolean" using by value context by reference z'runtime.golden.running' by value 0 end-call
move 0 to nv
call static "j_set_number" using by value context by reference z'runtime.golden.nextSpawnAt' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 0 to nv
call static "j_set_number" using by value context by reference z'runtime.golden.expiresAt' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
perform expire-spawn
move 0 to nv
call static "j_set_number" using by value context by reference z'runtime.golden.productionFrenzyEndsAt' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 0 to nv
call static "j_set_number" using by value context by reference z'runtime.golden.clickFrenzyEndsAt' nv returning write-status end-call
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
expire-frenzies.
    move 0 to found
    move function J-NUM(context, 'runtime.golden.productionFrenzyEndsAt') to ends-at
    if ends-at > 0 and (now-ms - ends-at) >= 0
move 0 to nv
call static "j_set_number" using by value context by reference z'runtime.golden.productionFrenzyEndsAt' nv returning write-status end-call
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
move 1 to found end-if
    move function J-NUM(context, 'runtime.golden.clickFrenzyEndsAt') to ends-at
    if ends-at > 0 and (now-ms - ends-at) >= 0
move 0 to nv
call static "j_set_number" using by value context by reference z'runtime.golden.clickFrenzyEndsAt' nv returning write-status end-call
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
move 1 to found end-if
    if found = 1
call static "j_object_into" using by reference rq end-call
move 'recalculate' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-GAME" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_delete" using by value rs end-call
end-if.
apply-reward.
call static "j_object_into" using by reference reward-node end-call
move reward-type to sv
call static "j_set_string" using by value reward-node by reference z'rewardType' sv by value function length(function trim(sv trailing)) end-call
evaluate reward-type
when 'bufo_frenzy'
move 7 to nv
call static "j_set_number" using by value state-node by reference z'resources.frenzyProductionMultiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
compute n = now-ms + 30000
move n to nv
call static "j_set_number" using by value context by reference z'runtime.golden.productionFrenzyEndsAt' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 'Bufo Frenzy!' to sv
call static "j_set_string" using by value reward-node by reference z'label' sv by value function length(function trim(sv trailing)) end-call
move 'x7 production for 30s' to sv
call static "j_set_string" using by value reward-node by reference z'detail' sv by value function length(function trim(sv trailing)) end-call

when 'click_frenzy'
move 7 to nv
call static "j_set_number" using by value state-node by reference z'resources.frenzyClickMultiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
compute n = now-ms + 15000
move n to nv
call static "j_set_number" using by value context by reference z'runtime.golden.clickFrenzyEndsAt' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 'Click Frenzy!' to sv
call static "j_set_string" using by value reward-node by reference z'label' sv by value function length(function trim(sv trailing)) end-call
move 'x7 click power for 15s' to sv
call static "j_set_string" using by value reward-node by reference z'detail' sv by value function length(function trim(sv trailing)) end-call

when other
call static "j_object_into" using by reference rq end-call
move 'generator.calculateTotalProduction' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-GENERATORS" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
move function J-NUM(rs, 'result') to total
call static "j_delete" using by value rs end-call
move function J-NUM(state-node, 'resources.bufos') to arithmetic-a
move .15 to arithmetic-b
call static "h_number_binary" using by value 3 by reference arithmetic-a arithmetic-b gain end-call
move 1200 to arithmetic-b
call static "h_number_binary" using by value 3 by reference total arithmetic-b arithmetic-a end-call
if (gain - arithmetic-a) > 0 move arithmetic-a to gain end-if
move 13 to arithmetic-b
call static "h_number_binary" using by value 1 by reference gain arithmetic-b gain end-call
call static "h_number_unary" using by value 2 by reference gain gain end-call

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
move 'lucky' to sv
call static "j_set_string" using by value reward-node by reference z'rewardType' sv by value function length(function trim(sv trailing)) end-call
move 'Lucky!' to sv
call static "j_set_string" using by value reward-node by reference z'label' sv by value function length(function trim(sv trailing)) end-call
call static "BUFO-FORMAT-NUMBER" using by reference gain formatted end-call
move spaces to detail-text
string '+' function trim(formatted) ' bufos' into detail-text end-string
move detail-text to sv
call static "j_set_string" using by value reward-node by reference z'detail' sv by value function length(function trim(sv trailing)) end-call
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
end program BUFO-GOLDEN.
