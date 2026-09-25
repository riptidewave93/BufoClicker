#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
sources=(tests/explorer/driver.cob cobol/explorer.cob cobol/explorer-models.cob cobol/enemies.cob cobol/combat.cob cobol/random.cob)
BUFO_NATIVE_BUILD_DIR=build/explorer-generated BUFO_NATIVE_OUTPUT=build/explorer-native ./scripts/build-native.sh "${sources[@]}"
python3 tests/explorer/compare.py
python3 tests/explorer/validation.py
mkdir -p build/explorer-wasm
objects=()
for source in "${sources[@]}"; do
  generated="build/explorer-wasm/$(basename "$source" .cob).c"
  cobc32 -C -free -static -Wall -Wno-prototypes -Wno-unfinished -o "$generated" "$source"
  objects+=("$generated")
done
emcc -O2 -fsigned-char -fno-strict-aliasing "${objects[@]}" runtime/*.c \
  -I runtime -I/opt/wasm/include -L/opt/wasm/lib -lcob -lgmp -lm \
  -s MODULARIZE=1 -s EXPORT_ES6=1 -s EXPORT_NAME=createBufoModule \
  -s EXPORTED_FUNCTIONS='["_bufo_dispatch"]' -s EXPORTED_RUNTIME_METHODS='["ccall"]' \
  -s ALLOW_MEMORY_GROWTH=1 -s DEFAULT_LIBRARY_FUNCS_TO_INCLUDE='["$stringToNewUTF8"]' \
  --preload-file assets/data@/assets/data -o build/explorer-wasm/bufo.js
cp tests/explorer/index.html build/explorer-wasm/index.html
