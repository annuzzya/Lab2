#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
BIN=${1:-build/bench_O0}
NAME=$(basename "$BIN")
OUT=results/$NAME
mkdir -p "$OUT"
$SUDO $PERF record -F 999 --call-graph dwarf -o /tmp/$NAME.data -- "$BIN"
$SUDO $PERF script -i /tmp/$NAME.data > /tmp/$NAME.perf
$FG/stackcollapse-perf.pl /tmp/$NAME.perf | sed -E "s/\.(constprop|part|isra)\.[0-9]+//g" > "$OUT/out.folded"
$FG/flamegraph.pl --title "CPU Flame Graph: $NAME" "$OUT/out.folded" > "$OUT/flamegraph.svg"
echo "$OUT/flamegraph.svg"
