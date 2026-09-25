 read-request.
 move function J-STR(req,'operation') to op
 move function J-NUM(req,'now') to now-ms
 call static 'j_get_into' using by value req by reference z'args' args end-call
 perform varying i from 1 by 1 until i > 8
 compute j = i - 1
 call static 'j_at_into' using by value args j by reference a(i) end-call
 move function J-STR(a(i),' ') to s(i)
 move function J-NUM(a(i),' ') to n(i)
 call static 'h_truthy' using by value a(i) returning b(i) end-call
 end-perform
 call static 'j_get_into' using by value ctx by reference z'uiLibrary' lib end-call
 if lib = null
 call static 'j_object_into' using by reference lib end-call
 call static 'j_set' using by value ctx by reference z'uiLibrary' by value lib end-call end-if
 call static 'j_set_boolean' using by value res by reference z'ok' by value 1 end-call.
 new-command.
 call static 'j_object_into' using by reference command end-call
 call static 'j_set_string' using by value command by reference z'kind' kind
 by value function length(function trim(kind)) end-call
 if target not = null
 call static 'j_clone_into' using by value target by reference temp end-call
 call static 'j_set' using by value command by reference z'element' by value temp end-call end-if.
 command-string.
 call static 'j_set_string' using by value command
 by reference function concatenate(function trim(key-text),x'00') value-text
 by value function length(function trim(value-text trailing)) end-call.
 command-number.
 call static 'j_set_number' using by value command
 by reference function concatenate(function trim(key-text),x'00') number-value end-call.
 command-value.
 call static 'j_clone_into' using by value item by reference temp end-call
 call static 'j_set' using by value command
 by reference function concatenate(function trim(key-text),x'00') by value temp end-call.
 run-command.
 if kind = 'callback'
 call static 'j_set_string' using by value command by reference z'kind' z'domCallback' by value 11 end-call
 call static 'j_get_into' using by value res by reference z'commands' deferred-commands end-call
 if deferred-commands = null call static 'j_array_into' using by reference deferred-commands end-call
 call static 'j_set' using by value res by reference z'commands' by value deferred-commands end-call end-if
 call static 'j_append' using by value deferred-commands command end-call
 move null to command exit paragraph end-if
 if answer not = null call static 'j_delete' using by value answer end-call end-if
 call static 'h_dom' using by value req command by reference answer returning rc end-call
 if rc not = 0
 move 1 to failed
 call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
 move function J-STR(answer,'$error') to text-value
 call static 'j_set_string' using by value res by reference z'error' text-value
 by value function length(function trim(text-value trailing)) end-call end-if
 call static 'j_delete' using by value command end-call
 move null to command.
 return-answer.
 call static 'j_clone_into' using by value answer by reference result-node end-call.
 return-value.
 call static 'j_clone_into' using by value item by reference result-node end-call.
 finish-result.
 if result-node = null call static 'j_parse_into' using by reference z'null' by value 4 by reference result-node end-call end-if
 call static 'j_set' using by value res by reference z'result' by value result-node end-call
 if answer not = null call static 'j_delete' using by value answer end-call end-if.
 next-id.
 move function J-NUM(lib,'sequence') to number-value add 1 to number-value
 call static 'j_set_number' using by value lib by reference z'sequence' number-value end-call
 call static 'h_decimal' using by reference number-value by value 0 0 0 by reference formatted by value 256 end-call
 move function concatenate('ui-',function trim(formatted)) to id-text.
 set-style.
 move 'style' to kind perform new-command
 move 'name' to key-text perform command-string
 move 'value' to key-text move text-value to value-text perform command-string
 perform run-command.
 set-html.
 move 'html' to kind perform new-command
 if morph-html = 1 call static 'j_set_boolean' using by value command by reference z'morph' by value 1 end-call end-if
 call static 'j_set_string' using by value command by reference z'value' html
 by value function length(function trim(html trailing)) end-call
 perform run-command.
 set-text.
 move 'text' to kind perform new-command
 move 'value' to key-text move text-value to value-text perform command-string
 perform run-command.
