#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p build/services-wasm
objects=()
for source in cobol/services.cob cobol/state-services.cob cobol/event-services.cob cobol/async-services.cob cobol/validation-services.cob cobol/random.cob cobol/format.cob cobol/format-number.cob; do
 name=$(basename "$source" .cob)
 cobc32 -C -free -static -I cobol -o "build/services-wasm/$name.c" "$source"
 objects+=("build/services-wasm/$name.c")
done
emcc -O2 -fsigned-char -fno-strict-aliasing "${objects[@]}" runtime/json.c runtime/json-functions.c runtime/cJSON.c runtime/host.c runtime/format.c runtime/storage.c runtime/utility.c tests/services/main.c \
 -I runtime -I/opt/wasm/include -L/opt/wasm/lib -lcob -lgmp -lm \
 -s MODULARIZE=1 -s EXPORT_ES6=0 -s ENVIRONMENT=node -s ALLOW_MEMORY_GROWTH=1 \
 -s EXPORTED_FUNCTIONS='["_service_dispatch"]' -s EXPORTED_RUNTIME_METHODS='["ccall"]' \
 -s DEFAULT_LIBRARY_FUNCS_TO_INCLUDE='["$stringToNewUTF8"]' -o build/services-wasm/services.cjs
python3 tests/services/compare.py node tests/services/wasm-runner.mjs
python3 tests/services/scenarios.py node tests/services/wasm-runner.mjs
python3 tests/services/numeric-edges.py node tests/services/wasm-runner.mjs
