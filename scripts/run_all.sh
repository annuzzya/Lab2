#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
make all asm
for b in build/bench_O0 build/bench_O3; do
  bash scripts/stats.sh $b
  bash scripts/flamegraph.sh $b
done
bash scripts/flamegraph_system.sh build/bench_O0
bash scripts/flamegraph_diff.sh
mkdir -p results/asm
cp build/bench_O0.s build/bench_O3.s results/asm/
bash scripts/compare.sh
if command -v rsvg-convert >/dev/null; then
  for f in results/*/*.svg; do rsvg-convert -z 1 -b white "$f" -o "${f%.svg}.png"; done
fi
