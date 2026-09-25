#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
./tests/domain/run.sh
sources=()
for name in random format format-number game generators upgrades achievements prestige golden bosses; do
    sources+=("build/domain-generated/$name.c")
done
gcc -g -O1 -fsanitize=address -fno-omit-frame-pointer -fsigned-char -fno-strict-aliasing \
    -I runtime "${sources[@]}" runtime/json.c runtime/json-functions.c runtime/cJSON.c \
    runtime/host.c runtime/format.c runtime/utility.c tests/domain/runner.c -lcob -lm -o build/domain-asan
python3 tests/domain/verify.py build/domain-asan
