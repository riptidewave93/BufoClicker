#!/bin/bash
set -euo pipefail
BUFO_NATIVE_BUILD_DIR=build/integration-generated BUFO_NATIVE_OUTPUT=build/integration-test ./scripts/build-native.sh \
  cobol/random.cob cobol/format.cob cobol/format-number.cob \
  cobol/app.cob cobol/catalog-validation.cob cobol/presentation.cob cobol/save.cob cobol/save-validation.cob \
  cobol/game.cob cobol/generators.cob cobol/upgrades.cob cobol/achievements.cob \
  cobol/prestige.cob cobol/golden.cob cobol/bosses.cob \
  cobol/explorer.cob cobol/explorer-models.cob cobol/enemies.cob cobol/combat.cob \
  tests/integration/boundaries.cob
python3 tests/integration/verify.py build/integration-test
python3 tests/integration/transactions.py build/integration-test
