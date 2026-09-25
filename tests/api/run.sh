#!/bin/bash
set -euo pipefail
BUFO_NATIVE_BUILD_DIR=build/api-generated BUFO_NATIVE_OUTPUT=build/api-test ./scripts/build-native.sh
python3 tests/api/verify.py build/api-test
python3 tests/api/routing.py build/api-test
