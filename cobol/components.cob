 identification division.
 program-id. BUFO-COMPONENTS recursive.
 environment division.
 configuration section.
 repository. function J-NUM function J-STR function all intrinsic.
 data division.
 local-storage section.
01 selection-request usage pointer.
01 selection-args usage pointer.
01 selection-ref usage pointer.
01 selection-id pic x(256).
01 selection-owner pic x(256).
01 selection-initialized binary-long.
01 notification-needed binary-long.
01 notification-count binary-long.
01 notification-index binary-long.
01 notification-size binary-long.
01 notification-active binary-long.
01 notification-node usage pointer.
 copy 'ui-library-vars.cpy' .
 01 component-node usage pointer.
 01 component-ref usage pointer.
 01 registry usage pointer.
 01 owned-target usage pointer.
 01 children-node usage pointer.
 01 record-node usage pointer.
 01 handlers usage pointer.
 01 nested-request usage pointer.
 01 nested-response usage pointer.
 01 nested-args usage pointer.
 01 saved-child usage pointer.
 01 data-node usage pointer.
 01 other-component usage pointer.
 01 cname pic x(64).
 01 reference-id pic x(256).
 01 other-id pic x(256).
 01 listener-id pic x(2048).
 01 key-cursor usage binary-long.
 01 key-index usage binary-long.
 01 key-source pic x(512).
 01 event-name pic x(256).
 01 callback-id pic x(256).
 01 saved-index usage binary-long.
 01 child-count usage binary-long.
 01 loop-index usage binary-long.
 01 notify-index usage binary-long.
 01 notify-count usage binary-long.
 01 kept-count usage binary-long.
 01 kept-index usage binary-long.
 01 incoming-index usage binary-long.
 01 incoming-count usage binary-long.
 01 keep-child usage binary-long.
 01 old-state usage pointer.
 01 current-state usage pointer.

 01 loop-count usage binary-long.
 01 subscriptions usage pointer.
 01 subscription usage pointer.
 01 selected-node usage pointer.
 01 previous-node usage pointer.
 01 event-payload usage pointer.
 01 list-source usage pointer.
 01 list-entry usage pointer.
 01 list-data usage pointer.
 01 child-ref usage pointer.
 01 parent-target usage pointer.
 01 child-kind pic x(64).
 01 child-class pic x(128).
 01 list-id pic x(256).
 01 sub-type pic x(32).
 01 factory-kind pic x(64).
 01 factory-key pic x(64).
 01 factory-options usage pointer.
 01 factory-output usage pointer.
 01 factory-reference usage pointer.
 01 factory-index usage binary-long.

 01 initialized-flag usage binary-long.
 01 match-index usage binary-long.
 linkage section.
 01 req usage pointer.
 01 ctx usage pointer.
 01 res usage pointer.
 procedure division using by value req ctx res.
 perform read-request
 evaluate true
 when op(1:12) = 'uiConstants.' or op(1:9) = 'uiStyles.'
 call static 'BUFO-UI-CONSTANTS' using by value req ctx res end-call goback
 when op(1:10) = 'templates.' call static 'BUFO-TEMPLATES' using by value req ctx res end-call goback
 when op(1:4) = 'dom.' or op(1:7) = 'styles.' call static 'BUFO-DOM' using by value req ctx res end-call goback
 when op(1:10) = 'animation.' call static 'BUFO-ANIMATION' using by value req ctx res end-call goback
 when op(1:8) = 'tooltip.' call static 'BUFO-TOOLTIP' using by value req ctx res end-call goback
 end-evaluate
 call static 'j_get_into' using by value lib by reference z'components' registry end-call
 if registry = null
 call static 'j_object_into' using by reference registry end-call
 call static 'j_set' using by value lib by reference z'components' by value registry end-call end-if
 if op = 'component.notifyState' or op = 'component.notifyEvent'
 perform notify-components perform finish-result goback end-if
 move 1 to j
 perform varying i from 1 by 1 until i > function length(function trim(op))
 if op(i:1) = '.' compute j = i + 1 end-if end-perform
 move op(j:) to method-name
 if method-name = 'initializeUI'
 call static 'j_object_into' using by reference factory-output end-call
 perform varying factory-index from 1 by 1 until factory-index > 6
 evaluate factory-index
 when 1 move 'ResourceDisplay' to factory-kind move 'resourceDisplay' to factory-key move 'resource-display' to id-text
 when 2 move 'ClickArea' to factory-kind move 'clickArea' to factory-key move 'frog-display' to id-text
 when 3 move 'GeneratorList' to factory-kind move 'generatorList' to factory-key move 'owned-generators' to id-text
 when 4 move 'Shop' to factory-kind move 'shop' to factory-key move 'buildings-container' to id-text
 when 5 move 'UpgradeList' to factory-kind move 'upgradeList' to factory-key move 'upgrades-container' to id-text
 when 6 move 'ProductionStats' to factory-kind move 'productionStats' to factory-key move 'production-stats' to id-text end-evaluate
 call static 'j_object_into' using by reference factory-options end-call
 call static 'j_set_string' using by value factory-options by reference z'id' id-text by value function length(function trim(id-text)) end-call
 perform invoke-factory
 call static 'j_delete' using by value factory-options end-call
 move factory-reference to saved-child move 'component.init' to text-value perform invoke-child
 call static 'j_set' using by value factory-output by reference function concatenate(function trim(factory-key),x'00') by value factory-reference end-call end-perform
 move factory-output to result-node perform finish-result goback end-if
 if method-name = 'createResourceDisplay' or method-name = 'createClickArea' or method-name = 'createGeneratorList' or method-name = 'createShop' or method-name = 'createUpgradeList' or method-name =
 'createProductionStats'
 move method-name(7:) to factory-kind
 if factory-kind = 'ResourceDisplay' or factory-kind = 'ClickArea'
 call static 'j_clone_into' using by value a(1) by reference factory-options end-call
 else call static 'j_object_into' using by reference factory-options end-call
 if a(1) not = null call static 'j_clone_into' using by value a(1) by reference temp end-call
 call static 'j_set' using by value factory-options by reference z'id' by value temp end-call end-if end-if
 perform invoke-factory
 call static 'j_delete' using by value factory-options end-call
 move factory-reference to result-node perform finish-result goback end-if
 if method-name = 'create' or method-name = 'constructor'
 perform create-component
 perform finish-result goback end-if
 move function J-STR(a(1),'$component') to reference-id
 if reference-id = spaces move s(1) to reference-id end-if
 call static 'j_get_into' using by value registry
 by reference function concatenate(function trim(reference-id),x'00') component-node end-call
 if component-node = null
 call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
 call static 'j_set_string' using by value res by reference z'error' z'Unknown component reference' by value 27 end-call
 perform finish-result goback end-if
 move function J-STR(component-node,'kind') to cname
 call static 'j_get_into' using by value component-node by reference z'element' target end-call
 call static 'j_get_into' using by value component-node by reference z'children' children-node end-call
 call static 'j_get_into' using by value component-node by reference z'handlers' handlers end-call
 evaluate method-name
 when 'imageError'
 call static 'j_get_into' using by value a(2) by reference z'target' target end-call
 move 'none' to text-value move 'display' to value-text perform set-style
 move 'nextSibling' to kind perform new-command perform run-command
 call static 'j_clone_into' using by value answer by reference owned-target end-call move owned-target to target
 move 'flex' to text-value move 'display' to value-text perform set-style
 call static 'j_delete' using by value owned-target end-call
 when 'handleClick' when 'handlePurchase'
 perform component-click
 when 'showTooltip' when 'handleInfoClick'
 perform component-tooltip
 when 'hideTooltip'
 call static 'j_object_into' using by reference nested-request end-call
 call static 'j_set_string' using by value nested-request by reference z'operation' z'tooltip.hideTooltip' by value 19 end-call
 call static 'BUFO-TOOLTIP' using by value nested-request ctx res end-call
 call static 'j_delete' using by value nested-request end-call
 when 'generateTooltipContent' when 'getUpgradeFlavorText' when 'getUpgradeIconHtml' when 'getGeneratorIconHtml'
 perform render-component
 call static 'j_get_into' using by value nested-response by reference z'result' item end-call perform return-value
 call static 'j_delete' using by value nested-response end-call
 when 'connectToState'
 move 'state' to sub-type perform add-subscription
 perform request-selection
 when 'selected' when 'isSubscribed'
 call static 'j_get_into' using by value component-node by reference z'subscriptions' subscriptions end-call
 call static 'j_size' using by value subscriptions by reference x'00' returning cnt end-call
 move null to subscription
 perform varying saved-index from 0 by 1 until saved-index >= cnt
 call static 'j_at_into' using by value subscriptions saved-index by reference subscription end-call
 if function J-STR(subscription,'id') = s(2) exit perform end-if
 move null to subscription end-perform
 if method-name = 'isSubscribed'
 move 0 to yes if subscription not = null move 1 to yes end-if
 call static 'j_set_boolean' using by value res by reference z'result' by value yes end-call
 if answer not = null call static 'j_delete' using by value answer end-call end-if goback end-if
 if subscription not = null
 call static 'j_boolean' using by value req by reference z'callbackResult.ok' returning yes end-call
 if yes = 1
 call static 'j_get_into' using by value req by reference z'callbackResult.value' item end-call
 call static 'j_clone_into' using by value item by reference answer end-call
 perform selection-ready end-if end-if
 when 'subscribeToEvent'
 move 'event' to sub-type perform add-subscription
 when 'getElement'
 call static 'j_get_into' using by value component-node by reference z'element' item end-call
 perform return-value
 when 'getId'
 call static 'j_get_into' using by value component-node by reference z'id' item end-call
 perform return-value
 when 'render'
 perform render-component
 call static 'j_get_into' using by value nested-response by reference z'result' item end-call
 perform return-value
 call static 'j_delete' using by value nested-response end-call
 when 'init'
 call static 'j_boolean' using by value component-node by reference z'initialized' returning initialized-flag end-call
 if initialized-flag = 0
 perform setup-component
 call static 'j_set_boolean' using by value component-node by reference z'initialized' by value 1 end-call end-if
 when 'update'
 call static 'j_get_into' using by value component-node by reference z'data' data-node end-call
 if cname = 'ShopItem'
 call static 'j_get_into' using by value a(2) by reference z'generator' item end-call
 if item = null perform finish-result goback end-if end-if
 if (cname = 'ShopItem' or cname = 'ResourceDisplay' ) and data-node not = null
 call static 'j_merge' using by value data-node a(2) end-call
 else call static 'j_clone_into' using by value a(2) by reference temp end-call
 call static 'j_set' using by value component-node by reference z'data' by value temp end-call end-if
 if cname not = 'Component' and cname not = 'Container'
 perform refresh-component end-if
 when 'setContent'
 call static 'j_get_into' using by value a(3) by reference z'replace' item end-call
 call static 'h_truthy' using by value item returning yes end-call
 if a(3) = null move 1 to yes end-if
 call static 'j_get_into' using by value a(3) by reference z'append' item end-call
 call static 'h_truthy' using by value item returning rc end-call
 if yes = 1 or rc = 1
 call static 'j_type' using by value a(2) by reference x'00' returning typ end-call
 if typ = 3
 move 'html' to kind perform new-command
 move 'value' to key-text move a(2) to item perform command-value
 if yes = 0 call static 'j_set_boolean' using by value command by reference z'append' by value 1 end-call end-if
 perform run-command
 else
 if yes = 1
 move 'html' to kind perform new-command
 move 'value' to key-text move spaces to value-text perform command-string
 perform run-command
 end-if
 move 'append' to kind perform new-command
 move 'child' to key-text move a(2) to item perform command-value
 perform run-command
 end-if end-if
 when 'addClass'
 move s(2) to text-value perform split-classes
 move 'class' to kind perform new-command
 move 'action' to key-text move 'add' to value-text perform command-string
 move 'names' to key-text move list-node to item perform command-value
 perform run-command
 call static 'j_delete' using by value list-node end-call
 when 'removeClass'
 move s(2) to text-value perform split-classes
 move 'class' to kind perform new-command
 move 'action' to key-text move 'remove' to value-text perform command-string
 move 'names' to key-text move list-node to item perform command-value
 perform run-command
 call static 'j_delete' using by value list-node end-call
 when 'toggleClass'
 move s(2) to text-value perform split-classes
 move 'class' to kind perform new-command
 move 'action' to key-text move 'toggle' to value-text perform command-string
 move 'names' to key-text move list-node to item perform command-value
 if a(3) not = null
 move 'force' to key-text move a(3) to item perform command-value
 end-if
 perform run-command
 call static 'j_delete' using by value list-node end-call
 when 'addEventListener'
 move s(2) to event-name move function J-STR(a(3),'$callback') to callback-id
 perform listener-key
 call static 'j_get_into' using by value component-node by reference z'handlers' handlers end-call
 call static 'j_has' using by value handlers by reference function concatenate(function trim(listener-id),x'00') returning yes end-call
 if yes = 0
 move 'listen' to kind perform new-command
 move 'id' to key-text move listener-id to value-text perform command-string
 move 'event' to key-text move event-name to value-text perform command-string
 move 'callback' to key-text move a(3) to item perform command-value
 perform run-command
 call static 'j_set_string' using by value handlers by reference function concatenate(function trim(listener-id),x'00') listener-id by value function length(function trim(listener-id)) end-call
 end-if
 when 'removeEventListener'
 move s(2) to event-name move function J-STR(a(3),'$callback') to callback-id
 perform listener-key
 move 'unlisten' to kind perform new-command
 move 'id' to key-text move listener-id to value-text perform command-string
 perform run-command
 call static 'j_remove' using by value handlers by reference function concatenate(function trim(listener-id),x'00') end-call
 when 'destroy'
 if cname = 'GoldenBufo' or cname = 'BossFight'
 move 'remove' to kind perform new-command perform run-command end-if
 perform clear-children
 call static 'j_size' using by value handlers by reference x'00' returning cnt end-call
 perform varying i from 0 by 1 until i >= cnt
 call static 'j_at_into' using by value handlers i by reference child end-call
 move function J-STR(child,' ') to listener-id
 move 'unlisten' to kind perform new-command
 move 'id' to key-text move listener-id to value-text perform command-string
 perform run-command
 end-perform
 call static 'j_object_into' using by reference temp end-call
 call static 'j_set' using by value component-node by reference z'handlers' by value temp end-call
 call static 'j_remove' using by value component-node by reference z'subscriptions' end-call
 call static 'j_remove' using by value component-node by reference z'autoRefresh' end-call
 perform refresh-notification-flag
 call static 'j_set_boolean' using by value component-node by reference z'initialized' by value 0 end-call
 move 'html' to kind perform new-command
 move 'value' to key-text move spaces to value-text perform command-string
 perform run-command
 when 'addChild'
 call static 'j_get_into' using by value a(2) by reference z'$component' item end-call
 move function J-STR(item,' ') to other-id
 call static 'j_get_into' using by value registry by reference function concatenate(function trim(other-id),x'00') other-component end-call
 if other-component not = null
 call static 'j_object_into' using by reference record-node end-call
 call static 'j_clone_into' using by value a(2) by reference temp end-call
 call static 'j_set' using by value record-node by reference z'component' by value temp end-call
 call static 'j_clone_into' using by value a(3) by reference temp end-call
 call static 'j_set' using by value record-node by reference z'data' by value temp end-call
 call static 'j_append' using by value children-node record-node end-call
 call static 'j_get_into' using by value other-component by reference z'element' child end-call
 move 'append' to kind perform new-command
 move 'child' to key-text move child to item perform command-value
 perform run-command
 move a(2) to saved-child move 'component.init' to text-value perform invoke-child
 move a(2) to item perform return-value end-if
 when 'getChildren'
 move children-node to item perform return-value
 when 'getChildById'
 perform find-child
 if match-index >= 0
 call static 'j_get_into' using by value record-node by reference z'component' item end-call
 perform return-value end-if
 when 'removeChild'
 perform find-child
 move 0 to yes if match-index >= 0 perform remove-child move 1 to yes end-if
 call static 'j_set_boolean' using by value res by reference z'result' by value yes end-call
 if answer not = null call static 'j_delete' using by value answer end-call end-if goback
 when 'clearChildren'
 perform clear-children
 when 'renderChildren'
 move 'html' to kind perform new-command
 move 'value' to key-text move spaces to value-text perform command-string
 perform run-command
 call static 'j_size' using by value children-node by reference x'00' returning child-count end-call
 perform varying saved-index from 0 by 1 until saved-index >= child-count
 call static 'j_at_into' using by value children-node saved-index by reference record-node end-call
 perform child-component
 call static 'j_get_into' using by value other-component by reference z'element' child end-call
 move 'append' to kind perform new-command
 move 'child' to key-text move child to item perform command-value
 perform run-command
 end-perform
 when 'setPurchaseAmount'
 call static 'j_clone_into' using by value a(2) by reference temp end-call
 call static 'j_set' using by value component-node by reference z'purchaseAmount' by value temp end-call
 if cname = 'Shop' perform refresh-shop else perform refresh-component end-if
 when 'updateGenerators'
 call static 'j_clone_into' using by value a(2) by reference temp end-call
 call static 'j_set' using by value component-node by reference z'items' by value temp end-call
 perform refresh-component
 when 'updateUpgrades'
 call static 'j_clone_into' using by value a(2) by reference temp end-call
 call static 'j_set' using by value component-node by reference z'items' by value temp end-call
 perform refresh-component
 when 'refreshStats' when 'updateStats' when 'refreshFrenzyIndicators' when 'refreshBanner'
 perform refresh-component
 when 'refreshGenerators'
 perform refresh-component
 when 'refreshUpgrades'
 perform refresh-component
 when 'updateCosts'
 perform refresh-shop
 when 'updateAffordability'
 perform refresh-shop
 when 'updateDisplay'
 perform refresh-component
 when 'updateButtonCost'
 perform refresh-component
 when other
 call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
 call static 'j_set_string' using by value res by reference z'error' z'Unknown component method' by value 24 end-call
 end-evaluate
 perform finish-result goback.
 create-component.
 move s(1) to cname move a(2) to options-node
 if op not = 'component.create'
 move a(1) to options-node
 evaluate true
 when op(1:16) = 'productionStats.' move 'ProductionStats' to cname
 when op(1:11) = 'goldenBufo.' move 'GoldenBufo' to cname
 when op(1:10) = 'bossFight.' move 'BossFight' to cname
 when op(1:10) = 'container.' move 'Container' to cname
 when op(1:16) = 'resourceDisplay.' move 'ResourceDisplay' to cname
 when op(1:10) = 'clickArea.' move 'ClickArea' to cname
 when op(1:14) = 'generatorItem.' move 'GeneratorItem' to cname
 when op(1:14) = 'generatorList.' move 'GeneratorList' to cname
 when op(1:9) = 'shopItem.' move 'ShopItem' to cname
 when op(1:5) = 'shop.' move 'Shop' to cname
 when op(1:12) = 'upgradeItem.' move 'UpgradeItem' to cname
 when op(1:12) = 'upgradeList.' move 'UpgradeList' to cname
 when other move 'Component' to cname end-evaluate end-if
 if cname not = 'Component' and cname not = 'Container' and cname not = 'ResourceDisplay' and cname not = 'ClickArea' and cname not = 'GeneratorItem' and cname not = 'GeneratorList'
 and cname not = 'ShopItem' and cname not = 'Shop' and cname not = 'UpgradeItem' and cname not = 'UpgradeList' and cname not = 'ProductionStats' and cname not = 'GoldenBufo' and cname not = 'BossFight'
 call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
 call static 'j_set_string' using by value res by reference z'error' z'Unknown component kind' by value 22 end-call exit paragraph end-if
 perform next-id move id-text to reference-id
 call static 'j_object_into' using by reference component-node end-call
 call static 'j_set' using by value registry by reference function concatenate(function trim(reference-id),x'00') by value component-node end-call
 move cname to text-value
 call static 'j_set_string' using by value component-node by reference z'kind' text-value by value function length(function trim(text-value trailing)) end-call
 call static 'j_clone_into' using by value options-node by reference temp end-call
 call static 'j_set' using by value component-node by reference z'options' by value temp end-call
 call static 'j_array_into' using by reference children-node end-call
 call static 'j_set' using by value component-node by reference z'children' by value children-node end-call
 call static 'j_object_into' using by reference handlers end-call
 call static 'j_set' using by value component-node by reference z'handlers' by value handlers end-call
 move function J-STR(options-node,'id') to id-text
 if id-text = spaces
 evaluate cname
 when 'ProductionStats' move 'production-stats' to id-text
 when 'ResourceDisplay' move 'resource-display' to id-text
 when 'ClickArea' move 'frog-display' to id-text
 when 'GeneratorList' move 'owned-generators' to id-text
 when 'Shop' move 'buildings-container' to id-text
 when 'UpgradeList' move 'upgrades-container' to id-text
 end-evaluate end-if
 if id-text not = spaces
 move id-text to text-value
 call static 'j_set_string' using by value component-node by reference z'id' text-value by value function length(function trim(text-value trailing)) end-call
 else call static 'j_set_null' using by value component-node by reference z'id' end-call end-if
 call static 'j_get_into' using by value options-node by reference z'element' target end-call
 if target = null and id-text not = spaces
 move 'byId' to kind perform new-command
 move 'id' to key-text move id-text to value-text perform command-string
 perform run-command
 call static 'j_clone_into' using by value answer by reference owned-target end-call
 move owned-target to target
 call static 'j_type' using by value target by reference x'00' returning typ end-call
 if typ not = 5 call static 'j_delete' using by value owned-target end-call move null to owned-target target end-if end-if
 if target = null
 move function J-STR(options-node,'tagName') to value-text
 if value-text = spaces move 'div' to value-text end-if
 move 'create' to kind perform new-command move 'tag' to key-text perform command-string perform run-command
 call static 'j_clone_into' using by value answer by reference owned-target end-call move owned-target to target
 if id-text not = spaces
 move 'attribute' to kind perform new-command
 move 'name' to key-text move 'id' to value-text perform command-string
 move 'value' to key-text move id-text to value-text perform command-string
 perform run-command
 end-if end-if
 call static 'j_clone_into' using by value target by reference temp end-call
 call static 'j_set' using by value component-node by reference z'element' by value temp end-call
 move function J-STR(options-node,'className') to text-value
 if text-value = spaces
 evaluate cname
 when 'ProductionStats' move 'production-stats panel' to text-value
 when 'GoldenBufo' move 'golden-bufo-layer' to text-value
 when 'BossFight' move 'boss-layer' to text-value
 when 'ResourceDisplay' move 'resource-display' to text-value
 when 'ClickArea' move 'frog-display' to text-value
 when 'GeneratorList' move 'owned-generators-container panel' to text-value
 when 'Shop' move 'buildings-container' to text-value
 when 'UpgradeList' move 'upgrades-grid' to text-value end-evaluate end-if
 call static 'j_get_into' using by value options-node by reference z'element' item end-call
 if text-value not = spaces and item = null
 perform split-classes
 move 'class' to kind perform new-command
 move 'action' to key-text move 'add' to value-text perform command-string
 move 'names' to key-text move list-node to item perform command-value
 perform run-command
 call static 'j_delete' using by value list-node end-call end-if
 move function J-STR(options-node,'template') to html
 if html not = spaces perform set-html end-if
 if owned-target not = null call static 'j_delete' using by value owned-target end-call end-if
 call static 'j_object_into' using by reference result-node end-call
 move reference-id to text-value
 call static 'j_set_string' using by value result-node by reference z'$component' text-value by value function length(function trim(text-value trailing)) end-call
 .
 setup-component.
 if cname = 'ResourceDisplay' or cname = 'ProductionStats' or cname = 'GeneratorList' or cname = 'Shop' or cname = 'UpgradeList' or cname = 'GoldenBufo' or cname = 'BossFight'
 call static 'j_set_boolean' using by value component-node by reference z'autoRefresh' by value 1 end-call
 call static 'j_set_boolean' using by value ctx by reference z'uiLibrary.needsNotifications' by value 1 end-call end-if
 if cname = 'GoldenBufo' or cname = 'BossFight'
 move target to parent-target
 call static 'j_parse_into' using by reference z'{"$element":"body"}' by value 19 by reference target end-call
 move 'append' to kind perform new-command move 'child' to key-text move parent-target to item perform command-value perform run-command
 call static 'j_delete' using by value target end-call move parent-target to target end-if
 if cname not = 'Component' and cname not = 'Container'
 perform refresh-component end-if
 if cname = 'ShopItem' or cname = 'UpgradeItem' or cname = 'ClickArea' or cname = 'GeneratorItem' or cname = 'Shop' or cname = 'GoldenBufo' or cname = 'BossFight'
 move 'click' to event-name move 'component.handleClick' to text-value perform attach-internal end-if
 if cname = 'ShopItem' or cname = 'GeneratorItem'
 move 'error' to event-name move 'component.imageError' to text-value perform attach-internal end-if
 if cname = 'UpgradeItem'
 move 'mouseenter' to event-name move 'component.showTooltip' to text-value perform attach-internal
 move 'mouseleave' to event-name move 'component.hideTooltip' to text-value perform attach-internal end-if.
 refresh-component.
 if cname = 'GeneratorList' or cname = 'Shop' or cname = 'UpgradeList'
 perform refresh-list exit paragraph end-if
 if cname = 'ResourceDisplay' and method-name not = 'update'
 call static 'j_get_into' using by value ctx by reference z'state.resources' data-node end-call
 if data-node not = null
 call static 'j_clone_into' using by value data-node by reference temp end-call
 call static 'j_set' using by value component-node by reference z'data' by value temp end-call
 move temp to data-node move 0 to number-value
 call static 'j_get_into' using by value ctx by reference z'state.generators' list-node end-call
 call static 'j_size' using by value list-node by reference x'00' returning cnt end-call
 perform varying i from 0 by 1 until i >= cnt
 call static 'j_at_into' using by value list-node i by reference item end-call
 compute number-value = number-value + function J-NUM(item,'totalProduction') end-perform
 call static 'j_set_number' using by value data-node by reference z'productionRate' number-value end-call
 end-if end-if
 perform render-component
 move function J-STR(nested-response,'result') to html
 move 1 to morph-html perform set-html move 0 to morph-html
 call static 'j_delete' using by value nested-response end-call.
 render-component.
 call static 'j_object_into' using by reference nested-request end-call
 call static 'j_object_into' using by reference nested-response end-call
 call static 'j_clone_into' using by value component-node by reference temp end-call
 call static 'j_set' using by value nested-request by reference z'component' by value temp end-call
 call static 'j_set_string' using by value nested-request by reference z'method' method-name by value function length(function trim(method-name)) end-call
 call static 'j_set_number' using by value nested-request by reference z'now' now-ms end-call
 call static 'BUFO-COMPONENT-RENDER' using by value nested-request ctx nested-response end-call
 call static 'j_delete' using by value nested-request end-call.
 split-classes.
 call static 'j_array_into' using by reference list-node end-call
 move 1 to j
 perform varying i from 1 by 1 until i > function length(function trim(text-value trailing)) + 1
 if text-value(i:1) = ' ' or i > function length(function trim(text-value trailing))
 if i > j
 compute k = i - j
 call static 'j_object_into' using by reference temp end-call
 call static 'j_set_string' using by value temp by reference z'value' text-value(j:k) by value k end-call
 call static 'j_get_into' using by value temp by reference z'value' child end-call
 call static 'j_clone_into' using by value child by reference child end-call
 call static 'j_append' using by value list-node child end-call
 call static 'j_delete' using by value temp end-call end-if
 compute j = i + 1 end-if end-perform.
 listener-key.
 move spaces to listener-id key-source move 1 to key-cursor
 string function trim(reference-id) '/' into listener-id with pointer key-cursor end-string
 move function concatenate(function trim(event-name),'/',function trim(callback-id)) to key-source
 perform varying key-index from 1 by 1 until key-index > function length(function trim(key-source trailing))
 evaluate key-source(key-index:1)
 when '.' string '%2E' into listener-id with pointer key-cursor end-string
 when '%' string '%25' into listener-id with pointer key-cursor end-string
 when other string key-source(key-index:1) into listener-id with pointer key-cursor end-string end-evaluate end-perform.
 find-child.
 move -1 to match-index
 call static 'j_size' using by value children-node by reference x'00' returning child-count end-call
 perform varying saved-index from 0 by 1 until saved-index >= child-count
 call static 'j_at_into' using by value children-node saved-index by reference record-node end-call
 perform child-component
 move function J-STR(a(2),'$component') to other-id
 if other-id not = spaces
 if other-id = function J-STR(record-node,'component.$component') move saved-index to match-index exit perform end-if
 else if s(2) = function J-STR(other-component,'id') move saved-index to match-index exit perform end-if end-if
 end-perform.
 child-component.
 move function J-STR(record-node,'component.$component') to other-id
 call static 'j_get_into' using by value registry by reference function concatenate(function trim(other-id),x'00') other-component end-call.
 invoke-child.
 call static 'j_object_into' using by reference nested-request end-call
 call static 'j_object_into' using by reference nested-response end-call
 call static 'j_array_into' using by reference nested-args end-call
 call static 'j_set_string' using by value nested-request by reference z'operation' text-value by value function length(function trim(text-value)) end-call
 call static 'j_clone_into' using by value saved-child by reference temp end-call
 call static 'j_append' using by value nested-args temp end-call
 if text-value = 'component.update' and data-node not = null
 call static 'j_clone_into' using by value data-node by reference temp end-call
 call static 'j_append' using by value nested-args temp end-call end-if
 call static 'j_set' using by value nested-request by reference z'args' by value nested-args end-call
 call static 'BUFO-COMPONENTS' using by value nested-request ctx nested-response end-call
 call static 'j_delete' using by value nested-request end-call
 call static 'j_delete' using by value nested-response end-call.
 remove-child.
 call static 'j_get_into' using by value record-node by reference z'component' saved-child end-call
 move 'component.destroy' to text-value perform invoke-child
 perform child-component
 call static 'j_get_into' using by value other-component by reference z'element' item end-call
 move target to owned-target move item to target
 move 'remove' to kind perform new-command
 perform run-command
 move owned-target to target move null to owned-target
 call static 'h_array_remove' using by value children-node match-index end-call.
 clear-children.
 call static 'j_size' using by value children-node by reference x'00' returning child-count end-call
 perform until child-count = 0
 call static 'j_at_into' using by value children-node by value 0 by reference record-node end-call
 move 0 to match-index perform remove-child
 call static 'j_size' using by value children-node by reference x'00' returning child-count end-call end-perform.

 refresh-notification-flag.
 move 0 to notification-needed
 call static 'j_size' using by value registry by reference x'00' returning notification-count end-call
 perform varying notification-index from 0 by 1 until notification-index >= notification-count
 call static 'j_at_into' using by value registry notification-index by reference notification-node end-call
 call static 'j_boolean' using by value notification-node by reference z'autoRefresh' returning notification-active end-call
 call static 'j_size' using by value notification-node by reference z'subscriptions' returning notification-size end-call
 if notification-active = 1 or notification-size > 0 move 1 to notification-needed end-if end-perform
 call static 'j_set_boolean' using by value ctx by reference z'uiLibrary.needsNotifications' by value notification-needed end-call.

 add-subscription.
 call static 'j_get_into' using by value component-node by reference z'subscriptions' subscriptions end-call
 if subscriptions = null call static 'j_array_into' using by reference subscriptions end-call
 call static 'j_set' using by value component-node by reference z'subscriptions' by value subscriptions end-call end-if
 call static 'j_object_into' using by reference subscription end-call
 perform next-id
 call static 'j_set_string' using by value subscription by reference z'id' id-text by value function length(function trim(id-text)) end-call
 call static 'j_set_string' using by value subscription by reference z'owner' reference-id by value function length(function trim(reference-id)) end-call
 call static 'j_set_string' using by value subscription by reference z'type' sub-type by value function length(function trim(sub-type)) end-call
 call static 'j_clone_into' using by value a(2) by reference temp end-call
 call static 'j_set' using by value subscription by reference z'selector' by value temp end-call
 call static 'j_clone_into' using by value a(3) by reference temp end-call
 call static 'j_set' using by value subscription by reference z'callback' by value temp end-call
 call static 'j_append' using by value subscriptions subscription end-call
 call static 'j_set_boolean' using by value ctx by reference z'uiLibrary.needsNotifications' by value 1 end-call.
 request-selection.
 call static 'j_get_into' using by value subscription by reference z'selector' callback-node end-call
 call static 'j_type' using by value callback-node by reference x'00' returning typ end-call
 if typ = 3
 move function J-STR(callback-node,' ') to key-text
 call static 'j_get_into' using by value ctx by reference z'state' item end-call
 call static 'j_get_into' using by value item by reference function concatenate(function trim(key-text),x'00') item end-call
 if answer not = null call static 'j_delete' using by value answer end-call end-if
 call static 'j_clone_into' using by value item by reference answer end-call
 perform selection-ready
 else
 move 'callback' to kind perform new-command
 move 'callback' to key-text move callback-node to item perform command-value
 call static 'j_get_into' using by value ctx by reference z'state' item end-call
 move 'value' to key-text perform command-value
 move 'component.selected' to text-value perform subscription-request
 call static 'j_set' using by value command by reference z'continuation' by value selection-request end-call
 perform subscription-guard
 perform run-command end-if.
 selection-ready.
 call static 'j_get_into' using by value subscription by reference z'previous' previous-node end-call
 call static 'h_json_equal' using by value previous-node answer returning yes end-call
 call static 'j_boolean' using by value subscription by reference z'hasPrevious' returning selection-initialized end-call
 if yes = 0 or selection-initialized = 0
 call static 'j_clone_into' using by value answer by reference selected-node end-call
 call static 'j_set' using by value subscription by reference z'previous' by value selected-node end-call
 call static 'j_set_boolean' using by value subscription by reference z'hasPrevious' by value 1 end-call
 call static 'j_get_into' using by value subscription by reference z'callback' callback-node end-call
 move 'callback' to kind perform new-command move 'callback' to key-text move callback-node to item perform command-value
 move 'value' to key-text move selected-node to item perform command-value
 perform subscription-guard perform run-command end-if.
 subscription-guard.
 move 'component.isSubscribed' to text-value perform subscription-request
 call static 'j_set' using by value command by reference z'guard' by value selection-request end-call.
 subscription-request.
 call static 'j_object_into' using by reference selection-request end-call
 call static 'j_set_string' using by value selection-request by reference z'operation' text-value by value function length(function trim(text-value)) end-call
 call static 'j_array_into' using by reference selection-args end-call
 call static 'j_object_into' using by reference selection-ref end-call
 move function J-STR(subscription,'owner') to selection-owner
 call static 'j_set_string' using by value selection-ref by reference z'$component' selection-owner by value function length(function trim(selection-owner)) end-call
 call static 'j_append' using by value selection-args selection-ref end-call
 call static 'j_get_into' using by value subscription by reference z'id' item end-call
 call static 'j_clone_into' using by value item by reference selection-ref end-call
 call static 'j_append' using by value selection-args selection-ref end-call
 call static 'j_set' using by value selection-request by reference z'args' by value selection-args end-call.

 notify-components.
 call static 'j_size' using by value registry by reference x'00' returning notify-count end-call
 perform varying notify-index from 0 by 1 until notify-index >= notify-count
 call static 'j_at_into' using by value registry notify-index by reference component-node end-call
 call static 'j_get_into' using by value component-node by reference z'subscriptions' subscriptions end-call
 call static 'j_size' using by value subscriptions by reference x'00' returning cnt end-call
 perform varying saved-index from 0 by 1 until saved-index >= cnt
 call static 'j_at_into' using by value subscriptions saved-index by reference subscription end-call
 move function J-STR(subscription,'type') to sub-type
 if op = 'component.notifyState' and sub-type = 'state' perform request-selection end-if
 if op = 'component.notifyEvent' and sub-type = 'event' and s(1) = function J-STR(subscription,'selector')
 call static 'j_get_into' using by value subscription by reference z'callback' callback-node end-call
 move 'callback' to kind perform new-command move 'callback' to key-text move callback-node to item perform command-value
 move 'value' to key-text move a(2) to item perform command-value perform subscription-guard perform run-command end-if
 end-perform
 call static 'j_boolean' using by value component-node by reference z'initialized' returning yes end-call
 if yes = 1
 call static 'j_boolean' using by value component-node by reference z'autoRefresh' returning yes end-call
 if yes = 1
 call static 'j_get_into' using by value ctx by reference z'state' current-state end-call
 call static 'j_get_into' using by value component-node by reference z'autoState' old-state end-call
 call static 'h_json_equal' using by value old-state current-state returning yes end-call
 move function J-STR(component-node,'kind') to cname
 if yes = 0 or cname = 'GoldenBufo' or cname = 'BossFight'
 call static 'j_clone_into' using by value current-state by reference temp end-call
 call static 'j_set' using by value component-node by reference z'autoState' by value temp end-call
 call static 'j_get_into' using by value component-node by reference z'element' target end-call
 call static 'j_get_into' using by value component-node by reference z'children' children-node end-call
 move 'refresh' to method-name perform refresh-component end-if end-if end-if
 end-perform.
 refresh-list.
 if cname not = 'UpgradeList' perform clear-children end-if
 move target to parent-target
 call static 'j_get_into' using by value component-node by reference z'items' list-source end-call
 if list-source = null
 if cname = 'UpgradeList'
 call static 'j_get_into' using by value ctx by reference z'state.upgrades.available' list-source end-call
 else call static 'j_get_into' using by value ctx by reference z'state.generators' list-source end-call end-if end-if
 if cname = 'Shop'
 move function concatenate( '<div class="purchase-controls"><div class="purchase-amount-buttons"><button class="purchase-amount-button" data-amount="1">1</button><button' ,
 ' class="purchase-amount-button" data-amount="10">10</button><button class="purchase-amount-button" data-amount="100">100</button><button cla' , 'ss="purchase-amount-button" data-amount="-1">Max</button></div></div>' )
 to
 html
 else move spaces to html end-if
 if cname not = 'UpgradeList' perform set-html else perform prune-upgrades end-if
 call static 'j_size' using by value list-source by reference x'00' returning loop-count end-call
 move 0 to child-count
 perform varying loop-index from 0 by 1 until loop-index >= loop-count
 call static 'j_at_into' using by value list-source loop-index by reference list-entry end-call
 move list-entry to list-data
 if cname = 'UpgradeList'
 call static 'j_type' using by value list-entry by reference x'00' returning typ end-call
 if typ = 3
 move function J-STR(list-entry,' ') to list-id
 call static 'j_get_into' using by value ctx by reference z'catalog.upgrades' list-node end-call
 call static 'j_size' using by value list-node by reference x'00' returning cnt end-call
 move null to list-data
 perform varying i from 0 by 1 until i >= cnt
 call static 'j_at_into' using by value list-node i by reference item end-call
 if list-id = function J-STR(item,'id') move item to list-data exit perform end-if end-perform end-if end-if
 move 1 to yes
 if cname = 'GeneratorList' and function J-NUM(list-data,'count') <= 0 move 0 to yes end-if
 if cname = 'Shop'
 call static 'j_boolean' using by value list-data by reference z'unlocked' returning yes end-call end-if
 if list-data = null move 0 to yes end-if
 if yes = 1
 add 1 to child-count
 move function J-STR(list-data,'id') to list-id
 evaluate cname
 when 'GeneratorList' move 'GeneratorItem' to child-kind move 'owned-generator' to child-class
 move function concatenate('generator-',function trim(list-id)) to other-id
 when 'Shop' move 'ShopItem' to child-kind move 'building-item' to child-class
 move function concatenate('shop-item-',function trim(list-id)) to other-id
 when 'UpgradeList' move 'UpgradeItem' to child-kind move 'upgrade-icon-container' to child-class
 move function concatenate('upgrade-container-',function trim(list-id)) to other-id end-evaluate
 if cname = 'UpgradeList' perform existing-upgrade else move 0 to keep-child end-if
 if keep-child = 0 perform create-list-child end-if end-if end-perform
 if child-count = 0 and cname not = 'Shop'
 if cname = 'GeneratorList' move '<div class="generators-container"><div class="empty-generators">No frogs yet! Buy some from the shop.</div></div>' to html
 else move '<div class="empty-upgrades">No upgrades available yet.</div>' to html end-if perform set-html end-if
 move parent-target to target
 if cname = 'Shop' perform refresh-shop end-if.
 create-list-child.
 call static 'j_object_into' using by reference nested-request end-call
 call static 'j_object_into' using by reference nested-response end-call
 call static 'j_array_into' using by reference nested-args end-call
 call static 'j_set_string' using by value nested-request by reference z'operation' z'component.create' by value 16 end-call
 call static 'j_object_into' using by reference temp end-call
 call static 'j_set_string' using by value temp by reference z'value' child-kind by value function length(function trim(child-kind)) end-call
 call static 'j_get_into' using by value temp by reference z'value' item end-call
 call static 'j_clone_into' using by value item by reference item end-call
 call static 'j_append' using by value nested-args item end-call call static 'j_delete' using by value temp end-call
 call static 'j_object_into' using by reference options-node end-call
 call static 'j_set_string' using by value options-node by reference z'id' other-id by value function length(function trim(other-id)) end-call
 move function concatenate(function trim(child-class),' category-',function trim(function J-STR(list-data,'category'))) to text-value
 call static 'j_set_string' using by value options-node by reference z'className' text-value by value function length(function trim(text-value)) end-call
 call static 'j_append' using by value nested-args options-node end-call
 call static 'j_set' using by value nested-request by reference z'args' by value nested-args end-call
 call static 'BUFO-COMPONENTS' using by value nested-request ctx nested-response end-call
 call static 'j_get_into' using by value nested-response by reference z'result' item end-call
 call static 'j_clone_into' using by value item by reference child-ref end-call
 call static 'j_delete' using by value nested-request end-call call static 'j_delete' using by value nested-response end-call
 move function J-STR(child-ref,'$component') to other-id
 call static 'j_get_into' using by value registry by reference function concatenate(function trim(other-id),x'00') other-component end-call
 if cname = 'Shop'
 call static 'j_object_into' using by reference data-node end-call
 call static 'j_clone_into' using by value list-data by reference temp end-call
 call static 'j_set' using by value data-node by reference z'generator' by value temp end-call
 move function J-NUM(component-node,'purchaseAmount') to number-value if number-value = 0 move 1 to number-value end-if
 call static 'j_set_number' using by value data-node by reference z'purchaseAmount' number-value end-call
 call static 'j_set' using by value other-component by reference z'data' by value data-node end-call
 else call static 'j_clone_into' using by value list-data by reference temp end-call
 call static 'j_set' using by value other-component by reference z'data' by value temp end-call end-if
 call static 'j_object_into' using by reference record-node end-call
 call static 'j_clone_into' using by value child-ref by reference temp end-call
 call static 'j_set' using by value record-node by reference z'component' by value temp end-call
 call static 'j_clone_into' using by value list-data by reference temp end-call
 call static 'j_set' using by value record-node by reference z'data' by value temp end-call
 call static 'j_append' using by value children-node record-node end-call
 call static 'j_get_into' using by value other-component by reference z'element' child end-call
 move parent-target to target move 'append' to kind perform new-command
 move 'child' to key-text move child to item perform command-value perform run-command
 move child-ref to saved-child move 'component.init' to text-value perform invoke-child
 call static 'j_delete' using by value child-ref end-call.


 attach-internal.
 call static 'j_object_into' using by reference callback-node end-call
 call static 'j_set_string' using by value callback-node by reference z'operation' text-value by value function length(function trim(text-value)) end-call
 call static 'j_array_into' using by reference nested-args end-call
 call static 'j_object_into' using by reference temp end-call
 call static 'j_set_string' using by value temp by reference z'$component' reference-id by value function length(function trim(reference-id)) end-call
 call static 'j_append' using by value nested-args temp end-call
 call static 'j_set' using by value callback-node by reference z'args' by value nested-args end-call
 move function concatenate(function trim(reference-id),'/',function trim(event-name),'/internal') to listener-id
 move 'listen' to kind perform new-command
 move 'id' to key-text move listener-id to value-text perform command-string
 move 'event' to key-text move event-name to value-text perform command-string
 move 'callback' to key-text move callback-node to item perform command-value
 if event-name = 'error' call static 'j_set_boolean' using by value command by reference z'capture' by value 1 end-call end-if
 call static 'j_set_boolean' using by value command by reference z'preventDefault' by value 1 end-call
 call static 'j_set_boolean' using by value command by reference z'stopPropagation' by value 1 end-call
 perform run-command
 call static 'j_delete' using by value callback-node end-call
 call static 'j_set_string' using by value handlers by reference function concatenate(function trim(listener-id),x'00') listener-id by value function length(function trim(listener-id)) end-call.
 component-click.
 if cname = 'GoldenBufo' or cname = 'BossFight'
 move target to parent-target
 call static 'j_get_into' using by value a(2) by reference z'target' target end-call
 move 'closest' to kind perform new-command move 'selector' to key-text move '[data-action]' to value-text perform command-string perform run-command
 call static 'j_clone_into' using by value answer by reference owned-target end-call move owned-target to target
 move 'getAttribute' to kind perform new-command move 'name' to key-text move 'data-action' to value-text perform command-string perform run-command
 move function J-STR(answer,' ') to text-value
 call static 'j_delete' using by value owned-target end-call move null to owned-target move parent-target to target
 if text-value = spaces exit paragraph end-if
 call static 'j_array_into' using by reference list-node end-call
 call static 'j_object_into' using by reference nested-request end-call
 call static 'j_set_string' using by value nested-request by reference z'operation' z'action' by value 6 end-call
 call static 'j_set_string' using by value nested-request by reference z'args.action' text-value by value function length(function trim(text-value)) end-call
 call static 'j_set_boolean' using by value nested-request by reference z'browser' by value 1 end-call
 call static 'j_append' using by value list-node nested-request end-call
 call static 'j_set' using by value res by reference z'after' by value list-node end-call exit paragraph end-if
 if cname = 'GeneratorItem' perform component-tooltip exit paragraph end-if
 if cname = 'Shop'
 call static 'j_get_into' using by value a(2) by reference z'target' target end-call
 move 'getAttribute' to kind perform new-command move 'name' to key-text move 'data-amount' to value-text perform command-string perform run-command
 move function J-STR(answer,' ') to text-value
 if text-value = spaces exit paragraph end-if
 compute number-value = function numval(text-value)
 call static 'j_set_number' using by value component-node by reference z'purchaseAmount' number-value end-call
 move target to saved-child
 call static 'j_get_into' using by value component-node by reference z'element' target end-call
 perform refresh-shop exit paragraph end-if
 if cname = 'ShopItem'
 call static 'j_get_into' using by value a(2) by reference z'target' child end-call
 move target to parent-target move child to target
 move 'closest' to kind perform new-command move 'selector' to key-text move '.buy-button' to value-text perform command-string perform run-command
 call static 'j_type' using by value answer by reference x'00' returning typ end-call move parent-target to target
 if typ = 0 perform component-tooltip exit paragraph end-if end-if
 call static 'j_array_into' using by reference list-node end-call
 if cname = 'ShopItem'
 call static 'j_object_into' using by reference nested-request end-call
 call static 'j_set_string' using by value nested-request by reference z'operation' z'action' by value 6 end-call
 call static 'j_set_string' using by value nested-request by reference z'args.action' z'quantity' by value 8 end-call
 move function J-NUM(component-node,'data.purchaseAmount') to number-value if number-value = 0 move 1 to number-value end-if
 call static 'h_decimal' using by reference number-value by value 0 0 0 by reference formatted by value 256 end-call
 call static 'j_set_string' using by value nested-request by reference z'args.amount' formatted by value function length(function trim(formatted)) end-call
 call static 'j_append' using by value list-node nested-request end-call end-if
 call static 'j_object_into' using by reference nested-request end-call
 call static 'j_set_string' using by value nested-request by reference z'operation' z'action' by value 6 end-call
 evaluate cname
 when 'ShopItem'
 move 'buyGenerator' to text-value move function J-STR(component-node,'data.generator.id') to other-id
 when 'UpgradeItem'
 move 'buyUpgrade' to text-value move function J-STR(component-node,'data.id') to other-id
 when 'ClickArea'
 move 'click' to text-value
 when other call static 'j_delete' using by value nested-request end-call
 call static 'j_delete' using by value list-node end-call exit paragraph end-evaluate
 call static 'j_set_string' using by value nested-request by reference z'args.action' text-value by value function length(function trim(text-value)) end-call
 call static 'j_set_string' using by value nested-request by reference z'args.id' other-id by value function length(function trim(other-id)) end-call
 move function J-NUM(a(2),'clientX') to number-value call static 'j_set_number' using by value nested-request by reference z'args.x' number-value end-call
 move function J-NUM(a(2),'clientY') to number-value call static 'j_set_number' using by value nested-request by reference z'args.y' number-value end-call
 call static 'j_set_boolean' using by value nested-request by reference z'browser' by value 1 end-call
 call static 'j_append' using by value list-node nested-request end-call
 call static 'j_set' using by value res by reference z'after' by value list-node end-call.
 component-tooltip.
 move 'generateTooltipContent' to method-name perform render-component
 call static 'j_object_into' using by reference nested-request end-call
 call static 'j_set_string' using by value nested-request by reference z'operation' z'tooltip.showTooltip' by value 19 end-call
 call static 'j_array_into' using by reference nested-args end-call
 call static 'j_get_into' using by value nested-response by reference z'result' item end-call
 call static 'j_clone_into' using by value item by reference temp end-call call static 'j_append' using by value nested-args temp end-call
 call static 'j_clone_into' using by value a(2) by reference temp end-call call static 'j_append' using by value nested-args temp end-call
 call static 'j_set' using by value nested-request by reference z'args' by value nested-args end-call
 call static 'BUFO-TOOLTIP' using by value nested-request ctx res end-call
 call static 'j_delete' using by value nested-request end-call call static 'j_delete' using by value nested-response end-call.


 existing-upgrade.
 move 0 to keep-child
 call static 'j_size' using by value children-node by reference x'00' returning kept-count end-call
 perform varying kept-index from 0 by 1 until kept-index >= kept-count
 call static 'j_at_into' using by value children-node kept-index by reference item end-call
 if list-id = function J-STR(item,'data.id') move 1 to keep-child exit perform end-if end-perform.
 prune-upgrades.
 call static 'j_size' using by value children-node by reference x'00' returning kept-count end-call
 call static 'j_size' using by value list-source by reference x'00' returning incoming-count end-call
 compute kept-index = kept-count - 1
 perform until kept-index < 0
 call static 'j_at_into' using by value children-node kept-index by reference record-node end-call
 move function J-STR(record-node,'data.id') to list-id move 0 to keep-child
 perform varying incoming-index from 0 by 1 until incoming-index >= incoming-count
 call static 'j_at_into' using by value list-source incoming-index by reference item end-call
 move function J-STR(item,'id') to other-id
 if other-id = spaces move function J-STR(item,' ') to other-id end-if
 if list-id = other-id move 1 to keep-child exit perform end-if end-perform
 if keep-child = 0 move kept-index to match-index perform remove-child end-if
 subtract 1 from kept-index end-perform
 if incoming-count > 0
 move 'query' to kind perform new-command move 'selector' to key-text move '.empty-upgrades' to value-text perform command-string perform run-command
 call static 'j_clone_into' using by value answer by reference owned-target end-call
 move owned-target to target move 'remove' to kind perform new-command perform run-command
 call static 'j_delete' using by value owned-target end-call move null to owned-target move parent-target to target end-if.


 refresh-shop.
 call static 'j_size' using by value children-node by reference x'00' returning loop-count end-call
 perform varying loop-index from 0 by 1 until loop-index >= loop-count
 call static 'j_at_into' using by value children-node loop-index by reference record-node end-call
 perform child-component
 if function J-STR(other-component,'kind') = 'ShopItem'
 call static 'j_get_into' using by value other-component by reference z'data' data-node end-call
 move function J-STR(record-node,'data.id') to list-id
 move function concatenate('state.generators.',function trim(list-id),x'00') to key-text
 call static 'j_get_into' using by value ctx by reference key-text list-data end-call
 if list-data = null call static 'j_get_into' using by value record-node by reference z'data' list-data end-call end-if
 if data-node not = null and list-data not = null
 call static 'j_clone_into' using by value list-data by reference temp end-call
 call static 'j_set' using by value data-node by reference z'generator' by value temp end-call
 move function J-NUM(component-node,'purchaseAmount') to number-value
 if number-value = 0 move 1 to number-value end-if
 call static 'j_set_number' using by value data-node by reference z'purchaseAmount' number-value end-call
 call static 'j_object_into' using by reference nested-request end-call
 call static 'j_object_into' using by reference nested-response end-call
 move 'model.generator.calculateBulkCost' to text-value
 if number-value = -1 move 'model.generator.calculateMaxAffordable' to text-value end-if
 call static 'j_set_string' using by value nested-request by reference z'operation' text-value by value function length(function trim(text-value)) end-call
 call static 'j_clone_into' using by value list-data by reference temp end-call
 call static 'j_set' using by value nested-request by reference z'args.generator' by value temp end-call
 call static 'j_set_number' using by value nested-request by reference z'args.quantity' number-value end-call
 move function J-NUM(ctx,'state.resources.bufos') to number-value
 call static 'j_set_number' using by value nested-request by reference z'args.bufos' number-value end-call
 call static 'BUFO-GENERATORS' using by value nested-request ctx nested-response end-call
 move function J-NUM(nested-response,'result') to x
 move 0 to yes
 if text-value = 'model.generator.calculateMaxAffordable'
 if x > 0 move 1 to yes end-if
 else if number-value >= x move 1 to yes end-if end-if
 call static 'j_set_boolean' using by value data-node by reference z'canAfford' by value yes end-call
 call static 'j_delete' using by value nested-request end-call call static 'j_delete' using by value nested-response end-call
 call static 'j_get_into' using by value record-node by reference z'component' saved-child end-call
 move 'component.update' to text-value perform invoke-child end-if end-if end-perform
 move 'queryAll' to kind perform new-command
 move 'selector' to key-text move '.purchase-amount-button' to value-text perform command-string perform run-command
 call static 'j_clone_into' using by value answer by reference list-source end-call
 call static 'j_size' using by value list-source by reference x'00' returning loop-count end-call
 move target to parent-target
 perform varying loop-index from 0 by 1 until loop-index >= loop-count
 call static 'j_at_into' using by value list-source loop-index by reference target end-call
 move 'getAttribute' to kind perform new-command move 'name' to key-text move 'data-amount' to value-text perform command-string perform run-command
 move function J-STR(answer,' ') to text-value
 compute x = function numval(text-value)
 move function J-NUM(component-node,'purchaseAmount') to number-value
 if number-value = 0 move 1 to number-value end-if
 move 0 to yes if x = number-value move 1 to yes end-if
 call static 'j_parse_into' using by reference z'["active"]' by value 10 by reference list-node end-call
 move 'class' to kind perform new-command move 'action' to key-text move 'toggle' to value-text perform command-string
 move 'names' to key-text move list-node to item perform command-value
 call static 'j_set_boolean' using by value command by reference z'force' by value yes end-call perform run-command
 call static 'j_delete' using by value list-node end-call end-perform
 call static 'j_delete' using by value list-source end-call move parent-target to target.


 invoke-factory.
 call static 'j_object_into' using by reference nested-request end-call
 call static 'j_object_into' using by reference nested-response end-call
 call static 'j_set_string' using by value nested-request by reference z'operation' z'component.create' by value 16 end-call
 call static 'j_array_into' using by reference nested-args end-call
 call static 'j_object_into' using by reference temp end-call
 call static 'j_set_string' using by value temp by reference z'kind' factory-kind by value function length(function trim(factory-kind)) end-call
 call static 'j_get_into' using by value temp by reference z'kind' item end-call
 call static 'j_clone_into' using by value item by reference item end-call
 call static 'j_append' using by value nested-args item end-call call static 'j_delete' using by value temp end-call
 call static 'j_clone_into' using by value factory-options by reference temp end-call
 call static 'j_append' using by value nested-args temp end-call
 call static 'j_set' using by value nested-request by reference z'args' by value nested-args end-call
 call static 'BUFO-COMPONENTS' using by value nested-request ctx nested-response end-call
 call static 'j_get_into' using by value nested-response by reference z'result' item end-call
 call static 'j_clone_into' using by value item by reference factory-reference end-call
 call static 'j_delete' using by value nested-request end-call call static 'j_delete' using by value nested-response end-call.

 copy 'ui-library-procedures.cpy' .
 end program BUFO-COMPONENTS.
