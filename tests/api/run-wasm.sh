#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p build/api-wasm
objects=()
for source in cobol/*.cob; do
 name=$(basename "$source" .cob)
 cobc32 -C -free -static -I cobol -o "build/api-wasm/$name.c" "$source"
 objects+=("build/api-wasm/$name.c")
done
emcc -O2 -fsigned-char -fno-strict-aliasing "${objects[@]}" runtime/*.c \
 -I runtime -I/opt/wasm/include -L/opt/wasm/lib -lcob -lgmp -lm \
 -s MODULARIZE=1 -s EXPORT_NAME=createApiModule -s ENVIRONMENT=node,web \
 -s EXPORTED_FUNCTIONS='["_bufo_dispatch"]' -s EXPORTED_RUNTIME_METHODS='["ccall"]' \
 -s ALLOW_MEMORY_GROWTH=1 -s DEFAULT_LIBRARY_FUNCS_TO_INCLUDE='["$stringToNewUTF8"]' \
 --preload-file assets/data@/assets/data -o build/api-wasm/api.cjs
API_RUNNER='node tests/api/wasm-runner.cjs' python3 tests/api/verify.py
API_RUNNER='node tests/api/wasm-runner.cjs' python3 tests/api/routing.py
