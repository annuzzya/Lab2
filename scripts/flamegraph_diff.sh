#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
OUT=results/diff
mkdir -p "$OUT"
$FG/difffolded.pl -n results/bench_O0/out.folded results/bench_O3/out.folded > "$OUT/diff.folded"
$FG/flamegraph.pl --title "Differential O0 -> O3 (normalised): red = bigger share after -O3, blue = smaller share" "$OUT/diff.folded" > "$OUT/diff_O0_to_O3.svg"
echo "$OUT/diff_O0_to_O3.svg"
