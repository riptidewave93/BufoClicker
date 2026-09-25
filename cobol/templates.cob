 identification division.
 program-id. BUFO-TEMPLATES.
 environment division.
 configuration section.
 repository. function J-NUM function J-STR function all intrinsic.
 data division.
 local-storage section.
 01 op pic x(96).
 01 args usage pointer.
 01 args-table.
 02 a usage pointer occurs 8.
 01 strings-table.
 02 s pic x(32768) occurs 8.
 01 numbers-table.
 02 n usage comp-2 occurs 8.
 01 bools-table.
 02 b usage binary-long occurs 8.
 01 i usage binary-long.
 01 j usage binary-long.
 01 cnt usage binary-long.
 01 typ usage binary-long.
 01 item usage pointer.
 01 hp usage binary-long value 1.
 01 html pic x(262144).
 01 idattr pic x(32768).
 01 cls pic x(32768).
 01 extra pic x(32768).
 01 val pic x(256).
 01 pct usage comp-2.
 01 title-text pic x(32768).
 01 item-id pic x(256).
 linkage section.
 01 req usage pointer.
 01 ctx usage pointer.
 01 res usage pointer.
 procedure division using by value req ctx res.
 move function J-STR(req,'operation') to op
 call static 'j_get_into' using by value req by reference z'args' args end-call
 perform varying i from 1 by 1 until i > 8
 compute j = i - 1
 call static 'j_at_into' using by value args j by reference a(i) end-call
 move function J-STR(a(i),' ') to s(i)
 move function J-NUM(a(i),' ') to n(i)
 call static 'h_truthy' using by value a(i) returning b(i) end-call
 call static 'j_type' using by value a(i) by reference x'00' returning typ end-call
 if typ = 2
 call static 'h_decimal' using by reference n(i) by value 12 0 1 by reference s(i) by value 32768 end-call end-if
 end-perform
 evaluate op
 when 'templates.sectionHeader'
 move 2 to i perform id-attribute
 string '<h2 class="section-header"' function trim(idattr trailing) '>' function trim(s(1) trailing) '</h2>' into html with pointer hp end-string
 when 'templates.panel'
 move 3 to i perform id-attribute
 move spaces to cls if b(4) = 1 move function concatenate(" ",function trim(s(4))) to cls end-if
 string '<div class="game-panel' function trim(cls trailing) '"' function trim(idattr trailing) '><div class="panel-header"><h2>' function trim(s(1) trailing) '</h2></div><div class="panel-content">' function
 trim(s(2) trailing) '</div></div>' into html with pointer hp end-string
 when 'templates.button'
 move 2 to i perform id-attribute
 move spaces to cls if b(4) = 1 move function concatenate(" ",function trim(s(4))) to cls end-if
 move spaces to extra
 if b(5) = 1 move function concatenate(function trim(cls trailing)," disabled") to cls move " disabled" to extra end-if
 string '<button class="game-button' function trim(cls trailing) '"' function trim(idattr trailing) into html with pointer hp end-string
 if b(3) = 1
 string ' onclick="' function trim(s(3) trailing) '"' into html with pointer hp end-string
 end-if
 string function trim(extra trailing) '>' function trim(s(1) trailing) '</button>' into html with pointer hp end-string
 when 'templates.iconButton'
 move 2 to i perform id-attribute
 move spaces to cls if b(5) = 1 move function concatenate(" ",function trim(s(5))) to cls end-if
 move spaces to extra
 if b(6) = 1 move function concatenate(function trim(cls trailing)," disabled") to cls move " disabled" to extra end-if
 string '<button class="icon-button' function trim(cls trailing) '"' function trim(idattr trailing) into html with pointer hp end-string
 if b(4) = 1
 string ' onclick="' function trim(s(4) trailing) '"' into html with pointer hp end-string
 end-if
 if b(3) = 1
 string ' title="' function trim(s(3) trailing) '"' into html with pointer hp end-string
 end-if
 string function trim(extra trailing) '>' function trim(s(1) trailing) '</button>' into html with pointer hp end-string
 when 'templates.progressBar'
 move 3 to i perform id-attribute
 move spaces to cls if b(5) = 1 move function concatenate(" ",function trim(s(5))) to cls end-if
 if n(2) = 0
 if n(1) = 0 move 'NaN' to val else
 if n(1) < 0 move '-Infinity' to val else move 'Infinity' to val end-if end-if
 else compute pct = function integer(n(1) / n(2) * 100)
 call static 'h_decimal' using by reference pct by value 0 0 0 by reference val by value 256 end-call end-if
 string '<div class="progress-container' function trim(cls trailing) '"' function trim(idattr trailing) '><div class="progress-bar" style="width: ' function trim(val trailing) '%"></div>' into html with pointer
 hp end-string
 if a(4) = null or b(4) = 1
 string '<span class="progress-label">' function trim(val trailing) '%</span>' into html with pointer hp end-string
 end-if
 string '</div>' into html with pointer hp end-string
 when 'templates.resourceDisplay'
 move 3 to i perform id-attribute
 move spaces to cls if b(6) = 1 move function concatenate(" ",function trim(s(6))) to cls end-if
 string '<div class="resource-display' function trim(cls trailing) '"' function trim(idattr trailing) '><div class="resource-count">' function trim(s(1) trailing) '</div>' into html with pointer hp end-string
 if b(4) = 1 and a(5) not = null
 string '<div class="production-rate">' function trim(s(5) trailing) '/sec</div>' into html with pointer hp end-string
 end-if
 string '</div>' into html with pointer hp end-string
 when 'templates.tooltip'
 move 3 to i perform id-attribute
 move spaces to cls if b(4) = 1 move function concatenate(" ",function trim(s(4))) to cls end-if
 string '<div class="game-tooltip' function trim(cls trailing) '"' function trim(idattr trailing) '>' into html with pointer hp end-string
 if b(2) = 1
 string '<div class="tooltip-header">' function trim(s(2) trailing) '</div>' into html with pointer hp end-string
 end-if
 string '<div class="tooltip-content">' function trim(s(1) trailing) '</div></div>' into html with pointer hp end-string
 when 'templates.notification'
 move 3 to i perform id-attribute
 if a(2) = null move 'info' to s(2) end-if
 string '<div class="notification notification-' function trim(s(2) trailing) '"' function trim(idattr trailing) '><div class="notification-content"><span class="notification-message">' function trim(s(1)
 trailing) '</span><button class="notification-close">&times;</button></div></div>' into html with pointer hp end-string
 when 'templates.modal'
 move 4 to i perform id-attribute
 string '<div class="modal"' function trim(idattr trailing) into html with pointer hp end-string
 if a(5) = null or b(5) = 1
 string ' data-close-on-backdrop="true"' into html with pointer hp end-string
 end-if
 string '><div class="modal-content"><div class="modal-header"><h2>' function trim(s(1) trailing) '</h2><button class="modal-close">&times;</button></div><div class="modal-body">' function trim(s(2) trailing)
 '</div>' into html with pointer hp end-string
 call static 'j_size' using by value a(3) by reference x'00' returning cnt end-call
 if cnt > 0
 string '<div class="modal-footer">' into html with pointer hp end-string
 perform varying j from 0 by 1 until j >= cnt
 call static 'j_at_into' using by value a(3) j by reference item end-call
 move function J-STR(item,'className') to cls
 if cls = spaces move 'modal-button' to cls end-if
 move function J-STR(item,'callback') to extra
 move function J-STR(item,'text') to title-text
 string '<button class="' function trim(cls trailing) '" onclick="' function trim(extra trailing) '">' function trim(title-text trailing) '</button>' into html with pointer hp end-string
 end-perform
 string '</div>' into html with pointer hp end-string
 end-if
 string '</div></div>' into html with pointer hp end-string
 when 'templates.tabContainer'
 move 3 to i perform id-attribute
 string '<div class="tab-container"' function trim(idattr trailing) '><div class="tab-buttons">' into html with pointer hp end-string
 call static 'j_size' using by value a(1) by reference x'00' returning cnt end-call
 perform varying j from 0 by 1 until j >= cnt
 call static 'j_at_into' using by value a(1) j by reference item end-call
 move function J-STR(item,'id') to item-id
 move spaces to cls if item-id = s(2) move ' active' to cls end-if
 move function J-STR(item,'label') to title-text
 move function J-STR(item,'icon') to extra
 string '<button class="tab-button' function trim(cls trailing) '" data-tab="' function trim(item-id trailing) '">' into html with pointer hp end-string
 if extra not = spaces
 string '<span class="tab-icon">' function trim(extra trailing) '</span>' into html with pointer hp end-string
 end-if
 string '<span class="tab-label">' function trim(title-text trailing) '</span></button>' into html with pointer hp end-string
 end-perform
 string '</div><div class="tab-contents">' into html with pointer hp end-string
 perform varying j from 0 by 1 until j >= cnt
 call static 'j_at_into' using by value a(1) j by reference item end-call
 move function J-STR(item,'id') to item-id
 move 'none' to cls if item-id = s(2) move 'block' to cls end-if
 move function J-STR(item,'content') to title-text
 string '<div id="tab-' function trim(item-id trailing) '" class="tab-content" style="display: ' function trim(cls trailing) '">' function trim(title-text trailing) '</div>' into html with pointer hp end-string
 end-perform
 string '</div></div>' into html with pointer hp end-string
 when other
 call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
 call static 'j_set_string' using by value res by reference z'error' z'Unknown template operation' by value 26 end-call goback
 end-evaluate
 if hp > 262144
 call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call goback end-if
 call static 'j_set_boolean' using by value res by reference z'ok' by value 1 end-call
 subtract 1 from hp
 call static 'j_set_string' using by value res by reference z'result' html by value hp end-call
 goback.
 id-attribute.
 move spaces to idattr
 if b(i) = 1 string ' id="' function trim(s(i)) '"' into idattr end-string end-if.
 end program BUFO-TEMPLATES.
