#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
OUT=results/diff
mkdir -p "$OUT"
sed "s/^bench_O0;/bench;/" results/bench_O0/out.folded > /tmp/o0.folded
sed "s/^bench_O3;/bench;/" results/bench_O3/out.folded > /tmp/o3.folded
$FG/difffolded.pl -n /tmp/o0.folded /tmp/o3.folded > "$OUT/diff.folded"
$FG/flamegraph.pl --title "Differential O0 -> O3 (normalised): red = bigger share after -O3, blue = smaller share" "$OUT/diff.folded" > "$OUT/diff_O0_to_O3.svg"
echo "$OUT/diff_O0_to_O3.svg"
