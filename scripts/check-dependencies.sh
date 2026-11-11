#!/usr/bin/env bash
# Report required and optional dependencies without installing anything.
# Exit status is 1 when a required dependency (Neovim >= 0.12, git) is missing.
set -euo pipefail
exec "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)/install.sh" --check "$@"
