identification division.
program-id. BUFO-UI-CONSTANTS.
environment division.
configuration section.
repository. function J-NUM function J-STR function all intrinsic.
data division.
local-storage section.
01 encoded pic x(8192).
01 position-index usage binary-long value 1.
01 op pic x(96).
01 path-text pic x(256).
01 name-text pic x(128).
01 tree usage pointer.
01 selected usage pointer.
01 result-node usage pointer.
linkage section.
01 req usage pointer.
01 ctx usage pointer.
01 res usage pointer.
procedure division using by value req ctx res.
 string
 '{"uiConstants":{"TABS":[{"id":"main","label":"Main","icon":"🐸"},{"id":"shop","label":"Shop","icon":"'
 '🛒"},{"id":"upgrades","label":"Upgrades","icon":"⬆️"},{"id":"stats","label":"Stats","icon":"📊"}],"DEF'
 'AULT_TAB":"main","Z_INDEX":{"base":1,"content":10,"notification":100,"modal":1000},"ANIMATION":{"sho'
 'rt":150,"medium":300,"long":500},"BREAKPOINTS":{"mobile":480,"tablet":768,"desktop":1024},"DEFAULT_N'
 'OTIFICATION_DURATION":3000,"DEFAULT_THEME":"dark","THEMES":["light","dark","forest"],"TOOLTIP_DELAY"'
 ':300},"uiStyles":{"LAYOUT":{"container":"game-container","header":"game-header","content":"game-cont'
 'ent","footer":"game-footer","tabContent":"tab-content","panel":"game-panel","section":"game-section"'
 ',"wrapper":"content-wrapper","flex":"flex-container","grid":"grid-container","hidden":"hidden","visi'
 'ble":"visible","mobile":"mobile-layout","desktop":"desktop-layout"},"COMPONENT":{"resourceDisplay":"'
 'resource-display","clickArea":"frog-display","generatorList":"owned-generators-container","generator'
 '":"owned-generator","shop":"buildings-container","shopItem":"building-item","upgradeList":"upgrades-'
 'grid","upgradeItem":"upgrade-icon-container","tab":"tab-button","activeTab":"active","button":"game-'
 'button","input":"game-input","icon":"game-icon","image":"game-image","tooltip":"game-tooltip"},"STAT'
 'E":{"selected":"selected","active":"active","disabled":"disabled","loading":"loading","error":"error'
 '","success":"success","warning":"warning","info":"info","new":"new","affordable":"affordable","notAf'
 'fordable":"not-affordable","unlocked":"unlocked","locked":"locked","hasNotification":"has-notificati'
 'on","highlighted":"highlighted","pulse":"pulse","shake":"shake","fade":"fade","bounce":"bounce"},"MO'
 'DAL":{"container":"modal-container","modal":"modal","content":"modal-content","header":"modal-header'
 '","body":"modal-body","footer":"modal-footer","close":"modal-close","button":"modal-button","confirm'
 '":"confirm-button","cancel":"cancel-button","visible":"visible"},"NOTIFICATION":{"container":"notifi'
 'cation-container","notification":"notification","content":"notification-content","message":"notifica'
 'tion-message","close":"notification-close","info":"notification-info","success":"notification-succes'
 's","warning":"notification-warning","error":"notification-error","visible":"visible"},"TOOLTIP":{"co'
 'ntainer":"tooltip-container","tooltip":"game-tooltip","header":"tooltip-header","title":"tooltip-tit'
 'le","description":"tooltip-description","section":"tooltip-section","label":"tooltip-label","value":'
 '"tooltip-value","visible":"visible"},"ANIMATION":{"fade":"fade","fadeIn":"fade-in","fadeOut":"fade-o'
 'ut","slide":"slide","slideIn":"slide-in","slideOut":"slide-out","pulse":"pulse","bounce":"bounce","s'
 'hake":"shake","spin":"spin","pop":"pop"},"CATEGORY":{"basic":"category-basic","premium":"category-pr'
 'emium","special":"category-special","click":"category-click","generator":"category-generator","globa'
 'l":"category-global"}}}'
 into encoded with pointer position-index end-string
 subtract 1 from position-index
 call static 'j_parse_into' using by reference encoded by value position-index by reference tree end-call
 move function J-STR(req,'operation') to op
 if op(1:12) = 'uiConstants.' move 'uiConstants' to path-text move op(13:) to name-text
 else move 'uiStyles' to path-text move op(10:) to name-text end-if
 if name-text = 'get' move function J-STR(req,'args.0') to name-text end-if
 if name-text not = spaces move function concatenate(function trim(path-text),'.',function trim(name-text)) to path-text end-if
 call static 'j_get_into' using by value tree by reference function concatenate(function trim(path-text),x'00') selected end-call
 if selected = null
 call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
 call static 'j_set_string' using by value res by reference z'error' z'Unknown UI constant' by value 19 end-call
 else call static 'j_set_boolean' using by value res by reference z'ok' by value 1 end-call
 call static 'j_clone_into' using by value selected by reference result-node end-call
 call static 'j_set' using by value res by reference z'result' by value result-node end-call end-if
 call static 'j_delete' using by value tree end-call goback.
end program BUFO-UI-CONSTANTS.
