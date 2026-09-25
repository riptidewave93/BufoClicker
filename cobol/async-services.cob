identification division.
program-id. BUFO-ASYNC-SERVICES.
environment division.
configuration section.
repository. function J-NUM function J-STR function all intrinsic.
data division.
local-storage section.
01 op pic x(96).
01 method-name pic x(48).
01 token pic x(64).
01 num-text pic Z(18)9.
01 text-value pic x(32768).
01 message-text pic x(32768).
01 context-text pic x(256).
01 style-text pic x(128).
01 key-text pic x(512).
01 clock-text pic x(12).
01 a usage pointer.
01 arg0 usage pointer.
01 arg1 usage pointer.
01 arg2 usage pointer.
01 temp usage pointer.
01 item usage pointer.
01 commands usage pointer.
01 command-node usage pointer.
01 command-args usage pointer.
01 out-node usage pointer.
01 continuation usage pointer.
01 timers usage pointer.
01 timer-node usage pointer.
01 config-node usage pointer.
01 child usage pointer.
01 results usage pointer.
01 now-ms usage comp-2.
01 r usage comp-2.
01 delay-ms usage comp-2.
01 generation usage comp-2.
01 elapsed usage comp-2.
01 level-number usage comp-2.
01 required-level usage comp-2.
01 i usage binary-long.
01 cnt usage binary-long.
01 yes usage binary-long.
01 rc usage binary-long.
01 flag usage binary-long.
linkage section.
01 req usage pointer.
01 ctx usage pointer.
01 res usage pointer.
procedure division using by value req ctx res.
 move function J-STR(req,'operation') to op
 call static 'j_get_into' using by value req by reference z'args' a end-call
 call static 'j_at_into' using by value a 0 by reference arg0 end-call
 call static 'j_at_into' using by value a 1 by reference arg1 end-call
 call static 'j_at_into' using by value a 2 by reference arg2 end-call
 move function J-NUM(req,'now') to now-ms
 call static 'j_array_into' using by reference commands end-call
 evaluate true
 when op(1:7) = 'logger.' perform logger-operation
 when op(1:5) = 'data.' perform data-operation
 when op = 'utils.attempt'
 move arg0 to child perform callback-command
 call static 'j_object_into' using by reference continuation end-call
 call static 'j_set_string' using by value continuation by reference z'operation' z'utils.attemptResult' by value 19 end-call
 call static 'j_clone_into' using by value a by reference temp end-call
 call static 'j_set' using by value continuation by reference z'args' by value temp end-call
 call static 'j_set' using by value res by reference z'continuation' by value continuation end-call
 when op = 'utils.attemptResult'
 call static 'j_boolean' using by value req by reference z'callbackResult.ok' returning yes end-call
 if yes = 1 call static 'j_get_into' using by value req by reference z'callbackResult.value' temp end-call
 else move arg1 to temp end-if perform return-copy
 when other perform timer-operation
 end-evaluate
 call static 'j_set' using by value res by reference z'commands' by value commands end-call goback.
return-copy.
 call static 'j_clone_into' using by value temp by reference out-node end-call
 if out-node = null call static 'j_parse_into' using by reference z'{"$oracle":"undefined"}' by value 23 by reference out-node end-call end-if
 call static 'j_set' using by value res by reference z'result' by value out-node end-call.
new-command.
 call static 'j_object_into' using by reference command-node end-call.
append-command.
 call static 'j_append' using by value commands command-node end-call.
callback-command.
 perform new-command
 call static 'j_set_string' using by value command-node by reference z'kind' z'callback' by value 8 end-call
 move function J-STR(child,'$callback') to text-value
 call static 'j_set_string' using by value command-node by reference z'id' text-value by value function length(function trim(text-value)) end-call
 call static 'j_array_into' using by reference command-args end-call
 call static 'j_set' using by value command-node by reference z'args' by value command-args end-call
 perform append-command.
next-token.
 compute r = function J-NUM(ctx,'runtime.serviceSequence') + 1
 call static 'j_set_number' using by value ctx by reference z'runtime.serviceSequence' r end-call
 move r to num-text move function trim(num-text) to token.
timer-operation.
 call static 'j_get_into' using by value ctx by reference z'runtime.serviceTimers' timers end-call
 if timers = null call static 'j_object_into' using by reference timers end-call
 call static 'j_set' using by value ctx by reference z'runtime.serviceTimers' by value timers end-call end-if
 evaluate op
 when 'time.throttle' when 'time.debounce' when 'utils.delay' when 'utils.cancellableDelay'
 perform next-token
 call static 'j_object_into' using by reference timer-node end-call
 call static 'j_set_string' using by value timer-node by reference z'mode' op by value function length(function trim(op)) end-call
 call static 'j_clone_into' using by value arg0 by reference temp end-call
 call static 'j_set' using by value timer-node by reference z'callback' by value temp end-call
 move function J-NUM(arg1,' ') to delay-ms
 if op = 'utils.delay' or op = 'utils.cancellableDelay' move function J-NUM(arg0,' ') to delay-ms end-if
 call static 'j_set_number' using by value timer-node by reference z'delay' delay-ms end-call
 call static 'j_set' using by value timers by reference function concatenate(function trim(token),x'00') by value timer-node end-call
 call static 'j_object_into' using by reference out-node end-call
 if op = 'time.throttle' or op = 'time.debounce'
 call static 'j_set_string' using by value out-node by reference z'$callable' token by value function length(function trim(token)) end-call
 else
 if op = 'utils.delay'
 call static 'j_set_string' using by value out-node by reference z'$promise' token by value function length(function trim(token)) end-call
 else
 call static 'j_set_string' using by value out-node by reference z'promise.$promise' token by value function length(function trim(token)) end-call
 call static 'j_set_string' using by value out-node by reference z'cancel.$cancel' token by value function length(function trim(token)) end-call end-if end-if
 call static 'j_set' using by value res by reference z'result' by value out-node end-call
 if op = 'utils.delay' or op = 'utils.cancellableDelay'
 move 1 to generation perform schedule-timer end-if
 when 'time.invoke' when 'time.fire' when 'time.cancel'
 move function J-STR(arg0,' ') to token
 call static 'j_get_into' using by value timers by reference function concatenate(function trim(token),x'00') timer-node end-call
 if timer-node = null exit paragraph end-if
 move function J-NUM(timer-node,'generation') to generation
 move function J-NUM(timer-node,'delay') to delay-ms
 evaluate op
 when 'time.cancel'
 perform cancel-timer
 add 1 to generation
 call static 'j_set_number' using by value timer-node by reference z'generation' generation end-call
 call static 'j_set_boolean' using by value timer-node by reference z'pending' by value 0 end-call
 when 'time.invoke'
 perform cancel-timer add 1 to generation
 call static 'j_clone_into' using by value arg1 by reference temp end-call
 call static 'j_set' using by value timer-node by reference z'args' by value temp end-call
 if arg2 not = null
 call static 'j_clone_into' using by value arg2 by reference temp end-call
 call static 'j_set' using by value timer-node by reference z'thisArg' by value temp end-call
 else call static 'j_remove' using by value timer-node by reference z'thisArg' end-call end-if
 compute elapsed = now-ms - function J-NUM(timer-node,'lastCall')
 if function J-STR(timer-node,'mode') = 'time.throttle' and elapsed >= delay-ms
 perform fire-callback
 else
 if function J-STR(timer-node,'mode') = 'time.throttle' subtract elapsed from delay-ms end-if
 perform schedule-timer end-if
 when 'time.fire'
 call static 'j_boolean' using by value timer-node by reference z'pending' returning yes end-call
 if function J-NUM(arg1,' ') = generation and yes = 1 perform fire-callback end-if
 end-evaluate
 when other
 call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
 end-evaluate.
schedule-timer.
 call static 'j_set_number' using by value timer-node by reference z'generation' generation end-call
 call static 'j_set_boolean' using by value timer-node by reference z'pending' by value 1 end-call
 perform new-command
 call static 'j_set_string' using by value command-node by reference z'kind' z'timer' by value 5 end-call
 call static 'j_set_string' using by value command-node by reference z'token' token by value function length(function trim(token)) end-call
 call static 'j_set_number' using by value command-node by reference z'generation' generation end-call
 call static 'j_set_number' using by value command-node by reference z'delay' delay-ms end-call
 perform append-command.
cancel-timer.
 call static 'j_boolean' using by value timer-node by reference z'pending' returning yes end-call
 if yes = 1
 perform new-command
 call static 'j_set_string' using by value command-node by reference z'kind' z'timerCancel' by value 11 end-call
 call static 'j_set_string' using by value command-node by reference z'token' token by value function length(function trim(token)) end-call
 perform append-command end-if.
fire-callback.
 if function J-STR(timer-node,'mode') = 'utils.delay' or function J-STR(timer-node,'mode') = 'utils.cancellableDelay'
 perform new-command
 call static 'j_set_string' using by value command-node by reference z'kind' z'resolve' by value 7 end-call
 call static 'j_set_string' using by value command-node by reference z'id' token by value function length(function trim(token)) end-call
 call static 'j_parse_into' using by reference z'{"$oracle":"undefined"}' by value 23 by reference temp end-call
 call static 'j_set' using by value command-node by reference z'value' by value temp end-call
 perform append-command
 call static 'j_remove' using by value timers by reference function concatenate(function trim(token),x'00') end-call exit paragraph end-if
 call static 'j_set_boolean' using by value timer-node by reference z'pending' by value 0 end-call
 call static 'j_set_number' using by value timer-node by reference z'lastCall' now-ms end-call
 call static 'j_set_number' using by value timer-node by reference z'generation' generation end-call
 call static 'j_get_into' using by value timer-node by reference z'callback' child end-call
 perform callback-command
 call static 'j_get_into' using by value timer-node by reference z'args' temp end-call
 if temp not = null call static 'j_clone_into' using by value temp by reference temp end-call
 call static 'j_set' using by value command-node by reference z'args' by value temp end-call end-if
 call static 'j_get_into' using by value timer-node by reference z'thisArg' temp end-call
 if temp not = null call static 'j_clone_into' using by value temp by reference temp end-call
 call static 'j_set' using by value command-node by reference z'thisArg' by value temp end-call end-if.
logger-operation.
 call static 'j_get_into' using by value ctx by reference z'runtime.serviceLogger' config-node end-call
 if config-node = null
 call static 'j_parse_into' using by reference z'{"level":3,"enableTimestamps":true,"enableConsoleColors":true,"enableGrouping":true,"context":"App","groupDepth":0}' by value 115 by reference config-node end-call
 call static 'j_set' using by value ctx by reference z'runtime.serviceLogger' by value config-node end-call end-if
 move op(8:) to method-name
 move function J-NUM(config-node,'level') to level-number
 evaluate method-name
 when 'setLogLevel'
 move function J-NUM(arg0,' ') to r
 call static 'j_set_number' using by value config-node by reference z'level' r end-call
 when 'getLogLevel'
 call static 'j_set_number' using by value res by reference z'result' level-number end-call
 when 'enableTimestamps' when 'enableConsoleColors' when 'enableGrouping'
 call static 'j_boolean' using by value arg0 by reference x'00' returning yes end-call
 call static 'j_set_boolean' using by value config-node by reference function concatenate(function trim(method-name),x'00') by value yes end-call
 when 'setContext'
 call static 'j_clone_into' using by value arg0 by reference temp end-call
 call static 'j_set' using by value config-node by reference z'context' by value temp end-call
 when 'createLogger'
 call static 'j_object_into' using by reference out-node end-call
 call static 'j_clone_into' using by value arg0 by reference temp end-call
 call static 'j_set' using by value out-node by reference z'$logger' by value temp end-call
 call static 'j_set' using by value res by reference z'result' by value out-node end-call
 when 'time'
 if level-number >= 4 move 'time' to method-name perform raw-log end-if
 move arg1 to child perform callback-command
 if level-number >= 4 move 'timeEnd' to method-name perform raw-log end-if
 call static 'j_object_into' using by reference continuation end-call
 call static 'j_set_string' using by value continuation by reference z'operation' z'logger.timeResult' by value 17 end-call
 call static 'j_set' using by value res by reference z'continuation' by value continuation end-call
 when 'timeResult'
 call static 'j_boolean' using by value req by reference z'callbackResult.ok' returning yes end-call
 if yes = 1 call static 'j_get_into' using by value req by reference z'callbackResult.value' temp end-call perform return-copy
 else call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
 move function J-STR(req,'callbackResult.error') to text-value
 call static 'j_set_string' using by value res by reference z'error' text-value by value function length(function trim(text-value)) end-call end-if
 when 'table'
 if level-number >= 4 perform raw-log end-if
 when 'groupEnd'
 call static 'j_boolean' using by value config-node by reference z'enableGrouping' returning yes end-call
 move function J-NUM(config-node,'groupDepth') to r
 if level-number >= 4 and yes = 1 and r > 0
 subtract 1 from r call static 'j_set_number' using by value config-node by reference z'groupDepth' r end-call perform raw-log end-if
 when other
 move 3 to required-level move 'color: #4CAF50;' to style-text
 evaluate method-name
 when 'error' move 1 to required-level move 'color: #FF5252;' to style-text
 when 'warn' move 2 to required-level move 'color: #FFC107;' to style-text
 when 'debug' move 4 to required-level move 'color: #2196F3;' to style-text
 when 'trace' move 5 to required-level move 'color: #9E9E9E;' to style-text
 when 'group' when 'groupCollapsed' move 4 to required-level move 'color: #673AB7; font-weight: bold;' to style-text
 when 'styled' move function J-STR(arg1,' ') to style-text
 end-evaluate
 if level-number < required-level exit paragraph end-if
 if method-name = 'group' or method-name = 'groupCollapsed'
 call static 'j_boolean' using by value config-node by reference z'enableGrouping' returning yes end-call
 if yes = 0 exit paragraph end-if
 compute r = function J-NUM(config-node,'groupDepth') + 1
 call static 'j_set_number' using by value config-node by reference z'groupDepth' r end-call end-if
 perform formatted-log
 end-evaluate.
raw-log.
 perform new-command
 call static 'j_set_string' using by value command-node by reference z'kind' z'log' by value 3 end-call
 call static 'j_set_string' using by value command-node by reference z'method' method-name by value function length(function trim(method-name)) end-call
 call static 'j_array_into' using by reference command-args end-call
 if arg0 not = null call static 'j_clone_into' using by value arg0 by reference temp end-call
 call static 'j_append' using by value command-args temp end-call end-if
 call static 'j_set' using by value command-node by reference z'args' by value command-args end-call
 perform append-command.
formatted-log.
 move function J-STR(config-node,'context') to context-text
 call static 'j_has' using by value req by reference z'loggerContext' returning yes end-call
 if yes = 1 move function J-STR(req,'loggerContext') to context-text end-if
 move function J-STR(arg0,' ') to text-value move spaces to message-text
 call static 'j_boolean' using by value config-node by reference z'enableTimestamps' returning yes end-call
 if yes = 1
 call static 'h_clock_text' using by reference now-ms clock-text end-call
 string '[' clock-text '] ' into message-text end-string end-if
 if message-text = spaces
 string '[' function trim(context-text) '] ' function trim(text-value trailing) into message-text end-string
 else move function concatenate(function trim(message-text trailing),' [',function trim(context-text),'] ',function trim(text-value trailing)) to message-text end-if
 call static 'j_boolean' using by value config-node by reference z'enableConsoleColors' returning flag end-call
 if flag = 1 move function concatenate('%c',function trim(message-text trailing)) to message-text end-if
 if method-name = 'info' or method-name = 'styled' move 'log' to method-name end-if
 if method-name = 'trace' move 'debug' to method-name end-if
 perform new-command
 call static 'j_set_string' using by value command-node by reference z'kind' z'log' by value 3 end-call
 call static 'j_set_string' using by value command-node by reference z'method' method-name by value function length(function trim(method-name)) end-call
 call static 'j_array_into' using by reference command-args end-call
 move message-text to text-value perform append-text
 if flag = 1 move style-text to text-value perform append-text end-if
 call static 'j_size' using by value a by reference x'00' returning cnt end-call
 move 1 to i if op = 'logger.styled' move 2 to i end-if
 perform until i >= cnt
 call static 'j_at_into' using by value a i by reference temp end-call
 call static 'j_clone_into' using by value temp by reference temp end-call
 call static 'j_append' using by value command-args temp end-call add 1 to i end-perform
 call static 'j_set' using by value command-node by reference z'args' by value command-args end-call perform append-command.
append-text.
 call static 'j_object_into' using by reference temp end-call
 call static 'j_set_string' using by value temp by reference z'text' text-value by value function length(function trim(text-value trailing)) end-call
 call static 'j_get_into' using by value temp by reference z'text' child end-call
 call static 'j_clone_into' using by value child by reference child end-call
 call static 'j_append' using by value command-args child end-call
 call static 'j_delete' using by value temp end-call.
data-operation.
 evaluate op
 when 'data.shouldLoadData'
 move function J-STR(arg0,' ') to text-value
 move function concatenate(function trim(text-value),'_version',x'00') to key-text
 call static 'h_storage_read' using by reference key-text temp rc end-call
 move 1 to yes
 if rc = 1 and function J-STR(temp,' ') not = spaces and function J-STR(temp,' ') = function J-STR(arg1,' ') move 0 to yes end-if
 call static 'j_delete' using by value temp end-call
 call static 'j_set_boolean' using by value res by reference z'result' by value yes end-call
 when 'data.updateDataCacheVersion'
 move function J-STR(arg0,' ') to text-value
 move function concatenate(function trim(text-value),'_version',x'00') to key-text
 call static 'h_storage_write' using by reference key-text by value arg1 returning rc end-call
 if rc not = 0
 move 'warn' to method-name perform raw-log end-if
 when 'data.loadJsonData' when 'data.loadMultipleJsonData'
 if op = 'data.loadJsonData'
 move 'value' to key-text move arg0 to item perform fetch-command
 else
 call static 'j_size' using by value arg0 by reference x'00' returning cnt end-call
 perform varying i from 0 by 1 until i >= cnt
 call static 'j_at_into' using by value arg0 i by reference item end-call
 call static 'j_key' using by value item by reference key-text by value 512 end-call
 perform fetch-command end-perform end-if
 call static 'j_object_into' using by reference continuation end-call
 if op = 'data.loadJsonData' move 'data.complete' to method-name else move 'data.completeMultiple' to method-name end-if
 call static 'j_set_string' using by value continuation by reference z'operation' method-name by value function length(function trim(method-name)) end-call
 call static 'j_set' using by value res by reference z'continuation' by value continuation end-call
 when 'data.complete' when 'data.completeMultiple'
 call static 'j_get_into' using by value req by reference z'commandResults' results end-call
 call static 'j_size' using by value results by reference x'00' returning cnt end-call
 call static 'j_object_into' using by reference out-node end-call
 perform varying i from 0 by 1 until i >= cnt
 call static 'j_at_into' using by value results i by reference item end-call
 call static 'j_boolean' using by value item by reference z'ok' returning yes end-call
 move function J-NUM(item,'status') to r
 move null to temp
 if yes = 1 and r >= 200 and r < 300
 call static 'j_get_into' using by value item by reference z'text' child end-call
 call static 'h_json_parse_value' using by value child by reference temp returning rc end-call
 else move -1 to rc end-if
 if rc = 0
 if op = 'data.complete'
 call static 'j_delete' using by value out-node end-call move temp to out-node
 else move function J-STR(item,'id') to key-text
 call static 'j_set' using by value out-node by reference function concatenate(function trim(key-text),x'00') by value temp end-call end-if
 else
 if op = 'data.complete'
 call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
 move function J-STR(item,'error') to text-value
 if text-value = spaces move 'Failed to load or parse JSON data' to text-value end-if
 call static 'j_set_string' using by value res by reference z'error' text-value by value function length(function trim(text-value)) end-call
 else move 'warn' to method-name perform raw-log end-if end-if end-perform
 call static 'j_set' using by value res by reference z'result' by value out-node end-call
 when other call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call end-evaluate.
fetch-command.
 perform new-command
 call static 'j_set_string' using by value command-node by reference z'kind' z'fetch' by value 5 end-call
 call static 'j_set_string' using by value command-node by reference z'id' key-text by value function length(function trim(key-text)) end-call
 move function J-STR(item,' ') to text-value
 call static 'j_set_string' using by value command-node by reference z'url' text-value by value function length(function trim(text-value)) end-call
 move 10000 to r call static 'j_set_number' using by value command-node by reference z'timeout' r end-call
 perform append-command.
end program BUFO-ASYNC-SERVICES.
