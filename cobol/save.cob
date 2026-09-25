identification division.
program-id. BUFO-SAVE.
environment division.
configuration section.
repository. function J-NUM function J-STR function all intrinsic.
data division.
local-storage section.
01 candidate usage pointer.
01 source-state usage pointer.
01 uncredited-state usage pointer.
01 live-explorer usage pointer.
01 arithmetic-a usage comp-2.
01 arithmetic-b usage comp-2.
01 validation-mode usage binary-long.
01 compare-code usage binary-long.
01 supplied-mode usage binary-long.
01 result-node usage pointer.
01 raw-node usage pointer.
01 decoded-node usage pointer.
01 envelope usage pointer.
01 input-envelope usage pointer.
01 node-a usage pointer.
01 node-b usage pointer.
01 node-c usage pointer.
01 node-d usage pointer.
01 copied-node usage pointer.
01 child-request usage pointer.
01 child-response usage pointer.
01 source-generators usage pointer.
01 target-generators usage pointer.
01 source-generator usage pointer.
01 target-generator usage pointer.
01 event-node usage pointer.
01 event-array usage pointer.
01 operation-name pic x(80).
01 child-operation pic x(80).
01 flow-name pic x(40).
01 event-name pic x(80).
01 field-name pic x(128).
01 field-z pic x(129).
01 id-name pic x(128).
01 id-z pic x(129).
01 error-text pic x(1024).
01 now-value usage comp-2.
01 number-value usage comp-2.
01 minimum-value usage comp-2.
01 elapsed-value usage comp-2.
01 rate-value usage comp-2.
01 earned-value usage comp-2.
01 gained-value usage comp-2.
01 index-value usage binary-long.
01 count-value usage binary-long.
01 field-index usage binary-long.
01 type-code usage binary-long.
01 status-code usage binary-long.
01 strict-mode usage binary-long.
01 require-current usage binary-long.
01 keep-transients usage binary-long.
01 result-flag usage binary-long.
01 slices.
   02 filler pic x(16) value 'resources'.
   02 filler pic x(16) value 'upgrades'.
   02 filler pic x(16) value 'achievements'.
   02 filler pic x(16) value 'prestige'.
   02 filler pic x(16) value 'bosses'.
   02 filler pic x(16) value 'gameSettings'.
   02 filler pic x(16) value 'explorer'.
01 slice-table redefines slices.
   02 slice-name pic x(16) occurs 7.
01 generator-fields.
   02 filler pic x(16) value 'count'.
   02 filler pic x(16) value 'unlocked'.
   02 filler pic x(16) value 'enabled'.
   02 filler pic x(16) value 'boosts'.
01 generator-field-table redefines generator-fields.
   02 generator-field pic x(16) occurs 4.
01 runtime-fields.
   02 filler pic x(16) value 'game'.
   02 filler pic x(16) value 'golden'.
   02 filler pic x(16) value 'boss'.
   02 filler pic x(16) value 'achievement'.
   02 filler pic x(16) value 'explorer'.
01 runtime-field-table redefines runtime-fields.
   02 runtime-field pic x(16) occurs 5.
linkage section.
01 request-node usage pointer.
01 context-node usage pointer.
01 response-node usage pointer.
procedure division using by value request-node context-node response-node.
    move function J-STR(request-node, 'operation') to operation-name
    move operation-name to flow-name
    move function J-NUM(context-node, 'runtime.now') to now-value
    move 60000 to minimum-value
    if operation-name = 'save' or 'saveSupplied' or 'prestige' or 'resume' move 1 to strict-mode end-if
    evaluate operation-name
      when 'saveSupplied'
        move 1 to supplied-mode strict-mode
        call static 'j_get_into' using by value request-node
            by reference z'args.state' source-state end-call
        perform validate-source
        if error-text = spaces perform prepare-source end-if
        if error-text = spaces perform write-candidate end-if
        if error-text = spaces move 1 to result-flag end-if
      when 'importSupplied'
        move 1 to supplied-mode
        call static 'j_get_into' using by value request-node
            by reference z'args.raw' raw-node end-call
        call static 'j_clone_into' using by value raw-node by reference raw-node end-call
        perform parse-envelope
        if error-text = spaces perform prepare-source end-if
        if error-text = spaces perform write-candidate end-if
        if error-text = spaces move 1 to result-flag end-if
      when 'readSaved' when 'exportSaved'
        move 1 to supplied-mode require-current
        call static 'h_storage_read' using by reference z'bufo_idle_save_cobol_v1'
            raw-node status-code end-call
        if status-code = 0
            move 0 to require-current
            call static 'h_storage_read' using by reference z'bufo_idle_save'
                raw-node status-code end-call end-if
        if status-code = 1
            perform parse-envelope
            if error-text = spaces
                if operation-name = 'readSaved'
                    perform prepare-source
                    if error-text = spaces perform return-saved end-if
                else
                    call static 'h_json_stringify_value' using by value input-envelope by reference decoded-node end-call
                    call static 'h_encode_uri64' using by value decoded-node
                        by reference copied-node returning status-code end-call
                    if status-code = 0
                        call static 'j_set' using by value response-node
                            by reference z'result' by value copied-node end-call
                    else move 'Stored save could not be encoded.' to error-text end-if
                end-if
            end-if
        end-if
        call static 'j_has' using by value response-node by reference z'result' returning status-code end-call
        if status-code = 0
            if operation-name = 'readSaved'
                call static 'j_set_null' using by value response-node by reference z'result' end-call
            else call static 'j_set_string' using by value response-node
                by reference z'result' z' ' by value 0 end-call end-if end-if
      when 'clearSaved'
        move 1 to supplied-mode
        call static 'h_storage_remove' using by reference z'bufo_idle_save' returning status-code end-call
        if status-code = 0
            call static 'h_storage_remove' using by reference z'bufo_idle_save_cobol_v1' returning status-code end-call
        end-if
        if status-code = 0 move 1 to result-flag end-if
      when 'load' perform load-operation
      when 'import'
        call static 'j_get_into' using by value request-node
            by reference z'args.raw' raw-node end-call
        call static 'j_clone_into' using by value raw-node by reference raw-node end-call
        perform parse-envelope
        if error-text = spaces perform activate-source end-if
      when 'reset'
        perform new-candidate
        perform write-candidate
        if error-text = spaces perform accept-candidate end-if
      when 'resume'
        call static 'j_boolean' using by value context-node
            by reference z'runtime.persistence.blocked' returning status-code end-call
        if status-code = 1
            move 'Save recovery must succeed before elapsed production can resume.' to error-text
        else
        move 1 to keep-transients
        move 0 to minimum-value
        call static 'j_has' using by value context-node
            by reference z'runtime.persistence.source' returning status-code end-call
        if status-code = 1
            move 'A storage retry is pending.' to error-text
        else
            call static 'j_get_into' using by value context-node
                by reference z'state' source-state end-call
            perform activate-source
        end-if end-if
      when 'retry'
        call static 'j_get_into' using by value context-node
            by reference z'runtime.persistence.source' source-state end-call
        if source-state = null
            call static 'j_boolean' using by value context-node
                by reference z'runtime.persistence.blocked' returning status-code end-call
            if status-code = 1
                call static 'j_boolean' using by value context-node
                    by reference z'runtime.persistence.retryLoad' returning status-code end-call
                if status-code = 1
                    move 'load' to flow-name perform load-operation
                else move 'Import a valid save or reset to recover this save.' to error-text end-if
            else move 1 to result-flag end-if
        else
            move function J-STR(context-node, 'runtime.persistence.flow') to flow-name
            if flow-name = 'resume'
                move 1 to keep-transients
                move 0 to minimum-value
            end-if
            perform activate-source
        end-if
      when 'save'
        call static 'j_boolean' using by value context-node
            by reference z'runtime.persistence.blocked' returning status-code end-call
        if status-code = 1
            move 'Save recovery is required before saving.' to error-text
        else
            call static 'j_get_into' using by value context-node
                by reference z'state' source-state end-call
            perform prepare-source
            if error-text = spaces perform write-candidate end-if
            if error-text = spaces
                call static 'j_set_number' using by value context-node
                    by reference z'state.gameSettings.lastSaved' now-value end-call
                move 1 to result-flag
                move 'GAME_SAVED' to event-name
                perform emit-event
            end-if
        end-if
      when 'export'
        call static 'j_get_into' using by value context-node
            by reference z'state' source-state end-call
        perform prepare-source
        if error-text = spaces
            perform create-envelope
            call static 'h_json_stringify_value' using by value envelope
                by reference decoded-node end-call
            call static 'h_encode_uri64' using by value decoded-node
                by reference copied-node returning status-code end-call
            if status-code = 0
                call static 'j_set' using by value response-node
                    by reference z'result' by value copied-node end-call
                move 1 to result-flag
            else move 'Save export could not be encoded.' to error-text end-if
        end-if
      when 'prestige'
        call static 'j_boolean' using by value context-node
            by reference z'runtime.persistence.blocked' returning status-code end-call
        if status-code = 1 move 'Save recovery is required before prestige.' to error-text end-if
        call static 'j_get_into' using by value context-node
            by reference z'state' source-state end-call
        perform prepare-source
        if error-text = spaces
            move 'prestige.transcend' to child-operation
            perform request-for-child
            perform run-game
            move function J-NUM(child-response, 'result') to gained-value
            if gained-value > 0
                perform write-candidate
                if error-text = spaces perform accept-candidate end-if
            end-if
            call static 'j_set_number' using by value response-node
                by reference z'result' gained-value end-call
        end-if
      when other move 'Unknown save operation' to error-text
    end-evaluate
    if supplied-mode = 0
        if error-text = spaces and operation-name = 'import'
            move 'saveImported' to event-name perform emit-event
        end-if
        if error-text not = spaces
            evaluate operation-name
              when 'save' move 'saveError' to event-name perform emit-event
              when 'import' move 'importError' to event-name perform emit-event
              when 'export' move 'exportError' to event-name perform emit-event
            end-evaluate
        end-if
    end-if
    if supplied-mode = 1 move spaces to error-text end-if
    if error-text = spaces
        call static 'j_set_boolean' using by value response-node
            by reference z'ok' by value 1 end-call
        call static 'j_has' using by value response-node
            by reference z'result' returning status-code end-call
        if status-code = 0
            call static 'j_set_boolean' using by value response-node
                by reference z'result' by value result-flag end-call
        end-if
    else
        call static 'j_set_boolean' using by value response-node
            by reference z'ok' by value 0 end-call
        call static 'j_set_string' using by value response-node
            by reference z'error' error-text
            by value function length(function trim(error-text)) end-call
    end-if
    call static 'j_delete' using by value uncredited-state end-call
    call static 'j_delete' using by value live-explorer end-call
    call static 'j_delete' using by value candidate end-call
    call static 'j_delete' using by value raw-node end-call
    call static 'j_delete' using by value decoded-node end-call
    call static 'j_delete' using by value envelope end-call
    call static 'j_delete' using by value input-envelope end-call
    call static 'j_delete' using by value child-request end-call
    call static 'j_delete' using by value child-response end-call
    goback.
load-operation.
        move 1 to require-current
        call static 'h_storage_read' using by reference z'bufo_idle_save_cobol_v1'
            raw-node status-code end-call
        if status-code = 0
            move 0 to require-current
            call static 'h_storage_read' using by reference z'bufo_idle_save'
                raw-node status-code end-call
        end-if
        evaluate status-code
          when -1 move 'Storage could not be read. Retry when storage is available.' to error-text
          when 0
            perform new-candidate
            call static 'j_get_into' using by value candidate
                by reference z'state' source-state end-call
            perform write-candidate
            if error-text = spaces perform accept-candidate end-if
          when other
            perform parse-envelope
            if error-text = spaces perform activate-source end-if
        end-evaluate
        if error-text not = spaces perform block-save end-if.
parse-envelope.
    call static 'h_json_parse_value' using by value raw-node
        by reference input-envelope returning status-code end-call
    if status-code not = 0 and require-current = 0
        call static 'h_decode_uri64' using by value raw-node
            by reference decoded-node returning status-code end-call
        if status-code = 0
            call static 'h_json_parse_value' using by value decoded-node
                by reference input-envelope returning status-code end-call
        end-if
    end-if
    if input-envelope = null
        move 'The save is not valid JSON or an encoded save.' to error-text
    else
        move 0 to strict-mode
        call static 'j_has' using by value input-envelope
            by reference z'format' returning status-code end-call
        if status-code = 1 or require-current = 1
            move 1 to strict-mode
            move function J-NUM(input-envelope, 'schemaVersion') to arithmetic-a
            move 1 to arithmetic-b
            call static 'h_number_compare' using arithmetic-a arithmetic-b returning compare-code end-call
            if function J-STR(input-envelope, 'format') not = 'bufo-clicker-cobol'
                or compare-code not = 0
                move 'Unsupported COBOL save format or schema.' to error-text
            end-if
        else
            if function J-STR(input-envelope, 'version') not = '1.0.0'
                move 'Unsupported legacy save version.' to error-text
            end-if
        end-if
        call static 'j_get_into' using by value input-envelope
            by reference z'state' source-state end-call
        call static 'j_type' using by value source-state
            by reference x'00' returning type-code end-call
        if type-code not = 5 move 'Save state must be an object.' to error-text end-if
        if error-text = spaces
            perform validate-source
        end-if
    end-if.
new-candidate.
    call static 'j_delete' using by value candidate end-call
    call static 'j_parse_into' using
        by reference '{"state":{},"runtime":{},"events":[]}'
        by value 37 by reference candidate end-call
    call static 'j_get_into' using by value context-node
        by reference z'catalog' node-a end-call
    call static 'j_clone_into' using by value node-a by reference copied-node end-call
    call static 'j_set' using by value candidate
        by reference z'catalog' by value copied-node end-call
    call static 'j_set_number' using by value candidate
        by reference z'runtime.now' now-value end-call
    call static 'j_get_into' using by value context-node
        by reference z'runtime.upgrades' node-a end-call
    if node-a not = null
        call static 'j_clone_into' using by value node-a by reference copied-node end-call
        call static 'j_set' using by value candidate
            by reference z'runtime.upgrades' by value copied-node end-call end-if
    move 'init' to child-operation
    perform request-for-child
    perform run-game
    call static 'BUFO-EXPLORER' using by value child-request candidate child-response end-call
    call static 'j_set_number' using by value candidate
        by reference z'state.gameSettings.lastTick' now-value end-call
    call static 'j_set_number' using by value candidate
        by reference z'state.gameSettings.lastSaved' now-value end-call
    call static 'j_set_number' using by value candidate
        by reference z'state.gameSettings.firstStartTime' now-value end-call
    call static 'j_set_boolean' using by value candidate
        by reference z'state.gameSettings.autoSave' by value 1 end-call
    call static 'j_set_string' using by value candidate
        by reference z'state.gameSettings.version' '1.0.0' by value 5 end-call.
prepare-source.
    if error-text = spaces perform validate-source end-if
    if error-text not = spaces exit paragraph end-if
    if keep-transients = 1
        call static 'j_delete' using by value live-explorer end-call
        call static 'j_get_into' using by value context-node
            by reference z'state.explorer' node-a end-call
        call static 'j_clone_into' using by value node-a by reference live-explorer end-call
    end-if
    perform new-candidate
    if source-state = null move 'Missing source state.' to error-text end-if
    perform varying index-value from 1 by 1 until index-value > 7
        move slice-name(index-value) to field-name
        perform field-path
        call static 'j_get_into' using by value source-state
            by reference field-z node-a end-call
        if node-a not = null
            call static 'j_get_into' using by value candidate
                by reference z'state' node-b end-call
            call static 'j_get_into' using by value node-b
                by reference field-z node-c end-call
            call static 'j_merge' using by value node-c node-a returning status-code end-call
            if status-code not = 0 move 'Invalid saved state section.' to error-text end-if
        else
            if index-value = 1 or 2 or 6 or 7
                move 'Missing required saved state section.' to error-text
            end-if
        end-if
    end-perform
    call static 'j_get_into' using by value source-state
        by reference z'generators' source-generators end-call
    call static 'j_type' using by value source-generators
        by reference x'00' returning type-code end-call
    if type-code not = 5 move 'Invalid saved generators.' to error-text end-if
    call static 'j_get_into' using by value candidate
        by reference z'state.generators' target-generators end-call
    call static 'j_size' using by value source-generators
        by reference x'00' returning count-value end-call
    perform varying index-value from 0 by 1 until index-value >= count-value
        call static 'j_at_into' using by value source-generators index-value
            by reference source-generator end-call
        call static 'j_key' using by value source-generator
            by reference id-name by value 128 end-call
        move low-values to id-z
        string function trim(id-name) x'00' into id-z end-string
        call static 'j_get_into' using by value target-generators
            by reference id-z target-generator end-call
        if target-generator = null
            move 'Unknown saved generator.' to error-text
        else
            perform varying field-index from 1 by 1 until field-index > 4
                move generator-field(field-index) to field-name
                perform field-path
                call static 'j_get_into' using by value source-generator
                    by reference field-z node-a end-call
                if node-a not = null
                    call static 'j_clone_into' using by value node-a by reference copied-node end-call
                    call static 'j_set' using by value target-generator
                        by reference field-z by value copied-node end-call
                end-if
            end-perform
        end-if
    end-perform
    if error-text = spaces
        move 'normalize' to child-operation
        perform request-for-child
        call static 'j_get_into' using by value candidate
            by reference z'state.explorer' node-a end-call
        call static 'j_clone_into' using by value node-a by reference copied-node end-call
        call static 'j_set' using by value child-request
            by reference z'args.explorer' by value copied-node end-call
        call static 'j_set_boolean' using by value child-request
            by reference z'args.strict' by value strict-mode end-call
        call static 'BUFO-EXPLORER' using by value child-request candidate child-response end-call
        perform child-error
        if error-text = spaces
            call static 'j_get_into' using by value child-response
                by reference z'result' node-a end-call
            call static 'j_clone_into' using by value node-a by reference copied-node end-call
            call static 'j_set' using by value candidate
                by reference z'state.explorer' by value copied-node end-call
            move 'rebuild' to child-operation
            perform request-for-child
            perform run-game
        end-if
    end-if
    if error-text = spaces
        call static 'j_get_into' using by value candidate
            by reference z'state' node-d end-call
        move 1 to validation-mode perform validate-node
    end-if.
activate-source.
    perform prepare-source
    if error-text = spaces
        call static 'j_get_into' using by value candidate
            by reference z'state' node-a end-call
        call static 'j_clone_into' using by value node-a by reference uncredited-state end-call
        move function J-NUM(source-state, 'gameSettings.lastTick') to arithmetic-a
        call static 'h_number_binary' using by value 2
            by reference now-value arithmetic-a elapsed-value end-call
        call static 'h_number_compare' using elapsed-value minimum-value
            returning compare-code end-call
        if compare-code >= 0 and elapsed-value > 0
            move 0 to rate-value
            call static 'j_get_into' using by value candidate
                by reference z'state.generators' node-a end-call
            call static 'j_size' using by value node-a
                by reference x'00' returning count-value end-call
            perform varying index-value from 0 by 1 until index-value >= count-value
                call static 'j_at_into' using by value node-a index-value by reference node-b end-call
                move function J-NUM(node-b, 'totalProduction') to arithmetic-a
                call static 'h_number_binary' using by value 1
                    by reference rate-value arithmetic-a rate-value end-call
            end-perform
            compute arithmetic-a = function min(elapsed-value, 43200000)
            move 1000 to arithmetic-b
            call static 'h_number_binary' using by value 4
                by reference arithmetic-a arithmetic-b arithmetic-a end-call
            call static 'h_number_binary' using by value 3
                by reference rate-value arithmetic-a earned-value end-call
            move function J-NUM(candidate, 'state.resources.bufos') to arithmetic-a
            call static 'h_number_binary' using by value 1
                by reference arithmetic-a earned-value number-value end-call
            call static 'j_set_number' using by value candidate
                by reference z'state.resources.bufos' number-value returning status-code end-call
            if status-code not = 0 move 'Elapsed production exceeds the supported range.' to error-text end-if
            move function J-NUM(candidate, 'state.resources.totalBufos') to arithmetic-a
            call static 'h_number_binary' using by value 1
                by reference arithmetic-a earned-value number-value end-call
            call static 'j_set_number' using by value candidate
                by reference z'state.resources.totalBufos' number-value returning status-code end-call
            if status-code not = 0 move 'Elapsed production exceeds the supported range.' to error-text end-if
            call static 'j_set_number' using by value response-node
                by reference z'offline.cappedProduction' earned-value end-call
            compute number-value = elapsed-value / 1000
            call static 'j_set_number' using by value response-node
                by reference z'offline.timeAway' number-value end-call
            call static 'h_number_binary' using by value 3
                by reference rate-value number-value arithmetic-a end-call
            call static 'j_set_number' using by value response-node
                by reference z'offline.production' arithmetic-a end-call
            move 43200000 to arithmetic-b
            call static 'h_number_compare' using elapsed-value arithmetic-b returning compare-code end-call
            move 0 to status-code if compare-code > 0 move 1 to status-code end-if
            call static 'j_set_boolean' using by value response-node
                by reference z'offline.isCapped' by value status-code end-call
        end-if
        call static 'j_set_number' using by value candidate
            by reference z'state.gameSettings.lastTick' now-value end-call
        perform write-candidate
        if error-text = spaces
            perform accept-candidate
            call static 'j_has' using by value response-node by reference z'offline' returning status-code end-call
            if status-code = 1 move 'offlineProgress' to event-name perform emit-event end-if
        else
            if flow-name = 'load' or flow-name = 'resume'
                call static 'j_clone_into' using by value uncredited-state by reference copied-node end-call
                call static 'j_set' using by value context-node
                    by reference z'runtime.persistence.source' by value copied-node end-call
                call static 'j_set_string' using by value context-node
                    by reference z'runtime.persistence.flow' flow-name
                    by value function length(function trim(flow-name)) end-call
                if flow-name = 'load'
                    call static 'j_clone_into' using by value uncredited-state by reference copied-node end-call
                    call static 'j_set' using by value context-node
                        by reference z'state' by value copied-node end-call
                end-if
                perform block-save
            end-if
        end-if
    end-if.
validate-source.
    set node-d to source-state
    move strict-mode to validation-mode
    perform validate-node.
validate-node.
    move 'validate' to child-operation
    perform request-for-child
    call static 'j_clone_into' using by value node-d by reference copied-node end-call
    call static 'j_set' using by value child-request
        by reference z'args.state' by value copied-node end-call
    call static 'j_set_boolean' using by value child-request
        by reference z'args.strict' by value validation-mode end-call
    call static 'BUFO-VALIDATE-SAVE' using by value child-request context-node child-response end-call
    perform child-error.
create-envelope.
    call static 'j_delete' using by value envelope end-call
    call static 'j_object_into' using by reference envelope end-call
    call static 'j_set_string' using by value envelope
        by reference z'format' 'bufo-clicker-cobol' by value 18 end-call
    move 1 to number-value
    call static 'j_set_number' using by value envelope
        by reference z'schemaVersion' number-value end-call
    call static 'j_set_number' using by value envelope
        by reference z'timestamp' now-value end-call
    call static 'j_get_into' using by value candidate
        by reference z'state' node-a end-call
    call static 'j_clone_into' using by value node-a by reference copied-node end-call
    call static 'j_set' using by value envelope
        by reference z'state' by value copied-node end-call
    perform varying field-index from 1 by 1 until field-index > 3
        evaluate field-index
          when 1 move 'generators' to field-name
          when 2 move 'upgrades' to field-name
          when 3 move 'explorer' to field-name
        end-evaluate
        perform field-path
        if operation-name = 'saveSupplied'
            if field-index = 2
                call static 'j_get_into' using by value request-node
                    by reference z'args.purchasedUpgrades' node-a end-call
            else
                call static 'j_get_into' using by value request-node
                    by reference z'args' node-b end-call
                call static 'j_get_into' using by value node-b by reference field-z node-a end-call end-if
        else
            call static 'j_get_into' using by value input-envelope by reference field-z node-a end-call
        end-if
        if node-a = null
            if field-index = 2
                call static 'j_get_into' using by value candidate
                    by reference z'state.upgrades.purchased' node-a end-call
            else
                call static 'j_get_into' using by value candidate by reference z'state' node-b end-call
                call static 'j_get_into' using by value node-b by reference field-z node-a end-call end-if
        end-if
        call static 'j_clone_into' using by value node-a by reference copied-node end-call
        call static 'j_set' using by value envelope by reference field-z by value copied-node end-call
    end-perform.
return-saved.
    call static 'j_object_into' using by reference result-node end-call
    call static 'j_get_into' using by value candidate by reference z'state' node-a end-call
    call static 'j_clone_into' using by value node-a by reference copied-node end-call
    call static 'j_set' using by value result-node by reference z'state' by value copied-node end-call
    call static 'j_get_into' using by value input-envelope by reference z'upgrades' node-a end-call
    if node-a = null call static 'j_array_into' using by reference copied-node end-call
    else call static 'j_clone_into' using by value node-a by reference copied-node end-call end-if
    call static 'j_set' using by value result-node by reference z'upgrades' by value copied-node end-call
    call static 'j_get_into' using by value input-envelope by reference z'explorer' node-a end-call
    if node-a = null call static 'j_object_into' using by reference copied-node end-call
    else call static 'j_clone_into' using by value node-a by reference copied-node end-call end-if
    call static 'j_set' using by value result-node by reference z'explorer' by value copied-node end-call
    call static 'j_set' using by value response-node by reference z'result' by value result-node end-call.
write-candidate.
    call static 'j_boolean' using by value candidate
        by reference z'runtime.game.numericInvalid' returning status-code end-call
    if status-code = 1 move 'Candidate arithmetic exceeded the supported range.' to error-text end-if
    if error-text = spaces
        call static 'j_get_into' using by value candidate
            by reference z'state' node-d end-call
        move 1 to validation-mode perform validate-node
    end-if
    if error-text = spaces
        call static 'j_set_number' using by value candidate
            by reference z'state.gameSettings.lastSaved' now-value end-call
        perform create-envelope
        call static 'h_storage_write_json' using by reference z'bufo_idle_save_cobol_v1'
            by value envelope returning status-code end-call
        if status-code not = 0
            move 'Save could not be written. Progress has not been replaced.' to error-text
        end-if
    end-if.
accept-candidate.
    call static 'j_get_into' using by value candidate
        by reference z'state' node-a end-call
    call static 'j_clone_into' using by value node-a by reference copied-node end-call
    if keep-transients = 1 and live-explorer not = null
        call static 'j_clone_into' using by value live-explorer by reference node-b end-call
        call static 'j_set' using by value copied-node
            by reference z'explorer' by value node-b end-call end-if
    call static 'j_set' using by value context-node
        by reference z'state' by value copied-node end-call
    if keep-transients = 0
        perform varying index-value from 1 by 1 until index-value > 5
            move function concatenate('runtime.',function trim(runtime-field(index-value))) to field-name
            perform field-path
            call static 'j_get_into' using by value candidate by reference field-z node-a end-call
            if node-a not = null
                call static 'j_clone_into' using by value node-a by reference copied-node end-call
                call static 'j_set' using by value context-node
                    by reference field-z by value copied-node end-call
            end-if
        end-perform
    end-if
    call static 'j_remove' using by value context-node by reference z'runtime.persistence.retryLoad' end-call
    call static 'j_remove' using by value context-node by reference z'runtime.persistence.source' end-call
    call static 'j_remove' using by value context-node by reference z'runtime.persistence.flow' end-call
    call static 'j_remove' using by value context-node by reference z'runtime.persistence.error' end-call
    call static 'j_set_boolean' using by value context-node
        by reference z'runtime.persistence.blocked' by value 0 end-call
    move 1 to result-flag
    if flow-name = 'prestige'
        call static 'j_get_into' using by value candidate by reference z'events' event-array end-call
        call static 'j_size' using by value event-array by reference x'00' returning count-value end-call
        call static 'j_get_into' using by value context-node by reference z'events' node-b end-call
        perform varying index-value from 0 by 1 until index-value >= count-value
            call static 'j_at_into' using by value event-array index-value by reference node-a end-call
            call static 'j_clone_into' using by value node-a by reference copied-node end-call
            call static 'j_append' using by value node-b copied-node end-call
        end-perform
    end-if
    if flow-name = 'reset' move 'GAME_RESET' to event-name
    else move 'GAME_LOADED' to event-name end-if
    perform emit-event.
block-save.
    if flow-name = 'load'
        call static 'j_set_boolean' using by value context-node
            by reference z'runtime.persistence.retryLoad' by value 1 end-call end-if
    call static 'j_set_boolean' using by value context-node
        by reference z'runtime.persistence.blocked' by value 1 end-call
    call static 'j_set_string' using by value context-node
        by reference z'runtime.persistence.error' error-text
        by value function length(function trim(error-text)) end-call.
request-for-child.
    call static 'j_delete' using by value child-request end-call
    call static 'j_delete' using by value child-response end-call
    call static 'j_object_into' using by reference child-request end-call
    call static 'j_object_into' using by reference child-response end-call
    call static 'j_set_string' using by value child-request
        by reference z'operation' child-operation
        by value function length(function trim(child-operation)) end-call
    call static 'j_set_number' using by value child-request
        by reference z'now' now-value end-call.
run-game.
    call static 'BUFO-GAME' using by value child-request candidate child-response end-call
    perform child-error.
child-error.
    call static 'j_boolean' using by value child-response
        by reference z'ok' returning status-code end-call
    if status-code = 0
        move function J-STR(child-response, 'error') to error-text
        if error-text = spaces move 'Could not prepare save candidate.' to error-text end-if
    end-if.
field-path.
    move low-values to field-z
    string function trim(field-name) x'00' into field-z end-string.
emit-event.
    call static 'j_object_into' using by reference event-node end-call
    call static 'j_set_string' using by value event-node
        by reference z'name' event-name
        by value function length(function trim(event-name)) end-call
    evaluate event-name
      when 'GAME_SAVED'
        call static 'j_set_number' using by value event-node
            by reference z'payload.timestamp' now-value end-call
        call static 'j_boolean' using by value request-node by reference z'args.auto' returning status-code end-call
        call static 'j_set_boolean' using by value event-node by reference z'payload.auto' by value status-code end-call
      when 'saveImported' continue
      when 'saveError'
        call static 'j_set_string' using by value event-node by reference z'payload.message'
            z'Failed to save game' by value 19 end-call
      when 'importError'
        call static 'j_set_string' using by value event-node by reference z'payload.message'
            z'Invalid save data' by value 17 end-call
      when 'exportError'
        call static 'j_set_string' using by value event-node by reference z'payload.message'
            z'Error exporting save' by value 20 end-call
        call static 'j_set_string' using by value event-node by reference z'payload.error'
            error-text by value function length(function trim(error-text)) end-call
      when 'offlineProgress'
        call static 'j_get_into' using by value response-node by reference z'offline' node-a end-call
        call static 'j_clone_into' using by value node-a by reference copied-node end-call
        call static 'j_set' using by value event-node by reference z'payload' by value copied-node end-call
      when other
        call static 'j_get_into' using by value context-node by reference z'state' node-a end-call
        call static 'j_clone_into' using by value node-a by reference copied-node end-call
        call static 'j_set' using by value event-node by reference z'payload.state' by value copied-node end-call
    end-evaluate
    call static 'j_get_into' using by value context-node
        by reference z'events' event-array end-call
    call static 'j_append' using by value event-array event-node end-call.
end program BUFO-SAVE.
