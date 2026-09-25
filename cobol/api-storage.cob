identification division.
program-id. BUFO-API-STORAGE.
environment division.
configuration section.
repository. function J-NUM function J-STR function all intrinsic.
data division.
local-storage section.
01 op pic x(128).
01 a usage pointer.
01 a0 usage pointer.
01 a1 usage pointer.
01 node usage pointer.
01 temp usage pointer.
01 raw usage pointer.
01 child usage pointer.
01 child-args usage pointer.
01 commands usage pointer.
01 text-value pic x(32768).
01 key-text pic x(32769).
01 number-value usage comp-2.
01 status-code usage binary-long.
01 rc usage binary-long.
01 flag usage binary-long.
01 i usage binary-long.
linkage section.
01 req usage pointer.
01 ctx usage pointer.
01 res usage pointer.
procedure division using by value req ctx res.
move function J-STR(req,'operation') to op
call static 'j_get_into' using by value req by reference z'args' a end-call
call static 'j_at_into' using by value a 0 by reference a0 end-call
call static 'j_at_into' using by value a 1 by reference a1 end-call
move function J-STR(a0,' ') to text-value
move low-values to key-text
string function trim(text-value trailing) x'00' into key-text end-string
call static 'j_set_boolean' using by value res by reference z'ok' by value 1 end-call
evaluate op
when 'storage.isStorageAvailable'
call static 'h_storage_available' returning flag end-call
call static 'j_set_boolean' using by value res by reference z'result' by value flag end-call

when 'storage.saveToStorage'
move 0 to flag
if text-value not = spaces
call static 'h_storage_available' returning flag end-call
if flag = 1
call static 'h_storage_write_json' using by reference key-text by value a1 returning rc end-call
move 0 to flag if rc = 0 move 1 to flag end-if
end-if end-if
call static 'j_set_boolean' using by value res by reference z'result' by value flag end-call

when 'storage.loadFromStorage'
set node to null
if text-value not = spaces
call static 'h_storage_available' returning flag end-call
if flag = 1
call static 'h_storage_read' using by reference key-text raw status-code end-call
if status-code = 1 call static 'h_json_parse_value' using by value raw by reference node returning rc end-call end-if
call static 'j_delete' using by value raw end-call
end-if end-if
if node not = null
call static 'j_set' using by value res by reference z'result' by value node end-call
else
call static 'j_clone_into' using by value a1 by reference temp end-call
call static 'j_set' using by value res by reference z'result' by value temp end-call
end-if
when 'storage.clearStorage'
move 0 to flag
if text-value not = spaces
call static 'h_storage_available' returning flag end-call
if flag = 1
call static 'h_storage_remove' using by reference key-text returning rc end-call
move 0 to flag if rc = 0 move 1 to flag end-if
end-if end-if
call static 'j_set_boolean' using by value res by reference z'result' by value flag end-call

when 'storage.clearAllStorage' when 'reset.hardReset'
call static 'h_storage_available' returning flag end-call
if flag = 1
call static 'h_storage_clear_all' returning rc end-call
move 0 to flag if rc = 0 move 1 to flag end-if end-if
call static 'j_set_boolean' using by value res by reference z'result' by value flag end-call
if op = 'reset.hardReset' and flag = 1
call static 'j_array_into' using by reference commands end-call
call static 'j_object_into' using by reference node end-call
move 'reload' to text-value
call static 'j_set_string' using by value node by reference z'kind' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_append' using by value commands node end-call
call static 'j_set' using by value res by reference z'commands' by value commands end-call
move 'Local storage cleared, reloading page' to text-value
call static 'j_set_string' using by value res by reference z'result' text-value by value function length(function trim(text-value trailing)) end-call
end-if
when 'storage.getStorageSize'
move 0 to number-value
call static 'h_storage_available' returning flag end-call
if flag = 1 call static 'h_storage_size' using by reference number-value returning rc end-call end-if
call static 'j_set_number' using by value res by reference z'result' number-value end-call
when 'storage.hasStorageKey'
move 0 to flag
if text-value not = spaces
call static 'h_storage_available' returning flag end-call
if flag = 1
call static 'h_storage_read' using by reference key-text raw status-code end-call
call static 'j_delete' using by value raw end-call
move 0 to flag if status-code = 1 move 1 to flag end-if end-if end-if
call static 'j_set_boolean' using by value res by reference z'result' by value flag end-call

when 'storage.exportToString'
call static 'h_json_stringify_value' using by value a0 by reference raw returning rc end-call
set node to null
if rc = 0 call static 'h_encode_uri64' using by value raw by reference node returning rc end-call end-if
call static 'j_delete' using by value raw end-call
if node = null call static 'j_set_null' using by value res by reference z'result' end-call
else call static 'j_set' using by value res by reference z'result' by value node end-call end-if
when 'storage.importFromString'
call static 'h_decode_uri64' using by value a0 by reference raw returning rc end-call
set node to null
if rc = 0 call static 'h_json_parse_value' using by value raw by reference node returning rc end-call end-if
call static 'j_delete' using by value raw end-call
if node = null call static 'j_set_null' using by value res by reference z'result' end-call
else call static 'j_set' using by value res by reference z'result' by value node end-call end-if
when other
if op(1:12) = 'saveManager.'
call static 'j_clone_into' using by value req by reference child end-call
call static 'j_object_into' using by reference child-args end-call
call static 'j_set' using by value child by reference z'args' by value child-args end-call
evaluate op
when 'saveManager.saveGame'
move 'saveSupplied' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_clone_into' using by value a0 by reference temp end-call
call static 'j_set' using by value child-args by reference z'state' by value temp end-call
call static 'j_clone_into' using by value a1 by reference temp end-call
call static 'j_set' using by value child-args by reference z'generators' by value temp end-call
call static 'j_at_into' using by value a 2 by reference node end-call
call static 'j_clone_into' using by value node by reference temp end-call
call static 'j_set' using by value child-args by reference z'purchasedUpgrades' by value temp end-call
call static 'j_at_into' using by value a 3 by reference node end-call
call static 'j_clone_into' using by value node by reference temp end-call
call static 'j_set' using by value child-args by reference z'explorer' by value temp end-call

when 'saveManager.loadGame'
move 'readSaved' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call

when 'saveManager.clearSave'
move 'clearSaved' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call

when 'saveManager.exportSave'
move 'exportSaved' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call

when 'saveManager.importSave'
move 'importSupplied' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_clone_into' using by value a0 by reference temp end-call
call static 'j_set' using by value child-args by reference z'raw' by value temp end-call

when other
move 'unknown' to text-value
call static 'j_set_string' using by value child by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
end-evaluate
call static 'BUFO-SAVE' using by value child ctx res end-call
call static 'j_delete' using by value child end-call
else
call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
move 'Unknown storage API method' to text-value
call static 'j_set_string' using by value res by reference z'error' text-value by value function length(function trim(text-value trailing)) end-call
end-if
end-evaluate goback.
end program BUFO-API-STORAGE.
