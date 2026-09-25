identification division.
program-id. BUFO-APP.
environment division.
configuration section.
repository.
    function J-STR
    function all intrinsic.
data division.
working-storage section.
01 rendered-text pic x(128).
01 rendered-length usage binary-long.
01 iteration usage binary-long.
linkage section.
01 request-pointer usage pointer.
01 response-pointer usage pointer.
procedure division using by value request-pointer response-pointer.
    perform varying iteration from 1 by 1 until iteration > 100
    move spaces to rendered-text
    string '[' function trim(function J-STR(request-pointer, 'text'))
        ']' into rendered-text end-string
    end-perform
    compute rendered-length = function length(function trim(rendered-text))
    call static "j_set_string" using by value response-pointer
        by reference z'text' rendered-text by value rendered-length end-call
    goback.
end program BUFO-APP.
