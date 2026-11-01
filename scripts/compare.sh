#!/usr/bin/env bash
set -euo pipefail
OUT=results/comparison.md
row() {
  local f=results/$1
  local wall=$(grep 'Elapsed (wall' $f/time_verbose.txt | awk '{print $NF}')
  local usr=$(grep 'User time' $f/time_verbose.txt | awk '{print $NF}')
  local cpu=$(grep 'Percent of CPU' $f/time_verbose.txt | awk '{print $NF}')
  local rss=$(grep 'Maximum resident' $f/time_verbose.txt | awk '{print $NF}')
  local minf=$(grep 'Minor' $f/time_verbose.txt | awk '{print $NF}')
  local ctx=$(grep 'Involuntary context' $f/time_verbose.txt | awk '{print $NF}')
  local tclk=$(grep 'task-clock' $f/perf_stat.txt | awk '{print $1}')
  echo "| $1 | $wall | $usr | $cpu | $rss | $minf | $ctx | $tclk |"
}
{
  echo "| build | wall time | user, s | CPU | max RSS, KB | minor faults | invol. ctx sw | task-clock, ms |"
  echo "|---|---|---|---|---|---|---|---|"
  row bench_O0
  row bench_O3
  echo
  echo '```'
  echo "O0:"; cat results/bench_O0/program_output.txt
  echo "O3:"; cat results/bench_O3/program_output.txt
  echo '```'
} > $OUT
cat $OUT
