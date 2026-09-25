 identification division.
 program-id. BUFO-COMPONENT-RENDER.
 environment division.
 configuration section.
 repository. function J-NUM function J-STR function all intrinsic.
 data division.
 local-storage section.
 copy 'ui-library-vars.cpy' .
 01 component-node usage pointer.
 01 data-node usage pointer.
 01 generator-node usage pointer.
 01 cname pic x(64).
 01 name-text pic x(256).
 01 category pic x(64).
 01 icon-path pic x(512).
 01 icon-text pic x(64).
 01 icon-html pic x(8192).
 01 count-text pic x(256).
 01 production-text pic x(256).
 01 price-text pic x(256).
 01 label-text pic x(256).
 01 disabled-text pic x(32).
 01 decs usage binary-long.
 01 mode-number usage binary-long.
 01 quantity usage comp-2.
 01 cost usage comp-2.
 01 budget usage comp-2.
 01 ratio usage comp-2.
 01 val usage comp-2.
 01 boosts usage pointer.
 01 boost usage pointer.
 01 tooltip-title pic x(64).
 01 description-text pic x(32768).
 01 flavor-text pic x(2048).
 01 color-text pic x(32).
 01 boost-html pic x(16384).
 01 boost-hp usage binary-long.
 01 count-index usage binary-long.
 01 current-cost usage comp-2.
 01 mode-index usage binary-long.
 01 projection-request usage pointer.
 01 production-list usage pointer.
 01 generators usage pointer.
 01 sorted-item usage pointer.
 01 sort-j usage binary-long.
 01 item-count usage binary-long.
 01 total-rate usage comp-2.
 01 lhs usage comp-2.
 01 rhs usage comp-2.

 01 labels.
 02 filler pic x(20) value 'Base production:' .
 02 filler pic x(20) value 'Current production:' .
 02 filler pic x(20) value 'Total production:' .
 01 label-table redefines labels.
 02 production-label pic x(20) occurs 3.

 linkage section.
 01 req usage pointer.
 01 ctx usage pointer.
 01 res usage pointer.
 procedure division using by value req ctx res.
 call static 'j_get_into' using by value req by reference z'component' component-node end-call
 move function J-STR(component-node,'kind') to cname
 call static 'j_get_into' using by value component-node by reference z'options' options-node end-call
 call static 'j_get_into' using by value component-node by reference z'data' data-node end-call
 move data-node to generator-node
 if cname = 'ShopItem' call static 'j_get_into' using by value data-node by reference z'generator' generator-node end-call end-if
 move function J-STR(generator-node,'id') to id-text
 move function J-STR(generator-node,'name') to name-text
 move function J-STR(generator-node,'category') to category
 move function J-STR(generator-node,'iconPath') to icon-path
 if name-text = spaces move 'Unknown' to name-text end-if
 move function J-NUM(generator-node,'count') to number-value
 call static 'h_decimal' using by reference number-value by value 0 0 0 by reference count-text by value 256 end-call
 if cname = 'GoldenBufo' or cname = 'BossFight'
 call static 'j_object_into' using by reference projection-request end-call
 move 'ui.renderGolden' to text-value if cname = 'BossFight' move 'ui.renderBoss' to text-value end-if
 call static 'j_set_string' using by value projection-request by reference z'operation' text-value by value function length(function trim(text-value)) end-call
 call static 'j_get_into' using by value req by reference z'now' item end-call
 if item not = null call static 'j_clone_into' using by value item by reference temp end-call
 call static 'j_set' using by value projection-request by reference z'now' by value temp end-call end-if
 call static 'BUFO-UI' using by value projection-request ctx res end-call
 call static 'j_delete' using by value projection-request end-call goback end-if
 move function J-STR(req,'method') to method-name
 evaluate method-name
 when 'generateTooltipContent' perform tooltip-markup perform return-html goback
 when 'getUpgradeFlavorText' perform upgrade-flavor move flavor-text to html compute hp = function length(function trim(html trailing)) + 1 perform return-html goback
 when 'getUpgradeIconHtml' perform upgrade-icon move icon-html to html compute hp = function length(function trim(html trailing)) + 1 perform return-html goback
 when 'getGeneratorIconHtml' perform generator-icon move icon-html to html compute hp = function length(function trim(html trailing)) + 1 perform return-html goback
 end-evaluate
 evaluate cname
 when 'ProductionStats'
 string '<div class="panel-content"><div class="stats-container"></div><div class="contributions"><h3>Production Sources</h3><div class="contributions-list">' into html with pointer hp end-string
 if method-name not = 'render' perform render-contributions else
 string '<div class="empty-contributions">No production sources yet.</div>' into html with pointer hp end-string end-if
 string '</div></div></div>' into html with pointer hp end-string
 when 'ResourceDisplay'
 string '<div class="resource-count"><span class="number-value">' into html with pointer hp end-string
 move function J-NUM(data-node,'bufos') to number-value
 compute number-value = function integer(number-value)
 move 1 to mode-number move 1 to decs perform format-number
 string function trim(formatted trailing) '</span><span class="number-label">' into html with pointer hp end-string
 if function abs(number-value) >= 1000000000000
 move 2 to mode-number move 1 to decs perform format-number
 string function trim(formatted trailing) ' ' into html with pointer hp end-string
 end-if
 string 'Bufos</span></div>' into html with pointer hp end-string
 call static 'j_get_into' using by value options-node by reference z'showProductionRate' item end-call
 call static 'h_truthy' using by value item returning yes end-call
 if item = null or yes = 1
 move function J-NUM(data-node,'productionRate') to number-value
 move 0 to mode-number move 1 to decs perform format-number
 string '<div class="production-rate">' function trim(formatted trailing) ' bufos/sec</div>' into html with pointer hp end-string
 end-if
 when 'ClickArea'
 move function J-STR(options-node,'imagePath') to icon-path
 if icon-path = spaces move './assets/images/bufo.png' to icon-path end-if
 string '<img src="' function trim(icon-path trailing) '" alt="Bufo" class="bufo-image" draggable="false"><div class="click-indicator-container"></div>' into html with pointer hp end-string
 when 'GeneratorItem'
 perform generator-icon
 move function J-NUM(generator-node,'totalProduction') to number-value
 move 0 to mode-number move 1 to decs perform format-number
 string '<div class="generator-icon">' function trim(icon-html trailing) '</div><div class="generator-info"><div class="name-count-container"><div class="generator-name">' function trim(name-text trailing)
 '</div><div class="generator-count">x' function trim(count-text trailing) '</div></div><div class="generator-production"><span class="production-value">' function trim(formatted trailing)
 '</span>/sec</div></div>' into html with pointer hp end-string
 when 'ShopItem'
 perform generator-icon
 move function J-NUM(generator-node,'currentProduction') to number-value
 move 0 to mode-number move 1 to decs perform format-number
 move formatted to production-text
 perform purchase-label
 move 'disabled' to disabled-text
 call static 'j_boolean' using by value data-node by reference z'canAfford' returning yes end-call
 if yes = 1 move spaces to disabled-text end-if
 string '<div class="generator-row"><div class="generator-left"><div class="generator-icon">' function trim(icon-html trailing)
 '</div><div class="generator-info"><div class="generator-name-section"><span class="generator-name">' function trim(name-text trailing) '</span></div><div class="generator-production">' function
 trim(production-text trailing) '/sec per unit</div></div></div><button class="buy-button ' function trim(disabled-text trailing) '" data-generator-id="' function trim(id-text trailing) '">' function
 trim(label-text trailing) '</button></div>' into html with pointer hp end-string
 when 'UpgradeItem'
 perform upgrade-icon
 string '<button class="upgrade-icon" data-upgrade-id="' function trim(id-text trailing) '">' function trim(icon-html trailing) '</button>' into html with pointer hp end-string
 end-evaluate
 perform return-html goback.
 return-html.
 call static 'j_set_boolean' using by value res by reference z'ok' by value 1 end-call
 subtract 1 from hp
 call static 'j_set_string' using by value res by reference z'result' html by value hp end-call.
 format-number.
 call static 'BUFO-FORMAT' using by reference number-value decs mode-number formatted end-call.
 generator-icon.
 move '🐸' to icon-text
 evaluate category when 'premium' move '✨' to icon-text when 'special' move '🔮' to icon-text end-evaluate
 if icon-path(1:2) = './' move icon-path(3:) to value-text move value-text to icon-path end-if
 if generator-node = null move spaces to icon-html exit paragraph end-if
 if icon-path not = spaces
 string '<div class="generator-icon-wrapper"><img src="' function trim(icon-path) '" alt="' function trim(name-text)
 '" class="generator-icon-img"><div class="generator-icon-fallback" style="display:none;">'
 function trim(icon-text) '</div></div>' into icon-html end-string
 else string '<div class="generator-icon-wrapper"><div class="generator-icon-fallback" style="display:flex;">'
 function trim(icon-text) '</div></div>' into icon-html end-string end-if.
 upgrade-icon.
 if generator-node = null exit paragraph end-if
 if icon-path not = spaces
 string '<img src="' function trim(icon-path) '" alt="' function trim(name-text) '" class="upgrade-icon-img">' into icon-html end-string
 else
 move '✨' to icon-text
 evaluate category when 'click' move '👆' to icon-text when 'generator' move '🐸' to icon-text when 'global' move '🌍' to icon-text end-evaluate
 evaluate id-text when 'stronger_clicks_1' move '💪' to icon-text when 'stronger_clicks_2' move '✨👆' to icon-text
 when 'tadpole_boost_1' move '🥚' to icon-text when 'froglet_boost_1' move '🐸' to icon-text when 'global_production_1' move '🌿' to icon-text end-evaluate
 string '<div class="upgrade-icon-emoji">' function trim(icon-text) '</div>' into icon-html end-string end-if.
 purchase-label.
 move function J-NUM(generator-node,'currentCost') to cost
 move function J-NUM(generator-node,'costMultiplier') to ratio
 move function J-NUM(data-node,'purchaseAmount') to quantity
 if quantity = 0 move function J-NUM(component-node,'purchaseAmount') to quantity end-if
 if quantity = 0 move 1 to quantity end-if
 move function J-NUM(ctx,'state.resources.bufos') to budget
 if quantity = -1
 if cost <= 0 or budget < cost move 0 to quantity
 else
 if ratio = 1 compute quantity = function integer(budget / cost)
 else
 compute val = budget * (ratio - 1) / cost + 1
 if val <= 0 move 0 to quantity else compute quantity = function max(0,function integer(function log(val) / function log(ratio))) end-if
 end-if end-if
 if quantity = 0 move "Can't afford" to label-text exit paragraph end-if end-if
 if quantity > 1
 if ratio = 1 compute cost = cost * quantity
 else
 call static 'h_power' using by reference ratio quantity val end-call
 compute cost = 0 - function integer(0 - cost * (1 - val) / (1 - ratio)) end-if end-if
 move cost to number-value move 0 to mode-number move 1 to decs perform format-number
 move function concatenate(function trim(formatted),' bufos') to label-text.

 tooltip-markup.
 if generator-node = null exit paragraph end-if
 if cname = 'UpgradeItem'
 perform upgrade-flavor
 evaluate category when 'click' move 'Click Upgrade' to tooltip-title
 when 'generator' move 'Generator Upgrade' to tooltip-title
 when 'global' move 'Global Upgrade' to tooltip-title end-evaluate
 move function J-NUM(generator-node,'cost') to number-value move 0 to mode-number move 1 to decs perform format-number
 move function J-STR(generator-node,'description') to description-text
 string '<div class="tooltip-upgrade tooltip-category-' function trim(category) '"><div class="tooltip-header"><span class="tooltip-title">' function trim(name-text)
 '</span><span class="tooltip-category">' function trim(tooltip-title) '</span></div><div class="tooltip-description">' function trim(description-text)
 '</div><div class="tooltip-flavor">' function trim(flavor-text) '</div><div class="tooltip-cost">' function trim(formatted) ' bufos</div></div>' into html with pointer hp end-string
 exit paragraph end-if
 move '#4CAF50' to color-text
 evaluate category when 'premium' move '#3f51b5' to color-text when 'special' move '#FF9800' to color-text end-evaluate
 move function J-STR(generator-node,'detailedDescription') to description-text
 if description-text = spaces move function J-STR(generator-node,'description') to description-text end-if
 string '<div class="tooltip-header" style="color: ' function trim(color-text) ';"><strong>' function trim(name-text)
 '</strong><span class="tooltip-count">x' function trim(count-text) '</span></div><div class="tooltip-description">' function trim(description-text)
 '</div><div class="tooltip-section"><div class="tooltip-section-title">Production</div><div class="tooltip-production">' into html with pointer hp end-string
 if cname = 'ShopItem'
 move function J-NUM(generator-node,'currentProduction') to number-value move 0 to mode-number move 1 to decs perform format-number
 string '<div class="tooltip-production-item"><span class="tooltip-label">Production:</span><span class="tooltip-value">' function trim(formatted)
 '/sec per unit</span></div></div></div><div class="tooltip-section"><div class="tooltip-section-title">Purchase Info</div><div class="tooltip-costs">' into html with pointer hp end-string
 move function J-NUM(generator-node,'currentCost') to current-cost
 move function J-NUM(generator-node,'costMultiplier') to ratio
 perform varying mode-index from 1 by 1 until mode-index > 3
 evaluate mode-index when 1 move 1 to quantity move 'Next:' to label-text
 when 2 move 10 to quantity move 'Next 10:' to label-text
 when 3 move 100 to quantity move 'Next 100:' to label-text end-evaluate
 perform tooltip-cost
 move cost to number-value move 0 to mode-number move 1 to decs perform format-number
 string '<div class="tooltip-cost-item"><span class="tooltip-label">' function trim(label-text) '</span><span class="tooltip-value">' function trim(formatted)
 ' bufos</span></div>' into html with pointer hp end-string end-perform
 move function J-NUM(ctx,'state.resources.bufos') to budget
 move 0 to number-value
 if budget >= current-cost and current-cost > 0
 if ratio = 1 compute number-value = function integer(budget / current-cost)
 else compute val = budget * (ratio - 1) / current-cost + 1
 if val > 0 compute number-value = function max(0,function integer(function log(val) / function log(ratio))) end-if end-if end-if
 call static 'h_decimal' using by reference number-value by value 0 0 0 by reference formatted by value 256 end-call
 string '<div class="tooltip-cost-item affordable"><span class="tooltip-label">You can afford:</span><span class="tooltip-value">' function trim(formatted)
 '</span></div></div></div>' into html with pointer hp end-string
 else
 perform varying mode-index from 1 by 1 until mode-index > 3
 evaluate mode-index when 1 move function J-NUM(generator-node,'baseProduction') to number-value
 when 2 move function J-NUM(generator-node,'currentProduction') to number-value
 when 3 move function J-NUM(generator-node,'totalProduction') to number-value end-evaluate
 move 0 to mode-number move 1 to decs perform format-number
 move spaces to disabled-text if mode-index = 3 move ' total' to disabled-text end-if
 string '<div class="tooltip-production-item' function trim(disabled-text trailing) '"><span class="tooltip-label">' function trim(production-label(mode-index))
 '</span><span class="tooltip-value">' function trim(formatted) '/sec' into html with pointer hp end-string
 if mode-index < 3 string ' per unit' into html with pointer hp end-string end-if
 string '</span></div>' into html with pointer hp end-string end-perform
 string '</div>' into html with pointer hp end-string
 call static 'j_get_into' using by value generator-node by reference z'boosts' boosts end-call
 call static 'j_size' using by value boosts by reference x'00' returning cnt end-call
 move 1 to boost-hp
 perform varying count-index from 0 by 1 until count-index >= cnt
 call static 'j_at_into' using by value boosts count-index by reference boost end-call
 call static 'j_boolean' using by value boost by reference z'active' returning yes end-call
 if yes = 1
 move function J-NUM(boost,'multiplier') to number-value
 call static 'h_decimal' using by reference number-value by value 2 0 0 by reference formatted by value 256 end-call
 move 'negative' to disabled-text if number-value > 1 move 'positive' to disabled-text end-if
 move function J-STR(boost,'source') to value-text
 string '<div class="tooltip-boost-item ' function trim(disabled-text) '"><span class="tooltip-label">' function trim(value-text) ':</span><span class="tooltip-value">x'
 function trim(formatted) '</span></div>' into boost-html with pointer boost-hp end-string end-if end-perform
 if boost-hp > 1
 string '<div class="tooltip-boosts"><div class="tooltip-section-subtitle">Boosts</div>' function trim(boost-html trailing) '</div>' into html with pointer hp end-string end-if
 string '</div>' into html with pointer hp end-string end-if.
 tooltip-cost.
 move current-cost to cost
 if quantity not = 1
 if ratio = 1 compute cost = current-cost * quantity
 else call static 'h_power' using by reference ratio quantity val end-call
 compute cost = 0 - function integer(0 - current-cost * (1 - val) / (1 - ratio)) end-if end-if.
 upgrade-flavor.
 if generator-node = null exit paragraph end-if
 move function J-STR(generator-node,'flavorText') to flavor-text
 if flavor-text not = spaces exit paragraph end-if
 evaluate id-text
 when 'stronger_clicks_1' move 'Your fingertips tingle with the power of a thousand taps. The frogs sense your newfound strength.' to flavor-text
 when 'stronger_clicks_2' move 'Advanced clicking techniques passed down from the ancient Bufo masters. Your fingers move with blinding speed.' to flavor-text
 when 'tadpole_boost_1' move 'A safe, nurturing environment for tadpoles to thrive. Happy tadpoles mean more bufos!' to flavor-text
 when 'froglet_boost_1' move 'An intensive training regimen that transforms ordinary froglets into bufo-producing champions.' to flavor-text
 when 'global_production_1' move 'A rising tide lifts all frogs. Your management skills benefit the entire operation.' to flavor-text
 when other evaluate category
 when 'click' move 'Every click reverberates through the pond, sending ripples of power across the lily pads.' to flavor-text
 when 'generator' move 'Optimized production techniques allow your frogs to work smarter, not harder.' to flavor-text
 when 'global' move 'A rising tide lifts all frogs. Your management skills benefit the entire operation.' to flavor-text
 when other move 'A mysterious upgrade with untold powers. The frogs whisper of its potential.' to flavor-text end-evaluate end-evaluate.


 render-contributions.
 call static 'j_array_into' using by reference production-list end-call
 call static 'j_get_into' using by value ctx by reference z'state.generators' generators end-call
 call static 'j_size' using by value generators by reference x'00' returning cnt end-call
 move 0 to total-rate
 perform varying i from 0 by 1 until i >= cnt
 call static 'j_at_into' using by value generators i by reference item end-call
 move function J-NUM(item,'totalProduction') to lhs
 if function J-NUM(item,'count') > 0 and lhs > 0
 add lhs to total-rate
 call static 'j_clone_into' using by value item by reference temp end-call
 call static 'j_append' using by value production-list temp end-call end-if end-perform
 call static 'j_size' using by value production-list by reference x'00' returning item-count end-call
 perform varying i from 1 by 1 until i >= item-count
 move i to sort-j
 perform until sort-j <= 0
 call static 'j_at_into' using by value production-list sort-j by reference item end-call
 compute j = sort-j - 1
 call static 'j_at_into' using by value production-list j by reference sorted-item end-call
 move function J-NUM(item,'totalProduction') to lhs
 move function J-NUM(sorted-item,'totalProduction') to rhs
 if lhs <= rhs exit perform end-if
 call static 'h_array_swap' using by value production-list sort-j j end-call
 subtract 1 from sort-j end-perform end-perform
 if item-count = 0 string '<div class="empty-contributions">No production sources yet.</div>' into html with pointer hp end-string end-if
 perform varying i from 0 by 1 until i >= item-count
 call static 'j_at_into' using by value production-list i by reference item end-call
 move function J-STR(item,'name') to name-text
 move function J-NUM(item,'count') to number-value
 call static 'h_decimal' using by reference number-value by value 0 0 0 by reference count-text by value 256 end-call
 move function J-NUM(item,'totalProduction') to number-value
 move 0 to mode-number move 1 to decs perform format-number move formatted to production-text
 compute number-value = number-value / total-rate * 100
 call static 'h_decimal' using by reference number-value by value 1 0 0 by reference formatted by value 256 end-call
 string '<div class="contribution-item"><span class="contribution-name">' function trim(name-text) ' (x' function trim(count-text)
 ')</span><span class="contribution-value">' function trim(production-text) '/sec (' function trim(formatted) '%)</span></div>' into html with pointer hp end-string end-perform
 call static 'j_delete' using by value production-list end-call.

 end program BUFO-COMPONENT-RENDER.
