#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
BIN=${1:-build/bench_O0}
NAME=$(basename "$BIN")
OUT=results/$NAME
mkdir -p "$OUT"

/usr/bin/time --verbose -o "$OUT/time_verbose.txt" "$BIN" | tee "$OUT/program_output.txt"
cat "$OUT/time_verbose.txt"

$SUDO $PERF stat -d -o "$OUT/perf_stat.txt" -- "$BIN" > /dev/null
cat "$OUT/perf_stat.txt"

$SUDO $PERF record -F 999 --call-graph dwarf -o /tmp/$NAME.rec -- "$BIN" > /dev/null
$SUDO $PERF report -i /tmp/$NAME.rec --stdio --no-children --sort comm,dso,symbol 2>/dev/null | grep -v '^$' | sed -n '1,60p' > "$OUT/perf_report.txt"
$SUDO $PERF report -i /tmp/$NAME.rec --stdio --no-children -g none --percent-limit 0.5 2>/dev/null | grep -v '^$' > "$OUT/perf_report_flat.txt"
for f in matmul saxpy dot; do
  SYM=$(nm "$BIN" | awk -v f="$f" '$3 ~ "^"f"(\\.|$)" {print $3}' | sort -r | awk 'NR==1')
  $SUDO $PERF annotate -i /tmp/$NAME.rec --stdio -M intel -s "$SYM" 2>/dev/null | sed -n '1,160p' > "$OUT/perf_annotate_$f.txt"
done
cat "$OUT/perf_report_flat.txt"
