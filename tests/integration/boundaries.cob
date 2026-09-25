identification division.
program-id. BUFO-UI.
data division.
linkage section.
01 request-node usage pointer.
01 context-node usage pointer.
01 response-node usage pointer.
procedure division using by value request-node context-node response-node.
    goback.
end program BUFO-UI.
identification division.
program-id. BUFO-API.
data division.
linkage section.
01 request-node usage pointer.
01 context-node usage pointer.
01 response-node usage pointer.
procedure division using by value request-node context-node response-node.
    call static 'j_set_boolean' using by value response-node by reference z'ok' by value 0 end-call
    goback.
end program BUFO-API.
identification division.
program-id. BUFO-ACTIONS.
data division.
linkage section.
01 request-node usage pointer.
01 context-node usage pointer.
01 response-node usage pointer.
procedure division using by value request-node context-node response-node.
    call static 'j_set_boolean' using by value response-node by reference z'ok' by value 0 end-call
    goback.
end program BUFO-ACTIONS.
identification division.
program-id. BUFO-SERVICES.
data division.
linkage section.
01 request-node usage pointer.
01 context-node usage pointer.
01 response-node usage pointer.
procedure division using by value request-node context-node response-node.
    call static 'j_set_boolean' using by value response-node by reference z'ok' by value 0 end-call
    goback.
end program BUFO-SERVICES.
identification division.
program-id. BUFO-COMPONENTS.
data division.
linkage section.
01 request-node usage pointer.
01 context-node usage pointer.
01 response-node usage pointer.
procedure division using by value request-node context-node response-node.
    goback.
end program BUFO-COMPONENTS.
identification division.
program-id. BUFO-API-UI.
data division.
linkage section.
01 request-node usage pointer.
01 context-node usage pointer.
01 response-node usage pointer.
procedure division using by value request-node context-node response-node.
    goback.
end program BUFO-API-UI.
identification division.
program-id. BUFO-API-INITIALIZATION.
data division.
linkage section.
01 request-node usage pointer.
01 context-node usage pointer.
01 response-node usage pointer.
procedure division using by value request-node context-node response-node.
    goback.
end program BUFO-API-INITIALIZATION.
