# COBOL browser ABI

GnuCOBOL 3.1.2 generates C with `cobc -C -free -static`. The generated C links with matching libcob and cJSON 1.7.19. The `-static` option binds literal `CALL` targets directly. [Runtime dependencies](RUNTIME.md) records versions, source hashes, and configuration changes.

## Entry points and ownership

[BUFO-APP](../cobol/app.cob) takes two `USAGE POINTER` arguments by value: the request and the response. It owns the persistent context in `WORKING-STORAGE`. Domain, Explorer, service, and UI module entries take three pointers by value: the request, the context, and the response.

[The C dispatcher](../runtime/dispatch.c) exports:

```c
const char *bufo_dispatch(const char *request_json);
```

The dispatcher initializes libcob once. Each call parses the request, creates a response object, calls `BUFO-APP`, and serializes the response. It then deletes the request and response objects. The returned string remains valid until the next dispatch. A nested call made while the dispatcher is active returns an error before it changes the shared output or enters COBOL.

Retained context values must own their storage. A borrowed pointer into the request expires when dispatch returns. JSON values copied into the context require a deep clone unless ownership is transferred explicitly.

## C call conventions

Literal static `CALL` targets use the C function names. Pointer inputs and scalar lengths or indexes pass `BY VALUE`. COBOL numeric fields, text buffers, and output pointers pass `BY REFERENCE`.

Helpers called with the default GnuCOBOL return convention return C `int`, including output and mutation helpers. A C `void` return does not match that convention and can cause a WebAssembly signature trap. Integer results use `RETURNING` with `BINARY-LONG`.

Numeric output uses a `double *` argument and a COBOL `COMP-2` field. The ABI does not use C `double` or pointer results through COBOL `CALL RETURNING`. GnuCOBOL 3.1.2 pointer-returning calls exposed an undeclared `temptr` in native ARM C generation. The `_into` helpers avoid that code path.

Paths are null-terminated strings. A literal uses `Z'state.resources.bufos'`. A dynamic path appends `X'00'` after its trimmed text. Reads traverse dot-separated object keys and decimal array indexes. An empty path selects the root. This path syntax cannot address an object key that contains a dot.

## JSON helpers

[The JSON implementation](../runtime/json.c) provides these COBOL-facing functions:

```c
int j_get_into(void *root, const char *path, void **out);
int j_at_into(void *root, int zero_based_index, void **out);
int j_has(void *root, const char *path);
int j_type(void *root, const char *path);
int j_number(void *root, const char *path, double *out);
int j_boolean(void *root, const char *path);
int j_string(void *root, const char *path, char *out, int capacity);
int j_size(void *root, const char *path);
int j_key(void *node, char *out, int capacity);

int j_object_into(void **out);
int j_array_into(void **out);
int j_clone_into(void *node, void **out);
int j_parse_into(const char *input, int length, void **out);
int j_read_file_into(const char *path, void **out);
int j_delete(void *node);

int j_set_number(void *root, const char *path, const double *value);
int j_set_boolean(void *root, const char *path, int value);
int j_set_null(void *root, const char *path);
int j_set_string(void *root, const char *path, const char *value, int length);
int j_set(void *root, const char *path, void *value);
int j_remove(void *root, const char *path);
int j_append(void *array, void *value);
int j_merge(void *target, void *source);
int j_print(void *node, char *out, int capacity);
int j_equal(void *left, void *right);
```

The C implementation also exposes pointer-returning `j_get`, `j_at`, `j_object`, `j_array`, `j_clone`, and `j_parse`. COBOL callers use the corresponding `_into` functions.

`j_get_into` and `j_at_into` return borrowed pointers, or `NULL` when absent. Constructors, parsing functions, and `j_clone_into` return owned pointers. They return `-1` with a `NULL` output when allocation or parsing fails. `j_delete(NULL)` succeeds.

`j_type` returns the following codes:

| Code | Value |
| --- | --- |
| 0 | Missing or JSON null |
| 1 | Boolean |
| 2 | Number |
| 3 | String |
| 4 | Array |
| 5 | Object |

`j_has` distinguishes a missing value from an explicit null. Missing or incorrectly typed scalar reads produce zero, false, or an empty field. Presence and type checks remain separate from those default values. `j_size` counts array elements or object members. `j_at_into` returns a direct child at a zero-based index.

`j_string`, `j_key`, and `j_print` write UTF-8 bytes into space-padded buffers without a null terminator. They return `-1` if the complete result exceeds capacity. They clear a valid output buffer instead of returning a truncated prefix. `j_set_string` takes an exact byte length and rejects embedded null bytes.

`j_parse_into` rejects malformed JSON, trailing non-whitespace, embedded null bytes, and nonfinite numbers. It also rejects duplicate object keys, including nested and escape-equivalent duplicates. `j_set_number` rejects nonfinite values.

Mutation functions return `0` on success and `-1` for invalid targets, paths, values, or allocation failures. `j_set` and `j_append` consume the supplied owned value on both success and failure. The caller must not delete that value afterward.

`j_set` creates missing intermediate objects. It does not create or traverse arrays. `j_remove` also traverses object keys only, and removing an absent leaf from an existing object succeeds. Array access uses direct child handles, and `j_append` extends an array. `j_merge` requires two objects and performs a shallow merge with a deep copy of each source value.

A copy into the context uses `j_clone_into` followed by `j_set`. Passing a borrowed `j_get_into` result directly to `j_set` would transfer storage still owned by another JSON object.

## Numeric and string functions

[J-NUM and J-STR](../runtime/json-functions.c) implement the GnuCOBOL user-defined-function ABI in C. Each function uses a caller-owned result field and reuses its buffer when a loop calls the function again. The bindings also avoid changes to GnuCOBOL's global `STRING` state.

The COBOL repository declares `FUNCTION J-NUM` and `FUNCTION J-STR`. These functions take ordinary COBOL path literals, without a null terminator. `J-NUM(root, path)` returns `COMP-2`. `J-STR(root, path)` returns an alphanumeric field of at most 32,768 bytes. It reports the actual string length, or a one-space field for an empty, invalid, or oversized value. COBOL `MOVE` pads its destination normally.

A direct numeric getter assignment uses `MOVE`. `COMPUTE` passes through decimal arithmetic and can change the double's least significant bit.

```cobol
01 value usage comp-2.
MOVE FUNCTION J-NUM(request-pointer, 'value') TO value
CALL STATIC 'j_set_number' USING BY VALUE response-pointer
	BY REFERENCE Z'value' value END-CALL
```

[The numeric helpers](../runtime/utility.c) provide exact comparisons and IEEE double arithmetic where COBOL decimal intermediates or tolerant comparisons change results:

| Helper | Behavior |
| --- | --- |
| `h_number_compare(a, b)` | Returns `-1`, `0`, or `1` using C double comparisons. Inputs must be finite. |
| `h_number_binary(op, a, b, out)` | Operations `1` add, `2` subtract, `3` multiply, `4` divide, and `5` power. |
| `h_number_unary(op, a, out)` | Operations `1` ceiling, `2` floor, `3` natural logarithm, and `4` square root. |
| `h_is_integer(value)` | Tests finiteness and exact equality with the truncated value. |

Operation codes pass by value. Double inputs and outputs pass by reference. Arithmetic helpers can produce nonfinite results, which application validation must reject or encode explicitly.

`j_equal` compares JSON recursively without a numeric epsilon. It compares object members in stored order. `h_json_equal`, used for component selections, delegates to `j_equal`. Both distinguish adjacent representable numbers such as `10000000000000000` and `10000000000000002`. [The runtime JSON check](../tests/runtime/json.c) covers that distinction and exact number serialization.

## Runtime initialization and target widths

The dispatcher uses `cob_init_nomain(0, NULL)`. This avoids the `dlopen(NULL)` path used by normal runtime initialization. Before the first COBOL call, it registers `J__NUM` and `J__STR` through `cob_set_cancel`, using static `cob_module` records. Function lookup therefore uses the registered C bindings.

Native C generation uses the native `cobc`. WebAssembly C generation uses the 32-bit `cobc32` wrapper in [the tools image](../Dockerfile). The wrapper runs Debian i386 GnuCOBOL 3.1.2 through `qemu-i386-static`, with an explicit 32-bit loader and library path. A 64-bit compiler emits eight-byte pointer fields and copies, which do not match wasm32.

The wasm32 configuration leaves `COB_LI_IS_LL` undefined and defines `COB_32_BIT_LONG` as `1`. [The runtime build script](../scripts/build-runtime.sh) verifies target integer widths and corrects these generated configuration entries. Without the correction, libcob truncates large integer constants to 32 bits. The compiler and libcob source remain unchanged.

## Browser loading and host functions

[The browser host](../web/host.js) imports the default factory from `runtime/bufo.js`. Its `locateFile` callback resolves runtime filenames relative to the host module, so `bufo.wasm` and `bufo.data` work under a site prefix. The generated `runtime/config.js` exports the development flag.

[Host functions](../runtime/host.c) provide `h_random(double *output)` and `h_now(double *output)`. Both take a `COMP-2` output by reference. Browser builds use `Math.random` and `Date.now`. Native builds use `rand` and `CLOCK_REALTIME`. `h_is_browser()` returns `1` for WebAssembly and `0` for native builds.

JSON access, numeric conversion, formatting, and DOM access belong to the generic runtime. COBOL owns game rules, catalog use, save migration, markup, and event decisions. Callback transport is documented with the [service contracts](../tests/services/OPERATIONS.md) and [component contracts](../tests/components/OPERATIONS.md).

Native browser events defer their runtime work while a COBOL call is active. Normal navigation saves through `beforeunload` and `pagehide`. Forced teardown can interrupt an active call before deferred work runs, so recovery then uses the last persisted save. [The Firefox lifecycle check](../tests/browser/lifecycle.cjs) exercises browser-initiated reloads and link navigation with unsaved progress.

[The runtime test script](../scripts/test-runtime.sh) checks JSON ownership, rejection cases, exact numeric values, and nested COBOL `STRING` calls under sanitizers. [Service tests](../tests/services/OPERATIONS.md) exercise the same utility contracts through native and WebAssembly builds.
