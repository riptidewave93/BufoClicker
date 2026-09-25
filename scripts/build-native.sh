#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
generated_dir=${BUFO_NATIVE_BUILD_DIR:-build/native}
mkdir -p "$generated_dir"
sources=("$@")
if ((${#sources[@]} == 0)); then sources=(cobol/*.cob); fi
objects=()
for source in "${sources[@]}"; do
    name=$(basename "$source" .cob)
    generated="$generated_dir/$name.c"
    cobc -C -free -static -Wall -Wno-prototypes -Wno-unfinished -I cobol -o "$generated" "$source"
    objects+=("$generated")
done
runtime_sources=(runtime/*.c)
if [[ -n ${BUFO_C_SOURCES:-} ]]; then read -r -a runtime_sources <<< "$BUFO_C_SOURCES"; fi
output=${BUFO_NATIVE_OUTPUT:-build/bufo-native}
mkdir -p "$(dirname "$output")"
gcc -O2 -fsigned-char -fno-strict-aliasing -I runtime "${objects[@]}" "${runtime_sources[@]}" -lcob -lm -o "$output"
printf 'Built %s\n' "$output"
