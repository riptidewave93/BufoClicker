 identification division.
 program-id. BUFO-ANIMATION.
 environment division.
 configuration section.
 repository. function J-NUM function J-STR function all intrinsic.
 data division.
 local-storage section.
 copy 'ui-library-vars.cpy' .
 01 easing-request usage pointer.
01 easing-args usage pointer.
01 easing-item usage pointer.
01 registry usage pointer.
 01 anim usage pointer.
 01 handle-node usage pointer.
 01 props usage pointer.
 01 prop usage pointer.
 01 input-props usage pointer.
 01 callback-args usage pointer.
 01 mode-name pic x(64).
 01 easing pic x(64).
 01 unit-text pic x(128).
 01 prop-name pic x(256).
 01 transform-text pic x(1024).
 01 timer-id pic x(256).
 01 t usage comp-2.
 01 eased usage comp-2.
 01 elapsed usage comp-2.
 01 duration usage comp-2.
 01 initial-value usage comp-2.
 01 target-value usage comp-2.
 01 current-value usage comp-2.
 01 scale-value usage comp-2.
 01 frame-index usage binary-long.
 01 decs usage binary-long.
 01 complete-flag usage binary-long.
 linkage section.
 01 req usage pointer.
 01 ctx usage pointer.
 01 res usage pointer.
 procedure division using by value req ctx res.
 perform read-request
 call static 'j_has' using by value req by reference z'monotonicNow' returning yes end-call
 if yes = 1 move function J-NUM(req,'monotonicNow') to now-ms end-if
 if op(1:17) = 'animation.Easing.' or op(1:17) = 'animation.easing.'
 move op(18:) to easing move n(1) to t perform ease-value
 call static 'j_set_number' using by value res by reference z'result' eased end-call goback end-if
 call static 'j_get_into' using by value lib by reference z'animations' registry end-call
 if registry = null call static 'j_object_into' using by reference registry end-call
 call static 'j_set' using by value lib by reference z'animations' by value registry end-call end-if
 if op = 'animation.frame' or op = 'animation.cancel' or op = 'animation.finish' or op = 'animation.eased'
 move function J-STR(a(1),'$animation') to id-text
 if id-text = spaces move s(1) to id-text end-if
 call static 'j_get_into' using by value registry by reference function concatenate(function trim(id-text),x'00') anim end-call
 if anim = null perform finish-result goback end-if
 call static 'j_get_into' using by value anim by reference z'element' target end-call
 move function J-STR(anim,'mode') to mode-name
 if op = 'animation.cancel' or op = 'animation.finish'
 perform finish-animation
 else
 move function J-NUM(a(2),'now') to now-ms perform animation-frame end-if
 perform finish-result goback end-if
 move op(11:) to mode-name
 move a(1) to target move a(2) to options-node
 if mode-name = 'animate' move null to target move a(3) to options-node end-if
 if mode-name not = 'animate' and target = null
 call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
 call static 'j_set_string' using by value res by reference z'error' z'Element is required' by value 19 end-call
 perform finish-result goback end-if
 if mode-name = 'pulse'
 move 'getAttribute' to kind perform new-command
 move 'name' to key-text move 'data-animating' to value-text perform command-string
 perform run-command
 if function J-STR(answer,' ') = ' true' perform finish-result goback end-if end-if
 perform next-id
 call static 'j_object_into' using by reference anim end-call
 call static 'j_set' using by value registry by reference function concatenate(function trim(id-text),x'00') by value anim end-call
 move mode-name to text-value
 call static 'j_set_string' using by value anim by reference z'mode' text-value by value function length(function trim(text-value trailing)) end-call
 call static 'j_clone_into' using by value target by reference temp end-call
 call static 'j_set' using by value anim by reference z'element' by value temp end-call
 call static 'j_clone_into' using by value options-node by reference temp end-call
 call static 'j_set' using by value anim by reference z'options' by value temp end-call
 call static 'j_set_number' using by value anim by reference z'start' now-ms end-call
 move 300 to duration move 'easeInOut' to easing
 evaluate mode-name
 when 'animate' move n(1) to duration move 'linear' to easing
 call static 'j_clone_into' using by value a(2) by reference temp end-call
 call static 'j_set' using by value anim by reference z'onProgress' by value temp end-call
 when 'animateElement'
 move function J-NUM(options-node,'duration') to duration if duration = 0 move 300 to duration end-if
 when 'fadeIn' when 'fadeOut' if a(2) not = null move n(2) to duration end-if
 when 'pulse' move 600 to duration if a(3) not = null move n(3) to duration end-if
 move 1.05 to scale-value if a(2) not = null move n(2) to scale-value end-if
 call static 'j_set_number' using by value anim by reference z'scale' scale-value end-call
 when 'shake' move 500 to duration if a(3) not = null move n(3) to duration end-if
 move 5 to scale-value if a(2) not = null move n(2) to scale-value end-if
 call static 'j_set_number' using by value anim by reference z'scale' scale-value end-call
 when other
 call static 'j_remove' using by value registry by reference function concatenate(function trim(id-text),x'00') end-call
 call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
 call static 'j_set_string' using by value res by reference z'error' z'Unknown animation operation' by value 27 end-call
 perform finish-result goback
 end-evaluate
 if mode-name = 'animate' or mode-name = 'animateElement'
 move function J-STR(options-node,'easing') to text-value
 if text-value not = spaces move text-value to easing end-if end-if
 move easing to text-value
 call static 'j_set_string' using by value anim by reference z'easing' text-value by value function length(function trim(text-value trailing)) end-call
 call static 'j_set_number' using by value anim by reference z'duration' duration end-call
 if mode-name = 'fadeIn'
 move 'opacity' to value-text move '0' to text-value perform set-style
 move 'display' to value-text move spaces to text-value perform set-style end-if
 if mode-name = 'fadeOut'
 move 1 to yes if a(3) not = null move b(3) to yes end-if
 call static 'j_set_boolean' using by value anim by reference z'hideAfter' by value yes end-call end-if
 if mode-name = 'shake'
 move 'getStyle' to kind perform new-command
 move 'name' to key-text move 'transform' to value-text perform command-string
 perform run-command
 call static 'j_clone_into' using by value answer by reference temp end-call
 call static 'j_set' using by value anim by reference z'originalTransform' by value temp end-call
 end-if
 if mode-name = 'pulse'
 move 'attribute' to kind perform new-command
 move 'name' to key-text move 'data-animating' to value-text perform command-string
 move 'value' to key-text move 'true' to value-text perform command-string
 perform run-command
 move 'transform' to value-text move spaces to text-value perform set-style
 compute number-value = duration + 300 move 'animation.finish' to text-value
 move function concatenate(function trim(id-text),'-failsafe') to timer-id
 perform schedule-delay end-if
 if mode-name = 'animateElement' or mode-name = 'fadeIn' or mode-name = 'fadeOut'
 perform prepare-properties end-if
 call static 'j_object_into' using by reference result-node end-call
 move id-text to text-value
 call static 'j_set_string' using by value result-node by reference z'$animation' text-value by value function length(function trim(text-value trailing)) end-call
 call static 'j_set_string' using by value result-node by reference z'$promise' text-value by value function length(function trim(text-value trailing)) end-call
 move id-text to timer-id
 move function J-NUM(options-node,'delay') to number-value
 if number-value > 0 and (mode-name = 'animate' or mode-name = 'animateElement' )
 move 'animation.frame' to text-value perform schedule-delay
 else if mode-name = 'shake' perform animation-frame else perform schedule-frame end-if end-if
 perform finish-result goback.
 prepare-properties.
 call static 'j_array_into' using by reference props end-call
 call static 'j_set' using by value anim by reference z'properties' by value props end-call
 if mode-name = 'animateElement'
 call static 'j_get_into' using by value options-node by reference z'properties' input-props end-call
 else
 call static 'j_object_into' using by reference input-props end-call
 move 1 to number-value if mode-name = 'fadeOut' move 0 to number-value end-if
 call static 'j_set_number' using by value input-props by reference z'opacity' number-value end-call end-if
 call static 'j_size' using by value input-props by reference x'00' returning cnt end-call
 perform varying i from 0 by 1 until i >= cnt
 call static 'j_at_into' using by value input-props i by reference child end-call
 call static 'j_key' using by value child by reference prop-name by value 256 end-call
 call static 'h_css_parse' using by value child by reference target-value unit-text by value 128 returning yes end-call
 if yes = 1
 move 'computed' to kind perform new-command
 move 'name' to key-text move prop-name to value-text perform command-string
 perform run-command
 call static 'h_css_parse' using by value answer by reference initial-value unit-text by value 128 returning yes end-call
 if yes = 1
 call static 'j_object_into' using by reference prop end-call
 move prop-name to text-value
 call static 'j_set_string' using by value prop by reference z'name' text-value by value function length(function trim(text-value trailing)) end-call
 move unit-text to text-value
 call static 'j_set_string' using by value prop by reference z'unit' text-value by value function length(function trim(text-value trailing)) end-call
 call static 'j_set_number' using by value prop by reference z'initial' initial-value end-call
 call static 'j_set_number' using by value prop by reference z'target' target-value end-call
 call static 'j_append' using by value props prop end-call end-if end-if end-perform
 if mode-name not = 'animateElement' call static 'j_delete' using by value input-props end-call end-if.
 animation-frame.
 move function J-NUM(anim,'duration') to duration
 compute elapsed = now-ms - function J-NUM(anim,'start')
 if duration <= 0 move 1 to t else compute t = function min(1,elapsed / duration) end-if
 move function J-STR(anim,'easing') to easing
 move 0 to complete-flag
 if t >= 1 move 1 to complete-flag end-if
 call static 'j_get_into' using by value anim by reference z'options.easing' callback-node end-call
 call static 'j_type' using by value callback-node by reference x'00' returning typ end-call
 if typ = 5
 if op = 'animation.eased'
 call static 'j_boolean' using by value req by reference z'callbackResult.ok' returning yes end-call
 if yes = 0 perform finish-animation exit paragraph end-if
 move function J-NUM(req,'callbackResult.value') to eased
 else
 move 'callback' to kind perform new-command move 'callback' to key-text move callback-node to item perform command-value
 call static 'j_set_number' using by value command by reference z'value' t end-call
 call static 'j_object_into' using by reference easing-request end-call
 call static 'j_set_string' using by value easing-request by reference z'operation' z'animation.eased' by value 15 end-call
 call static 'j_array_into' using by reference easing-args end-call
 call static 'j_clone_into' using by value a(1) by reference easing-item end-call
 call static 'j_append' using by value easing-args easing-item end-call
 call static 'j_clone_into' using by value a(2) by reference easing-item end-call
 call static 'j_append' using by value easing-args easing-item end-call
 call static 'j_set' using by value easing-request by reference z'args' by value easing-args end-call
 call static 'j_set' using by value command by reference z'continuation' by value easing-request end-call
 perform run-command exit paragraph end-if
 else perform ease-value end-if
 evaluate mode-name
 when 'animate'
 call static 'j_get_into' using by value anim by reference z'onProgress' callback-node end-call
 perform progress-callback
 when 'animateElement' when 'fadeIn' when 'fadeOut'
 call static 'j_get_into' using by value anim by reference z'properties' props end-call
 call static 'j_size' using by value props by reference x'00' returning cnt end-call
 perform varying i from 0 by 1 until i >= cnt
 call static 'j_at_into' using by value props i by reference prop end-call
 move function J-NUM(prop,'initial') to initial-value move function J-NUM(prop,'target') to target-value
 compute current-value = initial-value + (target-value - initial-value) * eased
 call static 'h_decimal' using by reference current-value by value 12 0 1 by reference formatted by value 256 end-call
 move function J-STR(prop,'unit') to unit-text
 move function concatenate(function trim(formatted),function trim(unit-text)) to text-value
 move function J-STR(prop,'name') to value-text perform set-style end-perform
 when 'pulse'
 move function J-NUM(anim,'scale') to scale-value
 if t < 0.5
 compute t = t * 2 move 'easeOut' to easing perform ease-value
 compute current-value = 1 + (scale-value - 1) * eased
 else compute t = (t - 0.5) * 2 move 'easeIn' to easing perform ease-value
 compute current-value = scale-value - (scale-value - 1) * eased end-if
 call static 'h_decimal' using by reference current-value by value 12 0 1 by reference formatted by value 256 end-call
 move function concatenate('scale(',function trim(formatted),')') to text-value
 move 'transform' to value-text perform set-style
 when 'shake'
 move 0 to complete-flag
 move function J-NUM(anim,'step') to frame-index
 if frame-index >= 6 move 1 to complete-flag
 else
 move function J-NUM(anim,'scale') to scale-value
 compute current-value = scale-value * (1 - frame-index / 6)
 if function mod(frame-index,2) = 1 compute current-value = 0 - current-value end-if
 call static 'h_decimal' using by reference current-value by value 12 0 1 by reference formatted by value 256 end-call
 move function J-STR(anim,'originalTransform') to transform-text
 move function concatenate(function trim(transform-text trailing),' translateX(',function trim(formatted),'px)') to text-value
 move 'transform' to value-text perform set-style
 compute number-value = frame-index + 1
 call static 'j_set_number' using by value anim by reference z'step' number-value end-call end-if
 end-evaluate
 call static 'j_get_into' using by value anim by reference z'options.onUpdate' callback-node end-call
 perform progress-callback
 if complete-flag = 1
 call static 'j_get_into' using by value anim by reference z'options.onComplete' callback-node end-call
 if callback-node not = null
 move 'callback' to kind perform new-command
 move 'callback' to key-text move callback-node to item perform command-value
 perform run-command
 end-if
 perform finish-animation
 else
 if mode-name = 'shake'
 compute number-value = duration / 6 move id-text to timer-id move 'animation.frame' to text-value perform schedule-delay
 else perform schedule-frame end-if end-if.
 progress-callback.
 if callback-node not = null
 move 'callback' to kind perform new-command
 move 'callback' to key-text move callback-node to item perform command-value
 call static 'j_set_number' using by value command by reference z'value' eased end-call
 perform run-command end-if.
 finish-animation.
 move 'cancel' to kind perform new-command
 move 'id' to key-text move id-text to value-text perform command-string
 perform run-command
 move 'cancel' to kind perform new-command
 move 'id' to key-text move function concatenate(function trim(id-text),'-failsafe') to value-text perform command-string
 perform run-command
 if mode-name = 'pulse'
 move 'transform' to value-text move spaces to text-value perform set-style
 move 'attribute' to kind perform new-command
 move 'name' to key-text move 'data-animating' to value-text perform command-string
 move 'value' to key-text move 'false' to value-text perform command-string
 perform run-command
 end-if
 if mode-name = 'shake'
 move function J-STR(anim,'originalTransform') to text-value move 'transform' to value-text perform set-style end-if
 if mode-name = 'fadeOut' and op not = 'animation.cancel'
 call static 'j_boolean' using by value anim by reference z'hideAfter' returning yes end-call
 if yes = 1 move 'display' to value-text move 'none' to text-value perform set-style end-if end-if
 call static 'j_get_into' using by value res by reference z'commands' list-node end-call
 if list-node = null call static 'j_array_into' using by reference list-node end-call
 call static 'j_set' using by value res by reference z'commands' by value list-node end-call end-if
 call static 'j_object_into' using by reference temp end-call
 call static 'j_set_string' using by value temp by reference z'kind' z'resolve' by value 7 end-call
 call static 'j_set_string' using by value temp by reference z'id' id-text by value function length(function trim(id-text)) end-call
 call static 'j_set_null' using by value temp by reference z'value' end-call
 call static 'j_append' using by value list-node temp end-call
 call static 'j_remove' using by value registry by reference function concatenate(function trim(id-text),x'00') end-call.
 schedule-frame.
 move id-text to timer-id move 'animation.frame' to text-value move 0 to number-value
 perform schedule-command
 call static 'j_set_boolean' using by value command by reference z'frame' by value 1 end-call
 perform run-command.
 schedule-delay.
 perform schedule-command
 call static 'j_set_number' using by value command by reference z'delay' number-value end-call
 perform run-command.
 schedule-command.
 call static 'j_object_into' using by reference callback-node end-call
 call static 'j_set_string' using by value callback-node by reference z'operation' text-value by value function length(function trim(text-value)) end-call
 call static 'j_array_into' using by reference callback-args end-call
 call static 'j_object_into' using by reference handle-node end-call
 move id-text to text-value
 call static 'j_set_string' using by value handle-node by reference z'$animation' text-value by value function length(function trim(text-value trailing)) end-call
 call static 'j_append' using by value callback-args handle-node end-call
 call static 'j_set' using by value callback-node by reference z'args' by value callback-args end-call
 move 'schedule' to kind perform new-command
 move 'id' to key-text move timer-id to value-text perform command-string
 move 'callback' to key-text move callback-node to item perform command-value
 call static 'j_delete' using by value callback-node end-call.
 ease-value.
 evaluate easing
 when 'linear' move t to eased
 when 'easeIn' compute eased = t * t
 when 'easeOut' compute eased = t * (2 - t)
 when 'easeInOut'
 if t < 0.5 compute eased = 2 * t * t else compute eased = -1 + (4 - 2 * t) * t end-if
 when 'elastic'
 move 2 to x compute y = -10 * t
 call static 'h_power' using by reference x y z end-call
 compute eased = z * function sin((t - 0.075) * (2 * 3.141592653589793) / 0.3) + 1
 when 'bounce'
 evaluate true
 when t < 0.36363636363636365 compute eased = 7.5625 * t * t
 when t < 0.7272727272727273 compute x = t - 1.5 / 2.75 compute eased = 7.5625 * x * x + 0.75
 when t < 0.9090909090909091 compute x = t - 2.25 / 2.75 compute eased = 7.5625 * x * x + 0.9375
 when other compute x = t - 2.625 / 2.75 compute eased = 7.5625 * x * x + 0.984375 end-evaluate
 when other move t to eased end-evaluate.
 copy 'ui-library-procedures.cpy' .
 end program BUFO-ANIMATION.
