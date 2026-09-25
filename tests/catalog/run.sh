#!/bin/bash
set -euo pipefail
BUFO_NATIVE_BUILD_DIR=build/catalog-generated BUFO_NATIVE_OUTPUT=build/catalog-test BUFO_C_SOURCES='runtime/json.c runtime/json-functions.c runtime/cJSON.c runtime/utility.c tests/catalog/runner.c' ./scripts/build-native.sh cobol/catalog-validation.cob
python3 tests/catalog/verify.py build/catalog-test
