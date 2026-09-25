identification division.
program-id. BUFO-RANDOM.
environment division.
configuration section.
repository. function J-NUM function all intrinsic.
data division.
local-storage section.
01 sequence-node usage pointer.
01 item-node usage pointer.
01 position-number usage comp-2.
01 item-index usage binary-long.
01 item-count usage binary-long.
linkage section.
01 request-node usage pointer.
01 context-node usage pointer.
01 result-number usage comp-2.
procedure division using by value request-node context-node
    by reference result-number.
    compute position-number = function J-NUM(context-node,
        'runtime.randomIndex')
    move position-number to item-index
    call static 'j_get_into' using by value request-node
        by reference z'random' sequence-node end-call
    call static 'j_size' using by value sequence-node
        by reference x'00' returning item-count end-call
    if item-index < item-count
        call static 'j_at_into' using by value sequence-node item-index
            by reference item-node end-call
        move function J-NUM(item-node, '') to result-number
    else
        call static 'h_random' using by reference result-number end-call
    end-if
    add 1 to position-number
    call static 'j_set_number' using by value context-node
        by reference z'runtime.randomIndex' position-number end-call
    goback.
end program BUFO-RANDOM.
