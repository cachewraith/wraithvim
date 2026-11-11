#!/usr/bin/env bash
# Run :checkhealth wraithvim headlessly and print the report.
#
#   scripts/health-check.sh [--dev] [--appname NAME]
#
# Exit status is 1 when the report contains an ERROR (missing optional tools
# are WARNINGs and do not fail the check).
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
DEV=0
APPNAME="${NVIM_APPNAME:-nvim}"
while (($#)); do
  case "$1" in
    --dev) DEV=1 ;;
    --appname) APPNAME="$2"; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

REPORT="$(mktemp "${TMPDIR:-/tmp}/wraithvim-health.XXXXXX")"
trap 'rm -f -- "$REPORT"' EXIT

lua_cmd="lua vim.cmd('checkhealth wraithvim'); vim.fn.writefile(vim.api.nvim_buf_get_lines(0, 0, -1, false), [[$REPORT]])"
if ((DEV)); then
  sb="$ROOT/.tests"
  env XDG_CONFIG_HOME="$sb/config" XDG_DATA_HOME="$sb/data" XDG_STATE_HOME="$sb/state" \
    XDG_CACHE_HOME="$sb/cache" WRAITHVIM_CONFIG_DIR="${WRAITHVIM_CONFIG_DIR:-$sb/empty-user-config}" \
    nvim --headless -u "$ROOT/init.lua" -c "$lua_cmd" -c 'qa!'
else
  NVIM_APPNAME="$APPNAME" nvim --headless -c "$lua_cmd" -c 'qa!'
fi

cat -- "$REPORT"
if grep -q '❌ ERROR' "$REPORT"; then
  exit 1
fi
