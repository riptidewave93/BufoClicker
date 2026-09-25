#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
export BUFO_NATIVE_BUILD_DIR=build/services-generated
export BUFO_NATIVE_OUTPUT=build/services-native
export BUFO_C_SOURCES='runtime/json.c runtime/json-functions.c runtime/cJSON.c runtime/host.c runtime/format.c runtime/storage.c runtime/utility.c tests/services/main.c'
bash scripts/build-native.sh cobol/services.cob cobol/state-services.cob cobol/event-services.cob cobol/async-services.cob cobol/validation-services.cob cobol/random.cob cobol/format.cob cobol/format-number.cob
python3 tests/services/compare.py build/services-native
python3 tests/services/scenarios.py build/services-native
python3 tests/services/numeric-edges.py build/services-native
