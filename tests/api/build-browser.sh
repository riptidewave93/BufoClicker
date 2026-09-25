#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p build/api-browser-generated build/api-browser/runtime
objects=()
for source in cobol/*.cob; do
 name=$(basename "$source" .cob)
 cobc32 -C -free -static -I cobol -o "build/api-browser-generated/$name.c" "$source"
 objects+=("build/api-browser-generated/$name.c")
done
emcc -O2 -fsigned-char -fno-strict-aliasing "${objects[@]}" runtime/*.c \
 -I runtime -I/opt/wasm/include -L/opt/wasm/lib -lcob -lgmp -lm \
 -s MODULARIZE=1 -s EXPORT_ES6=1 -s EXPORT_NAME=createBufoModule \
 -s EXPORTED_FUNCTIONS='["_bufo_dispatch"]' -s EXPORTED_RUNTIME_METHODS='["ccall"]' \
 -s ALLOW_MEMORY_GROWTH=1 -s DEFAULT_LIBRARY_FUNCS_TO_INCLUDE='["$stringToNewUTF8"]' \
 --preload-file assets/data@/assets/data -o build/api-browser/runtime/bufo.js
printf 'export const development = true;\n' > build/api-browser/runtime/config.js
cp -R web/. build/api-browser/
cp -R assets styles build/api-browser/
