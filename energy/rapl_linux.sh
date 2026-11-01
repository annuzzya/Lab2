#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../scripts/env.sh"
BIN=${1:-build/bench_O0}
if $PERF list 2>/dev/null | grep -q 'power/energy-pkg/'; then
  $SUDO $PERF stat -a -e power/energy-pkg/,power/energy-cores/,power/energy-ram/ -- "$BIN"
else
  echo "RAPL counters are not available here (VM / non-Intel CPU). Use energy/measure_mac.py on macOS."
fi
