identification division.
program-id. BUFO-APP.
environment division.
configuration section.
repository.
    function J-NUM
    function J-STR
    function all intrinsic.
data division.
working-storage section.
01 ctx usage pointer.
01 tmp usage pointer.
01 copy-node usage pointer.
01 request-node usage pointer.
01 events-node usage pointer.
01 op pic x(80).
01 n usage comp-2.
linkage section.
01 req usage pointer.
01 res usage pointer.
procedure division using by value req res.
    if ctx = null
        call static 'j_object_into' using by reference ctx end-call
        call static 'j_read_file_into' using by reference
            z'assets/data/enemies.json' tmp end-call
        call static 'j_set' using by value ctx
            by reference z'catalog.enemies' by value tmp end-call
    end-if
    call static 'j_array_into' using by reference events-node end-call
    call static 'j_set' using by value ctx
        by reference z'events' by value events-node end-call
    move 0 to n
    call static 'j_set_number' using by value ctx
        by reference z'runtime.randomIndex' n end-call
    call static 'j_get_into' using by value req
        by reference z'input' request-node end-call
    compute n = function J-NUM(request-node, 'now')
    call static 'j_set_number' using by value ctx
        by reference z'runtime.now' n end-call
    call static 'j_get_into' using by value req
        by reference z'seed' tmp end-call
    if tmp not = null
        call static 'j_clone_into' using by value tmp by reference copy-node end-call
        call static 'j_set' using by value ctx
            by reference z'state.explorer' by value copy-node end-call
        call static 'j_parse_into' using by reference
            '{"currentCombat":null,"currentEnemy":null,"explorationDistance":0,"maxExplorationDistance":10,"encounterChance":0.05}'
            by value 117 by reference tmp end-call
        call static 'j_set' using by value ctx
            by reference z'runtime.explorer' by value tmp end-call
    end-if
    move function J-STR(request-node, 'operation') to op
    evaluate true
      when op(1:6) = 'model.'
        call static 'BUFO-EXPLORER-MODELS' using by value request-node ctx res end-call
      when op(1:6) = 'enemy.'
        call static 'BUFO-ENEMIES' using by value request-node ctx res end-call
      when op(1:7) = 'combat.'
        call static 'BUFO-COMBAT' using by value request-node ctx res end-call
      when other
        call static 'BUFO-EXPLORER' using by value request-node ctx res end-call
    end-evaluate
    compute n = function J-NUM(ctx, 'runtime.randomIndex')
    call static 'j_set_number' using by value res
        by reference z'randomConsumed' n end-call
    call static 'j_get_into' using by value ctx
        by reference z'state.explorer' tmp end-call
    if tmp not = null
        call static 'j_clone_into' using by value tmp by reference copy-node end-call
        call static 'j_set' using by value res
            by reference z'explorer' by value copy-node end-call
    end-if
    call static 'j_clone_into' using by value events-node by reference copy-node end-call
    call static 'j_set' using by value res
        by reference z'events' by value copy-node end-call
    goback.
end program BUFO-APP.
