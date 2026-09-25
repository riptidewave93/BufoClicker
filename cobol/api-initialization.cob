identification division.
program-id. BUFO-API-INITIALIZATION recursive.
environment division.
configuration section.
repository. function J-NUM function J-STR function all intrinsic.
data division.
local-storage section.
01 operation-name pic x(96).
01 route-name pic x(96).
01 text-value pic x(32768).
01 status-text pic x(128).
01 error-message pic x(512).
01 root-id pic x(128).
01 a usage pointer.
01 callback-node usage pointer.
01 node usage pointer.
01 temp usage pointer.
01 child usage pointer.
01 child-args usage pointer.
01 child-res usage pointer.
01 progress-node usage pointer.
01 command-node usage pointer.
01 commands usage pointer.
01 continuation usage pointer.
01 next-args usage pointer.
01 service-json pic x(512).
01 stage binary-long.
01 progress-value comp-2.
01 number-value comp-2.
01 flag binary-long.
01 failed binary-long.
01 loaded-save binary-long.
linkage section.
01 req usage pointer.
01 ctx usage pointer.
01 res usage pointer.
procedure division using by value req ctx res.
move function J-STR(req,'operation') to operation-name
call static 'j_get_into' using by value req by reference z'args' a end-call
call static 'j_set_boolean' using by value res by reference z'ok' by value 1 end-call
if operation-name = 'initialization.initializeGame'
call static 'j_at_into' using by value a 0 by reference node end-call
move function J-STR(node,' ') to root-id
call static 'j_at_into' using by value a 1 by reference callback-node end-call
move 0 to stage
else
move function J-NUM(a,'step') to stage
move function J-STR(a,'rootElementId') to root-id
call static 'j_get_into' using by value a by reference z'callback' callback-node end-call
call static 'j_boolean' using by value a by reference z'loadedSave' returning loaded-save end-call
call static 'j_has' using by value req by reference z'callbackResult' returning flag end-call
if flag = 1
call static 'j_boolean' using by value req by reference z'callbackResult.ok' returning flag end-call
if flag = 0 move 1 to failed end-if end-if end-if
if root-id = spaces move 'game-container' to root-id end-if
if stage < 0 or stage > 10 move 1 to failed end-if
call static 'j_object_into' using by reference child-args end-call
if failed = 0
 evaluate stage
 when 0
  move 'logger.setContext' to route-name move '["GameInit"]' to service-json perform service-call
  move 'logger.setLogLevel' to route-name move '[3]' to service-json
  call static 'j_boolean' using by value req by reference z'development' returning flag end-call
  if flag = 1 move '[4]' to service-json end-if
  perform service-call
  move 'Initializing core systems' to status-text move 10 to progress-value
 when 1
  call static 'j_boolean' using by value req by reference z'development' returning flag end-call
  if flag = 1
   move 'event.setDebugMode' to route-name move '[true]' to service-json perform service-call
   move 'event.setExcludedEvents' to route-name
   move '[["GAME_TICK","EXPLORER_UPDATED","tick","explorerUpdated","GENERATOR_PRODUCTION_UPDATED"]]' to service-json perform service-call
  end-if
  move 'Loading game data' to status-text move 20 to progress-value
 when 2
  call static 'BUFO-VALIDATE-CATALOGS' using by value req ctx res end-call
  call static 'j_boolean' using by value res by reference z'ok' returning flag end-call
  if flag = 0 move 1 to failed end-if
  move 'Initializing managers' to status-text move 40 to progress-value
 when 3
  move 'managers.initializeManagers' to route-name perform extra-call
  move 'Initializing UI' to status-text move 60 to progress-value
 when 4
  move 'ui.init' to route-name perform prepare-call
  call static 'j_array_into' using by reference node end-call
  call static 'j_object_into' using by reference temp end-call
move root-id to text-value
call static 'j_set_string' using by value temp by reference z'id' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_get_into' using by value temp by reference z'id' progress-node end-call
call static 'j_clone_into' using by value progress-node by reference command-node end-call
  call static 'j_append' using by value node command-node end-call
  call static 'j_delete' using by value temp end-call
  call static 'j_set' using by value child by reference z'args' by value node end-call
  call static 'BUFO-API-UI' using by value child ctx res end-call
  call static 'j_delete' using by value child end-call
call static 'j_set_boolean' using by value res by reference z'ok' by value 1 end-call
call static 'j_remove' using by value res by reference z'error' end-call
  move 'Initializing game core' to status-text move 70 to progress-value
 when 5
  move 'gameCore.init' to route-name perform extra-call
  move 'Initializing game loop' to status-text move 80 to progress-value
 when 6 move 'Loading saved game' to status-text move 90 to progress-value
 when 7
  move 'load' to route-name perform prepare-call
  call static 'BUFO-SAVE' using by value child ctx res end-call
  call static 'j_delete' using by value child end-call
  call static 'j_boolean' using by value res by reference z'result' returning loaded-save end-call
  move 'Starting game systems' to status-text move 95 to progress-value
 when 8
  move 'game.start' to route-name perform extra-call
  move 'Initialization complete' to status-text move 100 to progress-value
 when 9
call static 'j_set_boolean' using by value res by reference z'result' by value 1 end-call
call static 'j_object_into' using by reference node end-call
move 'GAME_STARTED' to text-value
call static 'j_set_string' using by value node by reference z'name' text-value by value function length(function trim(text-value trailing)) end-call
move function J-NUM(ctx,'runtime.now') to number-value
call static 'j_set_number' using by value node by reference z'payload.timestamp' number-value end-call
call static 'j_set_boolean' using by value node by reference z'payload.loadedSave' by value loaded-save end-call
call static 'j_get_into' using by value ctx by reference z'events' commands end-call
call static 'j_append' using by value commands node end-call
 when other move 1 to failed
 end-evaluate
end-if
call static 'j_delete' using by value child-args end-call
move function J-STR(res,'error') to error-message
if error-message = spaces move function J-STR(req,'callbackResult.error') to error-message end-if
if failed = 1
call static 'j_set_boolean' using by value res by reference z'ok' by value 1 end-call
call static 'j_set_boolean' using by value res by reference z'result' by value 0 end-call
call static 'j_remove' using by value res by reference z'error' end-call
move 'Initialization failed' to status-text move 0 to progress-value
else
call static 'j_boolean' using by value res by reference z'ok' returning flag end-call
if flag = 0 move 1 to failed
call static 'j_set_boolean' using by value res by reference z'ok' by value 1 end-call
call static 'j_set_boolean' using by value res by reference z'result' by value 0 end-call
end-if
end-if
if stage < 9 or failed = 1
 if callback-node not = null perform status-command end-if
 if failed = 0
  call static 'j_object_into' using by reference continuation end-call
move 'initialization.step' to text-value
call static 'j_set_string' using by value continuation by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
move root-id to text-value
call static 'j_set_string' using by value continuation by reference z'args.rootElementId' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_clone_into' using by value callback-node by reference temp end-call
call static 'j_set' using by value continuation by reference z'args.callback' by value temp end-call
compute number-value = stage + 1
call static 'j_set_number' using by value continuation by reference z'args.step' number-value end-call
call static 'j_set_boolean' using by value continuation by reference z'args.loadedSave' by value loaded-save end-call
call static 'j_set' using by value res by reference z'continuation' by value continuation end-call
call static 'j_remove' using by value res by reference z'result' end-call
 end-if
end-if
goback.
prepare-call.
call static 'j_clone_into' using by value req by reference child end-call
move route-name to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_clone_into' using by value child-args by reference temp end-call
call static 'j_set' using by value child by reference z'args' by value temp end-call
.
extra-call.
perform prepare-call
call static 'j_array_into' using by reference node end-call
call static 'j_set' using by value child by reference z'args' by value node end-call
call static 'BUFO-API-EXTRA' using by value child ctx res end-call
call static 'j_delete' using by value child end-call.
service-call.
perform prepare-call
call static 'j_parse_into' using by reference service-json by value function length(function trim(service-json trailing)) by reference node end-call
call static 'j_set' using by value child by reference z'args' by value node end-call
call static 'BUFO-SERVICES' using by value child ctx res end-call
call static 'j_delete' using by value child end-call.
status-command.
call static 'j_get_into' using by value res by reference z'commands' commands end-call
if commands = null
call static 'j_array_into' using by reference commands end-call
call static 'j_set' using by value res by reference z'commands' by value commands end-call end-if
call static 'j_object_into' using by reference command-node end-call
move 'callback' to text-value
call static 'j_set_string' using by value command-node by reference z'kind' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_get_into' using by value callback-node by reference z'$callback' node end-call
call static 'j_clone_into' using by value node by reference temp end-call
call static 'j_set' using by value command-node by reference z'id' by value temp end-call
call static 'j_array_into' using by reference node end-call
call static 'j_object_into' using by reference progress-node end-call
move status-text to text-value
call static 'j_set_string' using by value progress-node by reference z'step' text-value by value function length(function trim(text-value trailing)) end-call
move progress-value to number-value
call static 'j_set_number' using by value progress-node by reference z'progress' number-value end-call
if failed = 1
move error-message to text-value
call static 'j_set_string' using by value progress-node by reference z'error.message' text-value by value function length(function trim(text-value trailing)) end-call
end-if
call static 'j_append' using by value node progress-node end-call
call static 'j_set' using by value command-node by reference z'args' by value node end-call
call static 'j_append' using by value commands command-node end-call.
end program BUFO-API-INITIALIZATION.
