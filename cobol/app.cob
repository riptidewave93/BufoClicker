identification division.
program-id. BUFO-APP.
environment division.
configuration section.
repository. function J-NUM function J-STR function all intrinsic.
data division.
working-storage section.
01 context-node usage pointer value null.
01 loaded-flag usage binary-long value 0.
local-storage section.
01 old-state usage pointer.
01 after-node usage pointer.
01 after-request usage pointer.
01 after-args usage pointer.
01 child-request usage pointer.
01 child-response usage pointer.
01 node-a usage pointer.
01 node-b usage pointer.
01 node-c usage pointer.
01 operation-name pic x(128).
01 route-name pic x(128).
01 key-text pic x(256).
01 key-z pic x(257).
01 error-text pic x(1024).
01 now-value usage comp-2.
01 number-value usage comp-2.
01 delta-value usage comp-2.
01 step-value usage comp-2.
01 accumulator usage comp-2.
01 result-number usage comp-2.
01 item-index usage binary-long.
01 item-count usage binary-long.
01 status-code usage binary-long.
01 other-status usage binary-long.
01 type-code usage binary-long.
01 notify-state-flag usage binary-long.
01 notify-component-flag usage binary-long.
01 render-flag usage binary-long.
01 running-flag usage binary-long.
01 catalog-index usage binary-long.
01 catalog-fields.
   02 filler pic x(16) value 'generators'.
   02 filler pic x(16) value 'upgrades'.
   02 filler pic x(16) value 'achievements'.
   02 filler pic x(16) value 'bosses'.
   02 filler pic x(16) value 'enemies'.
01 catalog-table redefines catalog-fields.
   02 catalog-name pic x(16) occurs 5.
linkage section.
01 request-node usage pointer.
01 response-node usage pointer.
procedure division using by value request-node response-node.
    call static 'j_type' using by value request-node
        by reference z'operation' returning type-code end-call
    if type-code not = 3
        move 'Request operation must be a string.' to error-text
        perform fail-response
        goback
    end-if
    move function J-STR(request-node, 'operation') to operation-name
    if operation-name = 'runtime.reset'
        call static 'j_delete' using by value context-node end-call
        set context-node to null
        move 0 to loaded-flag
        call static 'j_callback_roots' using by value context-node response-node end-call
        perform true-response
        goback
    end-if
    if operation-name(1:8) = 'storage.'
        perform storage-operation
        if error-text not = spaces perform fail-response end-if
        goback
    end-if
    call static 'j_type' using by value request-node
        by reference z'now' returning type-code end-call
    if type-code = 2
        move function J-NUM(request-node, 'now') to now-value
    else
        if type-code not = 0
            move 'Request time must be a number.' to error-text
            perform fail-response
            goback
        end-if
        call static 'h_now' using by reference now-value end-call
    end-if
    if now-value < 0 or now-value > 9007199254740991
        move 'Request time is outside the supported range.' to error-text
        perform fail-response
        goback
    end-if
    call static 'j_get_into' using by value request-node
        by reference z'random' node-a end-call
    if node-a not = null
        call static 'j_type' using by value node-a by reference x'00' returning type-code end-call
        call static 'j_size' using by value node-a by reference x'00' returning item-count end-call
        if type-code not = 4 or item-count > 10000
            move 'Random sequence must be a bounded array.' to error-text
        else
            perform varying item-index from 0 by 1 until item-index >= item-count
                call static 'j_at_into' using by value node-a item-index by reference node-b end-call
                call static 'j_type' using by value node-b by reference x'00' returning type-code end-call
                move function J-NUM(node-b, ' ') to number-value
                if type-code not = 2 or number-value < 0 or number-value >= 1
                    move 'Random values must be numbers from zero up to one.' to error-text
                end-if
            end-perform
        end-if
    end-if
    if error-text not = spaces perform fail-response goback end-if
    if context-node = null perform initialize-context end-if
    if error-text not = spaces
        call static 'j_delete' using by value context-node end-call
        set context-node to null
        perform fail-response goback end-if
    call static 'j_set_number' using by value context-node
        by reference z'runtime.now' now-value end-call
    move 0 to number-value
    call static 'j_set_number' using by value context-node
        by reference z'runtime.randomIndex' number-value end-call
    call static 'j_array_into' using by reference node-a end-call
    call static 'j_set' using by value context-node by reference z'events' by value node-a end-call
    if loaded-flag = 0
        move 'load' to route-name
        perform save-route
        move 1 to loaded-flag
        call static 'j_remove' using by value response-node by reference z'error' end-call
        call static 'j_boolean' using by value request-node
            by reference z'args.hidden' returning status-code end-call
        if status-code = 1
            call static 'j_set_boolean' using by value context-node
                by reference z'runtime.hidden' by value 1 end-call
            call static 'j_set_boolean' using by value context-node
                by reference z'runtime.loop.running' by value 0 end-call
        end-if
        move spaces to error-text
        call static 'j_boolean' using by value context-node
            by reference z'runtime.persistence.blocked' returning status-code end-call
        call static 'j_boolean' using by value context-node
            by reference z'runtime.hidden' returning other-status end-call
        if status-code = 0 and other-status = 0
            move 'golden.start' to route-name perform game-route
        end-if
    end-if
    call static 'j_has' using by value context-node
        by reference z'runtime.serviceStateNames.state' returning notify-state-flag end-call
    if operation-name(1:6) = 'state.' or operation-name(1:13) = 'stateManager.'
        or operation-name(1:10) = 'gameState.'
        or (operation-name = 'api' and (function J-STR(request-node, 'args.path.0') = 'state' or 'stateManager'))
        move 0 to notify-state-flag end-if
    call static 'j_boolean' using by value context-node
        by reference z'uiLibrary.needsNotifications' returning notify-component-flag end-call
    if (notify-state-flag > 0 or notify-component-flag > 0)
        and operation-name(1:6) not = 'event.' and operation-name(1:5) not = 'time.'
        and operation-name not = 'getState' and 'render' and 'component.notifyState' and 'component.notifyEvent'
        call static 'j_get_into' using by value context-node by reference z'state' node-a end-call
        call static 'j_clone_into' using by value node-a by reference old-state end-call
    end-if
    call static 'j_boolean' using by value request-node
        by reference z'browser' returning render-flag end-call
    call static 'j_boolean' using by value context-node
        by reference z'runtime.persistence.blocked' returning status-code end-call
    if status-code = 1 and operation-name not = 'init' and 'getState' and 'render'
        and operation-name(1:5) not = 'save.' and operation-name not = 'visibility'
        and operation-name not = 'frame' and operation-name not = 'api'
        and operation-name not = 'action'
        move 'Progress is paused until save recovery succeeds.' to error-text
    else
        evaluate true
          when operation-name = 'init'
            perform true-response
          when operation-name = 'getState'
            call static 'j_get_into' using by value context-node
                by reference z'state' node-a end-call
            call static 'j_clone_into' using by value node-a by reference node-b end-call
            call static 'j_set' using by value response-node by reference z'result' by value node-b end-call
            perform ok-response
          when operation-name = 'frame'
            perform process-frame
          when operation-name = 'visibility'
            perform visibility-change
          when operation-name = 'start'
            call static 'j_set_boolean' using by value context-node by reference z'runtime.game.destroyed' by value 0 end-call
            call static 'j_set_boolean' using by value context-node
                by reference z'runtime.loop.running' by value 1 end-call
            call static 'j_set_number' using by value context-node
                by reference z'runtime.loop.lastFrame' now-value end-call
            move 'golden.start' to route-name
            perform game-route
          when operation-name = 'stop'
            call static 'j_set_boolean' using by value context-node
                by reference z'runtime.loop.running' by value 0 end-call
            move 'golden.stop' to route-name
            perform game-route
          when operation-name = 'render'
            perform ok-response
          when operation-name = 'api'
            call static 'BUFO-API' using by value request-node context-node response-node end-call
          when operation-name = 'action'
            call static 'BUFO-ACTIONS' using by value request-node context-node response-node end-call
          when operation-name = 'prestige.transcend'
            move 'prestige' to route-name perform save-route
          when operation-name(1:5) = 'save.'
            move operation-name(6:) to route-name
            perform save-route
          when operation-name(1:9) = 'explorer.'
            move operation-name(10:) to route-name
            perform explorer-route
          when operation-name(1:5) = 'game.'
            move operation-name(6:) to route-name
            perform game-route
          when operation-name = 'click' or 'registerClick' or 'buyGenerator' or 'buyUpgrade'
            move operation-name to route-name
            perform game-route
          when operation-name(1:6) = 'model.' or operation-name(1:10) = 'generator.'
            or operation-name(1:8) = 'upgrade.' or operation-name(1:12) = 'achievement.'
            or operation-name(1:9) = 'prestige.' or operation-name(1:7) = 'golden.'
            or operation-name(1:5) = 'boss.'
            move operation-name to route-name
            perform game-route
          when operation-name(1:15) = 'initialization.'
            call static 'BUFO-API-INITIALIZATION' using by value request-node context-node response-node end-call
          when operation-name = 'ui.renderBoss' or 'ui.renderGolden'
            call static 'BUFO-UI' using by value request-node context-node response-node end-call
          when operation-name(1:3) = 'ui.'
            call static 'BUFO-API-UI' using by value request-node context-node response-node end-call
          when operation-name(1:10) = 'component.' or operation-name(1:10) = 'container.'
            or operation-name(1:10) = 'templates.' or operation-name(1:4) = 'dom.'
            or operation-name(1:10) = 'animation.' or operation-name(1:8) = 'tooltip.'
            or operation-name(1:7) = 'styles.' or operation-name(1:5) = 'shop.'
            or operation-name(1:14) = 'generatorList.' or operation-name(1:16) = 'resourceDisplay.'
            or operation-name(1:10) = 'clickArea.' or operation-name(1:14) = 'generatorItem.'
            or operation-name(1:9) = 'shopItem.' or operation-name(1:12) = 'upgradeItem.'
            or operation-name(1:12) = 'upgradeList.' or operation-name(1:12) = 'uiConstants.'
            or operation-name(1:9) = 'uiStyles.'
            call static 'BUFO-COMPONENTS' using by value request-node context-node response-node end-call
          when other
            call static 'BUFO-SERVICES' using by value request-node context-node response-node end-call
        end-evaluate
    end-if
    call static 'BUFO-PRESENTATION' using by value request-node context-node response-node end-call
    if operation-name = 'save.retry' or 'save.import' or 'save.reset' or 'save.prestige'
        or (operation-name = 'action' and (function J-STR(request-node, 'args.action') = 'retry'
            or 'import' or 'confirmReset' or 'confirmPrestige'))
        call static 'j_boolean' using by value context-node
            by reference z'runtime.persistence.blocked' returning status-code end-call
        call static 'j_boolean' using by value context-node
            by reference z'runtime.hidden' returning other-status end-call
        if status-code = 0 and other-status = 0
            call static 'j_boolean' using by value context-node
                by reference z'runtime.loop.running' returning running-flag end-call
            if running-flag = 0
                call static 'j_set_boolean' using by value context-node
                    by reference z'runtime.loop.running' by value 1 end-call
                call static 'j_set_number' using by value context-node
                    by reference z'runtime.loop.lastFrame' now-value end-call
            end-if
            call static 'j_delete' using by value child-response end-call
            call static 'j_object_into' using by reference child-response end-call
            move 'golden.start' to route-name perform child-route-request
            call static 'BUFO-GAME' using by value child-request context-node child-response end-call
            move 'boss.resume' to route-name perform child-route-request
            call static 'BUFO-GAME' using by value child-request context-node child-response end-call
        end-if
    end-if
    if operation-name = 'frame' and now-value -
        function J-NUM(context-node, 'runtime.ui.lastRender') < 100
        move 0 to render-flag end-if
    if render-flag = 1
        call static 'j_set_number' using by value context-node
            by reference z'runtime.ui.lastRender' now-value end-call
        call static 'BUFO-UI' using by value request-node context-node response-node end-call
    end-if
    if error-text not = spaces perform fail-response end-if
    call static 'j_get_into' using by value context-node by reference z'events' node-a end-call
    call static 'j_clone_into' using by value node-a by reference node-b end-call
    call static 'j_set' using by value response-node by reference z'events' by value node-b end-call
    call static 'j_size' using by value context-node
        by reference z'runtime.serviceEventNames' returning status-code end-call
    call static 'j_boolean' using by value context-node
        by reference z'runtime.eventDebug' returning other-status end-call
    if status-code > 0 or other-status = 1 move 1 to status-code else move 0 to status-code end-if
    call static 'j_set_boolean' using by value response-node
        by reference z'eventObservers' by value status-code end-call
    if notify-component-flag > 0
        call static 'j_set_boolean' using by value response-node
            by reference z'notifyComponents' by value 1 end-call
    end-if
    if old-state not = null
        call static 'j_get_into' using by value context-node by reference z'state' node-a end-call
        call static 'j_equal' using by value old-state node-a returning status-code end-call
        if status-code = 0
            call static 'j_get_into' using by value response-node by reference z'after' after-node end-call
            if after-node = null
                call static 'j_array_into' using by reference after-node end-call
                call static 'j_set' using by value response-node by reference z'after' by value after-node end-call
            end-if
            if notify-state-flag > 0
                call static 'j_object_into' using by reference after-request end-call
                call static 'j_set_string' using by value after-request
                    by reference z'operation' 'stateManager.notify' by value 19 end-call
                call static 'j_array_into' using by reference after-args end-call
                call static 'j_append' using by value after-args old-state end-call
                set old-state to null
                call static 'j_set' using by value after-request by reference z'args' by value after-args end-call
                call static 'j_append' using by value after-node after-request end-call
            end-if
            if notify-component-flag > 0
                call static 'j_object_into' using by reference after-request end-call
                call static 'j_set_string' using by value after-request
                    by reference z'operation' 'component.notifyState' by value 21 end-call
                call static 'j_append' using by value after-node after-request end-call
            end-if
        end-if
        call static 'j_delete' using by value old-state end-call
    end-if
    call static 'j_delete' using by value child-request end-call
    call static 'j_delete' using by value child-response end-call
    call static 'j_boolean' using by value request-node
        by reference z'collectCallbacks' returning status-code end-call
    if status-code = 1
        call static 'j_callback_roots' using by value context-node response-node end-call
    end-if
    goback.
initialize-context.
    call static 'j_parse_into' using
        by reference '{"state":{},"runtime":{},"events":[]}' by value 37
        by reference context-node end-call
    call static 'j_set_number' using by value context-node by reference z'runtime.now' now-value end-call
    perform varying catalog-index from 1 by 1 until catalog-index > 5
        move spaces to key-text
        string 'assets/data/' function trim(catalog-name(catalog-index)) '.json' into key-text end-string
        move low-values to key-z
        string function trim(key-text) x'00' into key-z end-string
        call static 'j_read_file_into' using by reference key-z node-a returning status-code end-call
        if status-code not = 0
            move function concatenate('Could not load ', function trim(key-text)) to error-text
        else
            move spaces to key-text
            string 'catalog.' function trim(catalog-name(catalog-index)) into key-text end-string
            move low-values to key-z
            string function trim(key-text) x'00' into key-z end-string
            call static 'j_set' using by value context-node by reference key-z by value node-a end-call
        end-if
    end-perform
    if error-text = spaces
        call static 'BUFO-VALIDATE-CATALOGS' using by value request-node context-node response-node end-call
        call static 'j_boolean' using by value response-node by reference z'ok' returning status-code end-call
        if status-code = 0 move function J-STR(response-node, 'error') to error-text end-if
    end-if
    if error-text = spaces
        move 'init' to route-name
        perform child-route-request
        call static 'BUFO-GAME' using by value child-request context-node response-node end-call
        call static 'BUFO-EXPLORER' using by value child-request context-node response-node end-call
        call static 'j_set_boolean' using by value context-node
            by reference z'state.gameSettings.autoSave' by value 1 end-call
        call static 'j_set_string' using by value context-node
            by reference z'state.gameSettings.version' '1.0.0' by value 5 end-call
        call static 'j_set_number' using by value context-node
            by reference z'state.gameSettings.lastTick' now-value end-call
        call static 'j_set_number' using by value context-node
            by reference z'state.gameSettings.lastSaved' now-value end-call
        call static 'j_set_number' using by value context-node
            by reference z'state.gameSettings.firstStartTime' now-value end-call
        move 60 to number-value
        call static 'j_set_number' using by value context-node
            by reference z'runtime.loop.fps' number-value end-call
        move 1 to number-value
        call static 'j_set_number' using by value context-node
            by reference z'runtime.loop.scale' number-value end-call
        call static 'j_set_number' using by value context-node
            by reference z'runtime.loop.lastFrame' now-value end-call
        call static 'j_set_boolean' using by value context-node
            by reference z'runtime.loop.running' by value 1 end-call
        call static 'j_get_into' using by value context-node
            by reference z'state' node-a end-call
        call static 'j_clone_into' using by value node-a by reference node-b end-call
        call static 'j_set' using by value context-node
            by reference z'runtime.defaultState' by value node-b end-call
    end-if.
child-route-request.
    call static 'j_delete' using by value child-request end-call
    call static 'j_clone_into' using by value request-node by reference child-request end-call
    call static 'j_set_string' using by value child-request
        by reference z'operation' route-name
        by value function length(function trim(route-name)) end-call.
game-route.
    perform child-route-request
    call static 'BUFO-GAME' using by value child-request context-node response-node end-call
    if route-name = 'buyGenerator' or 'buyUpgrade'
        call static 'j_delete' using by value child-response end-call
        call static 'j_object_into' using by reference child-response end-call
        call static 'j_set_string' using by value child-request
            by reference z'operation' 'save' by value 4 end-call
        call static 'BUFO-SAVE' using by value child-request context-node child-response end-call
    end-if.
explorer-route.
    perform child-route-request
    call static 'BUFO-EXPLORER' using by value child-request context-node response-node end-call.
save-route.
    perform child-route-request
    if route-name = 'save' and (operation-name = 'frame' or 'visibility')
        call static 'j_set_boolean' using by value child-request
            by reference z'args.auto' by value 1 end-call
    end-if
    call static 'BUFO-SAVE' using by value child-request context-node response-node end-call.
process-frame.
    call static 'j_boolean' using by value request-node
        by reference z'args.firstFrame' returning status-code end-call
    if status-code = 1
        call static 'j_set_number' using by value context-node
            by reference z'runtime.loop.lastFrame' now-value end-call
    end-if
    call static 'j_boolean' using by value context-node
        by reference z'runtime.loop.running' returning running-flag end-call
    call static 'j_boolean' using by value context-node
        by reference z'runtime.persistence.blocked' returning status-code end-call
    if running-flag = 1 and status-code = 0
        compute delta-value = function max(0, now-value -
            function J-NUM(context-node, 'runtime.loop.lastFrame'))
        compute accumulator = function min(1000,
            function J-NUM(context-node, 'runtime.loop.accumulator') + delta-value *
            function J-NUM(context-node, 'runtime.loop.scale'))
        compute step-value = 1000 / function J-NUM(context-node, 'runtime.loop.fps')
        perform until accumulator < step-value or error-text not = spaces
            move 'tick' to route-name
            perform child-route-request
            compute number-value = step-value / 1000
            call static 'j_set_number' using by value child-request
                by reference z'args.delta' number-value end-call
            call static 'j_set_boolean' using by value child-request
                by reference z'args.deferChecks' by value 1 end-call
            call static 'BUFO-GAME' using by value child-request context-node response-node end-call
            call static 'j_set_string' using by value child-request
                by reference z'operation' 'update' by value 6 end-call
            call static 'BUFO-EXPLORER' using by value child-request context-node response-node end-call
            call static 'j_set_string' using by value child-request
                by reference z'operation' 'finishTick' by value 10 end-call
            call static 'BUFO-GAME' using by value child-request context-node response-node end-call
            subtract step-value from accumulator
        end-perform
        call static 'j_set_number' using by value context-node
            by reference z'runtime.loop.accumulator' accumulator end-call
        compute number-value = function J-NUM(context-node, 'runtime.loop.timeSinceTick') + delta-value
        if number-value >= 100
            call static 'j_object_into' using by reference node-a end-call
            call static 'j_set_string' using by value node-a by reference z'name' 'GAME_TICK' by value 9 end-call
            call static 'j_set_number' using by value node-a by reference z'payload.deltaTime' number-value end-call
            move function J-NUM(context-node, 'runtime.loop.scale') to result-number
            call static 'j_set_number' using by value node-a by reference z'payload.timeScale' result-number end-call
            call static 'j_get_into' using by value context-node by reference z'events' node-b end-call
            call static 'j_append' using by value node-b node-a end-call
            move 0 to number-value
        end-if
        call static 'j_set_number' using by value context-node
            by reference z'runtime.loop.timeSinceTick' number-value end-call

        call static 'j_set_number' using by value context-node
            by reference z'state.gameSettings.lastTick' now-value end-call
        call static 'j_boolean' using by value context-node
            by reference z'state.gameSettings.autoSave' returning status-code end-call
        call static 'j_boolean' using by value context-node
            by reference z'runtime.game.destroyed' returning other-status end-call
        if status-code = 1 and other-status = 0 and now-value -
            function J-NUM(context-node, 'state.gameSettings.lastSaved') >= 60000
            and now-value - function J-NUM(context-node, 'runtime.loop.lastAutoSaveAttempt') >= 60000
            call static 'j_set_number' using by value context-node
                by reference z'runtime.loop.lastAutoSaveAttempt' now-value end-call
            move 'save' to route-name
            perform save-route
        end-if
    end-if
    call static 'j_set_number' using by value context-node
        by reference z'runtime.loop.lastFrame' now-value end-call
    call static 'j_has' using by value response-node by reference z'error' returning status-code end-call
    if status-code = 0 perform ok-response end-if.
visibility-change.
    call static 'j_boolean' using by value request-node
        by reference z'args.hidden' returning status-code end-call
    if status-code = 1
        call static 'j_boolean' using by value context-node
            by reference z'runtime.hidden' returning other-status end-call
        if other-status = 1 perform true-response exit paragraph end-if
        call static 'j_boolean' using by value context-node
            by reference z'runtime.persistence.blocked' returning other-status end-call
        if other-status = 1
            call static 'j_set_boolean' using by value context-node
                by reference z'runtime.hidden' by value 1 end-call
            perform true-response exit paragraph
        end-if
        call static 'j_set_boolean' using by value context-node
            by reference z'runtime.hidden' by value 1 end-call
        call static 'j_set_number' using by value context-node
            by reference z'state.gameSettings.lastTick' now-value end-call
        move 'golden.stop' to route-name
        perform game-route
        move 'boss.pause' to route-name
        perform game-route
        move 'save' to route-name
        perform save-route
        call static 'j_set_boolean' using by value context-node
            by reference z'runtime.loop.running' by value 0 end-call
    else
        call static 'j_boolean' using by value context-node
            by reference z'runtime.hidden' returning status-code end-call
        if status-code = 1
            call static 'j_set_boolean' using by value context-node
                by reference z'runtime.hidden' by value 0 end-call
            call static 'j_boolean' using by value context-node
                by reference z'runtime.persistence.blocked' returning other-status end-call
            if other-status = 1 perform true-response exit paragraph end-if
            move 'resume' to route-name
            perform save-route
            call static 'j_boolean' using by value response-node
                by reference z'ok' returning status-code end-call
            if status-code = 1
                move 'golden.start' to route-name
                perform game-route
                move 'boss.resume' to route-name
                perform game-route
                call static 'j_set_boolean' using by value context-node
                    by reference z'runtime.hidden' by value 0 end-call
                call static 'j_set_boolean' using by value context-node
                    by reference z'runtime.loop.running' by value 1 end-call
                call static 'j_set_number' using by value context-node
                    by reference z'runtime.loop.lastFrame' now-value end-call
            end-if
        end-if
    end-if.
storage-operation.
    move function J-STR(request-node, 'args.key') to key-text
    move low-values to key-z
    string function trim(key-text) x'00' into key-z end-string
    evaluate operation-name
      when 'storage.getRaw'
        call static 'h_storage_read' using by reference key-z node-a status-code end-call
        if status-code = -1 move 'Storage read failed.' to error-text
        else
            if status-code = 0
                call static 'j_set_null' using by value response-node by reference z'result' end-call
            else call static 'j_set' using by value response-node by reference z'result' by value node-a end-call
            end-if
            perform ok-response
        end-if
      when 'storage.setRaw'
        call static 'j_get_into' using by value request-node by reference z'args.raw' node-a end-call
        call static 'h_storage_write' using by reference key-z by value node-a returning status-code end-call
        if status-code = 0 perform true-response else move 'Storage write failed.' to error-text end-if
      when 'storage.fail'
        move function J-NUM(request-node, 'args.read') to status-code
        move function J-NUM(request-node, 'args.write') to other-status
        call static 'h_storage_fault' using by value status-code other-status returning status-code end-call
        if status-code = 0 perform true-response else move 'Storage fault injection is native-only.' to error-text end-if
      when 'storage.remove'
        call static 'h_storage_remove' using by reference key-z returning status-code end-call
        if status-code = 0 perform true-response else move 'Storage removal failed.' to error-text end-if
      when other move 'Unknown storage operation.' to error-text
    end-evaluate.
ok-response.
    call static 'j_set_boolean' using by value response-node by reference z'ok' by value 1 end-call.
true-response.
    perform ok-response
    call static 'j_set_boolean' using by value response-node by reference z'result' by value 1 end-call.
fail-response.
    call static 'j_set_boolean' using by value response-node by reference z'ok' by value 0 end-call
    call static 'j_set_string' using by value response-node by reference z'error' error-text
        by value function length(function trim(error-text)) end-call.
end program BUFO-APP.
