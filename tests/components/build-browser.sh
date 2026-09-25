#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p build/components-wasm
objects=()
for source in ui-constants components component-render templates dom animation tooltip format-number ui game generators upgrades achievements bosses golden prestige random; do
 cobc32 -C -free -static -Wall -Wno-prototypes -Wno-unfinished -I cobol -o "build/components-wasm/$source.c" "cobol/$source.cob"
 objects+=("build/components-wasm/$source.c")
done
cobc32 -C -free -static -Wall -Wno-prototypes -Wno-unfinished -I cobol -o build/components-wasm/format.c cobol/format.cob
emcc -O2 -fsigned-char -fno-strict-aliasing "${objects[@]}" build/components-wasm/format.c runtime/json.c runtime/json-functions.c runtime/cJSON.c runtime/dom.c runtime/utility.c runtime/format.c runtime/host.c tests/components/wasm.c -I runtime -I/opt/wasm/include -L/opt/wasm/lib -lcob -lgmp -lm -s MODULARIZE=1 -s EXPORT_ES6=1 -s EXPORT_NAME=createBufoModule -s EXPORTED_FUNCTIONS='["_bufo_dispatch"]' -s EXPORTED_RUNTIME_METHODS='["ccall"]' -s ALLOW_MEMORY_GROWTH=1 -s DEFAULT_LIBRARY_FUNCS_TO_INCLUDE='["$stringToNewUTF8"]' -o build/components-wasm/bufo.js
cp web/dom-bridge.js build/components-wasm/dom-bridge.js
cp tests/components/browser.html build/components-wasm/index.html
