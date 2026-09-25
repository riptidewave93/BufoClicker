#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
export BUFO_NATIVE_BUILD_DIR=build/components-generated
export BUFO_NATIVE_OUTPUT=build/components-native
export BUFO_C_SOURCES='runtime/json.c runtime/json-functions.c runtime/cJSON.c runtime/host.c runtime/format.c runtime/storage.c runtime/utility.c runtime/dom.c tests/components/main.c'
bash scripts/build-native.sh cobol/ui-constants.cob cobol/components.cob cobol/component-render.cob cobol/templates.cob cobol/dom.cob cobol/animation.cob cobol/tooltip.cob cobol/format.cob cobol/format-number.cob cobol/ui.cob cobol/game.cob cobol/generators.cob cobol/upgrades.cob cobol/achievements.cob cobol/bosses.cob cobol/golden.cob cobol/prestige.cob cobol/random.cob
python3 tests/components/compare.py build/components-native
