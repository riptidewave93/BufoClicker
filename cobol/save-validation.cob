identification division.
program-id. BUFO-VALIDATE-SAVE.
environment division.
configuration section.
repository. function J-NUM function J-STR function all intrinsic.
data division.
local-storage section.
01 state-node usage pointer.
01 record-node usage pointer.
01 generators-node usage pointer.
01 generator-node usage pointer.
01 definition-node usage pointer.
01 array-node usage pointer.
01 item-node usage pointer.
01 known-node usage pointer.
01 known-item usage pointer.
01 seen-node usage pointer.
01 child-request usage pointer.
01 child-response usage pointer.
01 field-name pic x(256).
01 field-z pic x(257).
01 identifier pic x(1000).
01 identifier-z pic x(1001).
01 error-text pic x(1024).
01 field-value usage comp-2.
01 count-value usage comp-2.
01 compare-a usage comp-2.
01 compare-b usage comp-2.
01 compare-code usage binary-long.
01 map-node usage pointer.
01 map-item usage pointer.
01 map-count usage binary-long.
01 map-index usage binary-long.
01 key-index usage binary-long.
01 map-key pic x(1000).
01 boost-seen usage pointer.
01 limit-value usage comp-2.
01 strict-mode usage binary-long.
01 integer-mode usage binary-long.
01 required-mode usage binary-long.
01 type-code usage binary-long.
01 present-flag usage binary-long.
01 item-count usage binary-long.
01 item-index usage binary-long.
01 generator-count usage binary-long.
01 generator-index usage binary-long.
01 known-count usage binary-long.
01 known-index usage binary-long.
01 matched usage binary-long.
01 status-code usage binary-long.
linkage section.
01 request-node usage pointer.
01 context-node usage pointer.
01 response-node usage pointer.
procedure division using by value request-node context-node response-node.
    call static 'j_get_into' using by value request-node
        by reference z'args.state' state-node end-call
    call static 'j_boolean' using by value request-node
        by reference z'args.strict' returning strict-mode end-call
    set record-node to state-node
    move 1 to required-mode
    move 'resources' to field-name
    perform object-field
    move 'generators' to field-name
    perform object-field
    move 'upgrades' to field-name
    perform object-field
    move 'gameSettings' to field-name
    perform object-field
    move 'explorer' to field-name
    perform object-field
    move strict-mode to required-mode
    move 'achievements' to field-name
    perform object-field
    move 'prestige' to field-name
    perform object-field
    move 'bosses' to field-name
    perform object-field
    move 'achievements.progress' to field-name
    perform object-field
    move 'achievements.customEvents' to field-name
    perform object-field
    move 1 to required-mode
    move 0 to integer-mode
    move 'resources.bufos' to field-name
    perform number-field
    move 'resources.totalBufos' to field-name
    perform number-field
    move function J-NUM(state-node, 'resources.bufos') to compare-a
    move function J-NUM(state-node, 'resources.totalBufos') to compare-b
    call static 'h_number_compare' using compare-a compare-b returning compare-code end-call
    if compare-code > 0
        move 'Current currency exceeds run earnings' to error-text
    end-if
    move strict-mode to required-mode
    move 'resources.baseClickPower' to field-name
    perform number-field
    if type-code = 2 and (field-value <= 0 or field-value > 1.0E+200)
        move 'Invalid base click power' to error-text
    end-if
    move 1 to integer-mode
    move 'resources.clickCount' to field-name
    perform number-field
    move 'achievements.clickCount' to field-name
    perform number-field
    move 'prestige.points' to field-name
    perform number-field
    move 'prestige.lifetimePoints' to field-name
    perform number-field
    move 'prestige.transcendences' to field-name
    perform number-field
    move 'bosses.lifetimeDefeats' to field-name
    perform number-field
    move 1 to required-mode
    move 'gameSettings.lastTick' to field-name
    perform number-field
    move 'gameSettings.lastSaved' to field-name
    perform number-field
    move 0 to required-mode
    move 'gameSettings.firstStartTime' to field-name
    perform number-field
    move function J-NUM(state-node, 'resources.clickCount') to compare-a
    move function J-NUM(state-node, 'achievements.clickCount') to compare-b
    call static 'h_number_compare' using compare-a compare-b returning compare-code end-call
    if strict-mode = 1 and compare-code not = 0
        move 'Inconsistent click counters' to error-text
    end-if
    move function J-NUM(state-node, 'prestige.points') to compare-a
    move function J-NUM(state-node, 'prestige.lifetimePoints') to compare-b
    call static 'h_number_compare' using compare-a compare-b returning compare-code end-call
    if compare-code > 0
        move 'Prestige points exceed lifetime points' to error-text
    end-if
    move strict-mode to required-mode
    move 'gameSettings.autoSave' to field-name
    perform boolean-field
    call static 'j_type' using by value state-node
        by reference z'gameSettings.version' returning type-code end-call
    if type-code not = 3 or function J-STR(state-node, 'gameSettings.version')
        not = '1.0.0'
        move 'Unsupported game version' to error-text
    end-if
    call static 'j_get_into' using by value state-node
        by reference z'generators' generators-node end-call
    call static 'j_size' using by value generators-node
        by reference x'00' returning generator-count end-call
    call static 'j_size' using by value context-node
        by reference z'catalog.generators' returning known-count end-call
    if strict-mode = 1 and generator-count not = known-count
        move 'Missing generator records' to error-text
    end-if
    perform varying generator-index from 0 by 1
        until generator-index >= generator-count
        call static 'j_at_into' using by value generators-node generator-index
            by reference generator-node end-call
        call static 'j_key' using by value generator-node
            by reference identifier by value 1000 end-call
        move low-values to identifier-z
        string function trim(identifier) x'00' into identifier-z end-string
        call static 'j_get_into' using by value context-node
            by reference z'catalog.generators' known-node end-call
        call static 'j_get_into' using by value known-node
            by reference identifier-z definition-node end-call
        if definition-node = null
            move 'Unknown saved generator' to error-text
        else
            set record-node to generator-node
            move 1 to required-mode integer-mode
            move 'count' to field-name
            perform number-field
            move field-value to count-value
            if type-code = 2
                compute limit-value = function log(function J-NUM(definition-node,
                    'baseCost')) + count-value * function log(
                    function J-NUM(definition-node, 'costMultiplier'))
                if limit-value > function log(1.0E+300)
                    move 'Generator count exceeds finite cost range' to error-text
                end-if
            end-if
            move strict-mode to required-mode
            move 'unlocked' to field-name
            perform boolean-field
            move 'enabled' to field-name
            perform boolean-field
            call static 'j_get_into' using by value generator-node
                by reference z'boosts' array-node end-call
            if array-node not = null
                call static 'j_type' using by value array-node
                    by reference x'00' returning type-code end-call
                if type-code not = 4
                    move 'Invalid generator boosts' to error-text
                else
                    call static 'j_size' using by value array-node
                        by reference x'00' returning item-count end-call
                    if item-count > 10000
                        move 'Too many generator boosts' to error-text
                    else
                        call static 'j_object_into' using by reference boost-seen end-call
                        perform varying item-index from 0 by 1 until item-index >= item-count
                            call static 'j_at_into' using by value array-node item-index
                                by reference record-node end-call
                            move 1 to required-mode
                            move 0 to integer-mode
                            move 'multiplier' to field-name
                            perform number-field
                            if field-value <= 0
                                move 'Invalid boost multiplier' to error-text
                            end-if
                            move 'active' to field-name
                            perform boolean-field
                            move 'id' to field-name
                            perform text-field
                            move function J-STR(record-node, 'id') to identifier
                            move function concatenate(function trim(identifier),x'00') to identifier-z
                            call static 'j_has' using by value boost-seen by reference identifier-z returning status-code end-call
                            if status-code = 1 move 'Duplicate generator boost identifier' to error-text end-if
                            call static 'j_set_boolean' using by value boost-seen by reference identifier-z by value 1 end-call
                            move 'source' to field-name
                            perform text-field
                        end-perform
                        call static 'j_delete' using by value boost-seen end-call
                    end-if
                end-if
            end-if
        end-if
    end-perform
    set record-node to state-node
    perform achievement-maps
    call static 'j_get_into' using by value context-node
        by reference z'catalog.upgrades' known-node end-call
    call static 'j_get_into' using by value context-node
        by reference z'runtime.upgrades' definition-node end-call
    if definition-node not = null set known-node to definition-node end-if
    move 'upgrades.purchased' to field-name
    move 1 to required-mode
    perform id-list
    call static 'j_get_into' using by value context-node
        by reference z'catalog.achievements' known-node end-call
    move 'achievements.unlocked' to field-name
    move strict-mode to required-mode
    perform id-list
    call static 'j_get_into' using by value context-node
        by reference z'catalog.bosses' known-node end-call
    move 'bosses.defeated' to field-name
    perform id-list
    call static 'j_get_into' using by value state-node
        by reference z'bosses.defeated' array-node end-call
    call static 'j_size' using by value array-node
        by reference x'00' returning item-count end-call
    perform varying item-index from 0 by 1 until item-index >= item-count
        call static 'j_at_into' using by value array-node item-index
            by reference item-node end-call
        call static 'j_at_into' using by value known-node item-index
            by reference known-item end-call
        if function J-STR(item-node, '') not = function J-STR(known-item, 'id')
            move 'Defeated bosses do not follow ladder order' to error-text
        end-if
    end-perform
    call static 'j_object_into' using by reference child-request end-call
    call static 'j_object_into' using by reference child-response end-call
    call static 'j_set_string' using by value child-request
        by reference z'operation' 'validate' by value 8 end-call
    call static 'j_get_into' using by value state-node
        by reference z'explorer' item-node end-call
    call static 'j_clone_into' using by value item-node by reference item-node end-call
    call static 'j_set' using by value child-request
        by reference z'args.explorer' by value item-node end-call
    call static 'BUFO-EXPLORER' using by value child-request context-node child-response end-call
    call static 'j_boolean' using by value child-response
        by reference z'ok' returning status-code end-call
    if status-code = 0
        move 'Invalid Explorer data' to error-text
    else
        call static 'j_boolean' using by value child-response
            by reference z'result' returning status-code end-call
        if status-code = 0 move 'Invalid Explorer data' to error-text end-if
    end-if
    call static 'j_delete' using by value child-request end-call
    call static 'j_delete' using by value child-response end-call
    if error-text = spaces
        call static 'j_set_boolean' using by value response-node
            by reference z'ok' by value 1 end-call
        call static 'j_set_boolean' using by value response-node
            by reference z'result' by value 1 end-call
    else
        call static 'j_set_boolean' using by value response-node
            by reference z'ok' by value 0 end-call
        call static 'j_set_string' using by value response-node
            by reference z'error' error-text
            by value function length(function trim(error-text)) end-call
    end-if
    goback.
field-type.
    move low-values to field-z
    string function trim(field-name) x'00' into field-z end-string
    call static 'j_type' using by value record-node
        by reference field-z returning type-code end-call
    call static 'j_has' using by value record-node
        by reference field-z returning present-flag end-call.
object-field.
    perform field-type
    if type-code not = 5 and (required-mode = 1 or present-flag = 1)
        move function concatenate('Invalid object: ',function trim(field-name)) to error-text
    end-if.
boolean-field.
    perform field-type
    if type-code not = 1 and (required-mode = 1 or present-flag = 1)
        move function concatenate('Invalid boolean: ',function trim(field-name)) to error-text
    end-if.
text-field.
    perform field-type
    if type-code not = 3 or function J-STR(record-node, function trim(field-name)) = spaces
        move function concatenate('Invalid text: ',function trim(field-name)) to error-text
    end-if.
number-field.
    perform field-type
    move 0 to field-value
    if type-code = 2
        move function J-NUM(record-node, function trim(field-name)) to field-value
        move 1.0E+300 to compare-b
        call static 'h_number_compare' using field-value compare-b returning compare-code end-call
        if field-value < 0 or compare-code > 0
            move function concatenate('Number out of range: ',function trim(field-name)) to error-text
        end-if
        call static 'h_is_integer' using field-value returning compare-code end-call
        move 9007199254740991 to compare-b
        call static 'h_number_compare' using field-value compare-b returning status-code end-call
        if integer-mode = 1 and (status-code > 0 or compare-code = 0)
            move function concatenate('Invalid integer: ',function trim(field-name)) to error-text
        end-if
    else
        if required-mode = 1 or present-flag = 1
            move function concatenate('Invalid number: ',function trim(field-name)) to error-text
        end-if
    end-if.
achievement-maps.
    call static 'j_get_into' using by value context-node
        by reference z'catalog.achievements' known-node end-call
    call static 'j_size' using by value known-node by reference x'00' returning known-count end-call
    call static 'j_get_into' using by value state-node
        by reference z'achievements.progress' map-node end-call
    call static 'j_size' using by value map-node by reference x'00' returning map-count end-call
    perform varying map-index from 0 by 1 until map-index >= map-count
        call static 'j_at_into' using by value map-node map-index by reference map-item end-call
        call static 'j_key' using by value map-item by reference map-key by value 1000 end-call
        move 0 to matched
        perform varying known-index from 0 by 1 until known-index >= known-count
            call static 'j_at_into' using by value known-node known-index by reference known-item end-call
            if function J-STR(known-item, 'id') = map-key move 1 to matched end-if
        end-perform
        call static 'j_type' using by value map-item by reference x'00' returning type-code end-call
        move function J-NUM(map-item, ' ') to field-value
        move 100 to compare-b
        call static 'h_number_compare' using field-value compare-b returning compare-code end-call
        if matched = 0 or type-code not = 2 or field-value < 0 or compare-code > 0
            move 'Invalid achievement progress entry' to error-text end-if
    end-perform
    call static 'j_get_into' using by value state-node
        by reference z'achievements.customEvents' map-node end-call
    call static 'j_size' using by value map-node by reference x'00' returning map-count end-call
    if map-count > 10000 move 'Too many custom event flags' to error-text end-if
    perform varying map-index from 0 by 1 until map-index >= map-count
        call static 'j_at_into' using by value map-node map-index by reference map-item end-call
        call static 'j_key' using by value map-item by reference map-key by value 1000 returning status-code end-call
        call static 'j_type' using by value map-item by reference x'00' returning type-code end-call
        if status-code < 0 or map-key = spaces or type-code not = 1
            move 'Invalid custom event flag' to error-text end-if
    end-perform.
id-list.
    perform field-type
    if type-code not = 4
        if required-mode = 1 or present-flag = 1
            move 'Invalid identifier list' to error-text
        end-if
    else
        call static 'j_get_into' using by value record-node
            by reference field-z array-node end-call
        call static 'j_size' using by value array-node
            by reference x'00' returning item-count end-call
        call static 'j_size' using by value known-node
            by reference x'00' returning known-count end-call
        call static 'j_object_into' using by reference seen-node end-call
        if item-count > known-count
            move 'Too many saved identifiers' to error-text
        else
            perform varying item-index from 0 by 1 until item-index >= item-count
                call static 'j_at_into' using by value array-node item-index
                    by reference item-node end-call
                move function J-STR(item-node, '') to identifier
                move low-values to identifier-z
                string function trim(identifier) x'00' into identifier-z end-string
                move 0 to matched
                perform varying known-index from 0 by 1 until known-index >= known-count
                    call static 'j_at_into' using by value known-node known-index
                        by reference known-item end-call
                    if function J-STR(known-item, 'id') = identifier move 1 to matched end-if
                end-perform
                call static 'j_has' using by value seen-node
                    by reference identifier-z returning status-code end-call
                if matched = 0 or status-code = 1 or identifier = spaces
                    move 'Unknown or duplicate saved identifier' to error-text
                end-if
                call static 'j_set_boolean' using by value seen-node
                    by reference identifier-z by value 1 end-call
            end-perform
        end-if
        call static 'j_delete' using by value seen-node end-call
    end-if.
end program BUFO-VALIDATE-SAVE.
