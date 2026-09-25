#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
./tests/api/run.sh
gcc -g -O1 -fsanitize=address -fno-omit-frame-pointer -fsigned-char -fno-strict-aliasing -I runtime build/api-generated/*.c runtime/*.c -lcob -lm -o build/api-asan
python3 tests/api/verify.py build/api-asan
python3 tests/api/routing.py build/api-asan
