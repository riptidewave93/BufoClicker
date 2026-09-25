identification division.
program-id. BUFO-FORMAT-NUMBER.
data division.
local-storage section.
01 decs usage binary-long value 1.
01 mode-value usage binary-long value 0.
linkage section.
01 input-value usage comp-2.
01 output-text pic x(256).
procedure division using input-value output-text.
 call static 'BUFO-FORMAT' using input-value decs mode-value output-text end-call
 goback.
end program BUFO-FORMAT-NUMBER.
