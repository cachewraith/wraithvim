# WraithVim development tasks. Everything runs inside the .tests/ sandbox and
# never touches your real Neovim configuration.

SHELL := bash
ROOT := $(abspath .)
SANDBOX := $(ROOT)/.tests
BIN := $(SANDBOX)/bin
export PATH := $(BIN):$(PATH)

STYLUA_VERSION := v2.6.0
LUACHECK_VERSION := v1.2.0
SHELLCHECK_VERSION := v0.11.0
ARCH := $(shell uname -m)

NVIM_ENV := XDG_CONFIG_HOME=$(SANDBOX)/config XDG_DATA_HOME=$(SANDBOX)/data \
	XDG_STATE_HOME=$(SANDBOX)/state XDG_CACHE_HOME=$(SANDBOX)/cache \
	WRAITHVIM_CONFIG_DIR=$(SANDBOX)/empty-user-config

LUA_SOURCES := init.lua lua tests scripts/benchmark.lua
SHELL_SOURCES := install.sh uninstall.sh scripts/*.sh

.PHONY: all deps update-plugins tools test test-unit test-integration lint luacheck format format-check shellcheck syntax health bench check clean

all: check

## deps: install pinned plugins into the sandbox (needs network)
deps:
	$(NVIM_ENV) nvim --headless -u init.lua "+Lazy! restore" +qa

## update-plugins: update plugins and rewrite lazy-lock.json (review the diff!)
update-plugins:
	$(NVIM_ENV) nvim --headless -u init.lua "+Lazy! update" +qa

## tools: download pinned StyLua, Luacheck and ShellCheck into .tests/bin
tools:
	@mkdir -p $(BIN)
	@if ! command -v stylua >/dev/null; then \
		echo "Downloading StyLua $(STYLUA_VERSION)"; \
		tmp=$$(mktemp -d); \
		curl -fsSL -o $$tmp/stylua.zip https://github.com/JohnnyMorganz/StyLua/releases/download/$(STYLUA_VERSION)/stylua-linux-$(ARCH).zip && \
		python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extract('stylua', sys.argv[2])" $$tmp/stylua.zip $(BIN) && \
		chmod +x $(BIN)/stylua; rm -rf $$tmp; fi
	@if ! command -v luacheck >/dev/null; then \
		echo "Downloading Luacheck $(LUACHECK_VERSION)"; \
		curl -fsSL -o $(BIN)/luacheck https://github.com/lunarmodules/luacheck/releases/download/$(LUACHECK_VERSION)/luacheck && \
		chmod +x $(BIN)/luacheck; fi
	@if ! command -v shellcheck >/dev/null; then \
		echo "Downloading ShellCheck $(SHELLCHECK_VERSION)"; \
		curl -fsSL https://github.com/koalaman/shellcheck/releases/download/$(SHELLCHECK_VERSION)/shellcheck-$(SHELLCHECK_VERSION).linux.$(ARCH).tar.xz \
			| tar -xJ -C $(BIN) --strip-components=1 shellcheck-$(SHELLCHECK_VERSION)/shellcheck; fi
	@stylua --version; luacheck --version | head -n1; shellcheck --version | sed -n 2p

## test: all Lua tests (unit + integration) with Plenary Busted
test:
	$(NVIM_ENV) nvim --headless --noplugin -u tests/minimal_init.lua -l tests/run.lua

test-unit:
	$(NVIM_ENV) nvim --headless --noplugin -u tests/minimal_init.lua -l tests/run.lua core config features ui languages installer

test-integration:
	$(NVIM_ENV) nvim --headless --noplugin -u tests/minimal_init.lua -l tests/run.lua integration

lint: luacheck format-check shellcheck syntax

luacheck:
	luacheck $(LUA_SOURCES)

format:
	stylua $(LUA_SOURCES)

format-check:
	stylua --check $(LUA_SOURCES)

shellcheck:
	shellcheck $(SHELL_SOURCES)

## syntax: byte-compile every Lua file and parse every shell script
syntax:
	@find init.lua lua tests scripts -name '*.lua' -print0 | xargs -0 -n1 luajit -bl >/dev/null
	@for f in $(SHELL_SOURCES); do bash -n "$$f"; done
	@echo "syntax ok"

health:
	scripts/health-check.sh --dev

bench:
	scripts/benchmark.sh --dev

check: lint test health

clean:
	rm -rf $(SANDBOX)/state $(SANDBOX)/cache
