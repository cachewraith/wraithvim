## What and why

<!-- What does this change, and which problem does it solve? -->

## Checklist

- [ ] `make check` passes (lint, format, tests, health)
- [ ] New behaviour has tests; keymaps/commands are documented (`docs/keymaps.md`, README)
- [ ] No new timers, polling, watchers or eager plugin loading
      (or the trade-off is explained below with `make bench` output)
- [ ] External commands use `vim.system` with an argument list (no shell strings)
- [ ] `CHANGELOG.md` updated under *Unreleased*

## Benchmark (if startup, UI refresh or Git paths changed)

```text
<!-- scripts/benchmark.sh --dev output before / after -->
```
