identification division.
program-id. BUFO-API-UI recursive.
environment division.
configuration section.
repository. function J-NUM function J-STR function all intrinsic.
data division.
local-storage section.
copy 'ui-library-vars.cpy'.
01 owned-element usage pointer.
01 owned-options usage pointer.
01 owned-event usage pointer.
01 owned-list usage pointer.
01 child-request usage pointer.
01 child-response usage pointer.
01 saved-element usage pointer.
01 close-callback usage pointer.
01 content-text pic x(32768).
01 element-id pic x(256).
01 timer-delay usage comp-2.
01 icon-html pic x(8192).
01 reward-html pic x(8192).
01 reward-text pic x(512).
linkage section.
01 req usage pointer.
01 ctx usage pointer.
01 res usage pointer.
procedure division using by value req ctx res.
perform read-request
evaluate op
when 'ui.showModal'
move function J-STR(ctx,'runtime.ui.modal') to element-id
if element-id not = spaces perform schedule-modal-closed end-if
call static 'j_clone_into' using by value a(1) by reference temp end-call
call static 'j_set' using by value ctx by reference z'runtime.ui.customOptions' by value temp end-call
move 'custom' to text-value
call static 'j_set_string' using by value ctx by reference z'runtime.ui.modal' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_get_into' using by value a(1) by reference z'title' item end-call
call static 'j_clone_into' using by value item by reference temp end-call
call static 'j_set' using by value ctx by reference z'runtime.ui.customTitle' by value temp end-call
call static 'j_get_into' using by value a(1) by reference z'content' item end-call
call static 'j_clone_into' using by value item by reference temp end-call
call static 'j_set' using by value ctx by reference z'runtime.ui.customContent' by value temp end-call
call static 'BUFO-UI' using by value req ctx res end-call
call static 'j_object_into' using by reference child-request end-call
move 'ui.modalResult' to text-value
call static 'j_set_string' using by value child-request by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_clone_into' using by value args by reference temp end-call
call static 'j_set' using by value child-request by reference z'args' by value temp end-call
call static 'j_set' using by value res by reference z'continuation' by value child-request end-call
move 'UI_MODAL_OPENED' to id-text perform modal-event
when 'ui.modalResult'
move null to target
move 'query' to kind perform new-command
move 'selector' to key-text move '#modal-layer .modal' to value-text perform command-string
perform run-command perform return-answer
when 'ui.closeModal'
call static 'j_has' using by value req by reference z'callbackResult' returning yes end-call
move 1 to rc
if yes = 1 call static 'j_boolean' using by value req by reference z'callbackResult.ok' returning rc end-call end-if
if rc = 0
call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
call static 'j_get_into' using by value req by reference z'callbackResult.error' item end-call
call static 'j_clone_into' using by value item by reference temp end-call
call static 'j_set' using by value res by reference z'error' by value temp end-call
else
move function J-STR(ctx,'runtime.ui.modal') to element-id
if element-id not = spaces
perform schedule-modal-closed
move '' to text-value
call static 'j_set_string' using by value ctx by reference z'runtime.ui.modal' text-value by value function length(function trim(text-value trailing)) end-call
call static 'BUFO-UI' using by value req ctx res end-call
end-if end-if
when 'ui.modalClosed'
call static 'j_object_into' using by reference owned-event end-call
move 'UI_MODAL_CLOSED' to text-value
call static 'j_set_string' using by value owned-event by reference z'name' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_clone_into' using by value a(1) by reference temp end-call
call static 'j_set' using by value owned-event by reference z'payload.modalId' by value temp end-call
call static 'j_get_into' using by value ctx by reference z'events' owned-list end-call
call static 'j_append' using by value owned-list owned-event end-call
when 'ui.customModalButton'
call static 'j_get_into' using by value ctx by reference z'runtime.ui.customOptions.buttons' list-node end-call
move n(1) to i
call static 'j_at_into' using by value list-node i by reference item end-call
call static 'j_get_into' using by value item by reference z'callback' callback-node end-call
if callback-node not = null
call static 'j_get_into' using by value res by reference z'commands' owned-list end-call
if owned-list = null call static 'j_array_into' using by reference owned-list end-call
call static 'j_set' using by value res by reference z'commands' by value owned-list end-call end-if
call static 'j_object_into' using by reference owned-event end-call
move 'callback' to text-value
call static 'j_set_string' using by value owned-event by reference z'kind' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_get_into' using by value callback-node by reference z'$callback' item end-call
call static 'j_clone_into' using by value item by reference temp end-call
call static 'j_set' using by value owned-event by reference z'id' by value temp end-call
call static 'j_array_into' using by reference item end-call
call static 'j_set' using by value owned-event by reference z'args' by value item end-call
call static 'j_append' using by value owned-list owned-event end-call
call static 'j_object_into' using by reference child-request end-call
move 'ui.closeModal' to text-value
call static 'j_set_string' using by value child-request by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_array_into' using by reference item end-call
call static 'j_set' using by value child-request by reference z'args' by value item end-call
call static 'j_set' using by value res by reference z'continuation' by value child-request end-call
end-if
when 'ui.showNotification' when 'ui.showAchievementNotification'
move a(1) to options-node
perform create-notification
when 'ui.hideNotification'
move a(1) to target move 'class' to kind perform new-command
move 'action' to key-text move 'remove' to value-text perform command-string
call static 'j_parse_into' using by reference '["visible"]' by value 11 by reference item end-call
move 'names' to key-text perform command-value
call static 'j_delete' using by value item end-call perform run-command
move 'unlisten' to kind perform new-command
move 'id' to key-text move s(2) to value-text perform command-string perform run-command
move null to target move 'schedule' to kind perform new-command
move 'id' to key-text move s(2) to value-text perform command-string
move 'delay' to key-text move 300 to number-value perform command-number
call static 'j_object_into' using by reference close-callback end-call
move 'ui.removeNotification' to text-value
call static 'j_set_string' using by value close-callback by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_array_into' using by reference owned-list end-call
call static 'j_clone_into' using by value a(1) by reference item end-call
call static 'j_append' using by value owned-list item end-call
call static 'j_set' using by value close-callback by reference z'args' by value owned-list end-call
move 'callback' to key-text move close-callback to item perform command-value perform run-command
call static 'j_delete' using by value close-callback end-call
when 'ui.removeNotification'
move a(1) to target move 'remove' to kind perform new-command perform run-command
move 'release' to kind perform new-command perform run-command
when 'ui.updateTabNotification'
move null to target move 'query' to kind perform new-command
move spaces to value-text
string '#' function trim(s(1)) '-panel' into value-text end-string
move 'selector' to key-text perform command-string perform run-command
call static 'j_clone_into' using by value answer by reference owned-element end-call
move owned-element to target move 'class' to kind perform new-command
move 'action' to key-text move 'toggle' to value-text perform command-string
call static 'j_parse_into' using by reference '["has-notification"]' by value 20 by reference item end-call
move 'names' to key-text perform command-value
call static 'j_delete' using by value item end-call
move a(2) to item move 'force' to key-text perform command-value perform run-command
call static 'j_delete' using by value owned-element end-call
when 'ui.updateAutoSaveStatus'
move null to target move 'query' to kind perform new-command
move 'selector' to key-text move '#auto-save-toggle' to value-text perform command-string perform run-command
call static 'j_type' using by value answer by reference x'00' returning typ end-call
if typ = 5
call static 'j_clone_into' using by value answer by reference owned-element end-call
move owned-element to target move 'property' to kind perform new-command
move 'name' to key-text move 'checked' to value-text perform command-string
move 'value' to key-text move a(1) to item perform command-value perform run-command
call static 'j_delete' using by value owned-element end-call
call static 'j_object_into' using by reference owned-options end-call
if b(1) = 1
move 'Auto-save enabled - game will be saved every 5 minutes' to text-value
call static 'j_set_string' using by value owned-options by reference z'message' text-value by value function length(function trim(text-value trailing)) end-call
move 'info' to text-value
call static 'j_set_string' using by value owned-options by reference z'type' text-value by value function length(function trim(text-value trailing)) end-call
else
move 'Auto-save disabled - remember to save manually!' to text-value
call static 'j_set_string' using by value owned-options by reference z'message' text-value by value function length(function trim(text-value trailing)) end-call
move 'warning' to text-value
call static 'j_set_string' using by value owned-options by reference z'type' text-value by value function length(function trim(text-value trailing)) end-call
end-if
move owned-options to options-node perform create-notification
call static 'j_delete' using by value owned-options end-call
call static 'j_delete' using by value result-node end-call move null to result-node
end-if
when 'ui.initUI'
call static 'j_set_boolean' using by value ctx by reference z'runtime.ui.mounted' by value 0 end-call
call static 'BUFO-UI' using by value req ctx res end-call
call static 'j_parse_into' using by reference '["ui"]' by value 6 by reference item end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value item end-call
when 'ui.updateUI'
call static 'j_get_into' using by value ctx by reference z'runtime.ui' item end-call
if item = null call static 'j_object_into' using by reference item end-call
call static 'j_set' using by value ctx by reference z'runtime.ui' by value item end-call end-if
when 'initialization.createLoadingUI'
perform next-id move id-text to element-id
move null to target move 'byId' to kind perform new-command
move 'id' to key-text move s(1) to value-text
if value-text = spaces move 'game-container' to value-text end-if
perform command-string perform run-command
call static 'j_clone_into' using by value answer by reference saved-element end-call
call static 'j_type' using by value saved-element by reference x'00' returning typ end-call
set owned-element to null
if typ = 5 and failed = 0
move 'create' to kind perform new-command
move 'tag' to key-text move 'div' to value-text perform command-string perform run-command
call static 'j_clone_into' using by value answer by reference owned-element end-call
move owned-element to target move 'attribute' to kind perform new-command
move 'name' to key-text move 'class' to value-text perform command-string
move 'value' to key-text move 'game-loading' to value-text perform command-string perform run-command
move 'attribute' to kind perform new-command
move 'name' to key-text move 'style' to value-text perform command-string
move 'value' to key-text move 'position:absolute;top:0;left:0;width:100%;height:100%;display:flex;flex-direction:column;align-items:center;justify-content:center;background:rgba(0,0,0,.7);color:#fff;z-index:1000' to value-text perform command-string perform run-command
move 'html' to kind perform new-command
move 'value' to key-text
move '<h2 style="margin-bottom:20px">Loading Bufo Idle...</h2><div style="width:300px;height:20px;background:#333;border-radius:10px;overflow:hidden"><div class="loading-progress" style="width:0%;height:100%;background:#4CAF50;transition:width .3s ease-out"></div></div><div class="loading-status" style="margin-top:10px;font-size:14px;color:#ccc"></div>' to value-text
perform command-string perform run-command
move saved-element to target move 'append' to kind perform new-command
move 'child' to key-text move owned-element to item perform command-value perform run-command
end-if
call static 'j_object_into' using by reference owned-options end-call
call static 'j_clone_into' using by value owned-element by reference temp end-call
call static 'j_set' using by value owned-options by reference z'element' by value temp end-call
move function concatenate('loading.',function trim(element-id),x'00') to key-text
call static 'j_set' using by value lib by reference key-text by value owned-options end-call
call static 'j_array_into' using by reference owned-list end-call
call static 'j_object_into' using by reference item end-call
move 'loadingUI' to text-value
call static 'j_set_string' using by value item by reference z'key' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_get_into' using by value item by reference z'key' temp end-call
call static 'j_clone_into' using by value temp by reference obj end-call
call static 'j_append' using by value owned-list obj end-call
move element-id to text-value
call static 'j_set_string' using by value item by reference z'key' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_get_into' using by value item by reference z'key' temp end-call
call static 'j_clone_into' using by value temp by reference obj end-call
call static 'j_append' using by value owned-list obj end-call
call static 'j_delete' using by value item end-call
call static 'j_set' using by value res by reference z'result.$proxy' by value owned-list end-call
call static 'j_delete' using by value saved-element end-call
call static 'j_delete' using by value owned-element end-call
when 'loadingUI.update' when 'loadingUI.remove'
call static 'j_get_into' using by value req by reference z'apiPath' owned-list end-call
call static 'j_at_into' using by value owned-list 1 by reference item end-call
move function J-STR(item,' ') to element-id
move function concatenate('loading.',function trim(element-id),'.element',x'00') to key-text
call static 'j_get_into' using by value lib by reference key-text owned-element end-call
if owned-element not = null
if op = 'loadingUI.remove'
move owned-element to target move 'style' to kind perform new-command
move 'name' to key-text move 'transition' to value-text perform command-string
move 'value' to key-text move 'opacity .5s ease-out' to value-text perform command-string perform run-command
move 'style' to kind perform new-command
move 'name' to key-text move 'opacity' to value-text perform command-string
move 'value' to key-text move '0' to value-text perform command-string perform run-command
move null to target move 'schedule' to kind perform new-command
move 'id' to key-text move element-id to value-text perform command-string
move 'delay' to key-text move 500 to number-value perform command-number
call static 'j_object_into' using by reference close-callback end-call
move 'ui.removeNotification' to text-value
call static 'j_set_string' using by value close-callback by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_array_into' using by reference owned-list end-call
call static 'j_clone_into' using by value owned-element by reference item end-call
call static 'j_append' using by value owned-list item end-call
call static 'j_set' using by value close-callback by reference z'args' by value owned-list end-call
move 'callback' to key-text move close-callback to item perform command-value perform run-command
call static 'j_delete' using by value close-callback end-call
else
move owned-element to target move 'query' to kind perform new-command
move 'selector' to key-text move '.loading-progress' to value-text perform command-string perform run-command
call static 'j_clone_into' using by value answer by reference saved-element end-call
move saved-element to target move 'style' to kind perform new-command
move 'name' to key-text move 'width' to value-text perform command-string
move function J-NUM(a(1),'progress') to number-value
call static 'h_decimal' using by reference number-value by value 12 0 1 by reference formatted by value 256 end-call
move spaces to value-text string function trim(formatted) '%' into value-text end-string
move 'value' to key-text perform command-string perform run-command
call static 'j_delete' using by value saved-element end-call
move owned-element to target move 'query' to kind perform new-command
move 'selector' to key-text move '.loading-status' to value-text perform command-string perform run-command
call static 'j_clone_into' using by value answer by reference saved-element end-call
move saved-element to target move 'text' to kind perform new-command
move function J-STR(a(1),'step') to value-text
call static 'j_get_into' using by value a(1) by reference z'error' item end-call
if item not = null move spaces to value-text
string 'Error: ' function trim(function J-STR(item,'message')) into value-text end-string end-if
move 'value' to key-text perform command-string perform run-command
call static 'j_get_into' using by value a(1) by reference z'error' item end-call
if item not = null
move 'style' to kind perform new-command
move 'name' to key-text move 'color' to value-text perform command-string
move 'value' to key-text move '#FF5252' to value-text perform command-string perform run-command end-if
call static 'j_delete' using by value saved-element end-call
end-if end-if
when 'ui.init' when 'ui.initializeMenu'
call static 'j_set_boolean' using by value ctx by reference z'runtime.ui.mounted' by value 0 end-call
call static 'BUFO-UI' using by value req ctx res end-call
when 'ui.destroy'
call static 'j_set_boolean' using by value ctx by reference z'runtime.ui.mounted' by value 0 end-call
call static 'j_set_boolean' using by value ctx by reference z'runtime.ui.destroyed' by value 1 end-call
move null to target move 'query' to kind perform new-command
move 'selector' to key-text move '#app' to value-text perform command-string perform run-command
call static 'j_clone_into' using by value answer by reference owned-element end-call
move owned-element to target move 'html' to kind perform new-command
move 'value' to key-text move spaces to value-text perform command-string perform run-command
call static 'j_delete' using by value owned-element end-call
when 'ui.getComponent'
move function concatenate('runtime.ui.components.',function trim(s(1))) to key-text
call static 'j_get_into' using by value ctx by reference function concatenate(function trim(key-text),x'00') item end-call
if item not = null perform return-value
else
move spaces to id-text element-id
evaluate s(1)
when 'resourceDisplay' move 'ResourceDisplay' to id-text move 'resource-count' to element-id
when 'clickArea' move 'ClickArea' to id-text move 'bufo' to element-id
when 'generatorList' move 'GeneratorList' to id-text move 'owned' to element-id
when 'shop' move 'Shop' to id-text move 'shop' to element-id
when 'upgradeList' move 'UpgradeList' to id-text move 'upgrades' to element-id
when 'productionStats' move 'ProductionStats' to id-text move 'sources' to element-id
when 'goldenBufo' move 'GoldenBufo' to id-text move 'golden' to element-id
when 'bossFight' move 'BossFight' to id-text move 'boss-layer' to element-id
end-evaluate
if id-text = spaces
call static 'j_parse_into' using by reference 'null' by value 4 by reference result-node end-call
else
move id-text to content-text
move null to target move 'byId' to kind perform new-command
move 'id' to key-text move element-id to value-text perform command-string perform run-command
call static 'j_type' using by value answer by reference x'00' returning typ end-call
if typ = 5 and failed = 0
call static 'j_get_into' using by value lib by reference z'components' owned-list end-call
if owned-list = null call static 'j_object_into' using by reference owned-list end-call
call static 'j_set' using by value lib by reference z'components' by value owned-list end-call end-if
call static 'j_object_into' using by reference owned-options end-call
move content-text to text-value
call static 'j_set_string' using by value owned-options by reference z'kind' text-value by value function length(function trim(text-value trailing)) end-call
move element-id to text-value
call static 'j_set_string' using by value owned-options by reference z'id' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_clone_into' using by value answer by reference temp end-call
call static 'j_set' using by value owned-options by reference z'element' by value temp end-call
call static 'j_set_boolean' using by value owned-options by reference z'initialized' by value 1 end-call
call static 'j_object_into' using by reference item end-call
call static 'j_set' using by value owned-options by reference z'handlers' by value item end-call
call static 'j_object_into' using by reference item end-call
call static 'j_set' using by value owned-options by reference z'options' by value item end-call
call static 'j_array_into' using by reference item end-call
call static 'j_set' using by value owned-options by reference z'children' by value item end-call
perform next-id
call static 'j_set' using by value owned-list by reference function concatenate(function trim(id-text),x'00') by value owned-options end-call
call static 'j_object_into' using by reference result-node end-call
move id-text to text-value
call static 'j_set_string' using by value result-node by reference z'$component' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_clone_into' using by value result-node by reference temp end-call
move function concatenate('runtime.ui.components.',function trim(s(1)),x'00') to key-text
call static 'j_set' using by value ctx by reference key-text by value temp end-call
else
call static 'j_parse_into' using by reference 'null' by value 4 by reference result-node end-call
end-if
end-if end-if
when other
move 1 to failed
call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
move 'Unknown UIManager method' to text-value
call static 'j_set_string' using by value res by reference z'error' text-value by value function length(function trim(text-value trailing)) end-call
end-evaluate
if result-node not = null call static 'j_set' using by value res by reference z'result' by value result-node end-call end-if
if answer not = null call static 'j_delete' using by value answer end-call end-if
goback.
modal-event.
call static 'j_object_into' using by reference owned-event end-call
move id-text to text-value
call static 'j_set_string' using by value owned-event by reference z'name' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_get_into' using by value ctx by reference z'runtime.ui.customOptions.id' item end-call
call static 'j_clone_into' using by value item by reference temp end-call
call static 'j_set' using by value owned-event by reference z'payload.modalId' by value temp end-call
call static 'j_get_into' using by value ctx by reference z'events' owned-list end-call
call static 'j_append' using by value owned-list owned-event end-call.
create-notification.
perform next-id move id-text to element-id
move null to target move 'create' to kind perform new-command
move 'tag' to key-text move 'div' to value-text perform command-string perform run-command
call static 'j_clone_into' using by value answer by reference owned-element end-call
move owned-element to target move 'attribute' to kind perform new-command
move 'name' to key-text move 'id' to value-text perform command-string
move 'value' to key-text move element-id to value-text perform command-string perform run-command
move 'attribute' to kind perform new-command
move 'name' to key-text move 'class' to value-text perform command-string
move 'notification notification-info visible' to value-text
if op = 'ui.showAchievementNotification' move 'achievement-notification visible' to value-text
else
move function J-STR(options-node,'type') to id-text
if id-text not = spaces
move spaces to value-text string 'notification notification-' function trim(id-text) ' visible' into value-text end-string end-if end-if
move 'value' to key-text perform command-string perform run-command
move 'html' to kind perform new-command
move function J-STR(options-node,'message') to content-text
if op = 'ui.showAchievementNotification' perform achievement-markup end-if
move spaces to value-text
if op = 'ui.showAchievementNotification' move content-text to value-text
else
string '<div class="notification-content"><span class="notification-message">' function trim(content-text) '</span><button class="notification-close">&times;</button></div>' into value-text end-string
end-if
move 'value' to key-text perform command-string perform run-command
call static 'j_parse_into' using by reference '{"$element":"body"}' by value 19 by reference saved-element end-call
move saved-element to target move 'append' to kind perform new-command
move 'child' to key-text move owned-element to item perform command-value perform run-command
call static 'j_delete' using by value saved-element end-call
call static 'j_object_into' using by reference close-callback end-call
move 'ui.hideNotification' to text-value
call static 'j_set_string' using by value close-callback by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_array_into' using by reference owned-list end-call
call static 'j_clone_into' using by value owned-element by reference item end-call
call static 'j_append' using by value owned-list item end-call
call static 'j_object_into' using by reference item end-call
move element-id to text-value
call static 'j_set_string' using by value item by reference z'id' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_get_into' using by value item by reference z'id' temp end-call
call static 'j_clone_into' using by value temp by reference obj end-call
call static 'j_append' using by value owned-list obj end-call
call static 'j_delete' using by value item end-call
call static 'j_set' using by value close-callback by reference z'args' by value owned-list end-call
move owned-element to target move 'query' to kind perform new-command
move 'selector' to key-text move '.notification-close' to value-text perform command-string perform run-command
call static 'j_clone_into' using by value answer by reference saved-element end-call
move saved-element to target move 'listen' to kind perform new-command
move 'id' to key-text move element-id to value-text perform command-string
move 'event' to key-text move 'click' to value-text perform command-string
move 'callback' to key-text move close-callback to item perform command-value perform run-command
call static 'j_delete' using by value saved-element end-call
move null to target move 'schedule' to kind perform new-command
move 'id' to key-text move element-id to value-text perform command-string
move 3000 to number-value
if op = 'ui.showAchievementNotification' move 1000 to number-value end-if
call static 'j_get_into' using by value options-node by reference z'duration' item end-call
if item not = null move function J-NUM(item,' ') to number-value end-if
if op = 'ui.showAchievementNotification' and number-value = 0 move 1000 to number-value end-if
move 'delay' to key-text perform command-number
move 'callback' to key-text move close-callback to item perform command-value perform run-command
call static 'j_delete' using by value close-callback end-call
move owned-element to result-node.
achievement-markup.
move spaces to icon-html reward-html reward-text content-text
move function J-STR(options-node,'achievement.iconPath') to id-text
if id-text not = spaces
string '<img src="' function trim(id-text) '" alt="' function trim(function J-STR(options-node,'achievement.name')) '" class="achievement-icon-img">' into icon-html end-string
else
call static 'j_object_into' using by reference child-request end-call
move 'model.achievement.getCategoryIcon' to text-value
call static 'j_set_string' using by value child-request by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_get_into' using by value options-node by reference z'achievement.category' item end-call
call static 'j_clone_into' using by value item by reference temp end-call
call static 'j_set' using by value child-request by reference z'args.category' by value temp end-call
call static 'j_object_into' using by reference child-response end-call
call static 'BUFO-GAME' using by value child-request ctx child-response end-call
string '<div class="achievement-icon-emoji">' function trim(function J-STR(child-response,'result')) '</div>' into icon-html end-string
call static 'j_delete' using by value child-request end-call
call static 'j_delete' using by value child-response end-call end-if
call static 'j_get_into' using by value options-node by reference z'achievement.reward' item end-call
if item not = null
move function J-NUM(item,'value') to number-value
call static 'h_decimal' using by reference number-value by value 12 0 1 by reference formatted by value 256 end-call
evaluate function J-STR(item,'type')
when 'productionBoost' string function trim(formatted) 'x production boost' into reward-text end-string
when 'clickBoost' string function trim(formatted) 'x click boost' into reward-text end-string
when 'generatorBoost' string function trim(formatted) 'x boost to ' function trim(function J-STR(item,'target')) ' generator' into reward-text end-string
when 'bufoBonus' string '+' function trim(formatted) ' Bufos' into reward-text end-string
when 'unlockGenerator' string 'Unlocked ' function trim(function J-STR(item,'target')) ' generator' into reward-text end-string
when 'unlockUpgrade' move 'Unlocked new upgrade' to reward-text
when 'unlockFeature' move 'Unlocked new feature' to reward-text
when other move 'Special bonus' to reward-text end-evaluate
string '<div class="achievement-notification-reward">Reward: ' function trim(reward-text) '</div>' into reward-html end-string end-if
string '<div class="achievement-notification-icon">' function trim(icon-html) '</div><div class="achievement-notification-content"><div class="achievement-notification-title">Achievement Unlocked!</div><div class="achievement-notification-name">' function trim(function J-STR(options-node,'achievement.name')) '</div><div class="achievement-notification-description">' function trim(function J-STR(options-node,'achievement.description')) '</div>' function
trim(reward-html) '</div>' into content-text end-string.
schedule-modal-closed.
if element-id = 'custom'
move function J-STR(ctx,'runtime.ui.customOptions.id') to element-id
else move function concatenate(function trim(element-id),'-modal') to element-id end-if
call static 'j_object_into' using by reference close-callback end-call
move 'ui.modalClosed' to text-value
call static 'j_set_string' using by value close-callback by reference z'operation' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_array_into' using by reference owned-list end-call
call static 'j_object_into' using by reference item end-call
move element-id to text-value
call static 'j_set_string' using by value item by reference z'id' text-value by value function length(function trim(text-value trailing)) end-call
call static 'j_get_into' using by value item by reference z'id' temp end-call
call static 'j_clone_into' using by value temp by reference obj end-call
call static 'j_append' using by value owned-list obj end-call
call static 'j_delete' using by value item end-call
call static 'j_set' using by value close-callback by reference z'args' by value owned-list end-call
perform next-id
move null to target move 'schedule' to kind perform new-command
move 'id' to key-text move id-text to value-text perform command-string
move 'delay' to key-text move 300 to number-value perform command-number
move 'callback' to key-text move close-callback to item perform command-value perform run-command
call static 'j_delete' using by value close-callback end-call.
copy 'ui-library-procedures.cpy'.
end program BUFO-API-UI.
