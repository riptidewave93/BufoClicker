#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
objects=()
for name in services state-services event-services async-services validation-services random format format-number; do
 objects+=("build/services-generated/$name.c")
done
gcc -g -fsanitize=address -fsigned-char -fno-strict-aliasing -I runtime "${objects[@]}" \
 runtime/json.c runtime/json-functions.c runtime/cJSON.c runtime/host.c runtime/format.c runtime/storage.c runtime/utility.c tests/services/main.c \
 -lcob -lm -o build/services-asan
ASAN_OPTIONS=detect_leaks=1 python3 tests/services/scenarios.py build/services-asan
ASAN_OPTIONS=detect_leaks=1 python3 tests/services/numeric-edges.py build/services-asan
