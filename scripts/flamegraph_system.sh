#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
BIN=${1:-build/bench_O0}
OUT=results/system
mkdir -p "$OUT"
$SUDO $PERF record -F 499 -a -g -o /tmp/system.data -- "$BIN"
$SUDO $PERF script -i /tmp/system.data > /tmp/system.perf
$FG/stackcollapse-perf.pl /tmp/system.perf > "$OUT/out.folded"
$FG/flamegraph.pl --title "System-wide Flame Graph while running $(basename "$BIN")" "$OUT/out.folded" > "$OUT/flamegraph.svg"
echo "$OUT/flamegraph.svg"
