#!/usr/bin/env bash
# WraithVim benchmark.
#
#   scripts/benchmark.sh [--runs N] [--dev] [--appname NAME] [--startup-only] [--idle-seconds N]
#
# Default: benchmarks the installed WraithVim (NVIM_APPNAME, default nvim).
# --dev:   benchmarks this checkout inside the .tests sandbox (used by `make bench`).
#
# Startup is measured with `nvim --headless --startuptime`; runtime metrics
# (idle CPU, memory, file open, LSP init, Git) run a real TUI in a pty.

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
RUNS=10
DEV=0
APPNAME="${NVIM_APPNAME:-nvim}"
STARTUP_ONLY=0
IDLE_SECONDS=10

while (($#)); do
  case "$1" in
    --runs) RUNS="$2"; shift ;;
    --dev) DEV=1 ;;
    --appname) APPNAME="$2"; shift ;;
    --startup-only) STARTUP_ONLY=1 ;;
    --idle-seconds) IDLE_SECONDS="$2"; shift ;;
    -h | --help)
      sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done
[[ "$RUNS" =~ ^[0-9]+$ && "$RUNS" -gt 0 ]] || { echo "--runs must be a positive integer" >&2; exit 1; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/wraithvim-bench.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

nvim_cmd() {
  if ((DEV)); then
    local sb="$ROOT/.tests"
    env XDG_CONFIG_HOME="$sb/config" XDG_DATA_HOME="$sb/data" XDG_STATE_HOME="$sb/state" \
      XDG_CACHE_HOME="$sb/cache" WRAITHVIM_CONFIG_DIR="$sb/empty-user-config" \
      nvim -u "$ROOT/init.lua" "$@"
  else
    env NVIM_APPNAME="$APPNAME" nvim "$@"
  fi
}

# Final timestamp (ms) in a --startuptime log.
total_ms() { awk '/^[0-9]+\.[0-9]+ +[0-9]+\.[0-9]+/ { t = $1 } END { print t }' "$1"; }

stats() {
  sort -n | awk '{ a[NR] = $1; s += $1 } END {
    m = (NR % 2) ? a[(NR + 1) / 2] : (a[NR / 2] + a[NR / 2 + 1]) / 2
    printf "median %.1f ms  mean %.1f ms  min %.1f ms  max %.1f ms  (n=%d)\n", m, s / NR, a[1], a[NR], NR
  }'
}

echo "Environment"
echo "  date:     $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "  kernel:   $(uname -sr) $(uname -m)"
echo "  cpu:      $(awk -F': ' '/model name/ { print $2; exit }' /proc/cpuinfo 2>/dev/null || echo unknown)"
echo "  neovim:   $(NVIM_LOG_FILE=/dev/null nvim --version | head -n1)"
echo "  target:   $([[ $DEV -eq 1 ]] && echo "checkout $ROOT (.tests sandbox)" || echo "installed (NVIM_APPNAME=$APPNAME)")"
echo

# Warm-up run: compiles the Lua bytecode cache so runs measure steady state.
nvim_cmd --headless +qa >/dev/null 2>&1 || true

echo "Startup (headless, no file):"
for i in $(seq "$RUNS"); do
  nvim_cmd --headless --startuptime "$TMP/empty-$i.log" +qa >/dev/null 2>&1
  total_ms "$TMP/empty-$i.log"
done | stats | sed 's/^/  /'

echo "Startup (headless, opening a Lua file):"
for i in $(seq "$RUNS"); do
  nvim_cmd --headless --startuptime "$TMP/file-$i.log" "$ROOT/lua/wraithvim/init.lua" +qa >/dev/null 2>&1
  total_ms "$TMP/file-$i.log"
done | stats | sed 's/^/  /'

echo "Slowest startup steps (self+sourced ms, last run with a file):"
awk '/^[0-9]+\.[0-9]+ +[0-9]+\.[0-9]+ +[0-9]+\.[0-9]+: / {
  t = $2; sub(/:$/, "", $3); $1 = ""; $2 = ""; $3 = ""; sub(/^ +/, ""); printf "%8.3f  %s\n", t, $0
}' "$TMP/file-$RUNS.log" | sort -rn | head -n 8 | sed 's/^/  /'

echo "Plugins at startup:"
nvim_cmd --headless "+lua local s = require('lazy').stats(); io.stdout:write(('  %d of %d plugins loaded during startup\n'):format(s.loaded, s.count))" +qa 2>/dev/null || echo "  lazy.nvim unavailable"

if ((STARTUP_ONLY)); then
  exit 0
fi

echo
args=(--idle-seconds "$IDLE_SECONDS")
((DEV)) || args+=(--installed)
NVIM_APPNAME="$APPNAME" nvim --headless --clean -l "$ROOT/scripts/benchmark.lua" "${args[@]}" | sed 's/^/  /'
