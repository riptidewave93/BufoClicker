identification division.
program-id. BUFO-EVENT-SERVICES.
environment division.
configuration section.
repository. function J-NUM function J-STR function all intrinsic.
data division.
local-storage section.
01 op pic x(96).
01 scope-text pic x(16).
01 names-path pic x(64).
01 lists-path pic x(64).
01 frames-path pic x(64).
01 name-text pic x(256).
01 token-text pic x(256).
01 path-text pic x(512).
01 list-id pic x(32).
01 frame-id pic x(32).
01 num-text pic Z(18)9.
01 a usage pointer.
01 arg0 usage pointer.
01 arg1 usage pointer.
01 table-node usage pointer.
01 lists usage pointer.
01 frames usage pointer.
01 list-node usage pointer.
01 callbacks usage pointer.
01 frame usage pointer.
01 temp usage pointer.
01 child usage pointer.
01 command-node usage pointer.
01 commands usage pointer.
01 out-node usage pointer.
01 r usage comp-2.
01 refs usage comp-2.
01 i usage binary-long.
01 cnt usage binary-long.
01 yes usage binary-long.
01 log-index usage binary-long.
01 log-count usage binary-long.
01 log-flag usage binary-long.
01 log-request usage pointer.
01 log-response usage pointer.
01 log-commands usage pointer.
01 log-item usage pointer.
01 log-args usage pointer.
01 log-method pic x(32).
01 log-text pic x(512).
linkage section.
01 req usage pointer.
01 ctx usage pointer.
01 res usage pointer.
procedure division using by value req ctx res.
 call static 'j_array_into' using by reference commands end-call
 call static 'j_set' using by value res by reference z'commands' by value commands end-call
 move function J-STR(req,'operation') to op
 move function J-STR(req,'serviceScope') to scope-text
 move 'runtime.serviceEventNames' to names-path
 move 'runtime.serviceEventLists' to lists-path
 move 'runtime.serviceEventFrames' to frames-path
 if scope-text = 'state'
 move 'runtime.serviceStateNames' to names-path
 move 'runtime.serviceStateLists' to lists-path
 move 'runtime.serviceStateFrames' to frames-path end-if
 call static 'j_get_into' using by value req by reference z'args' a end-call
 call static 'j_at_into' using by value a 0 by reference arg0 end-call
 call static 'j_at_into' using by value a 1 by reference arg1 end-call
 move function J-STR(arg0,' ') to name-text
 move function J-STR(arg1,'$callback') to token-text
 call static 'j_get_into' using by value ctx by reference function concatenate(function trim(names-path),x'00') table-node end-call
 if table-node = null call static 'j_object_into' using by reference table-node end-call
 call static 'j_set' using by value ctx by reference function concatenate(function trim(names-path),x'00') by value table-node end-call end-if
 call static 'j_get_into' using by value ctx by reference function concatenate(function trim(lists-path),x'00') lists end-call
 if lists = null call static 'j_object_into' using by reference lists end-call
 call static 'j_set' using by value ctx by reference function concatenate(function trim(lists-path),x'00') by value lists end-call end-if
 call static 'j_get_into' using by value ctx by reference function concatenate(function trim(frames-path),x'00') frames end-call
 if frames = null call static 'j_object_into' using by reference frames end-call
 call static 'j_set' using by value ctx by reference function concatenate(function trim(frames-path),x'00') by value frames end-call end-if
 move function J-STR(table-node,function trim(name-text)) to list-id
 call static 'j_get_into' using by value lists by reference function concatenate(function trim(list-id),x'00') list-node end-call
 call static 'j_get_into' using by value list-node by reference z'callbacks' callbacks end-call
 call static 'j_size' using by value callbacks by reference x'00' returning cnt end-call
 evaluate op
 when 'event.on' when 'event.onRepeated'
 if list-id = spaces
 perform next-id move num-text to list-id move function trim(list-id) to list-id
 call static 'j_object_into' using by reference list-node end-call
 call static 'j_array_into' using by reference callbacks end-call
 call static 'j_set' using by value list-node by reference z'callbacks' by value callbacks end-call
 call static 'j_set_boolean' using by value list-node by reference z'attached' by value 1 end-call
 call static 'j_set' using by value lists by reference function concatenate(function trim(list-id),x'00') by value list-node end-call
 call static 'j_set_string' using by value table-node by reference function concatenate(function trim(name-text),x'00') list-id by value function length(function trim(list-id)) end-call end-if
 move 0 to yes
 perform varying i from 0 by 1 until i >= cnt
 call static 'j_at_into' using by value callbacks i by reference child end-call
 if function J-STR(child,'$callback') = token-text move 1 to yes end-if end-perform
 if yes = 0 or op = 'event.onRepeated' call static 'j_clone_into' using by value arg1 by reference temp end-call
 call static 'j_append' using by value callbacks temp end-call end-if
 when 'event.off'
 perform varying i from 0 by 1 until i >= cnt
 call static 'j_at_into' using by value callbacks i by reference child end-call
 if function J-STR(child,'$callback') = token-text
 call static 'h_array_remove' using by value callbacks i end-call subtract 1 from cnt exit perform end-if end-perform
 if cnt = 0 and list-id not = spaces perform detach-list end-if
 when 'event.getListenerCount'
 move cnt to r call static 'j_set_number' using by value res by reference z'result' r end-call
 when 'event.hasListeners'
 move 0 to yes if cnt > 0 move 1 to yes end-if
 call static 'j_set_boolean' using by value res by reference z'result' by value yes end-call
 when 'event.clearEvent'
 if list-id not = spaces perform detach-list end-if
 when 'event.clearAllEvents'
 call static 'j_size' using by value table-node by reference x'00' returning cnt end-call
 perform cnt times
 call static 'j_at_into' using by value table-node 0 by reference child end-call
 call static 'j_key' using by value child by reference name-text by value 256 end-call
 move function J-STR(child,' ') to list-id
 call static 'j_get_into' using by value lists by reference function concatenate(function trim(list-id),x'00') list-node end-call
 perform detach-list end-perform
 when 'event.getEventNames'
 call static 'j_array_into' using by reference out-node end-call
 call static 'j_size' using by value table-node by reference x'00' returning cnt end-call
 perform varying i from 0 by 1 until i >= cnt
 call static 'j_at_into' using by value table-node i by reference child end-call
 call static 'j_key' using by value child by reference name-text by value 256 end-call
 call static 'j_object_into' using by reference temp end-call
 call static 'j_set_string' using by value temp by reference z'name' name-text by value function length(function trim(name-text)) end-call
 call static 'j_get_into' using by value temp by reference z'name' child end-call
 call static 'j_clone_into' using by value child by reference child end-call
 call static 'j_append' using by value out-node child end-call
 call static 'j_delete' using by value temp end-call end-perform
 call static 'j_set' using by value res by reference z'result' by value out-node end-call
 when 'event.emit' when 'event.emitArgs'
 if scope-text not = 'state'
 perform debug-enabled
 if log-flag = 1
 move function concatenate("EventBus: Emitting '",function trim(name-text),"'") to log-text
 move 'logger.debug' to log-method perform log-command
 if cnt > 0 move 'logger.group' to log-method perform log-command end-if end-if end-if
 if cnt > 0
 perform next-id move function trim(num-text) to frame-id
 call static 'j_object_into' using by reference frame end-call
 call static 'j_set_string' using by value frame by reference z'eventName' name-text by value function length(function trim(name-text)) end-call
 if op = 'event.emitArgs' call static 'j_set_boolean' using by value frame by reference z'argsMode' by value 1 end-call end-if
 call static 'j_set_string' using by value frame by reference z'list' list-id by value function length(function trim(list-id)) end-call
 call static 'j_clone_into' using by value arg1 by reference temp end-call
 if temp = null call static 'j_parse_into' using by reference z'{"$oracle":"undefined"}' by value 23 by reference temp end-call end-if
 call static 'j_set' using by value frame by reference z'payload' by value temp end-call
 call static 'j_set' using by value frames by reference function concatenate(function trim(frame-id),x'00') by value frame end-call
 compute refs = function J-NUM(list-node,'refs') + 1
 call static 'j_set_number' using by value list-node by reference z'refs' refs end-call
 perform next-callback end-if
 when 'event.continue'
 move name-text to frame-id
 call static 'j_get_into' using by value frames by reference function concatenate(function trim(frame-id),x'00') frame end-call
 if frame not = null
 move function J-STR(frame,'eventName') to name-text
 move function J-STR(frame,'list') to list-id
 call static 'j_get_into' using by value lists by reference function concatenate(function trim(list-id),x'00') list-node end-call
 call static 'j_get_into' using by value list-node by reference z'callbacks' callbacks end-call
 call static 'j_size' using by value callbacks by reference x'00' returning cnt end-call
 perform next-callback end-if
 when 'event.setDebugMode'
 call static 'j_boolean' using by value arg0 by reference x'00' returning yes end-call
 call static 'j_set_boolean' using by value ctx by reference z'runtime.eventDebug' by value yes end-call
 when 'event.setExcludedEvents'
 call static 'j_clone_into' using by value arg0 by reference temp end-call
 call static 'j_set' using by value ctx by reference z'runtime.eventExcluded' by value temp end-call
 when 'event.addExcludedEvent' when 'event.removeExcludedEvent'
 call static 'j_get_into' using by value ctx by reference z'runtime.eventExcluded' callbacks end-call
 if callbacks = null call static 'j_array_into' using by reference callbacks end-call
 call static 'j_set' using by value ctx by reference z'runtime.eventExcluded' by value callbacks end-call end-if
 call static 'j_size' using by value callbacks by reference x'00' returning cnt end-call move 0 to yes
 perform varying i from 0 by 1 until i >= cnt
 call static 'j_at_into' using by value callbacks i by reference child end-call
 if function J-STR(child,' ') = name-text
 move 1 to yes if op = 'event.removeExcludedEvent' call static 'h_array_remove' using by value callbacks i end-call end-if exit perform end-if end-perform
 if yes = 0 and op = 'event.addExcludedEvent'
 call static 'j_clone_into' using by value arg0 by reference temp end-call
 call static 'j_append' using by value callbacks temp end-call end-if
 when other
 call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
 end-evaluate
 if scope-text not = 'state' and (op = 'event.on' or op = 'event.off' or op = 'event.clearEvent' or op = 'event.clearAllEvents')
 call static 'j_boolean' using by value ctx by reference z'runtime.eventDebug' returning log-flag end-call
 if log-flag = 1
 move function concatenate('EventBus: ',function trim(op),' ',function trim(name-text)) to log-text
 move 'logger.debug' to log-method perform log-command end-if end-if
 goback.
debug-enabled.
 call static 'j_boolean' using by value ctx by reference z'runtime.eventDebug' returning log-flag end-call
 if log-flag = 1
 call static 'j_get_into' using by value ctx by reference z'runtime.eventExcluded' log-item end-call
 call static 'j_size' using by value log-item by reference x'00' returning log-count end-call
 perform varying log-index from 0 by 1 until log-index >= log-count
 call static 'j_at_into' using by value log-item log-index by reference log-args end-call
 if function J-STR(log-args,' ') = name-text move 0 to log-flag end-if end-perform end-if.
log-command.
 call static 'j_object_into' using by reference log-request end-call
 call static 'j_object_into' using by reference log-response end-call
 call static 'j_set_string' using by value log-request by reference z'operation' log-method by value function length(function trim(log-method)) end-call
 move function J-NUM(req,'now') to r
 call static 'j_set_number' using by value log-request by reference z'now' r end-call
 call static 'j_array_into' using by reference log-args end-call
 call static 'j_set_string' using by value log-request by reference z'message' log-text by value function length(function trim(log-text)) end-call
 call static 'j_get_into' using by value log-request by reference z'message' log-item end-call
 call static 'j_clone_into' using by value log-item by reference log-item end-call
 if log-method not = 'logger.groupEnd' call static 'j_append' using by value log-args log-item end-call
 else call static 'j_delete' using by value log-item end-call end-if
 call static 'j_set' using by value log-request by reference z'args' by value log-args end-call
 call static 'BUFO-ASYNC-SERVICES' using by value log-request ctx log-response end-call
 call static 'j_get_into' using by value log-response by reference z'commands' log-commands end-call
 call static 'j_size' using by value log-commands by reference x'00' returning log-count end-call
 perform varying log-index from 0 by 1 until log-index >= log-count
 call static 'j_at_into' using by value log-commands log-index by reference log-item end-call
 call static 'j_clone_into' using by value log-item by reference log-item end-call
 call static 'j_append' using by value commands log-item end-call end-perform
 call static 'j_delete' using by value log-request end-call
 call static 'j_delete' using by value log-response end-call.
next-id.
 compute r = function J-NUM(ctx,'runtime.serviceSequence') + 1
 call static 'j_set_number' using by value ctx by reference z'runtime.serviceSequence' r end-call
 move r to num-text.
detach-list.
 call static 'j_remove' using by value table-node by reference function concatenate(function trim(name-text),x'00') end-call
 call static 'j_set_boolean' using by value list-node by reference z'attached' by value 0 end-call
 if function J-NUM(list-node,'refs') = 0
 call static 'j_remove' using by value lists by reference function concatenate(function trim(list-id),x'00') end-call end-if.
next-callback.
 move function J-NUM(frame,'index') to i
 if i >= cnt
 if scope-text not = 'state'
 perform debug-enabled
 if log-flag = 1 move 'logger.groupEnd' to log-method perform log-command end-if end-if
 compute refs = function J-NUM(list-node,'refs') - 1
 call static 'j_set_number' using by value list-node by reference z'refs' refs end-call
 call static 'j_boolean' using by value list-node by reference z'attached' returning yes end-call
 if refs = 0 and yes = 0
 call static 'j_remove' using by value lists by reference function concatenate(function trim(list-id),x'00') end-call end-if
 call static 'j_remove' using by value frames by reference function concatenate(function trim(frame-id),x'00') end-call
 else
 call static 'j_at_into' using by value callbacks i by reference child end-call
 compute r = i + 1 call static 'j_set_number' using by value frame by reference z'index' r end-call
 call static 'j_object_into' using by reference command-node end-call
 call static 'j_set_string' using by value command-node by reference z'kind' z'callback' by value 8 end-call
 move function J-STR(child,'$callback') to token-text
 call static 'j_set_string' using by value command-node by reference z'id' token-text by value function length(function trim(token-text)) end-call
 call static 'j_get_into' using by value frame by reference z'payload' temp end-call
 call static 'j_boolean' using by value frame by reference z'argsMode' returning yes end-call
 if yes = 1 call static 'j_clone_into' using by value temp by reference a end-call
 else call static 'j_array_into' using by reference a end-call
 call static 'j_clone_into' using by value temp by reference temp end-call
 call static 'j_append' using by value a temp end-call end-if
 call static 'j_set' using by value command-node by reference z'args' by value a end-call
 call static 'j_append' using by value commands command-node end-call
 call static 'j_object_into' using by reference temp end-call
 call static 'j_set_string' using by value temp by reference z'serviceScope' scope-text by value function length(function trim(scope-text)) end-call
 call static 'j_set_string' using by value temp by reference z'operation' z'event.continue' by value 14 end-call
 call static 'j_array_into' using by reference a end-call
 call static 'j_object_into' using by reference child end-call
 call static 'j_set_string' using by value child by reference z'id' frame-id by value function length(function trim(frame-id)) end-call
 call static 'j_get_into' using by value child by reference z'id' out-node end-call
 call static 'j_clone_into' using by value out-node by reference out-node end-call
 call static 'j_append' using by value a out-node end-call
 call static 'j_delete' using by value child end-call
 call static 'j_set' using by value temp by reference z'args' by value a end-call
 call static 'j_set' using by value res by reference z'continuation' by value temp end-call end-if.
end program BUFO-EVENT-SERVICES.
