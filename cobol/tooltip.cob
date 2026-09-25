 identification division.
 program-id. BUFO-TOOLTIP.
 environment division.
 configuration section.
 repository. function J-NUM function J-STR function all intrinsic.
 data division.
 local-storage section.
 copy 'ui-library-vars.cpy' .
 01 state-node usage pointer.
 01 owned-target usage pointer.
 01 callback-args usage pointer.
 01 viewport usage pointer.
 01 rectangle usage pointer.
 01 mouse-x usage comp-2.
 01 mouse-y usage comp-2.
 01 width-value usage comp-2.
 01 height-value usage comp-2.
 01 timer-name pic x(256).
 01 callback-operation pic x(64).
 linkage section.
 01 req usage pointer.
 01 ctx usage pointer.
 01 res usage pointer.
 procedure division using by value req ctx res.
 perform read-request
 call static 'j_get_into' using by value lib by reference z'tooltip' state-node end-call
 if state-node = null call static 'j_object_into' using by reference state-node end-call
 call static 'j_set' using by value lib by reference z'tooltip' by value state-node end-call end-if
 call static 'j_get_into' using by value state-node by reference z'element' target end-call
 evaluate op
 when 'tooltip.showTooltip'
 move function J-NUM(a(2),'clientX') to mouse-x move function J-NUM(a(2),'clientY') to mouse-y
 perform store-mouse
 call static 'j_clone_into' using by value a(1) by reference temp end-call
 call static 'j_set' using by value state-node by reference z'content' by value temp end-call
 move 'cancel' to kind perform new-command
 move 'id' to key-text move 'tooltip-show' to value-text perform command-string
 perform run-command
 move 'tooltip-show' to timer-name move 'tooltip.display' to callback-operation move 300 to number-value
 move null to child perform schedule
 when 'tooltip.cancelTooltip'
 move 'cancel' to kind perform new-command
 move 'id' to key-text move 'tooltip-show' to value-text perform command-string
 perform run-command
 when 'tooltip.hideTooltip' perform hide-tooltip
 when 'tooltip.updateTooltipPosition'
 move function J-NUM(a(1),'clientX') to mouse-x move function J-NUM(a(1),'clientY') to mouse-y
 perform store-mouse
 when 'tooltip.movement'
 call static 'j_boolean' using by value state-node by reference z'active' returning yes end-call
 if yes = 1
 move function J-NUM(a(1),'clientX') to mouse-x move function J-NUM(a(1),'clientY') to mouse-y
 compute x = function abs(mouse-x - function J-NUM(state-node,'x'))
 compute y = function abs(mouse-y - function J-NUM(state-node,'y'))
 if x > 5 or y > 5 perform hide-tooltip end-if end-if
 when 'tooltip.remove'
 move a(1) to target
 move 'remove' to kind perform new-command perform run-command
 move 'release' to kind perform new-command perform run-command
 when 'tooltip.visible'
 move a(1) to target
 perform add-visible
 when 'tooltip.display'
 perform hide-tooltip
 move null to target
 move 'create' to kind perform new-command
 move 'tag' to key-text move 'div' to value-text perform command-string
 perform run-command
 call static 'j_clone_into' using by value answer by reference owned-target end-call
 move owned-target to target
 call static 'j_clone_into' using by value target by reference temp end-call
 call static 'j_set' using by value state-node by reference z'element' by value temp end-call
 move 'attribute' to kind perform new-command
 move 'name' to key-text move 'id' to value-text perform command-string
 move 'value' to key-text move 'game-tooltip' to value-text perform command-string
 perform run-command
 move 'attribute' to kind perform new-command
 move 'name' to key-text move 'class' to value-text perform command-string
 move 'value' to key-text move 'game-tooltip' to value-text perform command-string
 perform run-command
 move function J-STR(state-node,'content') to html perform set-html
 move function J-NUM(state-node,'x') to mouse-x move function J-NUM(state-node,'y') to mouse-y
 compute x = mouse-x + 15 compute y = mouse-y + 15 perform set-position
 call static 'j_parse_into' using by reference z'{"$element":"body"}' by value 19 by reference target end-call
 move 'append' to kind perform new-command
 move 'child' to key-text move owned-target to item perform command-value
 perform run-command
 call static 'j_delete' using by value target end-call move owned-target to target
 move 'rect' to kind perform new-command
 perform run-command
 call static 'j_clone_into' using by value answer by reference rectangle end-call
 move 'viewport' to kind perform new-command
 perform run-command
 move function J-NUM(rectangle,'width') to width-value
 move function J-NUM(rectangle,'height') to height-value
 if function J-NUM(rectangle,'right') > function J-NUM(answer,'width') compute x = mouse-x - width-value - 15 end-if
 if function J-NUM(rectangle,'bottom') > function J-NUM(answer,'height') compute y = mouse-y - height-value - 15 end-if
 perform set-position
 call static 'j_delete' using by value rectangle end-call
 move 'tooltip-visible' to timer-name move 'tooltip.visible' to callback-operation move 10 to number-value move target to child perform schedule
 call static 'j_set_boolean' using by value state-node by reference z'active' by value 1 end-call
 call static 'j_parse_into' using by reference z'{"$element":"document"}' by value 23 by reference target end-call
 call static 'j_parse_into' using by reference z'{"operation":"tooltip.movement","args":[]}' by value 42 by reference callback-node end-call
 move 'listen' to kind perform new-command
 move 'id' to key-text move 'tooltip-movement' to value-text perform command-string
 move 'event' to key-text move 'mousemove' to value-text perform command-string
 move 'callback' to key-text move callback-node to item perform command-value
 perform run-command
 call static 'j_delete' using by value callback-node end-call
 call static 'j_delete' using by value target end-call
 call static 'j_delete' using by value owned-target end-call
 when other
 call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
 call static 'j_set_string' using by value res by reference z'error' z'Unknown tooltip operation' by value 25 end-call
 end-evaluate
 perform finish-result goback.
 store-mouse.
 call static 'j_set_number' using by value state-node by reference z'x' mouse-x end-call
 call static 'j_set_number' using by value state-node by reference z'y' mouse-y end-call.
 set-position.
 call static 'h_decimal' using by reference x by value 8 0 1 by reference formatted by value 256 end-call
 move function concatenate(function trim(formatted),'px') to text-value move 'left' to value-text perform set-style
 call static 'h_decimal' using by reference y by value 8 0 1 by reference formatted by value 256 end-call
 move function concatenate(function trim(formatted),'px') to text-value move 'top' to value-text perform set-style.
 add-visible.
 call static 'j_parse_into' using by reference z'["visible"]' by value 11 by reference list-node end-call
 move 'class' to kind perform new-command
 move 'action' to key-text move 'add' to value-text perform command-string
 move 'names' to key-text move list-node to item perform command-value
 perform run-command
 call static 'j_delete' using by value list-node end-call.
 hide-tooltip.
 move 'unlisten' to kind perform new-command
 move 'id' to key-text move 'tooltip-movement' to value-text perform command-string
 perform run-command
 move 'cancel' to kind perform new-command
 move 'id' to key-text move 'tooltip-show' to value-text perform command-string
 perform run-command
 call static 'j_set_boolean' using by value state-node by reference z'active' by value 0 end-call
 if target not = null
 call static 'j_parse_into' using by reference z'["visible"]' by value 11 by reference list-node end-call
 move 'class' to kind perform new-command
 move 'action' to key-text move 'remove' to value-text perform command-string
 move 'names' to key-text move list-node to item perform command-value
 perform run-command
 call static 'j_delete' using by value list-node end-call
 perform next-id move id-text to timer-name move 'tooltip.remove' to callback-operation move 300 to number-value move target to child perform schedule
 end-if.
 schedule.
 call static 'j_object_into' using by reference callback-node end-call
 call static 'j_set_string' using by value callback-node by reference z'operation' callback-operation by value function length(function trim(callback-operation)) end-call
 call static 'j_array_into' using by reference callback-args end-call
 if child not = null
 call static 'j_clone_into' using by value child by reference temp end-call
 call static 'j_append' using by value callback-args temp end-call end-if
 call static 'j_set' using by value callback-node by reference z'args' by value callback-args end-call
 move 'schedule' to kind perform new-command
 move 'id' to key-text move timer-name to value-text perform command-string
 move 'callback' to key-text move callback-node to item perform command-value
 call static 'j_set_number' using by value command by reference z'delay' number-value end-call
 perform run-command
 call static 'j_delete' using by value callback-node end-call.
 copy 'ui-library-procedures.cpy' .
 end program BUFO-TOOLTIP.
