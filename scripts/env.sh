SUDO=""
[ "$(id -u)" -eq 0 ] || SUDO="sudo"
PERF=$(command -v perf || ls /usr/lib/linux-tools/*/perf 2>/dev/null | sort -V | tail -1 || true)
FG=${FG:-./FlameGraph}
