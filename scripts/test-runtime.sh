#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/native
gcc -Wall -Wextra -fsanitize=address,undefined -I runtime \
    tests/runtime/json.c runtime/json.c runtime/dom.c runtime/cJSON.c -lm -o build/native/test-runtime
build/native/test-runtime
gcc -Wall -Wextra -fsanitize=address,undefined -I runtime \
    tests/runtime/callbacks.c runtime/callbacks.c runtime/cJSON.c -lm -o build/native/test-callbacks
build/native/test-callbacks
gcc -Wall -Wextra -g -fsanitize=address,undefined -I runtime \
    -Dmain=bufo_cli_main -c runtime/dispatch.c -o build/native/dispatch-guard.o
gcc -Wall -Wextra -g -fsanitize=address,undefined -I runtime \
    tests/runtime/dispatch.c build/native/dispatch-guard.o runtime/json.c runtime/cJSON.c \
    -lcob -lm -o build/native/test-dispatch
ASAN_OPTIONS=detect_leaks=1 build/native/test-dispatch
cobc -C -free -static -Wno-unfinished -o build/native/test-string.c tests/runtime/string.cob
gcc -g -fsanitize=address,undefined -fsigned-char -I runtime \
    build/native/test-string.c runtime/json-functions.c \
    runtime/dispatch.c runtime/json.c runtime/cJSON.c -lcob -lm -o build/native/test-string
result=$(printf '%s\n' '{"text":"hello"}' | ASAN_OPTIONS=detect_leaks=1 build/native/test-string)
[[ "$result" == '{"text":"[hello]"}' ]]
printf 'Runtime JSON and nested COBOL STRING checks passed\n'

gcc -Wall -Wextra -g -fsanitize=address,undefined -I runtime \
    tests/components/json-strings.c runtime/json-functions.c runtime/json.c runtime/cJSON.c \
    -lcob -lm -o build/native/test-json-strings
ASAN_OPTIONS=detect_leaks=1 build/native/test-json-strings
