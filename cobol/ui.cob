identification division.
program-id. BUFO-UI recursive.
environment division.
configuration section.
repository. function J-NUM function J-STR function all intrinsic.
data division.
local-storage section.
01 markup pic x(262144).
01 projection pic x(262144).
01 projection-position binary-long.
01 projection-name pic x(32).
01 cursor-pos binary-long.
01 target-name pic x(128).
01 command-kind pic x(16) value 'html'.
01 commands usage pointer.
01 command-node usage pointer.
01 state-node usage pointer.
01 buttons-list usage pointer.
01 button-node usage pointer.
01 unlocked-list usage pointer.
01 unlocked-item usage pointer.
01 second-index binary-long.
01 second-count binary-long.
01 unlocked-flag binary-long.
01 list-node usage pointer.
01 item-node usage pointer.
01 other-node usage pointer.
01 child-request usage pointer.
01 child-response usage pointer.
01 index-value binary-long.
01 count-value binary-long.
01 flag binary-long.
01 owned-count binary-long.
01 number-value comp-2.
01 quantity comp-2.
01 price comp-2.
01 bank comp-2.
01 formatted pic x(256).
01 cost-text pic x(256).
01 count-text pic x(256).
01 key-text pic x(256).
01 id-text pic x(256).
01 name-text pic x(32768).
01 description-text pic x(32768).
01 icon-text pic x(32768).
01 modal-name pic x(32).
01 route-name pic x(128).
01 escape-input pic x(32768).
01 escape-output pic x(65536).
01 escape-index binary-long.
01 escape-length binary-long.
01 remaining-ms comp-2.
01 total-ms comp-2.
01 percent-value comp-2.
01 multiplier-value comp-2.
01 pending-points comp-2.
01 rate-value comp-2.
01 stat-label pic x(128).
01 frenzy-label pic x(32).
01 decimal-time pic ZZZ9.9.
01 saved-node usage pointer.
01 category-name pic x(32).
01 sort-index binary-long.
01 sort-before binary-long.
01 sort-node usage pointer.
01 sort-left comp-2.
01 sort-right comp-2.
01 escape-position binary-long.
linkage section.
01 request-node usage pointer.
01 context-node usage pointer.
01 response-node usage pointer.
procedure division using by value request-node context-node response-node.
 call static 'j_get_into' using by value context-node by reference z'state' state-node end-call
 call static 'j_get_into' using by value response-node by reference z'commands' commands end-call
 if commands = null
   call static 'j_array_into' using by reference commands end-call
   call static 'j_set' using by value response-node by reference z'commands' by value commands end-call
 end-if
 move function J-STR(request-node, 'operation') to projection-name
 if projection-name = 'ui.renderBoss' or 'ui.renderGolden'
   if projection-name = 'ui.renderBoss' perform render-boss else perform render-status end-if
   move spaces to projection move 1 to projection-position
   call static 'j_size' using by value commands by reference x'00' returning count-value end-call
   perform varying index-value from 0 by 1 until index-value >= count-value
   call static 'j_at_into' using by value commands index-value by reference command-node end-call
   move function J-STR(command-node, 'target') to target-name
   if (projection-name = 'ui.renderBoss' and (target-name = '#boss-banner' or '#boss-layer'))
      or (projection-name = 'ui.renderGolden' and (target-name = '#golden' or '#frenzies' or '#golden-toast'))
     string function trim(function J-STR(command-node, 'value')) into projection
       with pointer projection-position end-string
   end-if end-perform
   call static 'j_set_string' using by value response-node by reference z'result' projection
      by value function length(function trim(projection)) end-call
   call static 'j_remove' using by value response-node by reference z'commands' end-call
   call static 'j_set_boolean' using by value response-node by reference z'ok' by value 1 end-call
   call static 'j_delete' using by value child-request end-call
   call static 'j_delete' using by value child-response end-call
   goback
 end-if
 call static 'j_boolean' using by value context-node by reference z'runtime.ui.mounted' returning flag end-call
 if flag = 0 perform mount-ui end-if
 move function J-NUM(state-node, 'resources.bufos') to bank number-value
 move '#resource-count' to target-name perform number-command
 move 'generator.calculateTotalProduction' to route-name perform game-query
 move function J-NUM(child-response, 'result') to number-value
 move '#production-rate' to target-name perform number-command
 move function J-NUM(state-node, 'resources.clickPower') to number-value
 move '#click-power' to target-name perform number-command
 perform render-generators
 perform render-upgrades
 perform render-status
 perform render-boss
 perform render-modal
 call static 'j_delete' using by value child-request end-call
 call static 'j_delete' using by value child-response end-call
 goback.
mount-ui.
 move '#app' to target-name
 perform begin-markup
 string '<header class="game-header"><a class="brand" href="./"><img src="./assets/images/bufo.png" alt="">Bu' into markup with pointer cursor-pos end-string
 string 'foClicker<span>2.0</span></a><nav aria-label="Game menu"><button data-click="action" data-action="st' into markup with pointer cursor-pos end-string
 string 'ats">Statistics</button><button data-click="action" data-action="achievements">Achievements</button>' into markup with pointer cursor-pos end-string
 string '<button data-click="action" data-action="prestige">Transcend</button><button data-click="action" dat' into markup with pointer cursor-pos end-string
 string 'a-action="settings">Settings</button><button data-click="action" data-action="save">Save</button></n' into markup with pointer cursor-pos end-string
 string 'av></header><main class="game-layout"><section class="click-column" aria-label="Bufo production"><di' into markup with pointer cursor-pos end-string
 string 'v class="resources"><div id="resource-count">0</div><span>bufos</span><p><strong id="production-rate' into markup with pointer cursor-pos end-string
 string '">0</strong> per second</p></div><button id="bufo" class="bufo-button" data-click="action" data-acti' into markup with pointer cursor-pos end-string
 string 'on="click" aria-label="Click Bufo"><img src="./assets/images/bufo.png" alt="Bufo"></button><p class=' into markup with pointer cursor-pos end-string
 string '"click-caption">+<span id="click-power">1</span> per click</p><div id="frenzies"></div><div id="gold' into markup with pointer cursor-pos end-string
 string 'en"></div><div class="section-heading"><h2>Production sources</h2></div><div id="sources"></div></se' into markup with pointer cursor-pos end-string
 string 'ction><section class="owned-column"><div class="section-heading"><h1>Your Frogs</h1><span>Every bufo' into markup with pointer cursor-pos end-string
 string ' counts.</span></div><div id="owned"></div><div id="boss-banner"></div></section><aside class="shop-' into markup with pointer cursor-pos end-string
 string 'column"><div class="section-heading"><h2>Upgrades</h2></div><div id="upgrades"></div><div class="sec' into markup with pointer cursor-pos end-string
 string 'tion-heading"><h2>Frog Shop</h2></div><div class="purchase-controls" role="group" aria-label="Purcha' into markup with pointer cursor-pos end-string
 string 'se quantity"><button data-click="action" data-action="quantity" data-amount="1">1</button><button da' into markup with pointer cursor-pos end-string
 string 'ta-click="action" data-action="quantity" data-amount="10">10</button><button data-click="action" dat' into markup with pointer cursor-pos end-string
 string 'a-action="quantity" data-amount="100">100</button><button data-click="action" data-action="quantity"' into markup with pointer cursor-pos end-string
 string ' data-amount="-1">Max</button></div><p id="quantity-label" class="muted">Buying 1 at a time</p><div ' into markup with pointer cursor-pos end-string
 string 'id="shop"></div></aside></main><footer><span>Build your bufo empire.</span><span id="save-status"></' into markup with pointer cursor-pos end-string
 string 'span></footer><div id="recovery" role="alert"></div><div id="notification" role="status"></div><div ' into markup with pointer cursor-pos end-string
 string 'id="modal-layer"></div><div id="boss-layer"></div><div id="golden-toast" role="status"></div>' into markup with pointer cursor-pos end-string
 perform send-command
 call static 'j_set_boolean' using by value context-node by reference z'runtime.ui.mounted' by value 1 end-call.
render-generators.
 call static 'j_get_into' using by value state-node by reference z'generators' list-node end-call
 call static 'j_size' using by value list-node by reference x'00' returning count-value end-call
 move function J-NUM(context-node, 'runtime.ui.quantity') to quantity
 if quantity = 0 move 1 to quantity end-if
 move '#shop' to target-name
 perform begin-markup
 perform varying index-value from 0 by 1 until index-value >= count-value
 call static 'j_at_into' using by value list-node index-value by reference item-node end-call
 call static 'j_boolean' using by value item-node by reference z'unlocked' returning flag end-call
 if flag = 1
 perform generator-text
 string '<article class="shop-row"><img src="' into markup with pointer cursor-pos end-string
 string function trim(icon-text) into markup with pointer cursor-pos end-string
 string '" alt=""><div class="shop-info"><strong>' into markup with pointer cursor-pos end-string
 string function trim(name-text) into markup with pointer cursor-pos end-string
 string '</strong><span>Owned: ' into markup with pointer cursor-pos end-string
 string function trim(count-text) into markup with pointer cursor-pos end-string
 string '</span><span>' into markup with pointer cursor-pos end-string
 move function J-NUM(item-node, 'currentProduction') to number-value perform format-value
 string function trim(formatted) into markup with pointer cursor-pos end-string
 string ' / sec each</span></div><button class="buy-button" data-click="action" data-action="buyGenerator" da' into markup with pointer cursor-pos end-string
 string 'ta-id="' into markup with pointer cursor-pos end-string
 string function trim(id-text) into markup with pointer cursor-pos end-string
 string '" title="' into markup with pointer cursor-pos end-string
 string function trim(description-text) into markup with pointer cursor-pos end-string
 string '"' into markup with pointer cursor-pos end-string
 if bank - price < 0 or quantity = 0
 string ' aria-disabled="true"' into markup with pointer cursor-pos end-string end-if
 string '>' into markup with pointer cursor-pos end-string
 string function trim(cost-text) into markup with pointer cursor-pos end-string
 string ' bufos</button><button class="info-button" data-click="action" data-action="generatorInfo" data-id="' function trim(id-text) '" aria-label="Generator details">ⓘ</button></article>' into markup with pointer cursor-pos end-string
 end-if end-perform
 perform send-command
 move '#owned' to target-name
 perform begin-markup
 move 0 to owned-count
 perform varying index-value from 0 by 1 until index-value >= count-value
 call static 'j_at_into' using by value list-node index-value by reference item-node end-call
 if function J-NUM(item-node, 'count') > 0
 add 1 to owned-count perform generator-text
 string '<article class="owned-row"><img src="' into markup with pointer cursor-pos end-string
 string function trim(icon-text) into markup with pointer cursor-pos end-string
 string '" alt=""><div><strong>' into markup with pointer cursor-pos end-string
 string function trim(name-text) into markup with pointer cursor-pos end-string
 string '</strong><p>' into markup with pointer cursor-pos end-string
 move function J-NUM(item-node, 'totalProduction') to number-value perform format-value
 string function trim(formatted) into markup with pointer cursor-pos end-string
 string ' bufos / sec</p></div><b>×' into markup with pointer cursor-pos end-string
 string function trim(count-text) into markup with pointer cursor-pos end-string
 string '</b><button class="info-button" data-click="action" data-action="generatorInfo" data-kind="owned" data-id="' function trim(id-text) '" aria-label="Generator details">ⓘ</button></article>' into markup with pointer cursor-pos end-string
 end-if end-perform
 if owned-count = 0
 string '<div class="empty-pond"><img src="./assets/images/generators/bufo-smol.png" alt="A tiny bufo"><h2>A ' into markup with pointer cursor-pos end-string
 string 'pond full of possibilities.</h2><p>Click Bufo, then buy your first tadpole.</p></div>' into markup with pointer cursor-pos end-string
 end-if
 perform send-command
 move '#sources' to target-name
 perform begin-markup
 if owned-count = 0
 string '<p class="muted">Your frogs will produce bufos here.</p>' into markup with pointer cursor-pos end-string
 else
 perform varying index-value from 0 by 1 until index-value >= count-value
 call static 'j_at_into' using by value list-node index-value by reference item-node end-call
 if function J-NUM(item-node, 'count') > 0
 perform generator-text
 string '<p class="stat-line"><span>' into markup with pointer cursor-pos end-string
 string function trim(name-text) into markup with pointer cursor-pos end-string
 string '</span><strong>' into markup with pointer cursor-pos end-string
 move function J-NUM(item-node, 'totalProduction') to number-value perform format-value
 string function trim(formatted) into markup with pointer cursor-pos end-string
 string '/s</strong></p>' into markup with pointer cursor-pos end-string
 end-if end-perform end-if
 perform send-command
 .
generator-text.
 move function J-STR(item-node, 'id') to escape-input perform escape-html move escape-output to id-text
 move function J-STR(item-node, 'name') to escape-input perform escape-html move escape-output to name-text
 move function J-STR(item-node, 'description') to escape-input perform escape-html move escape-output to description-text
 move function J-STR(item-node, 'iconPath') to escape-input perform escape-html move escape-output to icon-text
 move function J-NUM(item-node, 'count') to number-value perform format-value move formatted to count-text
 if target-name not = '#shop' exit paragraph end-if
 move 'model.generator.calculateBulkCost' to route-name perform prepare-query
 call static 'j_clone_into' using by value item-node by reference other-node end-call
 call static 'j_set' using by value child-request by reference z'args.generator' by value other-node end-call
 if quantity = -1
 call static 'j_set_number' using by value child-request by reference z'args.bufos' bank end-call
 call static 'j_set_string' using by value child-request by reference z'operation' 'model.generator.calculateMaxAffordable' by value 38 end-call
 call static 'BUFO-GAME' using by value child-request context-node child-response end-call
 move function J-NUM(child-response, 'result') to number-value
 else move quantity to number-value end-if
 call static 'j_set_number' using by value child-request by reference z'args.quantity' number-value end-call
 call static 'j_set_string' using by value child-request by reference z'operation' 'model.generator.calculateBulkCost' by value 33 end-call
 call static 'BUFO-GAME' using by value child-request context-node child-response end-call
 move function J-NUM(child-response, 'result') to price number-value
 perform format-value move formatted to cost-text.
render-upgrades.
 move '#upgrades' to target-name
 perform begin-markup
 move 'upgrade.getAvailableUpgrades' to route-name perform game-query
 call static 'j_get_into' using by value child-response by reference z'result' list-node end-call
 call static 'j_size' using by value list-node by reference x'00' returning count-value end-call
 if count-value = 0
 string '<p class="muted">Keep clicking to discover upgrades.</p>' into markup with pointer cursor-pos end-string
 else perform varying index-value from 0 by 1 until index-value >= count-value
 call static 'j_at_into' using by value list-node index-value by reference item-node end-call
 move function J-STR(item-node, 'id') to escape-input perform escape-html move escape-output to id-text
 move function J-STR(item-node, 'name') to escape-input perform escape-html move escape-output to name-text
 move function J-STR(item-node, 'description') to escape-input perform escape-html move escape-output to description-text
 move function J-NUM(item-node, 'cost') to number-value perform format-value
 string '<div class="upgrade-row"><button class="upgrade" data-click="action" data-action="buyUpgrade" data-id="' into markup with pointer cursor-pos end-string
 string function trim(id-text) into markup with pointer cursor-pos end-string
 string '" title="' into markup with pointer cursor-pos end-string
 string function trim(description-text) into markup with pointer cursor-pos end-string
 string '"' into markup with pointer cursor-pos end-string
 if bank - number-value < 0 string ' aria-disabled="true"' into markup with pointer cursor-pos end-string end-if
 string '>' into markup with pointer cursor-pos end-string
 move function J-STR(item-node, 'iconPath') to escape-input perform escape-html
 if escape-output not = spaces
 string '<img class="upgrade-art" src="' function trim(escape-output) '" alt="">' into markup with pointer cursor-pos end-string
 end-if
 string '<strong>' into markup with pointer cursor-pos end-string
 string function trim(name-text) into markup with pointer cursor-pos end-string
 string '</strong><span>' into markup with pointer cursor-pos end-string
 string function trim(formatted) into markup with pointer cursor-pos end-string
 string ' bufos</span></button><button class="info-button" data-click="action" data-action="upgradeInfo" data-id="' function trim(id-text) '" aria-label="Upgrade details">ⓘ</button></div>' into markup with pointer cursor-pos end-string
 end-perform end-if
 perform send-command
 .
render-status.
 move '#recovery' to target-name
 perform begin-markup
 call static 'j_boolean' using by value context-node by reference z'runtime.persistence.blocked' returning flag end-call
 if flag = 1
 string '<div class="recovery"><h2>Progress is paused</h2><p>' into markup with pointer cursor-pos end-string
 move function J-STR(context-node, 'runtime.persistence.error') to escape-input perform escape-html
 string function trim(escape-output) into markup with pointer cursor-pos end-string
 string '</p><button data-click="action" data-action="retry">Retry</button><button data-click="action" data-a' into markup with pointer cursor-pos end-string
 string 'ction="settings">Import a save</button><button data-click="action" data-action="reset">Reset progres' into markup with pointer cursor-pos end-string
 string 's</button></div>' into markup with pointer cursor-pos end-string
 end-if
 perform send-command
 move '#golden' to target-name
 perform begin-markup
 call static 'j_get_into' using by value context-node by reference z'runtime.golden.active' item-node end-call
 if item-node not = null
 string '<button class="golden-bufo" data-click="action" data-action="golden" aria-label="Collect golden bufo" style="left:' into markup with pointer cursor-pos end-string
 move function J-NUM(item-node,'position.xPct') to number-value perform format-plain
 string function trim(formatted) 'vw;top:' into markup with pointer cursor-pos end-string
 move function J-NUM(item-node,'position.yPct') to number-value perform format-plain
 string function trim(formatted) 'vh;--ttl:' into markup with pointer cursor-pos end-string
 move function J-NUM(item-node,'ttl') to number-value perform format-plain
 string function trim(formatted) 'ms"><img src="./assets/images/generators/bufo-has-midas-touch.png" alt="Golden bufo">' into markup with pointer cursor-pos end-string
 compute remaining-ms = function max(0,function J-NUM(context-node,'runtime.golden.expiresAt') - function J-NUM(context-node,'runtime.now'))
 move function J-NUM(item-node,'ttl') to total-ms
 if total-ms > 0 compute percent-value = function min(100,remaining-ms / total-ms * 100) else move 0 to percent-value end-if
 string '<span>Golden Bufo!</span><span class="golden-life"><i style="width:' into markup with pointer cursor-pos end-string
 move percent-value to number-value perform format-plain
 string function trim(formatted) '%"></i></span></button>' into markup with pointer cursor-pos end-string
 end-if
 perform send-command
 move '#frenzies' to target-name perform begin-markup
 move function J-NUM(state-node,'resources.frenzyProductionMultiplier') to multiplier-value
 compute remaining-ms = function J-NUM(context-node,'runtime.golden.productionFrenzyEndsAt') - function J-NUM(context-node,'runtime.now')
 move function J-NUM(context-node,'runtime.ui.productionFrenzyTotalMs') to total-ms
 if total-ms <= 0 move 30000 to total-ms end-if
 move 'Bufo Frenzy' to frenzy-label perform frenzy-badge
 move function J-NUM(state-node,'resources.frenzyClickMultiplier') to multiplier-value
 compute remaining-ms = function J-NUM(context-node,'runtime.golden.clickFrenzyEndsAt') - function J-NUM(context-node,'runtime.now')
 move function J-NUM(context-node,'runtime.ui.clickFrenzyTotalMs') to total-ms
 if total-ms <= 0 move 15000 to total-ms end-if
 move 'Click Frenzy' to frenzy-label perform frenzy-badge
 perform send-command
 move '#golden-toast' to target-name perform begin-markup
 if function J-NUM(context-node,'runtime.ui.goldenRewardUntil') > function J-NUM(context-node,'runtime.now')
 string '<div class="golden-reward"><strong>' into markup with pointer cursor-pos end-string
 move function J-STR(context-node,'runtime.ui.goldenReward.label') to escape-input perform escape-html
 string function trim(escape-output) '</strong><p>' into markup with pointer cursor-pos end-string
 move function J-STR(context-node,'runtime.ui.goldenReward.detail') to escape-input perform escape-html
 string function trim(escape-output) '</p></div>' into markup with pointer cursor-pos end-string end-if
 perform send-command
 move '#notification' to target-name
 perform begin-markup
 if function J-NUM(context-node,'runtime.ui.achievementNoticeUntil') > function J-NUM(context-node,'runtime.now')
 string '<div class="notice achievement-toast">' into markup with pointer cursor-pos end-string
 move function J-STR(context-node,'runtime.ui.achievementNotice.iconPath') to escape-input perform escape-html
 if escape-output not = spaces
 string '<img src="' function trim(escape-output) '" alt="">' into markup with pointer cursor-pos end-string end-if
 string '<span>Achievement unlocked<br><strong>' into markup with pointer cursor-pos end-string
 move function J-STR(context-node,'runtime.ui.achievementNotice.name') to escape-input perform escape-html
 string function trim(escape-output) '</strong></span></div>' into markup with pointer cursor-pos end-string
 else
 if function J-NUM(context-node, 'runtime.ui.noticeUntil') - function J-NUM(context-node, 'runtime.now') > 0
 move function J-STR(context-node, 'runtime.ui.notice') to escape-input perform escape-html
 string '<p class="notice">' into markup with pointer cursor-pos end-string
 string function trim(escape-output) into markup with pointer cursor-pos end-string
 string '</p>' into markup with pointer cursor-pos end-string
 end-if
 end-if
 perform send-command
 move '#save-status' to target-name perform begin-markup
 call static 'j_boolean' using by value state-node by reference z'gameSettings.autoSave' returning flag end-call
 if flag = 1 string 'Autosave on' into markup with pointer cursor-pos end-string
 else string 'Autosave off' into markup with pointer cursor-pos end-string end-if
 move 'text' to command-kind perform send-command
 move '#quantity-label' to target-name perform begin-markup
 move function J-NUM(context-node, 'runtime.ui.quantity') to number-value
 if number-value = -1 string 'Buying the maximum affordable' into markup with pointer cursor-pos end-string
 else if number-value = 0 move 1 to number-value end-if perform format-value
 string 'Buying ' function trim(formatted) ' at a time' into markup with pointer cursor-pos end-string end-if
 move 'text' to command-kind perform send-command.
frenzy-badge.
 if multiplier-value <= 1 or remaining-ms <= 0 exit paragraph end-if
 string '<div class="frenzy"><strong>' function trim(frenzy-label) ' ×' into markup with pointer cursor-pos end-string
 move multiplier-value to number-value perform format-plain
 string function trim(formatted) '</strong><span class="frenzy-countdown">' into markup with pointer cursor-pos end-string
 compute decimal-time rounded = remaining-ms / 1000
 string function trim(decimal-time) 's</span><span class="frenzy-track"><i style="width:' into markup with pointer cursor-pos end-string
 compute number-value = function min(100,remaining-ms / total-ms * 100) perform format-plain
 string function trim(formatted) '%"></i></span></div>' into markup with pointer cursor-pos end-string.

render-boss.
 move '#boss-banner' to target-name perform begin-markup
 call static 'j_get_into' using by value context-node by reference z'runtime.boss.fight' item-node end-call
 if item-node = null and function J-NUM(context-node, 'runtime.now') - function J-NUM(context-node, 'runtime.ui.bossSnooze') >= 0
 move 'boss.getAvailableBoss' to route-name perform game-query
 call static 'j_get_into' using by value child-response by reference z'result' item-node end-call
 call static 'j_type' using by value item-node by reference x'00' returning flag end-call
 if flag = 5
 string '<div class="boss-banner"><h2>A boss has appeared!</h2><strong>' into markup with pointer cursor-pos end-string
 move function J-STR(item-node, 'name') to escape-input perform escape-html
 string function trim(escape-output) into markup with pointer cursor-pos end-string
 string '</strong><p>' into markup with pointer cursor-pos end-string
 move function J-STR(item-node, 'flavorText') to escape-input perform escape-html
 string function trim(escape-output) into markup with pointer cursor-pos end-string
 string '</p><p class="boss-preview">' into markup with pointer cursor-pos end-string
 call static 'j_clone_into' using by value item-node by reference saved-node end-call
 move 'boss.getScaledHealth' to route-name perform prepare-query
 call static 'j_set' using by value child-request by reference z'args.boss' by value saved-node end-call
 call static 'BUFO-GAME' using by value child-request context-node child-response end-call
 move function J-NUM(child-response,'result') to number-value perform format-value
 string function trim(formatted) ' HP · 30s</p><button data-click="action" data-action="bossStart">Fight!</button><button data-click="action" d' into markup with pointer cursor-pos end-string
 string 'ata-action="bossLater">Not yet</button></div>' into markup with pointer cursor-pos end-string
 end-if end-if
 perform send-command
 move '#boss-layer' to target-name perform begin-markup
 call static 'j_get_into' using by value context-node by reference z'runtime.boss.fight' item-node end-call
 if item-node not = null
 string '<div class="boss-overlay" role="dialog" aria-modal="true" aria-label="Boss fight"><div class="boss-h' into markup with pointer cursor-pos end-string
 string 'ud"><h2>' into markup with pointer cursor-pos end-string
 move function J-STR(item-node, 'boss.name') to escape-input perform escape-html
 string function trim(escape-output) into markup with pointer cursor-pos end-string
 string '</h2><div class="boss-health" role="progressbar" aria-label="Boss health" aria-valuemin="0" aria-valuemax="100" aria-valuenow="' into markup with pointer cursor-pos end-string
 move function J-NUM(item-node,'maxHealth') to total-ms
 if total-ms > 0 compute number-value = function max(0,function min(100,function J-NUM(item-node,'health') / total-ms * 100)) else move 0 to number-value end-if
 perform format-plain
 string function trim(formatted) '"><i class="boss-health-bar" style="width:' function trim(formatted) '%"></i></div><p class="boss-health-label">' into markup with pointer cursor-pos end-string
 move function J-NUM(item-node,'health') to number-value perform format-value
 string function trim(formatted) ' / ' into markup with pointer cursor-pos end-string
 move function J-NUM(item-node,'maxHealth') to number-value perform format-value
 string function trim(formatted) ' HP</p><p class="boss-timer' into markup with pointer cursor-pos end-string
 move function J-NUM(item-node,'remainingMs') to remaining-ms
 if remaining-ms <= 10000 string ' urgent' into markup with pointer cursor-pos end-string end-if
 compute decimal-time rounded = function max(0,remaining-ms / 1000)
 string '">' function trim(decimal-time) 's</p><button data-click="action" data-action="bossRetreat">Retreat</button></div>' into markup with pointer cursor-pos end-string
 string '<button class="boss-sprite" data-click="action" data-action="bossHit" aria-label="Hit boss" style="left:' into markup with pointer cursor-pos end-string
 move function J-NUM(context-node,'runtime.ui.bossX') to number-value perform format-plain
 string function trim(formatted) 'vw;top:' into markup with pointer cursor-pos end-string
 move function J-NUM(context-node,'runtime.ui.bossY') to number-value perform format-plain
 string function trim(formatted) 'vh"><img draggable="false" src="' into markup with pointer cursor-pos end-string
 move function J-STR(item-node, 'boss.iconPath') to escape-input perform escape-html
 string function trim(escape-output) into markup with pointer cursor-pos end-string
 string '" alt="Click the boss"></button></div>' into markup with pointer cursor-pos end-string

 end-if
 perform send-command
 call static 'j_has' using by value context-node by reference z'runtime.boss.fight' returning flag end-call
 if flag = 1
 move function J-NUM(context-node, 'runtime.ui.bossX') to number-value perform format-plain
 perform begin-markup
 string function trim(formatted) 'vw' into markup with pointer cursor-pos end-string
 move '.boss-sprite' to target-name move 'left' to key-text perform style-command
 move function J-NUM(context-node, 'runtime.ui.bossY') to number-value perform format-plain
 perform begin-markup
 string function trim(formatted) 'vh' into markup with pointer cursor-pos end-string
 move 'top' to key-text perform style-command
 end-if
 call static 'j_size' using by value state-node by reference z'bosses.defeated' returning flag end-call
 move flag to number-value perform format-plain
 call static 'j_object_into' using by reference command-node end-call
 call static 'j_set_string' using by value command-node by reference z'kind' 'attr' by value 4 end-call
 call static 'j_set_string' using by value command-node by reference z'target' 'body' by value 4 end-call
 call static 'j_set_string' using by value command-node by reference z'name' 'data-boss-stage' by value 15 end-call
 call static 'j_set_string' using by value command-node by reference z'value' formatted by value function length(function trim(formatted)) end-call
 call static 'j_append' using by value commands command-node end-call
 .
render-modal.
 move function J-STR(context-node, 'runtime.ui.modal') to modal-name
 if modal-name = 'settings'
 call static 'j_boolean' using by value context-node by reference z'runtime.ui.modalRendered' returning flag end-call
 if flag = 1 exit paragraph end-if end-if
 move '#modal-layer' to target-name perform begin-markup
 if modal-name not = spaces
 string '<div class="modal-backdrop"><section class="modal" role="dialog" aria-modal="true" aria-labelledby="' into markup with pointer cursor-pos end-string
 string 'modal-title"><button class="close" data-click="action" data-action="close" aria-label="Close dialog"' into markup with pointer cursor-pos end-string
 string '>×</button>' into markup with pointer cursor-pos end-string
 evaluate modal-name
 when 'stats'
 string '<h2 id="modal-title">Statistics</h2><dl class="statistics"><dt>Bufos earned</dt><dd>' into markup with pointer cursor-pos end-string
 move function J-NUM(state-node, 'resources.totalBufos') to number-value perform format-value
 string function trim(formatted) into markup with pointer cursor-pos end-string
 string '</dd><dt>Total clicks</dt><dd>' into markup with pointer cursor-pos end-string
 move function J-NUM(state-node, 'resources.clickCount') to number-value perform format-value
 string function trim(formatted) into markup with pointer cursor-pos end-string
 string '</dd><dt>Click power</dt><dd>' into markup with pointer cursor-pos end-string
 move function J-NUM(state-node, 'resources.clickPower') to number-value perform format-value
 string function trim(formatted) into markup with pointer cursor-pos end-string
 string '</dd><dt>Production multiplier</dt><dd>' into markup with pointer cursor-pos end-string
 move function J-NUM(state-node, 'resources.productionMultiplier') to number-value perform format-value
 string function trim(formatted) into markup with pointer cursor-pos end-string
 string '×</dd><dt>Lifetime prestige points</dt><dd>' into markup with pointer cursor-pos end-string
 move function J-NUM(state-node, 'prestige.lifetimePoints') to number-value perform format-value
 string function trim(formatted) into markup with pointer cursor-pos end-string
 string '</dd><dt>Transcendences</dt><dd>' into markup with pointer cursor-pos end-string
 move function J-NUM(state-node, 'prestige.transcendences') to number-value perform format-value
 string function trim(formatted) into markup with pointer cursor-pos end-string
 string '</dd><dt>Bosses defeated</dt><dd>' into markup with pointer cursor-pos end-string
 move function J-NUM(state-node, 'bosses.lifetimeDefeats') to number-value perform format-value
 string function trim(formatted) into markup with pointer cursor-pos end-string
 string '</dd></dl><h3>Resources</h3><dl class="statistics">' into markup with pointer cursor-pos end-string
 move 'Current bufos' to stat-label compute number-value = function J-NUM(state-node,'resources.bufos') perform statistic-row
 move 'Bufos spent' to stat-label compute number-value = function J-NUM(state-node,'resources.totalBufos') - function J-NUM(state-node,'resources.bufos') perform statistic-row
 move 'generator.getProductionStats' to route-name perform game-query
 move function J-NUM(child-response,'result.totalPerSecond') to rate-value
 move 'Per second' to stat-label move rate-value to number-value perform statistic-row
 move 'Per minute' to stat-label compute number-value = rate-value * 60 perform statistic-row
 move 'Per hour' to stat-label compute number-value = rate-value * 3600 perform statistic-row
 move 'Play time (minutes)' to stat-label
 move function J-NUM(state-node,'gameSettings.firstStartTime') to number-value
 if number-value = 0 move function J-NUM(state-node,'gameSettings.lastTick') to number-value end-if
 if number-value = 0 move function J-NUM(context-node,'runtime.now') to number-value end-if
 compute number-value = function max(0,(function J-NUM(context-node,'runtime.now') - number-value) / 60000)
 perform statistic-row
 string '</dl><h3>Collection</h3><dl class="statistics">' into markup with pointer cursor-pos end-string
 call static 'j_size' using by value state-node by reference z'achievements.unlocked' returning flag end-call
 move 'Achievements unlocked' to stat-label move flag to number-value perform statistic-row
 call static 'j_size' using by value context-node by reference z'catalog.achievements' returning flag end-call
 move 'Total achievements' to stat-label move flag to number-value perform statistic-row
 call static 'j_size' using by value state-node by reference z'upgrades.purchased' returning flag end-call
 move 'Upgrades purchased' to stat-label move flag to number-value perform statistic-row
 call static 'j_get_into' using by value state-node by reference z'generators' list-node end-call
 call static 'j_size' using by value list-node by reference x'00' returning count-value end-call
 move 'Generator types' to stat-label move count-value to number-value perform statistic-row
 move 0 to rate-value owned-count
 perform varying index-value from 0 by 1 until index-value >= count-value
 call static 'j_at_into' using by value list-node index-value by reference item-node end-call
 compute rate-value = rate-value + function J-NUM(item-node,'count')
 call static 'j_boolean' using by value item-node by reference z'unlocked' returning flag end-call
 if flag = 1 add 1 to owned-count end-if end-perform
 move 'Types unlocked' to stat-label move owned-count to number-value perform statistic-row
 move 'Generators owned' to stat-label move rate-value to number-value perform statistic-row
 string '</dl><h3>Production sources</h3>' into markup with pointer cursor-pos end-string
 move 'generator.getProductionStats' to route-name perform game-query
 call static 'j_get_into' using by value child-response by reference z'result.generatorContributions' list-node end-call
 call static 'j_size' using by value list-node by reference x'00' returning count-value end-call
 perform varying index-value from 1 by 1 until index-value >= count-value
 move index-value to sort-index
 perform until sort-index <= 0
 compute sort-before = sort-index - 1
 call static 'j_at_into' using by value list-node sort-index by reference item-node end-call
 call static 'j_at_into' using by value list-node sort-before by reference sort-node end-call
 move function J-NUM(item-node,'production') to sort-left
 move function J-NUM(sort-node,'production') to sort-right
 if sort-left <= sort-right exit perform end-if
 call static 'h_array_swap' using by value list-node sort-index sort-before end-call
 subtract 1 from sort-index end-perform end-perform
 perform varying index-value from 0 by 1 until index-value >= count-value
 call static 'j_at_into' using by value list-node index-value by reference item-node end-call
 move function J-STR(item-node,'name') to escape-input perform escape-html
 string '<p class="source-row"><span>' function trim(escape-output) '</span><b>' into markup with pointer cursor-pos end-string
 move function J-NUM(item-node,'production') to number-value perform format-value
 string function trim(formatted) '/sec (' into markup with pointer cursor-pos end-string
 move function J-NUM(item-node,'percentage') to decimal-time
 string function trim(decimal-time) '%)</b></p>' into markup with pointer cursor-pos end-string end-perform
 when 'achievements'
 string '<h2 id="modal-title">Achievements</h2><div class="achievement-filters"><button data-click="action" d' into markup with pointer cursor-pos end-string
 string 'ata-action="toggleLocked">Show / hide locked</button><button data-click="action" data-action="toggle' into markup with pointer cursor-pos end-string
 string 'Secret">Show / hide secrets</button></div><p class="achievement-summary">' into markup with pointer cursor-pos end-string
 call static 'j_size' using by value state-node by reference z'achievements.unlocked' returning flag end-call
 move flag to percent-value number-value perform format-value
 string function trim(formatted) ' / ' into markup with pointer cursor-pos end-string
 call static 'j_size' using by value context-node by reference z'catalog.achievements' returning flag end-call
 move flag to number-value perform format-value
 string function trim(formatted) ' unlocked (' into markup with pointer cursor-pos end-string
 if flag > 0 compute number-value = function integer(percent-value / flag * 100 + 0.5) else move 0 to number-value end-if
 perform format-plain string function trim(formatted) '%)</p><div class="achievement-categories" role="group" aria-label="Achievement category">' into markup with pointer cursor-pos end-string
 string '<button data-click="action" data-action="achievementCategory" data-category="all" aria-pressed="' into markup with pointer cursor-pos end-string
 move function J-STR(context-node,'runtime.ui.achievementCategory') to category-name
 if category-name = spaces move 'all' to category-name end-if
 if category-name = 'all' string 'true' into markup with pointer cursor-pos end-string else string 'false' into markup with pointer cursor-pos end-string end-if
 string '">All</button>' into markup with pointer cursor-pos end-string
 string '<button data-click="action" data-action="achievementCategory" data-category="generators" aria-pressed="' into markup with pointer cursor-pos end-string
 move function J-STR(context-node,'runtime.ui.achievementCategory') to category-name
 if category-name = spaces move 'all' to category-name end-if
 if category-name = 'generators' string 'true' into markup with pointer cursor-pos end-string else string 'false' into markup with pointer cursor-pos end-string end-if
 string '">Generators</button>' into markup with pointer cursor-pos end-string
 string '<button data-click="action" data-action="achievementCategory" data-category="production" aria-pressed="' into markup with pointer cursor-pos end-string
 move function J-STR(context-node,'runtime.ui.achievementCategory') to category-name
 if category-name = spaces move 'all' to category-name end-if
 if category-name = 'production' string 'true' into markup with pointer cursor-pos end-string else string 'false' into markup with pointer cursor-pos end-string end-if
 string '">Production</button>' into markup with pointer cursor-pos end-string
 string '<button data-click="action" data-action="achievementCategory" data-category="clicks" aria-pressed="' into markup with pointer cursor-pos end-string
 move function J-STR(context-node,'runtime.ui.achievementCategory') to category-name
 if category-name = spaces move 'all' to category-name end-if
 if category-name = 'clicks' string 'true' into markup with pointer cursor-pos end-string else string 'false' into markup with pointer cursor-pos end-string end-if
 string '">Clicks</button>' into markup with pointer cursor-pos end-string
 string '<button data-click="action" data-action="achievementCategory" data-category="special" aria-pressed="' into markup with pointer cursor-pos end-string
 move function J-STR(context-node,'runtime.ui.achievementCategory') to category-name
 if category-name = spaces move 'all' to category-name end-if
 if category-name = 'special' string 'true' into markup with pointer cursor-pos end-string else string 'false' into markup with pointer cursor-pos end-string end-if
 string '">Special</button>' into markup with pointer cursor-pos end-string
 string '</div><div class="achievement-list">' into markup with pointer cursor-pos end-string
 move 'achievement.getAllAchievements' to route-name perform game-query
 call static 'j_get_into' using by value child-response by reference z'result' list-node end-call
 call static 'j_size' using by value list-node by reference x'00' returning count-value end-call
 perform varying index-value from 0 by 1 until index-value >= count-value
 call static 'j_at_into' using by value list-node index-value by reference item-node end-call
 perform achievement-row
 end-perform
 string '</div>' into markup with pointer cursor-pos end-string
 when 'settings'
 string '<h2 id="modal-title">Settings &amp; saves</h2><p>Your game saves in this browser.</p><label class="s' into markup with pointer cursor-pos end-string
 string 'etting"><input type="checkbox" data-change="action" data-action="autoSave"' into markup with pointer cursor-pos end-string
 call static 'j_boolean' using by value state-node by reference z'gameSettings.autoSave' returning flag end-call
 if flag = 1 string ' checked' into markup with pointer cursor-pos end-string end-if
 string '> Automatic saving</label><div class="button-row"><button data-click="action" data-action="export">E' into markup with pointer cursor-pos end-string
 string 'xport save</button><button data-click="action" data-action="download">Download save</button></div><f' into markup with pointer cursor-pos end-string
 string 'orm data-submit="action" data-action="import"><label for="save-data">Save data</label><textarea id="' into markup with pointer cursor-pos end-string
 string 'save-data" name="data" rows="7" spellcheck="false" placeholder="Paste an exported save"></textarea><' into markup with pointer cursor-pos end-string
 string 'button type="submit">Import save</button></form><button class="danger" data-click="action" data-acti' into markup with pointer cursor-pos end-string
 string 'on="reset">Reset progress</button>' into markup with pointer cursor-pos end-string
 call static 'j_set_boolean' using by value context-node by reference z'runtime.ui.modalRendered' by value 1 end-call
 when 'reset'
 string '<h2 id="modal-title">Reset your progress?</h2><p>This clears this game’s saved progress. Export a ba' into markup with pointer cursor-pos end-string
 string 'ckup first if you want to keep it.</p><div class="button-row"><button data-click="action" data-actio' into markup with pointer cursor-pos end-string
 string 'n="close">Keep playing</button><button class="danger" data-click="action" data-action="confirmReset"' into markup with pointer cursor-pos end-string
 string '>Reset progress</button></div>' into markup with pointer cursor-pos end-string
 when 'prestige'
 string '<h2 id="modal-title">Transcend</h2><p>Start a new run and earn permanent prestige points. Each lifet' into markup with pointer cursor-pos end-string
 string 'ime point adds 10% to production and click power.</p><p class="prestige-points">' into markup with pointer cursor-pos end-string
 move 'prestige.getPendingPoints' to route-name perform game-query
 move function J-NUM(child-response, 'result') to pending-points number-value perform format-value
 string function trim(formatted) into markup with pointer cursor-pos end-string
 string ' points available</p><p>Your generators, upgrades, current bufos and boss ladder reset' into markup with pointer cursor-pos end-string
 string '.</p><dl class="statistics">' into markup with pointer cursor-pos end-string
 move 'Lifetime points' to stat-label move function J-NUM(state-node,'prestige.lifetimePoints') to number-value perform statistic-row
 move 'Transcendences' to stat-label move function J-NUM(state-node,'prestige.transcendences') to number-value perform statistic-row
 move 'Current multiplier' to stat-label compute number-value = 1 + function J-NUM(state-node,'prestige.lifetimePoints') * 0.1 perform statistic-row
 move 'After transcendence' to stat-label compute number-value = 1 + (function J-NUM(state-node,'prestige.lifetimePoints') + pending-points) * 0.1 perform statistic-row
 string '</dl>' into markup with pointer cursor-pos end-string
 if pending-points < 1 string '<p>Earn 1 billion total bufos to unlock your first prestige point.</p>' into markup with pointer cursor-pos end-string end-if
 move pending-points to number-value
 string '<button data-click="action" data-action="confirmPrestige"'  into markup with pointer cursor-pos end-string
 if number-value < 1 string ' disabled' into markup with pointer cursor-pos end-string end-if
 string '>Transcend and start again</button>' into markup with pointer cursor-pos end-string
 when 'bossResult'
 move function J-STR(context-node,'runtime.ui.bossResult.boss.iconPath') to escape-input perform escape-html
 if escape-output not = spaces
 string '<img class="boss-result-portrait" src="' function trim(escape-output) '" alt="">' into markup with pointer cursor-pos end-string end-if
 move function J-STR(context-node,'runtime.ui.bossResult.boss.name') to escape-input perform escape-html
 string '<p>' function trim(escape-output) '</p>' into markup with pointer cursor-pos end-string
 string '<h2 id="modal-title">' into markup with pointer cursor-pos end-string
 call static 'j_boolean' using by value context-node by reference z'runtime.ui.bossWon' returning flag end-call
 if flag = 1
 string 'Boss defeated!</h2><p>Your bufos will remember this croak for generations.</p><p>Permanent multiplier: ' into markup with pointer cursor-pos end-string
 move function J-NUM(context-node, 'runtime.ui.bossResult.multiplier') to number-value perform format-value
 string function trim(formatted) '×</p><p>A new area awaits.</p>' into markup with pointer cursor-pos end-string
 else
 string 'Defeated this time.</h2><p>Your bufo stash resets to zero. Your generators, upgrades and prestige remain.</p><p>Increase your click power and try again.</p>' into markup with pointer cursor-pos end-string
 end-if
 string '<button data-click="action" data-action="close"' into markup with pointer cursor-pos end-string
 if function J-NUM(context-node, 'runtime.now') - function J-NUM(context-node, 'runtime.ui.inputLockedUntil') < 0
 string ' disabled' into markup with pointer cursor-pos end-string end-if
 string '>Keep playing</button>' into markup with pointer cursor-pos end-string
 when 'custom'
 move function J-STR(context-node, 'runtime.ui.customTitle') to escape-input perform escape-html
 string '<h2 id="modal-title">' into markup with pointer cursor-pos end-string
 string function trim(escape-output) into markup with pointer cursor-pos end-string
 string '</h2>' into markup with pointer cursor-pos end-string
 move function J-STR(context-node, 'runtime.ui.customContent') to escape-input
 string function trim(escape-input) into markup with pointer cursor-pos end-string
 call static 'j_get_into' using by value context-node by reference z'runtime.ui.customOptions.buttons' buttons-list end-call
 call static 'j_size' using by value buttons-list by reference x'00' returning second-count end-call
 string '<div class="button-row">' into markup with pointer cursor-pos end-string
 perform varying second-index from 0 by 1 until second-index >= second-count
 call static 'j_at_into' using by value buttons-list second-index by reference button-node end-call
 move second-index to number-value perform format-plain
 string '<button data-click="action" data-action="customModalButton" data-index="' function trim(formatted) '" class="' into markup with pointer cursor-pos end-string
 move function J-STR(button-node, 'className') to escape-input perform escape-html
 string function trim(escape-output) '">' into markup with pointer cursor-pos end-string
 move function J-STR(button-node, 'text') to escape-input perform escape-html
 string function trim(escape-output) '</button>' into markup with pointer cursor-pos end-string
 end-perform
 string '</div>' into markup with pointer cursor-pos end-string
 end-evaluate
 string '</section></div>' into markup with pointer cursor-pos end-string
 end-if
 perform send-command
 .
achievement-row.
 move function J-STR(context-node,'runtime.ui.achievementCategory') to category-name
 if category-name not = spaces and category-name not = 'all' and category-name not = function J-STR(item-node,'category') exit paragraph end-if
 move function J-STR(item-node, 'id') to id-text
 move 0 to unlocked-flag
 call static 'j_get_into' using by value state-node by reference z'achievements.unlocked' unlocked-list end-call
 call static 'j_size' using by value unlocked-list by reference x'00' returning second-count end-call
 perform varying second-index from 0 by 1 until second-index >= second-count
 call static 'j_at_into' using by value unlocked-list second-index by reference unlocked-item end-call
 if function J-STR(unlocked-item, ' ') = id-text move 1 to unlocked-flag end-if
 end-perform
 if unlocked-flag = 0
 call static 'j_has' using by value context-node by reference z'runtime.ui.hideLocked' returning flag end-call
 if flag = 0 exit paragraph end-if
 call static 'j_boolean' using by value context-node by reference z'runtime.ui.hideLocked' returning flag end-call
 if flag = 1 exit paragraph end-if
 call static 'j_boolean' using by value item-node by reference z'secret' returning flag end-call
 if flag = 1
 call static 'j_boolean' using by value context-node by reference z'runtime.ui.showSecret' returning flag end-call
 if flag = 0 exit paragraph end-if end-if end-if
 move function J-STR(item-node, 'name') to escape-input perform escape-html move escape-output to name-text
 move function J-STR(item-node, 'description') to escape-input perform escape-html move escape-output to description-text
 string '<article class="achievement-row"><span class="achievement-state">' into markup with pointer cursor-pos end-string
 if unlocked-flag = 1
 string 'Unlocked' into markup with pointer cursor-pos end-string
 else string 'Locked' into markup with pointer cursor-pos end-string end-if
 string '</span>' into markup with pointer cursor-pos end-string
 move function J-STR(item-node,'iconPath') to escape-input perform escape-html
 if escape-output not = spaces
 string '<img class="achievement-icon" src="' function trim(escape-output) '" alt="">' into markup with pointer cursor-pos end-string
 else
 string '<span class="achievement-icon" aria-hidden="true">' into markup with pointer cursor-pos end-string
 evaluate function J-STR(item-node,'category')
 when 'generators' string '🏭' into markup with pointer cursor-pos end-string
 when 'production' string '💰' into markup with pointer cursor-pos end-string
 when 'clicks' string '👆' into markup with pointer cursor-pos end-string
 when 'special' string '🎮' into markup with pointer cursor-pos end-string
 when other string '🏆' into markup with pointer cursor-pos end-string end-evaluate
 string '</span>' into markup with pointer cursor-pos end-string end-if
 string '<strong>' function trim(name-text) '</strong><p>'
 function trim(description-text) '</p>' into markup with pointer cursor-pos end-string
 move function J-STR(item-node, 'reward.description') to escape-input perform escape-html
 if escape-output not = spaces
 string '<p class="reward">' function trim(escape-output) '</p>' into markup with pointer cursor-pos end-string
 end-if
 if unlocked-flag = 0
 move function J-NUM(item-node,'requirement.value') to total-ms
 call static 'j_get_into' using by value state-node by reference function concatenate('achievements.progress.',function trim(id-text),x'00') other-node end-call
 move function J-NUM(other-node,' ') to remaining-ms
 if total-ms > 0
 string '<p class="achievement-progress">' into markup with pointer cursor-pos end-string
 move remaining-ms to number-value perform format-value
 string function trim(formatted) ' / ' into markup with pointer cursor-pos end-string
 move total-ms to number-value perform format-value
 string function trim(formatted) '</p><progress max="100" value="' into markup with pointer cursor-pos end-string
 compute number-value = function max(0,function min(100,remaining-ms / total-ms * 100)) perform format-plain
 string function trim(formatted) '"></progress>' into markup with pointer cursor-pos end-string end-if end-if
 string '</article>' into markup with pointer cursor-pos end-string
 .
statistic-row.
 perform format-value
 string '<dt>' function trim(stat-label) '</dt><dd>' function trim(formatted) '</dd>' into markup with pointer cursor-pos end-string.
begin-markup.
 move spaces to markup
 move 1 to cursor-pos
 move 'html' to command-kind.
number-command.
 perform begin-markup
 perform format-value
 string function trim(formatted) into markup with pointer cursor-pos end-string
 move 'text' to command-kind
 perform send-command.
style-command.
 move 'style' to command-kind
 perform send-command
 call static 'j_set_string' using by value command-node by reference z'name' key-text
 by value function length(function trim(key-text)) end-call.
format-plain.
 call static 'h_decimal' using by reference number-value by value 2 0 1
 by reference formatted by value 256 end-call.
format-value.
 call static 'BUFO-FORMAT-NUMBER' using number-value formatted end-call.
send-command.
 call static 'j_object_into' using by reference command-node end-call
 call static 'j_set_string' using by value command-node by reference z'kind' command-kind
 by value function length(function trim(command-kind)) end-call
 call static 'j_set_string' using by value command-node by reference z'target' target-name
 by value function length(function trim(target-name)) end-call
 call static 'j_set_string' using by value command-node by reference z'value' markup
 by value function min(cursor-pos - 1, length of markup) end-call
 call static 'j_append' using by value commands command-node end-call.
prepare-query.
 call static 'j_delete' using by value child-request end-call
 call static 'j_delete' using by value child-response end-call
 call static 'j_object_into' using by reference child-request end-call
 call static 'j_object_into' using by reference child-response end-call
 call static 'j_set_string' using by value child-request by reference z'operation' route-name
 by value function length(function trim(route-name)) end-call.
game-query.
 perform prepare-query
 call static 'BUFO-GAME' using by value child-request context-node child-response end-call.
escape-html.
 move spaces to escape-output
 move 1 to escape-position
 move function length(function trim(escape-input trailing)) to escape-length
 perform varying escape-index from 1 by 1
 until escape-index > escape-length
 or escape-position > 65520
 evaluate escape-input(escape-index:1)
 when '&' string '&amp;' into escape-output with pointer escape-position end-string
 when '<' string '&lt;' into escape-output with pointer escape-position end-string
 when '>' string '&gt;' into escape-output with pointer escape-position end-string
 when '"' string '&quot;' into escape-output with pointer escape-position end-string
 when "'" string '&#39;' into escape-output with pointer escape-position end-string
 when other string escape-input(escape-index:1) into escape-output with pointer escape-position end-string
 end-evaluate
 end-perform.
end program BUFO-UI.
