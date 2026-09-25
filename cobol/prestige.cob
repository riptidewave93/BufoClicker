identification division.
program-id. BUFO-PRESTIGE recursive.
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
01 gained usage comp-2.
01 arithmetic-scale usage comp-2 value 1000000000.
linkage section.
01 request usage pointer.
01 context usage pointer.
01 response usage pointer.
procedure division using by value request context response.
call static "j_get_into" using by value request by reference z'args' args end-call
call static "j_get_into" using by value context by reference z'state' state-node end-call
move function J-STR(request, 'operation') to op
call static "j_set_boolean" using by value response by reference z'ok' by value 1 end-call
evaluate op
when 'model.prestige.prestigePointsFor'
    move function J-NUM(args, 'totalBufos') to n
    perform points-for
move gained to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'model.prestige.getPrestigeMultiplier'
call static "j_get_into" using by value args by reference z'state' node end-call
perform multiplier-for
move n to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'prestige.getPendingPoints' when 'prestige.canTranscend'
    move function J-NUM(state-node, 'resources.totalBufos') to n
    perform points-for
    if op = 'prestige.canTranscend'
        if gained >= 1
call static "j_set_boolean" using by value response by reference z'result' by value 1 end-call
else
call static "j_set_boolean" using by value response by reference z'result' by value 0 end-call
end-if
    else
move gained to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
end-if
when 'prestige.getMultiplier'
    set node to state-node
    perform multiplier-for
move n to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'prestige.getState'
call static "j_get_into" using by value state-node by reference z'prestige' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_set" using by value response by reference z'result' by value cp end-call

when 'prestige.getBonusPerPoint'
move .1 to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'prestige.getMinTotalBufos'
move 1000000000 to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'prestige.transcend'
    move function J-NUM(state-node, 'resources.totalBufos') to n
    perform points-for
    if gained >= 1
        compute n = function J-NUM(state-node, 'prestige.points') + gained
move n to nv
call static "j_set_number" using by value state-node by reference z'prestige.points' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
compute n = function J-NUM(state-node, 'prestige.lifetimePoints') + gained
move n to nv
call static "j_set_number" using by value state-node by reference z'prestige.lifetimePoints' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
compute n = function J-NUM(state-node, 'prestige.transcendences') + 1
move n to nv
call static "j_set_number" using by value state-node by reference z'prestige.transcendences' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_size" using by value state-node by reference z'bosses.defeated' returning count-items end-call
compute n = function J-NUM(state-node, 'bosses.lifetimeDefeats') + count-items
move n to nv
call static "j_set_number" using by value state-node by reference z'bosses.lifetimeDefeats' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_array_into" using by reference cp end-call
call static "j_set" using by value state-node by reference z'bosses.defeated' by value cp end-call
call static "j_get_into" using by value context by reference z'catalog.generators' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_set" using by value state-node by reference z'generators' by value cp end-call
call static "j_array_into" using by reference cp end-call
call static "j_set" using by value state-node by reference z'upgrades.purchased' by value cp end-call
call static "j_array_into" using by reference cp end-call
call static "j_set" using by value state-node by reference z'upgrades.available' by value cp end-call
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
call static "j_object_into" using by reference rq end-call
move 'rebuild' to sv
call static "j_set_string" using by value rq by reference z'operation' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value args by reference cp end-call
call static "j_set" using by value rq by reference z'args' by value cp end-call
call static "j_object_into" using by reference rs end-call
call static "BUFO-GAME" using by value rq context rs end-call
call static "j_delete" using by value rq end-call
call static "j_delete" using by value rs end-call
call static "j_object_into" using by reference payload end-call
move gained to nv
call static "j_set_number" using by value payload by reference z'gained' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
call static "j_get_into" using by value state-node by reference z'prestige' node end-call
call static "j_clone_into" using by value node by reference cp end-call
call static "j_set" using by value payload by reference z'prestige' by value cp end-call
set node to state-node
perform multiplier-for
move n to nv
call static "j_set_number" using by value payload by reference z'multiplier' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if
move 'PRESTIGE_TRANSCENDED' to event-name
perform emit-event
call static "j_delete" using by value payload end-call
end-if
move gained to nv
call static "j_set_number" using by value response by reference z'result' nv returning write-status end-call
if write-status not = 0
call static "j_set_boolean" using by value context by reference z'runtime.game.numericInvalid' by value 1 end-call
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
end-if

when 'prestige.reset' continue
when other
call static "j_set_boolean" using by value response by reference z'ok' by value 0 end-call
move 'Unknown prestige operation' to sv
call static "j_set_string" using by value response by reference z'error' sv by value function length(function trim(sv trailing)) end-call
end-evaluate
goback.
points-for.
    move 0 to gained
    if n >= 1000000000
        call static "h_number_binary" using by value 4 by reference n arithmetic-scale gained end-call
call static "h_number_unary" using by value 4 by reference gained gained end-call
call static "h_number_unary" using by value 2 by reference gained gained end-call

    end-if.
multiplier-for.
    compute n = 1 + function max(0, function J-NUM(node, 'prestige.lifetimePoints')) * .1.
emit-event.
call static "j_object_into" using by reference ev end-call
move event-name to sv
call static "j_set_string" using by value ev by reference z'name' sv by value function length(function trim(sv trailing)) end-call
call static "j_clone_into" using by value payload by reference cp end-call
call static "j_set" using by value ev by reference z'payload' by value cp end-call
call static "j_get_into" using by value context by reference z'events' events-node end-call
call static "j_append" using by value events-node ev end-call
.
end program BUFO-PRESTIGE.
