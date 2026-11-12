-- Material Icon Theme look for the explorer: folders get an icon and color
-- by name (src, docs, tests, .github, node_modules, …) and a few well-known
-- files get their Material icon. Other files keep nvim-web-devicons' colored
-- icons. Glyphs are Nerd Font code points written as escapes.

local M = {}

-- Material Icon Theme colors.
M.colors = {
  folder = "#90a4ae", -- blue grey: any other folder
  green = "#66bb6a",
  lime = "#c0ca33",
  teal = "#26a69a",
  cyan = "#26c6da",
  blue = "#42a5f5",
  indigo = "#5c6bc0",
  purple = "#ab47bc",
  pink = "#ec407a",
  red = "#ef5350",
  orange = "#ff7043",
  amber = "#ffca28",
  brown = "#a1887f",
  slate = "#78909c",
}

local glyph = {
  folder = "\u{f024b}", -- md-folder
  open = "\u{f0770}", -- md-folder_open
  git = "\u{e5fb}", -- custom-folder_git
  github = "\u{e5fd}", -- custom-folder_github
  npm = "\u{e5fa}", -- custom-folder_npm
  config = "\u{e5fc}", -- custom-folder_config
  text = "\u{f0c82}", -- md-folder_text
  image = "\u{f024f}", -- md-folder_image
  check = "\u{f197e}", -- md-folder_check
  play = "\u{f19fa}", -- md-folder_play
  zip = "\u{f06eb}", -- md-folder_zip
  multiple = "\u{f0253}", -- md-folder_multiple
  wrench = "\u{f19fc}", -- md-folder_wrench
  file = "\u{f19f6}", -- md-folder_file
  network = "\u{f0870}", -- md-folder_network
  account = "\u{f024c}", -- md-folder_account
  key = "\u{f08ac}", -- md-folder_key
  table = "\u{f12e3}", -- md-folder_table
  clock = "\u{f0aba}", -- md-folder_clock
  star = "\u{f069d}", -- md-folder_star
  eye = "\u{f178a}", -- md-folder_eye
  download = "\u{f024d}", -- md-folder_download
  music = "\u{f1359}", -- md-folder_music
  home = "\u{f10b5}", -- md-folder_home
}

-- { icon (nil = plain folder), color } by lowercase folder name.
local function def(icon, color, names)
  return { icon = icon, color = color, names = names }
end
local folder_defs = {
  def(nil, "green", { "src", "source", "sources", "app", "apps" }),
  def(glyph.star, "blue", { "core", "kernel", "main" }),
  def(glyph.text, "blue", { "docs", "doc", "documentation", "wiki", "man" }),
  def(glyph.check, "teal", { "test", "tests", "__tests__", "spec", "specs", "e2e", "testing", "fixtures" }),
  def(glyph.play, "amber", { "scripts", "script", "bin", "cmd", "tasks" }),
  def(glyph.git, "orange", { ".git" }),
  def(glyph.github, "slate", { ".github", ".gitlab", ".circleci" }),
  def(glyph.npm, "green", { "node_modules", ".pnpm-store", ".yarn" }),
  def(
    glyph.config,
    "cyan",
    { "config", "configs", ".config", "conf", "settings", ".vscode", ".idea", ".devcontainer" }
  ),
  def(glyph.image, "pink", { "assets", "images", "img", "icons", "public", "static", "media", "resources", "res" }),
  def(glyph.zip, "red", { "dist", "build", "out", "target", "release", "releases", ".next", ".nuxt" }),
  def(glyph.multiple, "slate", { "lib", "libs", "vendor", "packages", "third_party", "external", "deps", "plugins" }),
  def(glyph.wrench, "lime", { "utils", "util", "helpers", "helper", "tools", "common", "shared" }),
  def(glyph.file, "purple", { "types", "typings", "@types", "interfaces", "models", "schemas", "schema" }),
  def(nil, "lime", { "components", "component", "ui", "widgets", "views", "pages", "layouts", "screens" }),
  def(glyph.network, "indigo", { "api", "server", "routes", "router", "controllers", "services", "middleware" }),
  def(glyph.table, "amber", { "db", "database", "data", "migrations", "seeds", "sql", "prisma" }),
  def(glyph.eye, "purple", { "styles", "style", "css", "scss", "sass", "themes", "theme" }),
  def(glyph.clock, "brown", { "logs", "log", "tmp", "temp", ".cache", "cache", "coverage" }),
  def(glyph.key, "amber", { "keys", "secrets", "certs", "certificates", ".ssh", "auth" }),
  def(glyph.account, "blue", { "users", "user", "accounts", "profile" }),
  def(glyph.download, "blue", { "downloads", "download" }),
  def(glyph.music, "pink", { "music", "audio", "sounds" }),
  def(glyph.home, "blue", { "home" }),
  def(nil, "amber", { "hooks", "store", "stores", "state", "redux" }),
  def(nil, "teal", { "i18n", "locales", "locale", "lang", "translations" }),
}

---@type table<string, { icon?: string, color: string }>
M.folders = {}
for _, d in ipairs(folder_defs) do
  for _, name in ipairs(d.names) do
    M.folders[name] = { icon = d.icon, color = d.color }
  end
end

-- Well-known files whose Material icon differs from nvim-web-devicons'.
-- Keys are lowercase file names.
M.files = {
  ["readme.md"] = { icon = "\u{f02fc}", color = "blue" }, -- md-information
  ["readme"] = { icon = "\u{f02fc}", color = "blue" },
  ["changelog.md"] = { icon = "\u{f06b0}", color = "green" }, -- md-update
  ["changelog"] = { icon = "\u{f06b0}", color = "green" },
  ["license"] = { icon = "\u{f0124}", color = "amber" }, -- md-certificate
  ["license.md"] = { icon = "\u{f0124}", color = "amber" },
  ["license.txt"] = { icon = "\u{f0124}", color = "amber" },
  ["contributing.md"] = { icon = "\u{f0849}", color = "orange" }, -- md-account_group
  ["code_of_conduct.md"] = { icon = "\u{f0565}", color = "teal" }, -- md-shield_check
  ["security.md"] = { icon = "\u{f0565}", color = "red" },
}

---@param color string key of M.colors
---@return string highlight group
local function hl(color)
  return "WraithIcon" .. color:sub(1, 1):upper() .. color:sub(2)
end

--- Icon and highlight for a folder name.
---@param name string
---@param open boolean
---@return string icon, string highlight
function M.folder(name, open)
  local entry = M.folders[name:lower()]
  if entry and entry.icon then
    return entry.icon, hl(entry.color)
  end
  return open and glyph.open or glyph.folder, hl(entry and entry.color or "folder")
end

--- neo-tree icon provider (default_component_configs.icon.provider).
function M.provider(icon, node)
  if node.type == "directory" then
    local empty = node.loaded and not node:has_children()
    local text, group = M.folder(node.name, node:is_expanded())
    if empty and not M.folders[node.name:lower()] then
      text = icon.text -- outline folder for empty ones
    end
    icon.text, icon.highlight = text, group
  elseif node.type == "file" or node.type == "terminal" then
    local special = node.type == "file" and M.files[node.name:lower()]
    if special then
      icon.text, icon.highlight = special.icon, hl(special.color)
      return
    end
    local ok, devicons = pcall(require, "nvim-web-devicons")
    if ok then
      local text, group = devicons.get_icon(node.type == "terminal" and "terminal" or node.name)
      icon.text = text or icon.text
      icon.highlight = group or icon.highlight
    end
  end
end

--- Define the icon highlight groups. `default`, so `ui.colors` overrides win.
function M.define_highlights()
  for name, color in pairs(M.colors) do
    vim.api.nvim_set_hl(0, hl(name), { fg = color, default = true })
  end
end

return M
