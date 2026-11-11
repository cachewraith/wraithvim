# Language profiles

A profile bundles everything WraithVim knows about a language: filetypes,
Treesitter parsers, language servers (nvim-lspconfig names) and formatters
(conform.nvim names). Profiles live in `lua/wraithvim/languages/`.

## How activation works

1. A profile is **enabled** unless `languages.lua` disables it.
2. When the first file is opened, WraithVim checks each enabled server's
   executable on `PATH`. Present → `vim.lsp.enable(server)`. Missing → recorded
   for `:Health`, and a one-time hint appears when you open a matching
   file.
3. Neovim starts a server only when a buffer of one of its filetypes opens,
   with the project root found by nvim-lspconfig's root markers.
4. Formatters are registered with conform.nvim per filetype. conform runs a
   formatter only if it is installed. It prefers project-local installs such
   as `node_modules/.bin/prettier` and `vendor/bin/pint`, and every formatter
   reads its own project config file (`.prettierrc`, `stylua.toml`,
   `pyproject.toml`, `.clang-format`, `.editorconfig` for shfmt, …).
5. When no conform formatter applies, the server's own formatting is used
   (`options.format.lsp_fallback`). Two formatters never run on the same buffer.

Nothing is installed automatically.

## Profiles

| Profile (aliases) | Filetypes | LSP (executable) | Formatter (executable) | Parsers |
|---|---|---|---|---|
| `php` | php | intelephense (`intelephense`) | pint (`pint`) | php, phpdoc |
| `typescript` (`javascript`) | javascript, javascriptreact, typescript, typescriptreact | vtsls (`vtsls`) | prettier (`prettier`) | javascript, typescript, tsx, jsdoc |
| `java` | java | jdtls (`jdtls`) | google-java-format | java |
| `python` | python | basedpyright (`basedpyright-langserver`) | ruff_format (`ruff`) | python |
| `go` | go, gomod, gowork, gotmpl | gopls | gofumpt | go, gomod, gosum, gowork |
| `cpp` (`c`) | c, cpp, objc, objcpp, cuda | clangd | clang-format | c, cpp |
| `lua` | lua | lua_ls (`lua-language-server`) | stylua | lua, luadoc |
| `sql` | sql, mysql | sqls | sql_formatter (`sql-formatter`) | sql |
| `bash` (`sh`) | sh, bash | bashls (`bash-language-server`) | shfmt | bash |
| `yaml` | yaml, yaml.docker-compose, yaml.gitlab | yamlls (`yaml-language-server`) | prettier | yaml |

Notes:

- **intelephense** is proprietary freeware (core features free, premium
  features need a licence key). Replace it with phpactor if you prefer open
  source; see [customization](customization.md#languages).
- **lua_ls** gets the Neovim runtime as a library for projects that have a
  `lua/` directory and no `.luarc.json`, so Neovim configs work out of the box.
- **jdtls** needs Java 21+. nvim-lspconfig's `jdtls` definition expects a
  `jdtls` launcher script on `PATH`.
- **sqls** needs a `config.yml` with a database connection for completion of
  table names. Formatting with sql-formatter works without it.
- **yamlls** runs with `keyOrdering = false` so key order is not reported.

## Installing tools

WraithVim prefers tools installed by your system. Commands below are examples;
use whichever installer you trust.

### Arch Linux / EndeavourOS (official repositories)

```bash
sudo pacman -S --needed lua-language-server stylua \
  bash-language-server shfmt \
  yaml-language-server prettier \
  gopls gofumpt \
  clang \
  ruff \
  go nodejs npm python-pipx composer      # language toolchains for the rest
```

`clang` provides both `clangd` and `clang-format`.

### Everything else (works on any distribution)

| Tool | Install |
|---|---|
| intelephense | `npm install -g intelephense` |
| pint | `composer global require laravel/pint` (or per project: `composer require --dev laravel/pint`) |
| vtsls | `npm install -g @vtsls/language-server` |
| prettier | `npm install -g prettier` (or per project in `devDependencies`) |
| basedpyright | `pipx install basedpyright` |
| ruff | `pipx install ruff` |
| gopls | `go install golang.org/x/tools/gopls@latest` |
| gofumpt | `go install mvdan.cc/gofumpt@latest` |
| sqls | `go install github.com/sqls-server/sqls@latest` |
| sql-formatter | `npm install -g sql-formatter` |
| bash-language-server | `npm install -g bash-language-server` |
| yaml-language-server | `npm install -g yaml-language-server` |
| shfmt | `go install mvdan.cc/sh/v3/cmd/shfmt@latest` |
| stylua | `cargo install stylua`, or a binary from github.com/JohnnyMorganz/StyLua/releases |
| lua-language-server | binary from github.com/LuaLS/lua-language-server/releases |
| clangd, clang-format | Debian/Ubuntu/Kali: `sudo apt install clangd clang-format`; Fedora: `sudo dnf install clang-tools-extra` |
| jdtls | download from download.eclipse.org/jdtls/snapshots, or Mason |
| google-java-format | jar from github.com/google/google-java-format/releases (wrap it in a `google-java-format` script on `PATH`), or Mason |

Make sure `~/.local/bin` (pipx), `~/go/bin` (go install) and npm's global bin
directory are on your `PATH`.

### Mason (optional)

```lua
-- ~/.config/wraithvim/options.lua
return { mason = { enabled = true } }
```

With Mason enabled:

- Mason's `bin` directory is **appended** to `PATH`, so system installs still win.
- `:InstallTools` lists the missing servers and formatters of your
  enabled languages and installs them **after you confirm**. Restart Neovim
  afterwards.
- `:Mason` opens Mason's own UI.

Mason never runs on its own.

## Treesitter

Neovim 0.12 ships parsers for C, Lua, Markdown, Vim, Vimdoc and Query.
WraithVim starts Treesitter highlighting for filetypes of enabled languages
(plus `options.treesitter.extra_filetypes`), and only when a parser is
installed and the file is smaller than `large_file_size`. For other files,
Neovim's regex syntax highlighting applies.

Install parsers explicitly:

```vim
:InstallParsers              " parsers of enabled languages + extra_parsers that are missing
:InstallParsers rust toml    " specific parsers
:TSUpdate                     " update installed parsers (also runs after plugin updates)
```

This uses nvim-treesitter's `main` branch and requires the **tree-sitter CLI
≥ 0.26.1**, a C compiler, `curl` and `tar`. `:InstallParsers` reports exactly
what is missing. Parsers go to `~/.local/share/nvim/site/parser`.

Treesitter folding (`treesitter.folds`) and indentation
(`treesitter.indent`, experimental upstream) are opt-in.

## Adding a language

For a one-off, add a custom profile in `languages.lua` (see
[configuration](configuration.md#languageslua)). To contribute a builtin
profile, add `lua/wraithvim/languages/<name>.lua`, list it in
`registry.builtin`, add `enabled = true` to `config/defaults.lua`, and extend
`tests/languages/registry_spec.lua`. The test checks that every server exists
in nvim-lspconfig and every formatter exists in conform.nvim.
