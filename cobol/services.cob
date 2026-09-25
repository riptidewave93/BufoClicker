identification division.
program-id. BUFO-SERVICES recursive.
environment division.
configuration section.
repository. function J-NUM function J-STR function all intrinsic.
data division.
local-storage section.
01 op pic x(96).
01 a usage pointer.
01 nodes.
 02 an usage pointer occurs 8.
01 nums.
 02 n usage comp-2 occurs 8.
01 types.
 02 typ usage binary-long occurs 8.
01 lower-bound usage comp-2.
01 upper-bound usage comp-2.
01 compare-code binary-long.
01 one-value usage comp-2 value 1.
01 two-value usage comp-2 value 2.
01 three-value usage comp-2 value 3.
01 r usage comp-2.
01 x usage comp-2.
01 y usage comp-2.
01 z usage comp-2.
01 now-ms usage comp-2.
01 i usage binary-long.
01 j usage binary-long.
01 k usage binary-long.
01 cnt usage binary-long.
01 rc usage binary-long.
01 yes usage binary-long.
01 decs usage binary-long.
01 mode-number usage binary-long.
01 temp usage pointer.
01 out-node usage pointer.
01 list-node usage pointer.
01 child usage pointer.
01 text-value pic x(32768).
01 small-text pic x(256).
01 word-text pic x(32).
01 key-text pic x(256).
01 formatted pic x(256).
01 result-kind pic x.
linkage section.
01 req usage pointer.
01 ctx usage pointer.
01 res usage pointer.
procedure division using by value req ctx res.
 move function J-STR(req, 'operation') to op
 call static 'j_get_into' using by value req by reference z'args' a end-call
 perform varying i from 1 by 1 until i > 8
  compute j = i - 1
  call static 'j_at_into' using by value a j by reference an(i) end-call
  call static 'j_type' using by value an(i) by reference x'00' returning typ(i) end-call
  move function J-NUM(an(i), ' ') to n(i)
 end-perform
 call static 'h_has_tag' using by value a returning rc end-call
 if rc = 1 and op not = 'time.invoke'
 call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
 call static 'j_set_string' using by value res by reference z'error' z'Unsupported non-JSON value representation' by value 40 end-call goback end-if
 move function J-NUM(req, 'now') to now-ms
 call static 'j_set_boolean' using by value res by reference z'ok' by value 1 end-call
 move 0 to r yes
 move 'n' to result-kind
 evaluate true
 when op = 'number.roundTo'
  move 2 to decs
   if an(2) not = null move n(2) to decs end-if
   move n(1) to r perform round-number
 when op = 'number.clamp'
  move n(1) to r move n(2) to lower-bound move n(3) to upper-bound perform clamp-result
 when op = 'number.calculateExponentialCost'
  compute x = function max(0,n(3))
   call static 'h_power' using n(2) x r end-call
   call static 'h_number_binary' using by value 3 by reference n(1) r r end-call
 when op = 'number.formatNumber'
  if function abs(n(1)) >= 1000000 and an(2) not = null and (n(2) < 0 or n(2) > 100)
   call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
   call static 'j_set_string' using by value res by reference z'error' z'minimumFractionDigits value is out of range.' by value 43 end-call
   call static 'j_set_string' using by value res by reference z'errorName' z'RangeError' by value 10 end-call goback end-if
  move 1 to decs
   if an(2) not = null move n(2) to decs end-if
   move 0 to mode-number
   if op = 'number.formatNumberWithPrecision' move 1 to mode-number end-if
   if op = 'number.getNumberFullName' move 2 to mode-number end-if
   call static 'BUFO-FORMAT' using by reference n(1) decs mode-number formatted end-call
   move formatted to text-value move 's' to result-kind
 when op = 'number.formatNumberWithPrecision'
  move 1 to decs
   if an(2) not = null move n(2) to decs end-if
   move 0 to mode-number
   if op = 'number.formatNumberWithPrecision' move 1 to mode-number end-if
   if op = 'number.getNumberFullName' move 2 to mode-number end-if
   call static 'BUFO-FORMAT' using by reference n(1) decs mode-number formatted end-call
   move formatted to text-value move 's' to result-kind
 when op = 'number.getNumberFullName'
  move 1 to decs
   if an(2) not = null move n(2) to decs end-if
   move 0 to mode-number
   if op = 'number.formatNumberWithPrecision' move 1 to mode-number end-if
   if op = 'number.getNumberFullName' move 2 to mode-number end-if
   call static 'BUFO-FORMAT' using by reference n(1) decs mode-number formatted end-call
   move formatted to text-value move 's' to result-kind
 when op = 'number.calculatePercentage'
  if n(2) not = 0
   compute r = n(1) / n(2) * 100
   move n(3) to decs perform round-number end-if
 when op = 'number.formatPercentage'
  move n(1) to r move n(2) to decs perform round-number
   call static 'h_decimal' using by reference r by value 12 0 1 by reference formatted by value 256 end-call
   move spaces to text-value
   string function trim(formatted) '%' into text-value end-string move 's' to result-kind
 when op = 'number.sum'
  call static 'j_size' using by value an(1) by reference x'00' returning cnt end-call
   if typ(1) = 4
   perform varying i from 0 by 1 until i >= cnt
   call static 'j_at_into' using by value an(1) i by reference child end-call
   compute r = r + function J-NUM(child, ' ')
   end-perform
   if op = 'number.average' and cnt > 0 compute r = r / cnt end-if end-if
 when op = 'number.average'
  call static 'j_size' using by value an(1) by reference x'00' returning cnt end-call
   if typ(1) = 4
   perform varying i from 0 by 1 until i >= cnt
   call static 'j_at_into' using by value an(1) i by reference child end-call
   compute r = r + function J-NUM(child, ' ')
   end-perform
   if op = 'number.average' and cnt > 0 compute r = r / cnt end-if end-if
 when op = 'math.randomInt'
  perform random-value
   compute x = 0 - function integer(0 - n(1))
   compute y = function integer(n(2))
   compute r = function integer(r * (y - x + 1)) + x
 when op = 'math.randomFloat'
  perform random-value compute r = r * (n(2) - n(1)) + n(1)
   move 2 to decs if an(3) not = null move n(3) to decs end-if perform round-number
 when op = 'math.mapRange'
  move n(4) to r
  call static 'h_number_compare' using by reference n(3) n(2) returning compare-code end-call
  if compare-code not = 0
call static 'h_number_binary' using by value 2 by reference n(1) n(2) r end-call
call static 'h_number_binary' using by value 2 by reference n(3) n(2) x end-call
call static 'h_number_binary' using by value 4 by reference r x r end-call
call static 'h_number_binary' using by value 2 by reference n(5) n(4) x end-call
call static 'h_number_binary' using by value 3 by reference r x r end-call
call static 'h_number_binary' using by value 1 by reference r n(4) r end-call
   call static 'j_boolean' using by value an(6) by reference x'00' returning yes end-call
   if an(6) = null or yes = 1
    move n(4) to lower-bound move n(5) to upper-bound perform order-bounds perform clamp-result
   end-if
  end-if
 when op = 'math.inRange'
  move n(1) to r move n(2) to lower-bound move n(3) to upper-bound perform order-bounds perform range-result
  move 'b' to result-kind
 when op = 'math.lerp' or op = 'math.smoothLerp'
  move n(3) to r move 0 to lower-bound move 1 to upper-bound perform clamp-result move r to x
  if op = 'math.smoothLerp'
   move 2 to y if an(4) not = null move n(4) to y end-if
   perform varying i from 0 by 1 until i > 10000
    move i to z
    call static 'h_number_compare' using by reference z y returning compare-code end-call
    if compare-code >= 0 exit perform end-if
call static 'h_number_binary' using by value 3 by reference two-value x z end-call
call static 'h_number_binary' using by value 2 by reference three-value z z end-call
call static 'h_number_binary' using by value 3 by reference x x r end-call
call static 'h_number_binary' using by value 3 by reference r z x end-call
   end-perform
  end-if
call static 'h_number_binary' using by value 2 by reference one-value x r end-call
call static 'h_number_binary' using by value 3 by reference n(1) r r end-call
call static 'h_number_binary' using by value 3 by reference n(2) x x end-call
call static 'h_number_binary' using by value 1 by reference r x r end-call
 when op = 'math.inverseLerp'
  call static 'h_number_compare' using by reference n(1) n(2) returning compare-code end-call
  if compare-code not = 0
call static 'h_number_binary' using by value 2 by reference n(3) n(1) r end-call
call static 'h_number_binary' using by value 2 by reference n(2) n(1) x end-call
call static 'h_number_binary' using by value 4 by reference r x r end-call
   move 0 to lower-bound move 1 to upper-bound perform clamp-result
  end-if
 when op = 'math.distance'
  compute x = n(3) - n(1) compute y = n(4) - n(2)
   compute r = function sqrt(x * x + y * y)
 when op = 'math.angle'
  compute x = n(4) - n(2) compute y = n(3) - n(1)
   call static 'h_atan2' using by reference x y r end-call
 when op = 'math.toDegrees'
  compute r = n(1) * (180 / 3.141592653589793)
 when op = 'math.toRadians'
  compute r = n(1) * (3.141592653589793 / 180)
 when op = 'math.pointFromAngle'
  call static 'j_array_into' using by reference out-node end-call
   compute r = n(1) + function cos(n(3)) * n(4) perform append-number
   compute r = n(2) + function sin(n(3)) * n(4) perform append-number move 'o' to result-kind
 when op = 'math.weightedRandom'
  move -1 to r
   call static 'j_size' using by value an(1) by reference x'00' returning cnt end-call
   move 0 to x
   perform varying i from 0 by 1 until i >= cnt
   call static 'j_at_into' using by value an(1) i by reference child end-call
   compute x = x + function max(0,function J-NUM(child, ' ')) end-perform
   if x > 0
   perform random-value compute y = r * x move 0 to x compute r = cnt - 1
   perform varying i from 0 by 1 until i >= cnt
   call static 'j_at_into' using by value an(1) i by reference child end-call
   compute x = x + function max(0,function J-NUM(child, ' '))
   call static 'h_number_compare' using by reference y x returning compare-code end-call
   if compare-code < 0 move i to r exit perform end-if end-perform end-if
 when op = 'math.factorial'
  move 1 to r
   call static 'h_is_integer' using n(1) returning rc end-call
   if n(1) >= 0 and rc = 1
   perform varying i from 2 by 1 until i > n(1) or i > 171 compute r = r * i end-perform end-if
 when op = 'math.chance'
  perform random-value if r * 100 < function max(0,function min(100,n(1))) move 1 to yes end-if move 'b' to result-kind
 when op = 'math.randomNormal'
  if an(2) = null move 1 to n(2) end-if
   move 0 to r perform until r not = 0 perform random-value end-perform move r to x
   move 0 to r perform until r not = 0 perform random-value end-perform
   compute r = function sqrt(0 - 2 * function log(x)) * function cos(2 * 3.141592653589793 * r) * n(2) + n(1)
 when op = 'time.getCurrentTime'
  move now-ms to r
 when op = 'time.calculateElapsedTime'
  if an(2) = null move now-ms to n(2) end-if compute r = function max(0,n(2) - n(1))
 when op = 'time.calculateFPS'
  if n(1) > 0 compute r = function integer(1000 / n(1) + 0.5) end-if
 when op = 'time.formatTimestamp'
  move 1 to yes
   if an(2) not = null call static 'j_boolean' using by value an(2) by reference x'00' returning yes end-call end-if
   call static 'h_timestamp' using by reference n(1) by value yes by reference text-value by value 32768 end-call
   move 's' to result-kind
 when op = 'number.formatDuration'
  compute x = function max(0,function integer(n(1)))
   compute y = function integer(x / 3600)
   compute z = function integer(function mod(x,3600) / 60)
   move spaces to text-value
   if y > 0 move y to r perform integer-text
   string function trim(formatted) 'h ' into text-value end-string end-if
   if z > 0 or y > 0 move z to r perform integer-text
   move function concatenate(function trim(text-value trailing), ' ') to small-text
   if y = 0 move spaces to small-text end-if
   move spaces to text-value
   string function trim(small-text trailing) ' ' function trim(formatted) 'm' into text-value end-string
   move function trim(text-value) to text-value end-if
   compute r = function mod(x,60) perform integer-text
   if text-value = spaces move function concatenate(function trim(formatted),'s') to text-value
   else move function concatenate(function trim(text-value),' ',function trim(formatted),'s') to text-value end-if
   move 's' to result-kind
 when op = 'time.formatTimeAgo'
  if an(2) = null move now-ms to n(2) end-if
   compute r = function integer(function max(0,n(2) - n(1)) / 1000)
   move 'second' to word-text
   evaluate true
   when r < 60 continue
   when r < 3600 compute r = function integer(r / 60) move 'minute' to word-text
   when r < 86400 compute r = function integer(r / 3600) move 'hour' to word-text
   when r < 2592000 compute r = function integer(r / 86400) move 'day' to word-text
   when r < 31104000 compute r = function integer(r / 2592000) move 'month' to word-text
   when other compute r = function integer(r / 31104000) move 'year' to word-text end-evaluate
   if r not = 1 move function concatenate(function trim(word-text), 's') to word-text end-if
   perform integer-text move spaces to text-value
   string function trim(formatted) ' ' function trim(word-text) ' ago' into text-value end-string
   move 's' to result-kind
 when op = 'validation.isValidNumber'
  call static 'j_size' using by value an(1) by reference x'00' returning cnt end-call
   if typ(1) = 2 move 1 to yes end-if move 'b' to result-kind
 when op = 'validation.isValidInteger'
  call static 'j_size' using by value an(1) by reference x'00' returning cnt end-call
   call static 'h_is_integer' using n(1) returning rc end-call
   if typ(1) = 2 and rc = 1 move 1 to yes end-if move 'b' to result-kind
 when op = 'validation.isPositiveNumber'
  call static 'j_size' using by value an(1) by reference x'00' returning cnt end-call
   if typ(1) = 2 and n(1) > 0 move 1 to yes end-if move 'b' to result-kind
 when op = 'validation.isNonNegativeNumber'
  call static 'j_size' using by value an(1) by reference x'00' returning cnt end-call
   if typ(1) = 2 and n(1) >= 0 move 1 to yes end-if move 'b' to result-kind
 when op = 'validation.isInRange'
  call static 'j_size' using by value an(1) by reference x'00' returning cnt end-call
   if typ(1) = 2
    move n(1) to r move n(2) to lower-bound move n(3) to upper-bound perform range-result
   end-if move 'b' to result-kind
 when op = 'validation.isNonEmptyString'
  call static 'j_size' using by value an(1) by reference x'00' returning cnt end-call
   call static 'h_nonempty' using by value an(1) returning yes end-call move 'b' to result-kind
 when op = 'validation.isValidArray'
  call static 'j_size' using by value an(1) by reference x'00' returning cnt end-call
   if typ(1) = 4 move 1 to yes end-if move 'b' to result-kind
 when op = 'validation.isValidObject'
  call static 'j_size' using by value an(1) by reference x'00' returning cnt end-call
   if typ(1) = 5 move 1 to yes end-if move 'b' to result-kind
 when op = 'validation.isValidDate'
  call static 'j_size' using by value an(1) by reference x'00' returning cnt end-call
   if 1 = 0 move 1 to yes end-if move 'b' to result-kind
 when op = 'validation.isNonEmptyArray'
  call static 'j_size' using by value an(1) by reference x'00' returning cnt end-call
   if typ(1) = 4 and cnt > 0 move 1 to yes end-if move 'b' to result-kind
 when op = 'utils.isPlainObject'
  if typ(1) = 5 move 1 to yes end-if move 'b' to result-kind
 when op = 'utils.isDefined'
  if typ(1) not = 0 move 1 to yes end-if move 'b' to result-kind
 when op = 'utils.isNullOrUndefined'
  if typ(1) = 0 move 1 to yes end-if move 'b' to result-kind
 when op = 'utils.defaultIfNullOrUndefined'
  move an(1) to temp if typ(1) = 0 move an(2) to temp end-if perform clone-result
 when op = 'utils.deepClone'
  move an(1) to temp perform clone-result
 when op = 'utils.safeJsonParse'
  call static 'h_json_parse_value' using by value an(1) by reference out-node returning rc end-call
   if rc not = 0 move an(2) to temp perform clone-result end-if move 'o' to result-kind
 when op = 'utils.safeJsonStringify'
  call static 'h_json_stringify_value' using by value an(1) by reference out-node returning rc end-call
   if rc not = 0 move an(2) to temp perform clone-result end-if move 'o' to result-kind
 when op = 'utils.generateId'
  perform random-value compute r = function integer(r * 10000) perform integer-text
   move formatted to small-text move now-ms to r perform integer-text
   move function J-STR(an(1), ' ') to word-text move spaces to text-value
   string function trim(word-text) function trim(formatted) '-' function trim(small-text) into text-value end-string move 's' to result-kind
 when op = 'utils.getRandomElement'
  call static 'j_size' using by value an(1) by reference x'00' returning cnt end-call
   if cnt > 0 perform random-value compute i = function integer(r * cnt)
   call static 'j_at_into' using by value an(1) i by reference temp end-call perform clone-result
   else call static 'j_parse_into' using by reference z'{"$oracle":"undefined"}' by value 23 by reference out-node end-call move 'o' to result-kind end-if
 when op = 'utils.shuffleArray'
  call static 'j_clone_into' using by value an(1) by reference out-node end-call
   if typ(1) not = 4 call static 'j_delete' using by value out-node end-call call static 'j_array_into' using by reference out-node end-call end-if
   call static 'j_size' using by value out-node by reference x'00' returning cnt end-call
   compute i = cnt - 1
   perform until i <= 0
   perform random-value compute j = function integer(r * (i + 1))
   call static 'h_array_swap' using by value out-node i j end-call subtract 1 from i end-perform
   move 'o' to result-kind
 when op = 'validation.isValidEmail'
  move function J-STR(an(1), ' ') to text-value
   move 0 to j k yes
   if typ(1) = 3 and text-value not = spaces
   move 1 to yes
   perform varying i from 1 by 1 until i > function length(function trim(text-value trailing))
   evaluate text-value(i:1)
   when ' ' when x'09' when x'0a' when x'0d' move 0 to yes
   when '@' if j not = 0 or i = 1 move 0 to yes end-if move i to j
   when '.' if j > 0 and i > j + 1 move i to k end-if end-evaluate end-perform
   if j = 0 or k = 0 or k >= function length(function trim(text-value trailing)) move 0 to yes end-if end-if
   move 'b' to result-kind
 when op = 'validation.isValidUrl'
  call static 'h_url_valid' using by value an(1) returning yes end-call move 'b' to result-kind
 when op = 'validation.isOneOf'
  call static 'j_size' using by value an(2) by reference x'00' returning cnt end-call
   perform varying i from 0 by 1 until i >= cnt
   call static 'j_at_into' using by value an(2) i by reference child end-call
   call static 'h_scalar_equal' using by value an(1) child returning rc end-call
   if rc = 1 move 1 to yes end-if end-perform move 'b' to result-kind
 when op = 'validation.hasRequiredProperties'
  move 1 to yes if typ(1) not = 5 move 0 to yes end-if
   call static 'j_size' using by value an(2) by reference x'00' returning cnt end-call
   perform varying i from 0 by 1 until i >= cnt
   call static 'j_at_into' using by value an(2) i by reference child end-call
   move function J-STR(child,' ') to key-text
   call static 'j_has' using by value an(1) by reference function concatenate(function trim(key-text),x'00') returning rc end-call
   if rc = 0 move 0 to yes end-if end-perform move 'b' to result-kind
 when op = 'validation.createValidationResult'
  call static 'j_object_into' using by reference out-node end-call
   call static 'j_boolean' using by value an(1) by reference x'00' returning yes end-call
   call static 'j_set_boolean' using by value out-node by reference z'isValid' by value yes end-call
   if yes = 1 or an(2) = null call static 'j_array_into' using by reference temp end-call
   else call static 'j_clone_into' using by value an(2) by reference temp end-call end-if
   call static 'j_set' using by value out-node by reference z'errors' by value temp end-call move 'o' to result-kind
 when op(1:6) = 'state.' or op(1:10) = 'gameState.' or op(1:13) = 'stateManager.'
  call static 'BUFO-STATE-SERVICES' using by value req ctx res end-call goback
 when op(1:6) = 'event.'
  call static 'BUFO-EVENT-SERVICES' using by value req ctx res end-call goback
 when op(1:7) = 'logger.' or op(1:5) = 'data.' or op(1:5) = 'time.' or op = 'utils.delay' or op = 'utils.cancellableDelay' or op = 'utils.attempt' or op = 'utils.attemptResult'
  call static 'BUFO-ASYNC-SERVICES' using by value req ctx res end-call goback
 when op(1:11) = 'validation.'
  call static 'BUFO-VALIDATION-SERVICES' using by value req ctx res end-call goback
 when other
  call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
  call static 'j_set_string' using by value res by reference z'error' z'Unknown service operation' by value 25 end-call goback
 end-evaluate
 evaluate result-kind
 when 'n'
 if r = 0 and n(1) < 0 and (op = 'number.roundTo')
 call static 'j_parse_into' using by reference z'{"$oracle":"number","value":"-0"}' by value 33 by reference out-node end-call
 call static 'j_set' using by value res by reference z'result' by value out-node end-call goback end-if
 if op = 'math.factorial' and n(1) >= 171
 call static 'j_parse_into' using by reference z'{"$oracle":"number","value":"Infinity"}' by value 39 by reference out-node end-call
 call static 'j_set' using by value res by reference z'result' by value out-node end-call goback end-if
 call static 'h_number_result' using by reference r out-node end-call
 call static 'j_set' using by value res by reference z'result' by value out-node end-call
 when 'b' call static 'j_set_boolean' using by value res by reference z'result' by value yes end-call
 when 's' call static 'j_set_string' using by value res by reference z'result' text-value by value function length(function trim(text-value trailing)) end-call
 when 'o' if out-node = null call static 'j_parse_into' using by reference z'null' by value 4 by reference out-node end-call end-if
 call static 'j_set' using by value res by reference z'result' by value out-node end-call
 end-evaluate goback.
clamp-result.
 call static 'h_number_compare' using by reference r lower-bound returning compare-code end-call
 if compare-code < 0 move lower-bound to r end-if
 call static 'h_number_compare' using by reference r upper-bound returning compare-code end-call
 if compare-code > 0 move upper-bound to r end-if.
order-bounds.
 call static 'h_number_compare' using by reference lower-bound upper-bound returning compare-code end-call
 if compare-code > 0 move lower-bound to z move upper-bound to lower-bound move z to upper-bound end-if.
range-result.
 call static 'h_number_compare' using by reference r lower-bound returning compare-code end-call
 if compare-code >= 0
  call static 'h_number_compare' using by reference r upper-bound returning compare-code end-call
  if compare-code <= 0 move 1 to yes end-if
 end-if.
round-number.
 move 10 to y move decs to z
 call static 'h_power' using y z x end-call
 call static 'h_round' using by reference r x end-call.
integer-text.
 call static 'h_decimal' using by reference r by value 0 0 0 by reference formatted by value 256 end-call.
random-value.
 call static 'BUFO-RANDOM' using by value req ctx by reference r end-call.
clone-result.
 call static 'j_clone_into' using by value temp by reference out-node end-call move 'o' to result-kind.
append-number.
 call static 'j_object_into' using by reference temp end-call
 call static 'j_set_number' using by value temp by reference z'n' r end-call
 call static 'j_get_into' using by value temp by reference z'n' child end-call
 call static 'j_clone_into' using by value child by reference child end-call
 call static 'j_append' using by value out-node child end-call
 call static 'j_delete' using by value temp end-call.
end program BUFO-SERVICES.
