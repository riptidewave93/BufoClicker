#!/bin/bash
set -euo pipefail
objects=()
for name in random format format-number app catalog-validation presentation save save-validation game generators upgrades achievements prestige golden bosses explorer explorer-models enemies combat boundaries; do
 objects+=("build/integration-generated/$name.c")
done
gcc -g -fsanitize=address -fsigned-char -fno-strict-aliasing -I runtime "${objects[@]}" runtime/*.c -lcob -lm -o build/integration-asan
ASAN_OPTIONS=detect_leaks=1 python3 tests/integration/verify.py build/integration-asan
ASAN_OPTIONS=detect_leaks=1 python3 tests/integration/transactions.py build/integration-asan
