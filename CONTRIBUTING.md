# Contributing to WraithVim

Thanks for helping. WraithVim's value is in what it leaves out, so please read
the principles before proposing features.

## Principles

1. **Performance is a feature.** No repeating timers, polling, file watchers,
   background indexing or eager plugin loading. Check
   [docs/performance.md](docs/performance.md#budgets) for the budgets.
2. **Native first.** Prefer Neovim APIs over plugins, and existing plugins over
   new ones. A new plugin needs a concrete benefit that native features cannot
   provide.
3. **No fake features.** Do not document or add a keymap for anything that is
   not implemented and tested.
4. **Safe by default.** Never run a shell with user-controlled strings (use
   `vim.system` with an argument list), never overwrite user files silently,
   never install tools without confirmation.
5. **User settings survive.** Anything personal belongs in
   `~/.config/wraithvim/`; the distribution must never need edits.

## Development setup

```bash
git clone https://github.com/cachewraith/wraithvim && cd wraithvim
make deps     # install pinned plugins into .tests/ (never touches your config)
make tools    # download pinned StyLua, Luacheck and ShellCheck into .tests/bin
```

Try your checkout without installing it:

```bash
./install.sh --link --appname wvim && NVIM_APPNAME=wvim nvim
```

## Checks

| Command | What it does |
|---|---|
| `make lint` | Luacheck, StyLua check, ShellCheck, Lua/shell syntax |
| `make format` | Format Lua with StyLua |
| `make test` | All tests (unit, installer, headless and pty integration) |
| `make test-unit` / `make test-integration` | Subsets |
| `make health` | `:checkhealth wraithvim` against the sandbox |
| `make bench` | Benchmark the checkout |
| `make check` | lint + test + health |

Run one spec file: `nvim --headless --noplugin -u tests/minimal_init.lua -l tests/run.lua features/conflicts_spec.lua`.

Tests run in `.tests/` with their own XDG directories. Integration tests start
real Neovim processes, and `tests/integration/tui_spec.lua` drives the real TUI
in a pseudo-terminal, sending keys and mouse events as escape sequences. Use
`tests/helpers/` for temporary Git repositories and child processes.

## Code style

- Lua formatted by StyLua (`stylua.toml`), clean under Luacheck.
- Small modules with one responsibility. Plugin specs are data; option
  builders live in `ui/`, `features/` or `integrations/`.
- All autocommands in named augroups (`utils.augroup`).
- Comments explain *why*, not what.
- New keymaps go in `config/keymaps.lua` and `docs/keymaps.md` (a test checks
  both); new commands go in `config/commands.lua` and the README (also
  tested).

## Updating plugins

```bash
make update-plugins     # updates the sandbox and rewrites lazy-lock.json
git diff lazy-lock.json # review what moved
make check && make bench
```

Commit the updated `lazy-lock.json` together with any required changes, and
note it in `CHANGELOG.md`.

## Pull requests

- One topic per pull request, with tests.
- Describe user-visible changes in `CHANGELOG.md` under *Unreleased*.
- Include benchmark output when touching startup, UI refresh or Git paths.

By contributing you agree that your contributions are licensed under the MIT
License and that you will follow the [Code of Conduct](CODE_OF_CONDUCT.md).
