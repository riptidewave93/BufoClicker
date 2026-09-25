#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/wasm dist/runtime
./scripts/build-native.sh
objects=()
for source in cobol/*.cob; do
    name=$(basename "$source" .cob)
    generated="build/wasm/$name.c"
    cobc32 -C -free -static -Wall -Wno-prototypes -Wno-unfinished -I cobol -o "$generated" "$source"
    objects+=("$generated")
done
emcc -O2 -fsigned-char -fno-strict-aliasing "${objects[@]}" runtime/*.c \
    -I runtime -I/opt/wasm/include -L/opt/wasm/lib -lcob -lgmp -lm \
    -s MODULARIZE=1 -s EXPORT_ES6=1 -s EXPORT_NAME=createBufoModule \
    -s EXPORTED_FUNCTIONS='["_bufo_dispatch"]' \
    -s EXPORTED_RUNTIME_METHODS='["ccall"]' \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s DEFAULT_LIBRARY_FUNCS_TO_INCLUDE='["$stringToNewUTF8"]' \
    --preload-file assets/data@/assets/data -o dist/runtime/bufo.js
case ${BUILD_MODE:-production} in
    production) development=false ;;
    development) development=true ;;
    *) printf 'BUILD_MODE must be production or development\n' >&2; exit 2 ;;
esac
printf 'export const development = %s;\n' "$development" > dist/runtime/config.js
cp -R web/. dist/
cp -R assets styles dist/
cp -R vendor/licenses dist/
cp /opt/runtime-sources/gnucobol-3.1.2.tar.xz /opt/runtime-sources/gmp-6.2.1.tar.xz dist/licenses/
printf 'Built dist/\n'
