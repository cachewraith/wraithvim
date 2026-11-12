# Performance

Performance is a product requirement. This page explains how WraithVim stays
light, how to measure it, the measured baseline and the budgets that changes
are expected to stay within.

## What WraithVim does (and avoids)

- **Two plugins at startup.** lazy.nvim and the colorscheme. lualine,
  bufferline and the explorer load right after the first screen is drawn
  (`VeryLazy`); gitsigns, nvim-lspconfig and blink.cmp load when the first file
  opens; everything else loads when used.
- **No idle work.** No repeating timers, no polling, no file watchers in the
  explorer (`use_libuv_file_watcher = false`), no update checker
  (`checker.enabled = false`), no config-change watcher, no project indexing.
  gitsigns keeps an inotify watch on `.git`. That is event-driven: it costs
  nothing until Git changes something.
- **Event-driven statusline.** By default lualine wakes up every 16 ms to check
  a refresh queue, plus a periodic full refresh. WraithVim sets those intervals
  to effectively never and refreshes lualine itself on the events that change
  what it shows (`ModeChanged`, `BufEnter`, `BufModifiedSet`,
  `DiagnosticChanged`, `LspAttach`, `GitSignsUpdate`, …), coalesced to one
  refresh per event-loop tick. Cursor position and progress are `%l:%v` and
  `%P` items, which Neovim fills in while drawing. Measured effect: idle CPU
  fell from about 0.3% to 0%.
- **Cheap components.** Statusline and tab header read cached values
  (`b:gitsigns_status_dict`, `b:wraith_lsp`, `g:gitsigns_head`) and never run
  processes.
- **LSP on demand.** A server is enabled only if its language is enabled and
  its executable exists (checked once, cached). Neovim starts it only for a
  matching buffer.
- **Treesitter on demand.** Highlighting starts only for configured filetypes
  with an installed parser, and never for files larger than
  `large_file_size` (1.5 MiB). Parsers are never installed automatically.
- **Large files.** Above `large_file_size`: no Treesitter, no regex syntax, no
  undo file, no format-on-save.
- **No shell.** External commands are argument lists passed to `vim.system()`.

## Measuring

```bash
scripts/benchmark.sh                 # installed WraithVim (NVIM_APPNAME, default nvim)
scripts/benchmark.sh --appname wvim  # an --appname install
scripts/benchmark.sh --dev           # this checkout in the .tests sandbox (make bench)
scripts/benchmark.sh --startup-only --runs 30
```

`:Benchmark` runs the same script in a terminal split. `:Profile`
opens lazy.nvim's profiler.

The script reports:

| Metric | Method |
|---|---|
| Startup | `nvim --headless --startuptime` × N runs, after one warm-up run that fills the bytecode cache; median/mean/min/max of the final timestamp |
| Slowest startup steps | the largest `sourcing`/`require` entries of the last run |
| Plugins at startup | `require("lazy").stats().loaded` |
| Idle CPU / memory | a real TUI in a pseudo-terminal with a file open; user+system CPU ticks and `VmRSS` from `/proc/<pid>` over N seconds (default 10) |
| File open | `:edit` time inside the running TUI (filetype detection, Treesitter start), median of 5 files |
| LSP initialisation | time from `:edit` of a C file (clangd) or Lua file (lua-language-server) until the client is initialised; includes lazy-loading the LSP plugins. Skipped if neither server is installed. |
| Git | on a generated repository (2 000 files, 3 commits, 25 modified files): gitsigns hunks ready, `git status --porcelain`, diffview listing all changes |

### Reading `--startuptime`

```bash
nvim --startuptime /tmp/wraithvim-startup.log +qa
```

Each line is `clock  self+sourced  self:  event`. The first column is
milliseconds since start, so the last line (`--- NVIM STARTED ---`) is the
total. For `sourcing`/`require` lines, the second column includes everything
that file loaded and the third is the file's own time. Sort by the second
column to find what is expensive:

```bash
grep -E 'sourcing|require' /tmp/wraithvim-startup.log | sort -k2 -rn | head
```

Interactive startups also include terminal round-trips (for example the
background-colour query), which vary between terminal emulators. Headless runs
exclude them and are more reproducible.

## Baseline

Measured with `scripts/benchmark.sh --dev --runs 20 --idle-seconds 20`:

| | |
|---|---|
| Date | 2026-11-11 |
| Machine | Intel Core i7-13620H laptop, Linux 7.2.15 (Arch Linux), desktop session running |
| Neovim | 0.12.6 (LuaJIT 2.1) |
| Plugins | as pinned in `lazy-lock.json` at that date |
| Languages installed | clangd and clang-format only |

| Metric | Result |
|---|---|
| Startup, no file (headless) | **median 19.4 ms** (min 11.3, n=20; one 125 ms outlier from system noise) |
| Startup, opening a Lua file (headless) | **median 40.5 ms** (min 25.1, max 47.1). Includes gitsigns, nvim-lspconfig and blink.cmp loading for that file. |
| `nvim --clean` for comparison | median 5.2 ms |
| Plugins loaded at startup | 2 of 19 |
| Plugins loaded after the UI with a file open | 12 |
| Idle CPU, file open, explorer + statusline + gitsigns active | **0 ms over 20 s** (0.000%) |
| Memory (RSS) | **27.3 MiB** after startup, unchanged after idle |
| Opening a file | median 4.7 ms (min 1.4, max 18.8) |
| LSP (clangd) | attached after 50 ms, initialised within 55 ms |
| gitsigns hunks ready | 26 ms |
| `git status --porcelain` | 17 ms |
| diffview with 25 changed files | 50 ms |

Re-measured for 0.5.0 (which-key and vim-flog added, 21 plugins), same
machine, `--startup-only --runs 15`: startup median 19.4 ms without a file and
40.9 ms with one, still 2 plugins loaded at startup; the idle-CPU test still
passes.

For comparison, the same TUI idle measurement with lualine's default refresh
settings used 30–50 ms of CPU per 10 s (≈0.3%), all of it from lualine's
timers.

Measurements on a laptop vary by roughly ±30% between runs (frequency scaling,
background load). Compare medians from the same machine.

## Budgets

These budgets apply to the headless benchmark on hardware similar to the
baseline. A change that exceeds one must be optimised, made optional, or
justified in its pull request.

| Metric | Budget |
|---|---|
| Startup without files (median) | ≤ 30 ms |
| Startup with one file (median) | ≤ 60 ms |
| Plugins loaded at startup | ≤ 2 |
| Idle CPU with a file open | ≤ 20 ms per 10 s (2 scheduler ticks); enforced by `tests/integration/tui_spec.lua` |
| RSS after startup with a file | ≤ 40 MiB |
| Repeating timers / pollers while idle | none |

The idle-CPU budget is enforced by the test suite, and
`tests/core/plugin_manager_spec.lua` ensures no plugin spec is eager. The other
budgets are checked with `make bench` before releases.
