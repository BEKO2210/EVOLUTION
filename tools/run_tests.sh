#!/usr/bin/env bash
#
# Run all standalone Godot test scripts. Exits non-zero on first failure.
#
# Usage:
#   ./tools/run_tests.sh
#
# Requires `godot` (4.x stable matching .godot-version) on PATH.
# CI integration lands in a later phase via .github/workflows/.

set -euo pipefail

cd "$(dirname "$0")/.."

GODOT_BIN="${GODOT_BIN:-godot}"
if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
    echo "error: '$GODOT_BIN' not found on PATH. Install Godot 4.x stable or set GODOT_BIN." >&2
    exit 2
fi

TESTS=(
    tests/test_data_loader.gd
    tests/test_save_system.gd
    tests/test_tick_system.gd
)

FAIL=0
for test in "${TESTS[@]}"; do
    echo ">>> Running $test"
    if "$GODOT_BIN" --headless --path . --script "$test"; then
        echo "    ok"
    else
        echo "    FAILED"
        FAIL=1
    fi
done

if [[ $FAIL -ne 0 ]]; then
    echo ""
    echo "One or more test scripts failed." >&2
    exit 1
fi

echo ""
echo "All tests passed."
