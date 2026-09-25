identification division.
program-id. BUFO-ACTIONS recursive.
environment division.
configuration section.
repository. function J-NUM function J-STR function all intrinsic.
data division.
local-storage section.
01 action-name pic x(64).
01 route-name pic x(128).
01 text-value pic x(32768).
01 notice-text pic x(1024).
01 child-request usage pointer.
01 child-response usage pointer.
01 item-node usage pointer.
01 copy-node usage pointer.
01 command-node usage pointer.
01 commands usage pointer.
01 number-value comp-2.
01 now-value comp-2.
01 random-value comp-2.
01 effect-x comp-2.
01 effect-y comp-2.
01 effect-gain comp-2.
01 effect-start-x comp-2.
01 effect-start-y comp-2.
01 effect-drift comp-2.
01 effect-rise comp-2.
01 effect-spin comp-2.
01 effect-duration comp-2.
01 effect-progress comp-2.
01 effect-ease comp-2.
01 effect-scale comp-2.
01 effect-opacity comp-2.
01 effect-horizontal comp-2.
01 effect-frame usage pointer.
01 effect-frames usage pointer.
01 effect-index binary-long.
01 effect-image-index binary-long.
01 effect-transform pic x(256).
01 effect-part pic x(128).
01 effect-asset pic x(256).
01 effect-assets.
 02 filler pic x(128) value './assets/images/bufo.png'.
 02 filler pic x(128) value './assets/images/generators/bufo-smol.png'.
 02 filler pic x(128) value './assets/images/generators/bufo-brain.png'.
 02 filler pic x(128) value './assets/images/generators/bufo-cash-money.png'.
 02 filler pic x(128) value './assets/images/generators/bufo-galaxy-brain.png'.
 02 filler pic x(128) value './assets/images/generators/bufo-has-midas-touch.png'.
 02 filler pic x(128) value './assets/images/generators/bufo-monstera.png'.
 02 filler pic x(128) value './assets/images/generators/bufo-old.png'.
 02 filler pic x(128) value './assets/images/generators/chonky-bufo-wants-to-be-held.png'.
 02 filler pic x(128) value './assets/images/generators/hypnobufo.png'.
 02 filler pic x(128) value './assets/images/generators/smol-bufo-feels-blessed.png'.
 02 filler pic x(128) value './assets/images/upgrades/bufo-dapper.png'.
 02 filler pic x(128) value './assets/images/upgrades/bufo-drake-yes.png'.
 02 filler pic x(128) value './assets/images/upgrades/bufo-mindblown.png'.
 02 filler pic x(128) value './assets/images/upgrades/bufo-simba.png'.
 02 filler pic x(128) value './assets/images/upgrades/bufo-gives-star.png'.
 02 filler pic x(128) value './assets/images/upgrades/bufo-give-money.png'.
 02 filler pic x(128) value './assets/images/upgrades/bufo-chefkiss-with-hat.png'.
 02 filler pic x(128) value './assets/images/upgrades/bufo-deal-with-it.png'.
 02 filler pic x(128) value './assets/images/upgrades/bufo-gentleman.png'.
 02 filler pic x(128) value './assets/images/upgrades/king-bufo.png'.
 02 filler pic x(128) value './assets/images/upgrades/shut-up-and-take-my-bufo.png'.
 02 filler pic x(128) value './assets/images/upgrades/bufo-caught-a-small-bufo.png'.
 02 filler pic x(128) value './assets/images/upgrades/bufo-iron-throne.png'.
 02 filler pic x(128) value './assets/images/upgrades/bufo-universe.png'.
 02 filler pic x(128) value './assets/images/upgrades/confused-math-bufo.png'.
01 effect-asset-table redefines effect-assets.
 02 effect-image pic x(128) occurs 26.
01 effect-text pic x(1024).
01 formatted pic x(256).
01 flag binary-long.
01 save-flag binary-long.
linkage section.
01 request-node usage pointer.
01 context-node usage pointer.
01 response-node usage pointer.
procedure division using by value request-node context-node response-node.
 move function J-STR(request-node, 'args.action') to action-name
 move function J-NUM(context-node, 'runtime.now') to now-value
 call static 'j_boolean' using by value context-node by reference z'runtime.persistence.blocked' returning flag end-call
 if flag = 1 and action-name not = 'settings' and 'reset' and 'confirmReset'
 and 'import' and 'export' and 'download' and 'close' and 'retry'
 move 'Progress is paused until save recovery succeeds.' to notice-text
 perform notice
 goback end-if
 call static 'j_clone_into' using by value request-node by reference child-request end-call
 call static 'j_object_into' using by reference child-response end-call
 call static 'j_set_boolean' using by value response-node by reference z'ok' by value 1 end-call
 evaluate action-name
 when 'click'
   move 'click' to route-name perform game-route
   move function J-NUM(response-node, 'result.bufosGained') to number-value
   perform click-effect
 when 'generatorInfo' when 'upgradeInfo'
   call static 'BUFO-UI-DETAILS' using by value request-node context-node response-node end-call
 when 'quantity'
   move function J-STR(request-node, 'args.amount') to text-value
   evaluate text-value when '1' move 1 to number-value when '10' move 10 to number-value
   when '100' move 100 to number-value when '-1' move -1 to number-value
   when other move 1 to number-value end-evaluate
   call static 'j_set_number' using by value context-node by reference z'runtime.ui.quantity' number-value end-call
 when 'buyGenerator'
   move function J-STR(request-node, 'args.id') to text-value
   call static 'j_set_string' using by value child-request by reference z'args.generatorType' text-value
     by value function length(function trim(text-value)) end-call
   move function J-NUM(context-node, 'runtime.ui.quantity') to number-value
   if number-value = 0 move 1 to number-value end-if
   call static 'j_set_number' using by value child-request by reference z'args.quantity' number-value end-call
   move 'buyGenerator' to route-name perform game-route
   call static 'j_boolean' using by value response-node by reference z'result' returning flag end-call
   if flag = 1 move 1 to save-flag
   else move 'Not enough bufos, or the purchase is not available yet.' to notice-text perform notice end-if
 when 'buyUpgrade'
   move function J-STR(request-node, 'args.id') to text-value
   call static 'j_set_string' using by value child-request by reference z'args.upgradeId' text-value
     by value function length(function trim(text-value)) end-call
   move 'buyUpgrade' to route-name perform game-route
   call static 'j_boolean' using by value response-node by reference z'result' returning flag end-call
   if flag = 1 move 1 to save-flag
   else move 'Not enough bufos, or the purchase is not available yet.' to notice-text perform notice end-if
 when 'golden'
   move 'golden.collect' to route-name perform game-route
   move 'Golden Bufo collected!' to notice-text perform notice
 when 'bossStart'
   move 'boss.startFight' to route-name perform game-route
 when 'bossRetreat'
   move 'boss.retreat' to route-name perform game-route
 when 'bossHit'
   move function J-NUM(context-node, 'state.resources.clickPower') to number-value
   call static 'j_set_number' using by value child-request by reference z'args.amount' number-value end-call
   move 'registerClick' to route-name perform game-route
   move 'boss.hit' to route-name perform game-route
 when 'bossLater'
   call static 'BUFO-RANDOM' using by value request-node context-node by reference random-value end-call
   compute number-value = now-value + 60000 + random-value * 120000
   call static 'j_set_number' using by value context-node by reference z'runtime.ui.bossSnooze' number-value end-call
 when 'save'
   move 'save' to route-name perform save-route
   call static 'j_boolean' using by value response-node by reference z'ok' returning flag end-call
   if flag = 1 move 'Game saved.' to notice-text perform notice end-if
 when 'retry'
   move 'retry' to route-name perform save-route
 when 'autoSave'
   call static 'j_boolean' using by value request-node by reference z'args.checked' returning flag end-call
   call static 'j_set_boolean' using by value context-node by reference z'state.gameSettings.autoSave' by value flag end-call
   move 'save' to route-name perform save-route
 when 'settings' when 'stats' when 'achievements' when 'prestige' when 'reset'
   move action-name to text-value perform open-modal
 when 'close'
   if now-value - function J-NUM(context-node, 'runtime.ui.inputLockedUntil') < 0
     continue
   else
   move spaces to text-value perform open-modal end-if
 when 'confirmReset'
   move 'reset' to route-name perform save-route
   call static 'j_boolean' using by value response-node by reference z'ok' returning flag end-call
   if flag = 1 move spaces to text-value perform open-modal
     move 'Progress reset.' to notice-text perform notice end-if
 when 'confirmPrestige'
   move 'prestige' to route-name perform save-route
   call static 'j_boolean' using by value response-node by reference z'ok' returning flag end-call
   if flag = 1 move spaces to text-value perform open-modal
     move 'Transcendence complete.' to notice-text perform notice end-if
 when 'import'
   call static 'j_get_into' using by value request-node by reference z'args.fields.data' item-node end-call
   call static 'j_clone_into' using by value item-node by reference copy-node end-call
   call static 'j_set' using by value child-request by reference z'args.raw' by value copy-node end-call
   move 'import' to route-name perform save-route
   call static 'j_boolean' using by value response-node by reference z'ok' returning flag end-call
   if flag = 1 move spaces to text-value perform open-modal
     move 'Save imported.' to notice-text perform notice end-if
 when 'export' when 'download'
   move 'export' to route-name perform save-route
   call static 'j_boolean' using by value response-node by reference z'ok' returning flag end-call
   if flag = 1
     call static 'j_array_into' using by reference commands end-call
     call static 'j_object_into' using by reference command-node end-call
     if action-name = 'download'
       call static 'j_set_string' using by value command-node by reference z'kind' 'download' by value 8 end-call
       call static 'j_set_string' using by value command-node by reference z'name' 'bufoclicker-save.txt' by value 19 end-call
     else
       call static 'j_set_string' using by value command-node by reference z'kind' 'value' by value 5 end-call
       call static 'j_set_string' using by value command-node by reference z'target' '#save-data' by value 10 end-call
     end-if
     call static 'j_get_into' using by value response-node by reference z'result' item-node end-call
     call static 'j_clone_into' using by value item-node by reference copy-node end-call
     call static 'j_set' using by value command-node by reference z'value' by value copy-node end-call
     call static 'j_append' using by value commands command-node end-call
     call static 'j_set' using by value response-node by reference z'commands' by value commands end-call
   end-if
 when 'customModalButton'
   move function J-STR(request-node, 'args.index') to text-value
   if function test-numval(function trim(text-value)) = 0
     compute number-value = function numval(text-value)
     call static 'j_array_into' using by reference item-node end-call
     call static 'j_object_into' using by reference copy-node end-call
     call static 'j_set_number' using by value copy-node by reference z'value' number-value end-call
     call static 'j_get_into' using by value copy-node by reference z'value' command-node end-call
     call static 'j_clone_into' using by value command-node by reference commands end-call
     call static 'j_append' using by value item-node commands end-call
     call static 'j_delete' using by value copy-node end-call
     call static 'j_set' using by value child-request by reference z'args' by value item-node end-call
     move 'ui.customModalButton' to route-name perform set-operation
     call static 'BUFO-API-UI' using by value child-request context-node response-node end-call
   end-if
 when 'achievementCategory'
   move function J-STR(request-node, 'args.category') to text-value
   call static 'j_set_string' using by value context-node by reference z'runtime.ui.achievementCategory' text-value
      by value function length(function trim(text-value)) end-call
 when 'toggleLocked'
   call static 'j_boolean' using by value context-node by reference z'runtime.ui.hideLocked' returning flag end-call
   call static 'j_has' using by value context-node by reference z'runtime.ui.hideLocked' returning save-flag end-call
   if save-flag = 0 move 1 to flag end-if
   move 0 to save-flag
   compute flag = 1 - flag
   call static 'j_set_boolean' using by value context-node by reference z'runtime.ui.hideLocked' by value flag end-call
 when 'toggleSecret'
   call static 'j_boolean' using by value context-node by reference z'runtime.ui.showSecret' returning flag end-call
   compute flag = 1 - flag
   call static 'j_set_boolean' using by value context-node by reference z'runtime.ui.showSecret' by value flag end-call
 when other
   call static 'j_set_boolean' using by value response-node by reference z'ok' by value 0 end-call
   move 'Unknown UI action.' to notice-text
   call static 'j_set_string' using by value response-node by reference z'error' notice-text by value 18 end-call
 end-evaluate
 if save-flag = 1
   move 'save' to route-name perform set-operation
   call static 'BUFO-SAVE' using by value child-request context-node child-response end-call
   call static 'j_boolean' using by value child-response by reference z'ok' returning flag end-call
   if flag = 0
     move function J-STR(child-response, 'error') to notice-text perform notice
   end-if
 end-if
 call static 'j_boolean' using by value response-node by reference z'ok' returning flag end-call
 if flag = 0
   move function J-STR(response-node, 'error') to notice-text perform notice
 end-if
 call static 'j_delete' using by value child-request end-call
 call static 'j_delete' using by value child-response end-call
 goback.
click-effect.
 move number-value to effect-gain
 move function J-NUM(request-node,'args.x') to effect-x effect-start-x
 move function J-NUM(request-node,'args.y') to effect-y effect-start-y
 call static 'j_get_into' using by value response-node by reference z'commands' commands end-call
 if commands = null
 call static 'j_array_into' using by reference commands end-call
 call static 'j_set' using by value response-node by reference z'commands' by value commands end-call end-if
 call static 'j_parse_into' using by reference '{"kind":"animate","target":"#bufo img","key":"click-squish","frames":[{"transform":"scale(0.95)"},{"transform":"scale(0.95)"}],"options":{"duration":90}}' by value 153 by reference command-node end-call
 call static 'j_append' using by value commands command-node end-call
 call static 'j_parse_into' using by reference '{"kind":"ephemeral","target":"#click-effects","className":"click-indicator","value":"","limit":150,"duration":1000,"easing":"linear","frames":[{"opacity":0.8,"transform":"translate(-50%,-50%) scale(0)"},{"offset":0.6,"opacity":0,"transform":"translate(-50%,-50%) scale(2.5)"},{"opacity":0,"transform":"translate(-50%,-50%) scale(2.5)"}]}' by value 337 by reference command-node end-call
 perform emit-effect
 call static 'j_parse_into' using by reference '{"kind":"ephemeral","target":"#click-effects","className":"floating-number","limit":150,"duration":1500,"easing":"linear","constrainX":{"min":6}}' by value 145 by reference command-node end-call
 compute number-value = function J-NUM(request-node,'args.width') - 6
 if number-value < 6 move 6 to number-value end-if
 call static 'j_set_number' using by value command-node by reference z'constrainX.max' number-value end-call
 call static 'j_boolean' using by value response-node by reference z'result.isCombo' returning flag end-call
 if flag = 1
 call static 'j_set_string' using by value command-node by reference z'className' z'floating-number combo' by value 21 end-call end-if
 move effect-gain to number-value
 call static 'h_decimal' using by reference number-value by value 1 0 0 by reference formatted by value 256 end-call
 move spaces to effect-text
 string '<span class="value">+' function trim(formatted) '</span>' into effect-text end-string
 call static 'j_set_string' using by value command-node by reference z'value' effect-text by value function length(function trim(effect-text)) end-call
 perform effect-random compute effect-x = effect-start-x + random-value * 30 - 15
 perform effect-random compute effect-y = effect-start-y + random-value * 20 - 10
 perform effect-random compute effect-drift = random-value * 40 - 20
 perform effect-random compute effect-rise = 50 + random-value * 20
 call static 'j_array_into' using by reference effect-frames end-call
 perform varying effect-index from 0 by 1 until effect-index > 100
 compute effect-progress = effect-index / 100
 compute effect-ease = 1 - (1 - effect-progress) ** 3
 if effect-progress < 0.5 compute effect-horizontal = 2 * effect-progress ** 2
 else compute effect-horizontal = 1 - (-2 * effect-progress + 2) ** 2 / 2 end-if
 if effect-progress < 0.7 move 1 to effect-opacity else compute effect-opacity = 1 - (effect-progress - 0.7) / 0.3 end-if
 if effect-progress < 0.2 compute effect-scale = 0.7 + effect-progress / 0.2 * 0.5
 else compute effect-scale = 1.2 - (effect-progress - 0.2) / 0.8 * 0.4 end-if
 perform new-effect-frame
 compute number-value = effect-x + effect-drift * effect-horizontal perform effect-decimal
 move function concatenate(function trim(formatted),'px') to effect-part
 call static 'j_set_string' using by value effect-frame by reference z'left' effect-part by value function length(function trim(effect-part)) end-call
 compute number-value = 0 - effect-rise * effect-ease perform effect-decimal
 move function concatenate('translateY(',function trim(formatted),'px) scale(') to effect-transform
 move effect-scale to number-value perform effect-decimal
 move function concatenate(function trim(effect-transform),function trim(formatted),')') to effect-transform
 perform set-effect-transform
 end-perform
 call static 'j_set' using by value command-node by reference z'frames' by value effect-frames end-call
 perform emit-effect
 call static 'j_parse_into' using by reference '{"kind":"ephemeral","target":"#click-effects","className":"click-emoji-pop","limit":150,"easing":"linear","removeOnImageError":true}' by value 132 by reference command-node end-call
 perform effect-random compute effect-image-index = function integer(random-value * 26) + 1
 move effect-image(effect-image-index) to effect-asset
 move spaces to effect-text
 string '<img src="' function trim(effect-asset) '" alt="" draggable="false">' into effect-text end-string
 call static 'j_set_string' using by value command-node by reference z'value' effect-text by value function length(function trim(effect-text)) end-call
 compute effect-x = function max(22,function min(effect-start-x,function J-NUM(request-node,'args.width') - 22))
 move effect-start-y to effect-y
 perform effect-random compute effect-duration = 800 + random-value * 200
 call static 'j_set_number' using by value command-node by reference z'duration' effect-duration end-call
 perform effect-random compute effect-rise = 50 + random-value * 50
 perform effect-random compute effect-drift = random-value * 140 - 70
 perform effect-random compute effect-spin = random-value * 100 - 50
 call static 'j_array_into' using by reference effect-frames end-call
 perform varying effect-index from 0 by 1 until effect-index > 100
 compute effect-progress = effect-index / 100
 if effect-progress <= 0.5 move 1 to effect-opacity else compute effect-opacity = 1 - (effect-progress - 0.5) / 0.5 end-if
 perform new-effect-frame
 compute number-value = effect-drift * effect-progress perform effect-decimal
 move function concatenate('translate(',function trim(formatted),'px,') to effect-transform
 compute number-value = -4 * effect-rise * effect-progress * (1 - effect-progress) perform effect-decimal
 move function concatenate(function trim(effect-transform),function trim(formatted),'px) rotate(') to effect-transform
 compute number-value = effect-spin * effect-progress perform effect-decimal
 move function concatenate(function trim(effect-transform),function trim(formatted),'deg)') to effect-transform
 perform set-effect-transform
 end-perform
 call static 'j_set' using by value command-node by reference z'frames' by value effect-frames end-call
 perform emit-effect.
effect-random.
 call static 'BUFO-RANDOM' using by value request-node context-node by reference random-value end-call.
effect-decimal.
 call static 'h_decimal' using by reference number-value by value 3 0 1 by reference formatted by value 256 end-call.
new-effect-frame.
 call static 'j_object_into' using by reference effect-frame end-call
 call static 'j_set_number' using by value effect-frame by reference z'offset' effect-progress end-call
 call static 'j_set_number' using by value effect-frame by reference z'opacity' effect-opacity end-call
 call static 'j_append' using by value effect-frames effect-frame end-call.
set-effect-transform.
 call static 'j_set_string' using by value effect-frame by reference z'transform' effect-transform by value function length(function trim(effect-transform)) end-call.
emit-effect.
 call static 'j_set_number' using by value command-node by reference z'x' effect-x end-call
 call static 'j_set_number' using by value command-node by reference z'y' effect-y end-call
 call static 'j_append' using by value commands command-node end-call.

set-operation.
 call static 'j_set_string' using by value child-request by reference z'operation' route-name
 by value function length(function trim(route-name)) end-call.
game-route.
 perform set-operation
 call static 'BUFO-GAME' using by value child-request context-node response-node end-call.
save-route.
 perform set-operation
 call static 'BUFO-SAVE' using by value child-request context-node response-node end-call.
open-modal.
 call static 'j_set_string' using by value context-node by reference z'runtime.ui.modal' text-value
 by value function length(function trim(text-value)) end-call
 call static 'j_set_boolean' using by value context-node by reference z'runtime.ui.modalRendered' by value 0 end-call.
notice.
 call static 'j_set_string' using by value context-node by reference z'runtime.ui.notice' notice-text
 by value function length(function trim(notice-text)) end-call
 compute number-value = now-value + 4000
 call static 'j_set_number' using by value context-node by reference z'runtime.ui.noticeUntil' number-value end-call.
end program BUFO-ACTIONS.
