identification division.
program-id. BUFO-FORMAT.
environment division.
configuration section.
repository. function all intrinsic.
data division.
local-storage section.
01 scaled-value usage comp-2.
01 display-value usage comp-2.
01 math-base usage comp-2.
01 math-exp usage comp-2.
01 math-result usage comp-2.
01 exponent-number usage binary-long.

01 trim-flag usage binary-long.
01 capped usage binary-long.
01 formatted pic x(240).
01 suffixes.
   02 filler pic x(2) value '  '.
   02 filler pic x(2) value 'K '.
   02 filler pic x(2) value 'M '.
   02 filler pic x(2) value 'B '.
   02 filler pic x(2) value 'T '.
   02 filler pic x(2) value 'Qa'.
   02 filler pic x(2) value 'Qi'.
   02 filler pic x(2) value 'Sx'.
   02 filler pic x(2) value 'Sp'.
   02 filler pic x(2) value 'Oc'.
   02 filler pic x(2) value 'No'.
   02 filler pic x(2) value 'Dc'.
01 suffix-table redefines suffixes.
   02 suffix-name pic x(2) occurs 12 times.
linkage section.
01 input-value usage comp-2.
01 decimal-count usage binary-long.
01 format-mode usage binary-long.
01 output-text pic x(256).
procedure division using input-value decimal-count format-mode output-text.
    move spaces to output-text formatted
    move 1 to trim-flag
    move 0 to exponent-number capped
    evaluate true
      when input-value = 0
        if format-mode not = 2 move '0' to output-text end-if
        goback
      when format-mode = 1 and function abs(input-value) < 1000000000000
        compute display-value = function integer(input-value + 0.5)
        move 0 to decimal-count
      when function abs(input-value) < 1000
        move 10 to math-base move decimal-count to math-exp
        call static 'h_power' using math-base math-exp math-result end-call
        move input-value to display-value
        call static 'h_round' using display-value math-result end-call
      when format-mode = 1 and function abs(input-value) < 1000000000000
        compute display-value = function integer(input-value + 0.5)
        move 0 to decimal-count
      when function abs(input-value) < 1000000
        compute display-value = function integer(input-value + 0.5)
        move 0 to decimal-count
      when other
        call static 'h_log10' using input-value math-result end-call
        compute exponent-number = function min(11, function integer(math-result / 3))
        if format-mode = 1 move 3 to decimal-count end-if
        move 10 to math-base compute math-exp = exponent-number * 3
        call static 'h_power' using math-base math-exp math-result end-call
        call static 'h_number_binary' using by value 4 by reference input-value math-result scaled-value end-call
        move 999999 to math-base
        call static 'h_number_compare' using scaled-value math-base returning capped end-call
        if capped > 0 move math-base to display-value else move scaled-value to display-value end-if
        move 0 to trim-flag
    end-evaluate
    if format-mode = 2
        evaluate exponent-number
          when 0 if function abs(input-value) >= 1000 move 'Thousand' to output-text end-if
          when 1 move 'Thousand' to output-text
          when 2 move 'Million' to output-text
          when 3 move 'Billion' to output-text
          when 4 move 'Trillion' to output-text
          when 5 move 'Quadrillion' to output-text
          when 6 move 'Quintillion' to output-text
          when 7 move 'Sextillion' to output-text
          when 8 move 'Septillion' to output-text
          when 9 move 'Octillion' to output-text
          when 10 move 'Nonillion' to output-text
          when 11 move 'Decillion' to output-text
        end-evaluate goback end-if
    call static 'h_decimal'  using by reference display-value
        by value decimal-count 1 trim-flag
        by reference formatted by value 240 end-call
    if display-value = 0 and input-value < 0
       move function concatenate('-',function trim(formatted)) to formatted end-if
    add 1 to exponent-number
    string function trim(formatted) function trim(suffix-name(exponent-number))
        into output-text end-string
    if exponent-number > 1 and capped > 0
        move function concatenate(function trim(output-text), '+') to output-text
    end-if
    goback.
end program BUFO-FORMAT.
