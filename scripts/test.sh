#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/test-runtime.sh
./tests/catalog/run.sh
./tests/domain/run.sh
./tests/domain/run-wasm.sh
./tests/services/run.sh
./tests/services/wasm.sh
./tests/explorer/build.sh
./tests/components/run.sh
./tests/components/build-browser.sh
./tests/integration/run.sh
./tests/integration/asan.sh
./tests/api/run.sh
./tests/api/run-wasm.sh
