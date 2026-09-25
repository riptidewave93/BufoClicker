identification division.
program-id. BUFO-VALIDATION-SERVICES recursive.
environment division.
configuration section.
repository. function J-NUM function J-STR function all intrinsic.
data division.
local-storage section.
01 op pic x(96).
01 message-text pic x(256).
01 key-text pic x(256).
01 text-value pic x(32768).
01 a usage pointer.
01 value-node usage pointer.
01 schema usage pointer.
01 out-node usage pointer.
01 errors usage pointer.
01 temp usage pointer.
01 child usage pointer.
01 item usage pointer.
01 prop usage pointer.
01 inner-req usage pointer.
01 inner-res usage pointer.
01 outcomes usage pointer.
01 previous-outcomes usage pointer.
01 command-node usage pointer.
01 commands usage pointer.
01 continuation usage pointer.
01 callback-result usage pointer.
01 token-text pic x(256).
01 i usage binary-long.
01 cnt usage binary-long.
01 typ usage binary-long.
01 yes usage binary-long.
01 valid-flag usage binary-long.
linkage section.
01 req usage pointer.
01 ctx usage pointer.
01 res usage pointer.
procedure division using by value req ctx res.
 move function J-STR(req,'operation') to op
 call static 'j_get_into' using by value req by reference z'args' a end-call
 call static 'j_at_into' using by value a 0 by reference value-node end-call
 call static 'j_at_into' using by value a 1 by reference schema end-call
 call static 'j_get_into' using by value req by reference z'validationResults' previous-outcomes end-call
 call static 'j_clone_into' using by value previous-outcomes by reference outcomes end-call
 if outcomes = null call static 'j_object_into' using by reference outcomes end-call end-if
 call static 'j_get_into' using by value req by reference z'callbackResult' callback-result end-call
 if callback-result not = null
 call static 'j_boolean' using by value callback-result by reference z'ok' returning yes end-call
 if yes = 0
 call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
 move function J-STR(callback-result,'error') to text-value
 call static 'j_set_string' using by value res by reference z'error' text-value by value function length(function trim(text-value)) end-call
 call static 'j_delete' using by value outcomes end-call goback end-if
 call static 'j_get_into' using by value callback-result by reference z'value' temp end-call
 call static 'h_truthy' using by value temp returning yes end-call
 move function J-STR(req,'pendingKey') to key-text
 call static 'j_set_boolean' using by value outcomes by reference function concatenate(function trim(key-text),x'00') by value yes end-call end-if
 call static 'j_object_into' using by reference out-node end-call
 call static 'j_array_into' using by reference errors end-call
 call static 'j_type' using by value value-node by reference x'00' returning typ end-call
 evaluate op
 when 'validation.validateSaveData'
 if typ not = 5
 move 'Save data must be an object' to message-text perform add-error
 else
 call static 'j_has' using by value value-node by reference z'state' returning yes end-call
 call static 'j_has' using by value value-node by reference z'version' returning valid-flag end-call
 if yes = 0 or valid-flag = 0
 move 'Save data missing required properties' to message-text perform add-error end-if
 call static 'j_get_into' using by value value-node by reference z'state' prop end-call
 call static 'h_truthy' using by value prop returning yes end-call
 call static 'j_type' using by value prop by reference x'00' returning typ end-call
 if yes = 1 and (typ not = 5)
 move 'Invalid state property' to message-text perform add-error end-if
 call static 'j_get_into' using by value value-node by reference z'version' prop end-call
 call static 'h_truthy' using by value prop returning yes end-call
 call static 'j_type' using by value prop by reference x'00' returning typ end-call
 call static 'h_nonempty' using by value prop returning valid-flag end-call
 if yes = 1 and (typ not = 3 or valid-flag = 0)
 move 'Invalid version property' to message-text perform add-error end-if
 call static 'j_get_into' using by value value-node by reference z'state.resources' prop end-call
 call static 'h_truthy' using by value prop returning yes end-call
 call static 'j_type' using by value prop by reference x'00' returning typ end-call
 if yes = 1 and (typ not = 5)
 move 'Invalid resources property' to message-text perform add-error end-if
 call static 'j_get_into' using by value value-node by reference z'state.gameSettings' prop end-call
 call static 'h_truthy' using by value prop returning yes end-call
 call static 'j_type' using by value prop by reference x'00' returning typ end-call
 if yes = 1 and (typ not = 5)
 move 'Invalid gameSettings property' to message-text perform add-error end-if
 end-if
 when 'validation.validateObject'
 if typ not = 5
 move '[not an object]' to message-text perform add-error
 else
 call static 'j_size' using by value schema by reference x'00' returning cnt end-call
 perform varying i from 0 by 1 until i >= cnt
 call static 'j_at_into' using by value schema i by reference child end-call
 call static 'j_key' using by value child by reference key-text by value 256 end-call
 call static 'j_get_into' using by value value-node by reference function concatenate(function trim(key-text),x'00') prop end-call
 if prop = null move key-text to message-text perform add-error
 else
 move function J-STR(child,'$callback') to token-text
 if token-text not = spaces
 call static 'j_has' using by value outcomes by reference function concatenate(function trim(key-text),x'00') returning yes end-call
 if yes = 0
 call static 'j_object_into' using by reference command-node end-call
 call static 'j_set_string' using by value command-node by reference z'kind' z'callback' by value 8 end-call
 call static 'j_set_string' using by value command-node by reference z'id' token-text by value function length(function trim(token-text)) end-call
 call static 'j_array_into' using by reference item end-call
 call static 'j_clone_into' using by value prop by reference temp end-call
 call static 'j_append' using by value item temp end-call
 call static 'j_set' using by value command-node by reference z'args' by value item end-call
 call static 'j_array_into' using by reference commands end-call
 call static 'j_append' using by value commands command-node end-call
 call static 'j_set' using by value res by reference z'commands' by value commands end-call
 call static 'j_object_into' using by reference continuation end-call
 call static 'j_set_string' using by value continuation by reference z'operation' z'validation.validateObject' by value 25 end-call
 call static 'j_clone_into' using by value a by reference temp end-call
 call static 'j_set' using by value continuation by reference z'args' by value temp end-call
 call static 'j_set' using by value continuation by reference z'validationResults' by value outcomes end-call
 call static 'j_set_string' using by value continuation by reference z'pendingKey' key-text by value function length(function trim(key-text)) end-call
 call static 'j_set' using by value res by reference z'continuation' by value continuation end-call
 call static 'j_delete' using by value out-node end-call call static 'j_delete' using by value errors end-call goback
 end-if
 call static 'j_boolean' using by value outcomes by reference function concatenate(function trim(key-text),x'00') returning yes end-call
 if yes = 0 move key-text to message-text perform add-error end-if
 else
 move function J-STR(child,' ') to text-value
 if text-value = spaces move function J-STR(child,'operation') to text-value end-if
 if text-value(1:11) not = 'validation.'
 call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
 call static 'j_set_string' using by value res by reference z'error' z'Schema validators require a validation operation descriptor' by value 59 end-call
 call static 'j_delete' using by value out-node end-call call static 'j_delete' using by value errors end-call call static 'j_delete' using by value outcomes end-call goback end-if
 call static 'j_object_into' using by reference inner-req end-call
 call static 'j_object_into' using by reference inner-res end-call
 call static 'j_set_string' using by value inner-req by reference z'operation' text-value by value function length(function trim(text-value)) end-call
 call static 'j_array_into' using by reference item end-call
 call static 'j_clone_into' using by value prop by reference temp end-call
 call static 'j_append' using by value item temp end-call
 call static 'j_set' using by value inner-req by reference z'args' by value item end-call
 call static 'BUFO-SERVICES' using by value inner-req ctx inner-res end-call
 call static 'j_boolean' using by value inner-res by reference z'result' returning yes end-call
 if yes = 0 move key-text to message-text perform add-error end-if
 call static 'j_delete' using by value inner-req end-call call static 'j_delete' using by value inner-res end-call end-if end-if end-perform end-if
 when other
 call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
 call static 'j_delete' using by value out-node end-call call static 'j_delete' using by value errors end-call call static 'j_delete' using by value outcomes end-call goback
 end-evaluate
 call static 'j_size' using by value errors by reference x'00' returning cnt end-call
 move 0 to yes if cnt = 0 move 1 to yes end-if
 call static 'j_set_boolean' using by value out-node by reference z'isValid' by value yes end-call
 if op = 'validation.validateObject' move 'invalidProps' to key-text else move 'errors' to key-text end-if
 call static 'j_set' using by value out-node by reference function concatenate(function trim(key-text),x'00') by value errors end-call
 call static 'j_set' using by value res by reference z'result' by value out-node end-call
 call static 'j_delete' using by value outcomes end-call goback.
add-error.
 call static 'j_object_into' using by reference temp end-call
 call static 'j_set_string' using by value temp by reference z'message' message-text by value function length(function trim(message-text)) end-call
 call static 'j_get_into' using by value temp by reference z'message' item end-call
 call static 'j_clone_into' using by value item by reference item end-call
 call static 'j_append' using by value errors item end-call
 call static 'j_delete' using by value temp end-call.
end program BUFO-VALIDATION-SERVICES.
