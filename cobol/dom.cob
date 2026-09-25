 identification division.
 program-id. BUFO-DOM recursive.
 environment division.
 configuration section.
 repository. function J-NUM function J-STR function all intrinsic.
 data division.
 local-storage section.
 copy 'ui-library-vars.cpy' .
 01 content-node usage pointer.
 01 saved-target usage pointer.
 01 entries usage pointer.
 01 saved-list usage pointer.
 01 index2 usage binary-long.
 01 size2 usage binary-long.
 01 event-name pic x(256).
 01 loads usage pointer.
 01 load-node usage pointer.
 01 callback-args usage pointer.
 01 nested-request usage pointer.
 01 nested-response usage pointer.
 01 load-id pic x(256).
 01 listener-name pic x(256).
 01 fallback-flag usage binary-long.
 01 load-index usage binary-long.

 linkage section.
 01 req usage pointer.
 01 ctx usage pointer.
 01 res usage pointer.
 procedure division using by value req ctx res.
 perform read-request
 move a(1) to target
 evaluate op
 when 'dom.focus'
 move 'focus' to kind perform new-command perform run-command
 when 'dom.createElement'
 move null to target
 move 'create' to kind perform new-command
 move 'tag' to key-text move s(1) to value-text perform command-string
 perform run-command
 call static 'j_clone_into' using by value answer by reference saved-target end-call
 move saved-target to target
 move a(2) to options-node
 move function J-STR(options-node,'id') to value-text
 if value-text not = spaces
 move 'attribute' to kind perform new-command
 move 'name' to key-text move 'id' to value-text perform command-string
 move 'value' to key-text move function J-STR(options-node,'id') to value-text perform command-string
 perform run-command
 end-if
 call static 'j_get_into' using by value options-node by reference z'classes' entries end-call
 call static 'j_type' using by value entries by reference x'00' returning typ end-call
 if typ = 3
 call static 'j_array_into' using by reference list-node end-call
 call static 'j_clone_into' using by value entries by reference temp end-call
 call static 'j_append' using by value list-node temp end-call
 else call static 'j_clone_into' using by value entries by reference list-node end-call end-if
 if list-node not = null
 move 'class' to kind perform new-command
 move 'action' to key-text move 'add' to value-text perform command-string
 move 'names' to key-text move list-node to item perform command-value
 perform run-command
 call static 'j_delete' using by value list-node end-call end-if
 call static 'j_get_into' using by value options-node by reference z'attributes' entries end-call
 call static 'j_size' using by value entries by reference x'00' returning cnt end-call
 perform varying i from 0 by 1 until i >= cnt
 call static 'j_at_into' using by value entries i by reference child end-call
 call static 'j_key' using by value child by reference event-name by value 256 end-call
 move 'attribute' to kind perform new-command
 move 'name' to key-text move event-name to value-text perform command-string
 move 'value' to key-text move child to item perform command-value
 perform run-command
 end-perform
 call static 'j_get_into' using by value options-node by reference z'content' content-node end-call
 if content-node not = null perform set-content end-if
 call static 'j_get_into' using by value options-node by reference z'events' entries end-call
 perform listeners
 call static 'j_get_into' using by value options-node by reference z'parent' target end-call
 if target not = null
 move 'append' to kind perform new-command
 move 'child' to key-text move saved-target to item perform command-value
 perform run-command
 end-if
 move saved-target to result-node
 when 'dom.addClass'
 if target not = null and b(2) = 1
 call static 'j_array_into' using by reference list-node end-call
 call static 'j_clone_into' using by value a(2) by reference temp end-call
 call static 'j_append' using by value list-node temp end-call
 move 'class' to kind perform new-command
 move 'action' to key-text move 'add' to value-text perform command-string
 move 'names' to key-text move list-node to item perform command-value
 perform run-command
 call static 'j_delete' using by value list-node end-call end-if
 move a(1) to item perform return-value
 when 'dom.removeClass'
 if target not = null and b(2) = 1
 call static 'j_array_into' using by reference list-node end-call
 call static 'j_clone_into' using by value a(2) by reference temp end-call
 call static 'j_append' using by value list-node temp end-call
 move 'class' to kind perform new-command
 move 'action' to key-text move 'remove' to value-text perform command-string
 move 'names' to key-text move list-node to item perform command-value
 perform run-command
 call static 'j_delete' using by value list-node end-call end-if
 move a(1) to item perform return-value
 when 'dom.toggleClass'
 if target not = null and b(2) = 1
 call static 'j_array_into' using by reference list-node end-call
 call static 'j_clone_into' using by value a(2) by reference temp end-call
 call static 'j_append' using by value list-node temp end-call
 move 'class' to kind perform new-command
 move 'action' to key-text move 'toggle' to value-text perform command-string
 move 'names' to key-text move list-node to item perform command-value
 if a(3) not = null
 move 'force' to key-text move a(3) to item perform command-value
 end-if
 perform run-command
 call static 'j_delete' using by value list-node end-call end-if
 move a(1) to item perform return-value
 when 'dom.setContent'
 move a(2) to content-node perform set-content
 move a(1) to item perform return-value
 when 'dom.addEventListeners'
 move a(2) to entries perform listeners
 move a(1) to item perform return-value
 when 'dom.querySelector'
 move a(2) to target
 move 'query' to kind perform new-command
 move 'selector' to key-text move s(1) to value-text perform command-string
 perform run-command
 perform return-answer
 when 'dom.querySelectorAll'
 move a(2) to target
 move 'queryAll' to kind perform new-command
 move 'selector' to key-text move s(1) to value-text perform command-string
 perform run-command
 perform return-answer
 when 'dom.removeElement'
 move 'remove' to kind perform new-command
 perform run-command
 when 'dom.setVisible'
 move 'display' to value-text move spaces to text-value
 if b(2) = 0 move 'none' to text-value end-if
 perform set-style
 move a(1) to item perform return-value
 when 'styles.loadStylesheet' when 'styles.initializeStyles'
 perform next-id move id-text to load-id
 call static 'j_get_into' using by value lib by reference z'styleLoads' loads end-call
 if loads = null call static 'j_object_into' using by reference loads end-call
 call static 'j_set' using by value lib by reference z'styleLoads' by value loads end-call end-if
 call static 'j_object_into' using by reference load-node end-call
 call static 'j_set' using by value loads by reference function concatenate(function trim(load-id),x'00') by value load-node end-call
 move null to target
 move 'create' to kind perform new-command move 'tag' to key-text move 'link' to value-text perform command-string perform run-command
 call static 'j_clone_into' using by value answer by reference saved-target end-call move saved-target to target
 call static 'j_clone_into' using by value target by reference temp end-call
 call static 'j_set' using by value load-node by reference z'element' by value temp end-call
 move 'attribute' to kind perform new-command move 'name' to key-text move 'rel' to value-text perform command-string
 move 'value' to key-text move 'stylesheet' to value-text perform command-string perform run-command
 move 'attribute' to kind perform new-command move 'name' to key-text move 'href' to value-text perform command-string
 move 'value' to key-text move s(1) to value-text if op = 'styles.initializeStyles' move './styles/index.css' to value-text end-if
 call static 'j_set_string' using by value load-node by reference z'path' value-text by value function length(function trim(value-text)) end-call
 perform command-string perform run-command
 move 0 to fallback-flag if op = 'styles.initializeStyles' move 1 to fallback-flag end-if
 call static 'j_set_boolean' using by value load-node by reference z'fallback' by value fallback-flag end-call
 perform varying load-index from 0 by 1 until load-index > 1
 call static 'j_object_into' using by reference callback-node end-call
 call static 'j_set_string' using by value callback-node by reference z'operation' z'styles.complete' by value 15 end-call
 call static 'j_array_into' using by reference callback-args end-call
 call static 'j_object_into' using by reference temp end-call
 call static 'j_set_string' using by value temp by reference z'id' load-id by value function length(function trim(load-id)) end-call
 call static 'j_set_boolean' using by value temp by reference z'success' by value load-index end-call
 call static 'j_append' using by value callback-args temp end-call
 call static 'j_set' using by value callback-node by reference z'args' by value callback-args end-call
 move 'error' to event-name if load-index = 1 move 'load' to event-name end-if
 move function concatenate(function trim(load-id),'/',function trim(event-name)) to listener-name
 move 'listen' to kind perform new-command move 'id' to key-text move listener-name to value-text perform command-string
 move 'event' to key-text move event-name to value-text perform command-string
 move 'callback' to key-text move callback-node to item perform command-value perform run-command
 call static 'j_delete' using by value callback-node end-call end-perform
 perform append-head
 call static 'j_delete' using by value saved-target end-call
 call static 'j_object_into' using by reference result-node end-call
 call static 'j_set_string' using by value result-node by reference z'$promise' load-id by value function length(function trim(load-id)) end-call
 when 'styles.complete'
 move function J-STR(a(1),'id') to load-id
 call static 'j_get_into' using by value lib by reference z'styleLoads' loads end-call
 call static 'j_get_into' using by value loads by reference function concatenate(function trim(load-id),x'00') load-node end-call
 if load-node not = null
 call static 'j_boolean' using by value a(1) by reference z'success' returning yes end-call
 call static 'j_boolean' using by value load-node by reference z'fallback' returning fallback-flag end-call
 if yes = 0 and fallback-flag = 1
 call static 'j_object_into' using by reference nested-request end-call
 call static 'j_object_into' using by reference nested-response end-call
 call static 'j_set_string' using by value nested-request by reference z'operation' z'styles.fallback' by value 15 end-call
 call static 'BUFO-DOM' using by value nested-request ctx nested-response end-call
 call static 'j_delete' using by value nested-request end-call call static 'j_delete' using by value nested-response end-call end-if
 perform varying load-index from 0 by 1 until load-index > 1
 move 'error' to event-name if load-index = 1 move 'load' to event-name end-if
 move function concatenate(function trim(load-id),'/',function trim(event-name)) to listener-name
 move 'unlisten' to kind perform new-command move 'id' to key-text move listener-name to value-text perform command-string perform run-command end-perform
 call static 'j_array_into' using by reference list-node end-call
 call static 'j_set' using by value res by reference z'commands' by value list-node end-call
 call static 'j_object_into' using by reference temp end-call
 call static 'j_set_string' using by value temp by reference z'id' load-id by value function length(function trim(load-id)) end-call
 if yes = 1 or fallback-flag = 1
 call static 'j_set_string' using by value temp by reference z'kind' z'resolve' by value 7 end-call
 if fallback-flag = 0
 call static 'j_get_into' using by value load-node by reference z'element' item end-call
 call static 'j_clone_into' using by value item by reference item end-call
 call static 'j_set' using by value temp by reference z'value' by value item end-call
 else call static 'j_set_null' using by value temp by reference z'value' end-call end-if
 else
 call static 'j_set_string' using by value temp by reference z'kind' z'reject' by value 6 end-call
 move function concatenate('Failed to load stylesheet: ',function trim(function J-STR(load-node,' path'))) to text-value
 call static 'j_set_string' using by value temp by reference z'error' text-value by value function length(function trim(text-value)) end-call end-if
 call static 'j_append' using by value list-node temp end-call
 call static 'j_remove' using by value loads by reference function concatenate(function trim(load-id),x'00') end-call end-if
 when 'styles.addStyles' when 'styles.fallback'
 move null to target move 'create' to kind perform new-command move 'tag' to key-text move 'style' to value-text perform command-string perform run-command
 call static 'j_clone_into' using by value answer by reference saved-target end-call move saved-target to target
 move s(1) to text-value
 if op = 'styles.fallback' move function concatenate( '.three-column-layout{display:flex;gap:16px;width:100%}.column{flex:1;display:flex;flex-direction:column;gap:16px}.game-tooltip{position:abso' ,
 'lute;z-index:100;background:#111;color:white;padding:16px;max-width:300px;pointer-events:none}@media(max-width:1024px){.three-column-layout{' , 'flex-direction:column}}' ) to text-value end-if
 perform set-text
 if b(2) = 1 or op = 'styles.fallback'
 move 'attribute' to kind perform new-command move 'name' to key-text move 'id' to value-text perform command-string
 move 'value' to key-text move s(2) to value-text if op = 'styles.fallback' move 'critical-fallback-styles' to value-text end-if perform command-string perform run-command end-if
 perform append-head move saved-target to result-node
 when 'styles.cleanupStyles'
 move null to target move 'queryAll' to kind perform new-command
 move 'selector' to key-text move 'style[id^="dynamic-"]' to value-text perform command-string perform run-command
 call static 'j_clone_into' using by value answer by reference saved-list end-call
 call static 'j_size' using by value saved-list by reference x'00' returning cnt end-call
 perform varying i from 0 by 1 until i >= cnt
 call static 'j_at_into' using by value saved-list i by reference target end-call
 move 'remove' to kind perform new-command perform run-command end-perform
 call static 'j_delete' using by value saved-list end-call
 when other
 call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
 call static 'j_set_string' using by value res by reference z'error' z'Unknown DOM operation' by value 21 end-call
 end-evaluate
 perform finish-result goback.
 set-content.
 move 'html' to kind perform new-command
 move 'value' to key-text move spaces to value-text perform command-string
 perform run-command
 call static 'j_type' using by value content-node by reference x'00' returning typ end-call
 evaluate typ
 when 3
 move 'text' to kind perform new-command
 move 'value' to key-text move content-node to item perform command-value
 perform run-command
 when 4
 call static 'j_size' using by value content-node by reference x'00' returning size2 end-call
 perform varying index2 from 0 by 1 until index2 >= size2
 call static 'j_at_into' using by value content-node index2 by reference child end-call
 move 'append' to kind perform new-command
 move 'child' to key-text move child to item perform command-value
 perform run-command
 end-perform
 when 5
 move 'append' to kind perform new-command
 move 'child' to key-text move content-node to item perform command-value
 perform run-command
 end-evaluate.
 listeners.
 call static 'j_size' using by value entries by reference x'00' returning size2 end-call
 perform varying index2 from 0 by 1 until index2 >= size2
 call static 'j_at_into' using by value entries index2 by reference child end-call
 call static 'j_key' using by value child by reference event-name by value 256 end-call
 perform next-id
 move 'listen' to kind perform new-command
 move 'id' to key-text move id-text to value-text perform command-string
 move 'event' to key-text move event-name to value-text perform command-string
 move 'callback' to key-text move child to item perform command-value
 perform run-command
 end-perform.
 append-head.
 call static 'j_parse_into' using by reference z'{"$element":"head"}' by value 19 by reference target end-call
 move 'append' to kind perform new-command move 'child' to key-text move saved-target to item perform command-value perform run-command
 call static 'j_delete' using by value target end-call.

 copy 'ui-library-procedures.cpy' .
 end program BUFO-DOM.
