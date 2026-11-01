#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
$SUDO apt-get update -qq
$SUDO apt-get install -y -qq build-essential linux-tools-generic linux-tools-common time git python3 librsvg2-bin >/dev/null
[ -d FlameGraph ] || git clone -q --depth 1 https://github.com/brendangregg/FlameGraph.git
P=$(ls /usr/lib/linux-tools/*/perf | sort -V | tail -1)
$SUDO ln -sf "$P" /usr/local/bin/perf
$SUDO sysctl -qw kernel.perf_event_paranoid=-1 || true
$SUDO sysctl -qw kernel.kptr_restrict=0 || true
perf --version
