#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p build/domain-wasm
objects=()
for name in random format format-number game generators upgrades achievements prestige golden bosses; do
    cobc32 -C -free -static -I cobol -o "build/domain-wasm/$name.c" "cobol/$name.cob"
    objects+=("build/domain-wasm/$name.c")
done
emcc -O2 -fsigned-char -fno-strict-aliasing "${objects[@]}" \
    runtime/json.c runtime/json-functions.c runtime/cJSON.c runtime/host.c runtime/format.c runtime/utility.c tests/domain/runner.c \
    -I runtime -I/opt/wasm/include -L/opt/wasm/lib -lcob -lgmp -lm \
    -s MODULARIZE=1 -s EXPORT_NAME=createDomainModule -s ENVIRONMENT=node,web \
    -s EXPORTED_FUNCTIONS='["_bufo_dispatch"]' -s EXPORTED_RUNTIME_METHODS='["ccall"]' \
    -s ALLOW_MEMORY_GROWTH=1 -s DEFAULT_LIBRARY_FUNCS_TO_INCLUDE='["$stringToNewUTF8"]' \
    --preload-file assets/data@/assets/data -o build/domain-wasm/domain.cjs
DOMAIN_RUNNER='node tests/domain/wasm-runner.cjs' python3 tests/domain/verify.py
