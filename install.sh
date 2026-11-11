#!/usr/bin/env bash
# WraithVim installer.
#
# Installs the distribution to $XDG_DATA_HOME/wraithvim (default
# ~/.local/share/wraithvim) and writes a small bootstrap to
# ~/.config/<appname>/init.lua. Never uses sudo. Existing configurations are
# moved to timestamped backups, never deleted. Safe to run repeatedly.

set -euo pipefail

readonly MIN_NVIM="0.12.0"
readonly MARKER="WraithVim bootstrap"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

DRY_RUN=0
CHECK_ONLY=0
LINK=0
SYNC=0
APPNAME="nvim"
TARGET="$DATA_HOME/wraithvim"
REPO=""

if [[ -t 1 ]]; then
  C_RED=$'\033[31m' C_GREEN=$'\033[32m' C_YELLOW=$'\033[33m' C_BLUE=$'\033[34m' C_RESET=$'\033[0m'
else
  C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_RESET=""
fi

info() { printf '%s==>%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok() { printf '  %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '  %s!%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die() {
  printf '%serror:%s %s\n' "$C_RED" "$C_RESET" "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: install.sh [options]

  --dry-run          Print every action without changing anything
  --check            Only check dependencies (exit 1 if a required one is missing)
  --appname NAME     Neovim config directory name (default: nvim). With
                     --appname wvim, start it as `NVIM_APPNAME=wvim nvim`
                     and keep your current ~/.config/nvim untouched.
  --dir PATH         Install location (default: $XDG_DATA_HOME/wraithvim)
  --repo URL         Clone from URL instead of this checkout
  --link             Symlink this checkout instead of cloning (development)
  --sync             Install pinned plugins now (needs network; otherwise
                     they install on first start)
  -h, --help         Show this help
EOF
}

# Run a command, or print it in dry-run mode.
run() {
  if ((DRY_RUN)); then
    printf '  [dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

timestamp() { date +%Y%m%d-%H%M%S; }

# Path for a backup of $1 that does not exist yet.
backup_path() {
  local base
  base="$1.bak.$(timestamp)"
  local candidate="$base" n=1
  while [[ -e "$candidate" || -L "$candidate" ]]; do
    candidate="$base.$n"
    n=$((n + 1))
  done
  printf '%s' "$candidate"
}

parse_args() {
  while (($#)); do
    case "$1" in
      --dry-run) DRY_RUN=1 ;;
      --check) CHECK_ONLY=1 ;;
      --link) LINK=1 ;;
      --sync) SYNC=1 ;;
      --appname)
        [[ $# -ge 2 ]] || die "--appname needs a value"
        APPNAME="$2"
        shift
        ;;
      --dir)
        [[ $# -ge 2 ]] || die "--dir needs a value"
        TARGET="$2"
        shift
        ;;
      --repo)
        [[ $# -ge 2 ]] || die "--repo needs a value"
        REPO="$2"
        shift
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *) die "unknown option: $1 (see --help)" ;;
    esac
    shift
  done
  [[ "$APPNAME" =~ ^[A-Za-z0-9._-]+$ ]] || die "--appname may only contain letters, digits, '.', '_' and '-'"
  # ~/.config/wraithvim holds personal settings; it cannot double as a Neovim config dir.
  [[ "$APPNAME" != "wraithvim" ]] || die "--appname wraithvim collides with the settings directory ~/.config/wraithvim; use e.g. --appname wvim"
  case "$TARGET" in
    /*) ;;
    *) TARGET="$PWD/$TARGET" ;;
  esac
}

# --- environment detection ---------------------------------------------------

DISTRO="unknown"
DISTRO_LIKE=""
detect_platform() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    DISTRO="$(. /etc/os-release && printf '%s' "${ID:-unknown}")"
    # shellcheck disable=SC1091
    DISTRO_LIKE="$(. /etc/os-release && printf '%s' "${ID_LIKE:-}")"
  fi
  ARCH="$(uname -m)"
  info "Platform: $DISTRO ${DISTRO_LIKE:+(like $DISTRO_LIKE) }on $ARCH"
  case "$ARCH" in
    x86_64 | aarch64 | arm64) ;;
    *) warn "Architecture $ARCH is untested; prebuilt blink.cmp binaries may be unavailable (Lua fallback is used)" ;;
  esac
}

# Package manager hint for a package name per distribution family.
pkg_hint() {
  local arch_pkg="$1" deb_pkg="$2" fedora_pkg="$3"
  case " $DISTRO $DISTRO_LIKE " in
    *" arch "* | *" endeavouros "*) printf 'sudo pacman -S %s' "$arch_pkg" ;;
    *" debian "* | *" ubuntu "* | *" kali "*) printf 'sudo apt install %s' "$deb_pkg" ;;
    *" fedora "* | *" rhel "*) printf 'sudo dnf install %s' "$fedora_pkg" ;;
    *) printf 'install %s with your package manager' "$arch_pkg" ;;
  esac
}

version_ge() {
  # version_ge A B: true when A >= B (dotted numeric versions)
  [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" == "$2" ]]
}

check_dependencies() {
  info "Checking dependencies"
  local missing_required=0

  if command -v nvim >/dev/null 2>&1; then
    local v
    v="$(NVIM_LOG_FILE=/dev/null nvim --version | head -n1 | sed -E 's/^NVIM v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
    if version_ge "$v" "$MIN_NVIM"; then
      ok "neovim $v"
    else
      warn "neovim $v found; WraithVim needs >= $MIN_NVIM"
      warn "  Arch: sudo pacman -S neovim | others: use the official release tarball/AppImage from github.com/neovim/neovim/releases"
      missing_required=1
    fi
  else
    warn "neovim not found (required, >= $MIN_NVIM): $(pkg_hint neovim neovim neovim) or use the official release tarball"
    missing_required=1
  fi

  if command -v git >/dev/null 2>&1; then
    ok "git $(git --version | awk '{print $3}')"
  else
    warn "git not found (required): $(pkg_hint git git git)"
    missing_required=1
  fi

  local name cmds hint found c
  while IFS='|' read -r name cmds hint; do
    found=""
    for c in $cmds; do
      if command -v "$c" >/dev/null 2>&1; then
        found="$c"
        break
      fi
    done
    if [[ -n "$found" ]]; then
      ok "$name ($found)"
    else
      warn "$name not found (optional): $hint"
    fi
  done <<EOF
ripgrep - text search|rg|$(pkg_hint ripgrep ripgrep ripgrep)
fd - file search|fd fdfind|$(pkg_hint fd fd-find fd-find)
make - builds telescope-fzf-native|make|$(pkg_hint make make make)
C compiler - fzf-native and Treesitter parsers|cc gcc clang|$(pkg_hint gcc gcc gcc)
curl - downloads|curl|$(pkg_hint curl curl curl)
tree-sitter CLI - parser installation|tree-sitter|$(pkg_hint tree-sitter-cli "tree-sitter-cli (or cargo install tree-sitter-cli)" tree-sitter-cli)
clipboard provider|wl-copy xclip xsel|$(pkg_hint wl-clipboard wl-clipboard wl-clipboard) (Wayland) or xclip (X11)
EOF

  if command -v fc-list >/dev/null 2>&1; then
    # Capture first: `fc-list | grep -q` fails under pipefail when grep exits
    # early and fc-list is killed by SIGPIPE.
    local families
    families="$(fc-list : family 2>/dev/null || true)"
    if grep -qi 'nerd' <<<"$families"; then
      NERD_FONT=true
      ok "Nerd Font installed"
    else
      NERD_FONT=false
      warn "no Nerd Font found: ASCII icons will be configured (set icons.nerd_font in ~/.config/wraithvim/ui.lua)"
    fi
  else
    NERD_FONT=true
    warn "fc-list unavailable: cannot detect a Nerd Font; Nerd Font icons stay enabled"
  fi

  return "$missing_required"
}

# --- installation steps ------------------------------------------------------

ensure_writable_parent() {
  local dir
  dir="$(dirname -- "$1")"
  while [[ ! -e "$dir" ]]; do dir="$(dirname -- "$dir")"; done
  [[ -w "$dir" ]] || die "no write permission for $dir (WraithVim installs without sudo; choose another --dir)"
}

is_wraithvim_tree() { [[ -f "$1/lua/wraithvim/init.lua" && -f "$1/init.lua" ]]; }

source_repo() {
  if [[ -n "$REPO" ]]; then
    printf '%s' "$REPO"
  elif git -C "$SCRIPT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    printf '%s' "$SCRIPT_DIR"
  else
    printf ''
  fi
}

install_distribution() {
  info "Installing WraithVim to $TARGET"
  local src_real target_real=""
  src_real="$SCRIPT_DIR"
  [[ -e "$TARGET" ]] && target_real="$(cd -- "$TARGET" 2>/dev/null && pwd -P || true)"

  if [[ -n "$target_real" && "$target_real" == "$src_real" && -z "$REPO" ]]; then
    ok "already in place (this checkout is the install location)"
    return
  fi

  if ((LINK)); then
    if [[ -L "$TARGET" && "$target_real" == "$src_real" ]]; then
      ok "symlink already points to $SCRIPT_DIR"
      return
    fi
    ensure_writable_parent "$TARGET"
    if [[ -e "$TARGET" || -L "$TARGET" ]]; then
      local bak
      bak="$(backup_path "$TARGET")"
      warn "moving existing $TARGET to $bak"
      run mv -- "$TARGET" "$bak"
    fi
    run mkdir -p -- "$(dirname -- "$TARGET")"
    run ln -s -- "$SCRIPT_DIR" "$TARGET"
    ok "linked $TARGET -> $SCRIPT_DIR"
    return
  fi

  if [[ -e "$TARGET" ]] && is_wraithvim_tree "$TARGET"; then
    ok "WraithVim already installed (update with :WraithUpdate or git -C \"$TARGET\" pull --ff-only)"
    return
  fi

  ensure_writable_parent "$TARGET"
  if [[ -e "$TARGET" || -L "$TARGET" ]]; then
    local bak
    bak="$(backup_path "$TARGET")"
    warn "$TARGET exists but is not WraithVim; moving it to $bak"
    run mv -- "$TARGET" "$bak"
  fi

  local repo
  repo="$(source_repo)"
  run mkdir -p -- "$(dirname -- "$TARGET")"
  if [[ -n "$repo" ]]; then
    # Clone into a temporary sibling first so a failed clone leaves nothing behind.
    if ((DRY_RUN)); then
      run git clone --quiet -- "$repo" "$TARGET"
    else
      local tmp
      tmp="$(mktemp -d "$(dirname -- "$TARGET")/.wraithvim-install.XXXXXX")"
      if ! git clone --quiet -- "$repo" "$tmp/wraithvim"; then
        rm -rf -- "$tmp"
        die "git clone of $repo failed (network or permissions). Nothing was changed."
      fi
      # A local clone points origin at this directory; prefer this checkout's upstream.
      if [[ -z "$REPO" ]]; then
        local upstream
        upstream="$(git -C "$SCRIPT_DIR" remote get-url origin 2>/dev/null || true)"
        if [[ -n "$upstream" ]]; then
          git -C "$tmp/wraithvim" remote set-url origin "$upstream"
        fi
      fi
      mv -- "$tmp/wraithvim" "$TARGET"
      rmdir -- "$tmp"
    fi
    ok "cloned $repo"
  else
    warn "this copy is not a Git checkout; copying files (:WraithUpdate will be unavailable)"
    run mkdir -p -- "$TARGET"
    if ((DRY_RUN)); then
      printf '  [dry-run] copy %s -> %s (excluding .tests)\n' "$SCRIPT_DIR" "$TARGET"
    else
      tar -C "$SCRIPT_DIR" --exclude=./.tests -cf - . | tar -C "$TARGET" -xf -
    fi
    ok "copied files"
  fi
}

# Escape a string for a Lua double-quoted literal.
lua_quote() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '"%s"' "$s"
}

bootstrap_content() {
  cat <<EOF
-- $MARKER (generated by install.sh).
-- Personal settings belong in ~/.config/wraithvim/, not here: this file may be
-- regenerated by the installer.
local root = vim.env.WRAITHVIM_DIR or $(lua_quote "$TARGET")
if not vim.uv.fs_stat(root .. "/init.lua") then
  vim.api.nvim_echo({ { "WraithVim not found at " .. root .. ". Re-run install.sh or set \$WRAITHVIM_DIR.", "ErrorMsg" } }, true, {})
  return
end
dofile(root .. "/init.lua")
EOF
}

install_bootstrap() {
  local config_dir="$CONFIG_HOME/$APPNAME"
  local init="$config_dir/init.lua"
  info "Writing Neovim bootstrap to $init"
  ensure_writable_parent "$config_dir"

  if [[ -f "$init" ]] && grep -q "$MARKER" "$init"; then
    if [[ "$(cat -- "$init")" == "$(bootstrap_content)" ]]; then
      ok "bootstrap already up to date"
      return
    fi
    run cp -- "$init" "$(backup_path "$init")"
  elif [[ -e "$config_dir" || -L "$config_dir" ]]; then
    local bak
    bak="$(backup_path "$config_dir")"
    warn "existing configuration found; moving $config_dir to $bak"
    run mv -- "$config_dir" "$bak"
    BACKUP_MADE="$bak"
  fi

  run mkdir -p -- "$config_dir"
  if ((DRY_RUN)); then
    printf '  [dry-run] write %s\n' "$init"
  else
    local tmp
    tmp="$(mktemp "$config_dir/.init.lua.XXXXXX")"
    bootstrap_content >"$tmp"
    mv -- "$tmp" "$init"
  fi
  ok "bootstrap written"
}

# Create commented starter files; never overwrite existing user files.
install_user_config() {
  local dir="$CONFIG_HOME/wraithvim"
  info "User configuration: $dir"
  run mkdir -p -- "$dir"
  local name created=0
  for name in options ui languages plugins keymaps; do
    local file="$dir/$name.lua"
    if [[ -e "$file" ]]; then
      ok "$name.lua kept (existing)"
      continue
    fi
    if ((DRY_RUN)); then
      printf '  [dry-run] create %s\n' "$file"
    else
      user_template "$name" >"$file"
    fi
    created=$((created + 1))
  done
  ((created == 0)) || ok "created $created starter file(s)"
}

user_template() {
  case "$1" in
    options)
      cat <<'EOF'
-- WraithVim options. See docs/configuration.md for every setting.
return {
  -- format = { on_save = true },
  -- mason = { enabled = true },
  -- opt = { relativenumber = true },
}
EOF
      ;;
    ui)
      cat <<EOF
-- WraithVim UI. Presets: "default", "compact", "minimal". See docs/ui-layout.md.
return {
  preset = "default",
  icons = { nerd_font = ${NERD_FONT:-true} },
  -- explorer = { width = 34 },
  -- terminal = { position = "bottom", height = 14 },
}
EOF
      ;;
    languages)
      cat <<'EOF'
-- Enable or disable language profiles. See docs/languages.md.
return {
  -- go = false,
  -- python = { enabled = true },
}
EOF
      ;;
    plugins)
      cat <<'EOF'
-- Extra lazy.nvim plugin specs, and plugins to disable by name.
return {
  -- disable = { "flash.nvim" },
  -- { "folke/todo-comments.nvim", event = "BufReadPost", opts = {} },
}
EOF
      ;;
    keymaps)
      cat <<'EOF'
-- Extra keymaps and default mappings to remove. See docs/keymaps.md.
return {
  -- preset = "vscode",   -- VS Code shortcuts: Ctrl+P, Ctrl+B, Ctrl+/, Ctrl+C/V, F12, ...
  -- disable = { "s", "S" },
  -- { "n", "<leader>qq", "<cmd>qa<cr>", desc = "Quit all" },
}
EOF
      ;;
  esac
}

sync_plugins() {
  info "Installing pinned plugins (this needs network access)"
  if ((DRY_RUN)); then
    run env NVIM_APPNAME="$APPNAME" nvim --headless "+Lazy! restore" +qa
    return
  fi
  if ! env NVIM_APPNAME="$APPNAME" nvim --headless "+Lazy! restore" +qa; then
    warn "plugin installation failed (network?). Start Neovim later and run :Lazy restore."
    return
  fi
  ok "plugins installed"
}

main() {
  parse_args "$@"
  ((DRY_RUN)) && info "Dry run: nothing will be changed"
  detect_platform
  local deps_ok=0
  check_dependencies || deps_ok=$?
  if ((CHECK_ONLY)); then
    exit "$deps_ok"
  fi
  ((deps_ok == 0)) || die "required dependencies are missing (see above)"

  BACKUP_MADE=""
  install_distribution
  install_bootstrap
  install_user_config
  ((SYNC)) && sync_plugins

  echo
  info "Done."
  [[ -n "$BACKUP_MADE" ]] && printf '  Previous configuration saved to %s\n' "$BACKUP_MADE"
  if [[ "$APPNAME" == "nvim" ]]; then
    printf '  Start WraithVim with: nvim\n'
  else
    printf '  Start WraithVim with: NVIM_APPNAME=%s nvim\n' "$APPNAME"
  fi
  printf '  Then run :WraithHealth. Personal settings live in %s/wraithvim/\n' "$CONFIG_HOME"
}

main "$@"
