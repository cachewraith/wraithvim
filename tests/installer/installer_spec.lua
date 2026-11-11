-- install.sh / uninstall.sh run against throwaway HOME directories.

local env = require("tests.helpers.env")
local gh = require("tests.helpers.git")

local function sh(home, script, args, extra_env)
  local cmd = { "bash", env.root .. "/" .. script }
  vim.list_extend(cmd, args or {})
  local e = vim.tbl_extend("force", {
    HOME = home,
    PATH = vim.env.PATH,
    XDG_CONFIG_HOME = home .. "/.config",
    XDG_DATA_HOME = home .. "/.local/share",
    XDG_STATE_HOME = home .. "/.local/state",
  }, extra_env or {})
  -- stdin is not a terminal, so the uninstaller cannot prompt.
  return vim.system(cmd, { env = e, clear_env = true, text = true, stdin = "" }):wait(120000)
end

--- Sorted list of every path under `dir` (relative).
local function snapshot(dir)
  local out = {}
  for name, type in vim.fs.dir(dir, { depth = 20 }) do
    out[#out + 1] = name .. ":" .. type
  end
  table.sort(out)
  return out
end

--- A bare-bones copy of this checkout as a Git repository to install from.
local function source_repo()
  local dir = gh.repo()
  local r = vim
    .system({ "bash", "-c", 'tar -C "$1" --exclude=./.tests --exclude=./.git -cf - . | tar -C "$2" -xf -', "_", env.root, dir })
    :wait()
  assert(r.code == 0, r.stderr)
  gh.commit_all(dir, "snapshot")
  return dir
end

describe("install.sh", function()
  local home, src

  before_each(function()
    home = env.tmpdir("home")
    src = src or source_repo()
  end)

  after_each(function()
    vim.fn.delete(home, "rf")
  end)

  it("prints help and validates options", function()
    assert.equals(0, sh(home, "install.sh", { "--help" }).code)
    local r = sh(home, "install.sh", { "--bogus" })
    assert.equals(1, r.code)
    assert.matches("unknown option", r.stderr)
    r = sh(home, "install.sh", { "--appname", "wraithvim" })
    assert.equals(1, r.code)
    assert.matches("collides", r.stderr)
    r = sh(home, "install.sh", { "--appname", "../evil" })
    assert.equals(1, r.code)
  end)

  it("--check reports dependencies without changing anything", function()
    local r = sh(home, "install.sh", { "--check" })
    assert.equals(0, r.code)
    assert.matches("neovim", r.stdout)
    assert.same({}, snapshot(home))
  end)

  it("--dry-run changes nothing", function()
    env.write(home .. "/.config/nvim/init.lua", "-- old config\n")
    local before = snapshot(home)
    local r = sh(home, "install.sh", { "--dry-run", "--repo", src })
    assert.equals(0, r.code, r.stderr)
    assert.matches("%[dry%-run%]", r.stdout)
    assert.same(before, snapshot(home))
  end)

  it("clones, backs up an existing config, writes the bootstrap and starter files", function()
    env.write(home .. "/.config/nvim/init.lua", "-- old config\n")
    env.write(home .. "/.config/nvim/lua/mine.lua", "return 1\n")
    local r = sh(home, "install.sh", { "--repo", src })
    assert.equals(0, r.code, r.stderr)

    local target = home .. "/.local/share/wraithvim"
    assert.is_not_nil(vim.uv.fs_stat(target .. "/.git"))
    assert.is_not_nil(vim.uv.fs_stat(target .. "/lua/wraithvim/init.lua"))

    local init = env.read(home .. "/.config/nvim/init.lua")
    assert.matches("WraithVim bootstrap", init)
    assert.is_truthy(init:find(target, 1, true))

    local backups = vim.fn.glob(home .. "/.config/nvim.bak.*", false, true)
    assert.equals(1, #backups)
    assert.equals("-- old config\n", env.read(backups[1] .. "/init.lua"))
    assert.equals("return 1\n", env.read(backups[1] .. "/lua/mine.lua"))

    for _, name in ipairs({ "options", "ui", "languages", "plugins", "keymaps" }) do
      local file = home .. "/.config/wraithvim/" .. name .. ".lua"
      local chunk = assert(loadfile(file), name .. ".lua must be valid Lua")
      assert.is_table(chunk())
    end
  end)

  it("is idempotent and never overwrites user files", function()
    assert.equals(0, sh(home, "install.sh", { "--repo", src }).code)
    env.write(home .. "/.config/wraithvim/ui.lua", "return { preset = 'compact' }\n")
    local before = snapshot(home)
    local r = sh(home, "install.sh", { "--repo", src })
    assert.equals(0, r.code, r.stderr)
    assert.matches("already installed", r.stdout)
    assert.matches("bootstrap already up to date", r.stdout)
    assert.same(before, snapshot(home))
    assert.equals("return { preset = 'compact' }\n", env.read(home .. "/.config/wraithvim/ui.lua"))
  end)

  it("installs alongside an existing config with --appname", function()
    env.write(home .. "/.config/nvim/init.lua", "-- keep\n")
    assert.equals(0, sh(home, "install.sh", { "--repo", src, "--appname", "wvim" }).code)
    assert.equals("-- keep\n", env.read(home .. "/.config/nvim/init.lua"))
    assert.matches("WraithVim bootstrap", env.read(home .. "/.config/wvim/init.lua"))
    assert.equals(0, #vim.fn.glob(home .. "/.config/nvim.bak.*", false, true))
  end)

  it("links a checkout with --link", function()
    assert.equals(0, sh(home, "install.sh", { "--link" }).code)
    local target = home .. "/.local/share/wraithvim"
    assert.equals("link", vim.uv.fs_lstat(target).type)
    assert.equals(env.root, vim.uv.fs_realpath(target))
  end)

  it("fails cleanly when the clone fails", function()
    local r = sh(home, "install.sh", { "--repo", home .. "/does-not-exist" })
    assert.equals(1, r.code)
    assert.matches("Nothing was changed", r.stderr)
    assert.is_nil(vim.uv.fs_stat(home .. "/.local/share/wraithvim"))
    assert.equals(0, #vim.fn.glob(home .. "/.local/share/.wraithvim-install.*", true, true))
  end)

  it("reports missing write permission instead of using sudo", function()
    vim.fn.mkdir(home .. "/ro", "p")
    vim.uv.fs_chmod(home .. "/ro", 365) -- 0555
    local r = sh(home, "install.sh", { "--repo", src, "--dir", home .. "/ro/wraithvim" })
    vim.uv.fs_chmod(home .. "/ro", 493) -- 0755
    assert.equals(1, r.code)
    assert.matches("no write permission", r.stderr)
  end)

  it("the generated bootstrap starts WraithVim", function()
    assert.equals(0, sh(home, "install.sh", { "--link" }).code)
    -- Reuse the sandbox's installed plugins so no network is needed.
    local data = home .. "/.local/share/nvim"
    vim.fn.mkdir(data, "p")
    vim.uv.fs_symlink(env.sandbox .. "/data/nvim/wraithvim", data .. "/wraithvim")
    local r = vim
      .system({ "nvim", "--headless", "+lua io.stdout:write(tostring(vim.g.wraithvim_root))", "+qa" }, {
        env = { HOME = home, PATH = vim.env.PATH },
        clear_env = true,
        text = true,
      })
      :wait(60000)
    assert.equals(0, r.code, r.stderr)
    assert.equals(env.root, vim.uv.fs_realpath(r.stdout))
  end)
end)

describe("uninstall.sh", function()
  local home, src

  before_each(function()
    home = env.tmpdir("home")
    src = src or source_repo()
    env.write(home .. "/.config/nvim/init.lua", "-- old config\n")
    assert.equals(0, sh(home, "install.sh", { "--repo", src }).code)
    env.write(home .. "/.local/share/nvim/wraithvim/plugins/x/init.lua", "")
  end)

  after_each(function()
    vim.fn.delete(home, "rf")
  end)

  it("--dry-run changes nothing", function()
    local before = snapshot(home)
    assert.equals(0, sh(home, "uninstall.sh", { "--dry-run", "--yes" }).code)
    assert.same(before, snapshot(home))
  end)

  it("does nothing without confirmation when not interactive", function()
    local before = snapshot(home)
    local r = sh(home, "uninstall.sh", {})
    assert.equals(0, r.code)
    assert.matches("skipping", r.stderr)
    assert.same(before, snapshot(home))
  end)

  it("removes WraithVim, restores the previous config and keeps user settings", function()
    env.write(home .. "/.config/wraithvim/options.lua", "return { format = { on_save = true } }\n")
    local r = sh(home, "uninstall.sh", { "--yes" })
    assert.equals(0, r.code, r.stderr)
    assert.is_nil(vim.uv.fs_stat(home .. "/.local/share/wraithvim"))
    assert.is_nil(vim.uv.fs_stat(home .. "/.local/share/nvim/wraithvim"))
    assert.equals("-- old config\n", env.read(home .. "/.config/nvim/init.lua"))
    assert.equals("return { format = { on_save = true } }\n", env.read(home .. "/.config/wraithvim/options.lua"))
  end)

  it("refuses to purge user settings without an interactive confirmation", function()
    local r = sh(home, "uninstall.sh", { "--yes", "--purge-user-config" })
    assert.equals(0, r.code)
    assert.matches("refusing", r.stderr)
    assert.is_not_nil(vim.uv.fs_stat(home .. "/.config/wraithvim/options.lua"))
  end)

  it("leaves a non-WraithVim init.lua alone", function()
    env.write(home .. "/.config/nvim/init.lua", "-- someone else's config\n")
    local r = sh(home, "uninstall.sh", { "--yes" })
    assert.equals(0, r.code)
    assert.equals("-- someone else's config\n", env.read(home .. "/.config/nvim/init.lua"))
    assert.equals(1, #vim.fn.glob(home .. "/.config/nvim.bak.*", false, true)) -- backup kept
  end)
end)
