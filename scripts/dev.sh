#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
BUILD_MODE=development ./scripts/build.sh
exec python3 -m http.server "${PORT:-9000}" --bind 0.0.0.0 --directory dist
