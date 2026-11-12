# Language profiles

A profile bundles everything WraithVim knows about a language: filetypes,
Treesitter parsers, language servers (nvim-lspconfig names) and formatters
(conform.nvim names). Profiles live in `lua/wraithvim/languages/`.

## Completion, errors and lint: what you get

Open a file and WraithVim offers to install what that language needs, once:

```text
Go: install the tools for completion, error checking and formatting?
  gopls    (language server)
  gofumpt  (formatter)
  go, gomod, gosum, gowork  (syntax colors)
[I]nstall  (N)ot now  Ne(v)er for Go
```

Press <kbd>i</kbd>. The tools install in the background through
[Mason](https://github.com/mason-org/mason.nvim) and the language server starts
in the open file as soon as it is ready. No restart.

The language server gives:
- **completion** of your code and libraries
- **errors and warnings** as you type, underlined, with the message at the end
  of the line and a count in the statusline
- go to definition, hover docs (`K`), rename, code actions

Some languages also get a **linter**. Its findings appear the same way. The
formatter runs with `Space c f`, or on save if you turn that on.

| Key | Shows |
|---|---|
| `Space d d` | Problems on this line |
| `Space d n` / `Space d p` | Next / previous problem |
| `Space d x` | Search all problems |
| `Space c a` | Quick fixes for the problem under the cursor |

**Not now** asks again next session. **Never** stops asking for that
language; `:InstallTools` installs everything any time. Set
`mason = { auto_install = "always" }` in `options.lua` to install without
asking, or `"never"` to never offer.

A tool you installed yourself (on `PATH`) always wins over Mason's copy.
Some packages need a language toolchain to build. For example, gopls needs Go,
and npm-based servers need Node.js. The prompt says so when one is missing.
Headless runs (`nvim --headless`, CI) never install anything.

## How activation works

1. A profile is **enabled** unless `languages.lua` disables it.
2. When the first file is opened, WraithVim checks each enabled server's
   executable on `PATH` (Mason's `bin` directory is appended to it). Present →
   `vim.lsp.enable(server)`; Neovim starts it when a buffer of one of its
   filetypes opens, with the project root found by nvim-lspconfig.
3. Formatters are registered with conform.nvim per filetype. conform runs a
   formatter only if it is installed. It prefers project-local installs such
   as `node_modules/.bin/prettier` and `vendor/bin/pint`, and every formatter
   reads its own project config file (`.prettierrc`, `stylua.toml`,
   `pyproject.toml`, `.clang-format`, `.editorconfig` for shfmt, …).
4. When no conform formatter applies, the server's own formatting is used
   (`options.format.lsp_fallback`). Two formatters never run on the same buffer.

## Languages

| Language | Files | Language server | Lint | Formatter |
|---|---|---|---|---|
| Bash / POSIX shell (`sh`) | sh, bash | bashls | ShellCheck (bash-language-server) | shfmt |
| C and C++ (`c`) | c, cpp, objc, objcpp, cuda | clangd | clang-tidy (clangd) | clang-format |
| C# (`cs`) | cs | csharp_ls | errors from the language server | csharpier |
| CSS, SCSS and Less (`scss`) | css, scss, less | cssls | errors from the language server | prettier |
| Dart and Flutter (`flutter`) | dart | dartls | errors from the language server | dart_format |
| Dockerfile (`dockerfile`) | dockerfile | dockerls | errors from the language server | language server |
| Elixir | elixir, eelixir, heex, surface | elixirls | errors from the language server | mix |
| Go | go, gomod, gowork, gotmpl | gopls | staticcheck and vet (gopls) | gofumpt |
| GraphQL | graphql | graphql | errors from the language server | prettier |
| HTML | html | emmet_language_server, html | errors from the language server | prettier |
| Java | java | jdtls | errors from the language server | google-java-format |
| JSON | json, jsonc, json5 | jsonls | errors from the language server | prettier |
| Kotlin | kotlin | kotlin_language_server | errors from the language server | ktlint |
| Lua | lua | lua_ls | errors from the language server | stylua |
| Markdown (`md`) | markdown | marksman | errors from the language server | prettier |
| Nix | nix | nil_ls | errors from the language server | nixfmt |
| PHP | php | intelephense | errors from the language server | pint |
| Prisma | prisma | prismals | errors from the language server | language server |
| Python | python | basedpyright, ruff | Ruff (ruff server) + type errors (basedpyright) | ruff_format |
| Ruby | ruby, eruby | ruby_lsp | RuboCop (ruby-lsp) | rubocop |
| Rust (`rs`) | rust | rust_analyzer | Clippy (rust-analyzer) | rustfmt |
| SQL | sql, mysql | sqls | errors from the language server | sql_formatter |
| Svelte | svelte | svelte | errors from the language server | prettier |
| Swift | swift | sourcekit | errors from the language server | language server |
| Terraform and HCL (`tf`) | terraform, terraform-vars, hcl | terraformls | errors from the language server | language server |
| TOML | toml | taplo | errors from the language server | language server |
| JavaScript and TypeScript (`javascript`) | javascript, javascriptreact, typescript, typescriptreact | eslint, vtsls | ESLint (eslint server, projects with an ESLint config) | prettier |
| YAML | yaml, yaml.docker-compose, yaml.gitlab | yamlls | errors from the language server | prettier |
| Zig | zig, zir | zls | errors from the language server | language server |

Not built in yet: Vue (its server needs a TypeScript plugin setup), Tailwind
CSS, Haskell, Scala, OCaml. Add them yourself in `languages.lua`; see
[Adding a language](#adding-a-language).

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

### Mason

Mason is on by default (`options.mason.enabled`). It installs into
`~/.local/share/nvim/mason`, and its `bin` directory is **appended** to
`PATH`, so system installs still win.

- Opening a file offers that language's missing tools (see the top of this page).
- `:InstallTools` lists everything missing for all enabled languages and
  installs it after you confirm.
- `:Mason` opens Mason's own UI (update or remove tools).

Turn it off with `mason = { enabled = false }` to manage every tool yourself.

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
