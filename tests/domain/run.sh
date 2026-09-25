#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
export BUFO_C_SOURCES='runtime/json.c runtime/json-functions.c runtime/cJSON.c runtime/host.c runtime/format.c runtime/utility.c tests/domain/runner.c'
export BUFO_NATIVE_BUILD_DIR=build/domain-generated
export BUFO_NATIVE_OUTPUT=build/domain-test
./scripts/build-native.sh cobol/random.cob cobol/format.cob cobol/format-number.cob cobol/game.cob cobol/generators.cob cobol/upgrades.cob cobol/achievements.cob cobol/prestige.cob cobol/golden.cob cobol/bosses.cob
python3 tests/domain/verify.py
