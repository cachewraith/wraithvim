-- Image files open as a picture instead of raw bytes, like VS Code's image
-- preview. Uses the kitty graphics protocol (kitty, Ghostty, WezTerm);
-- ImageMagick converts every format that is not PNG. Other terminals get a
-- short note instead of the binary data. Only the image module of snacks.nvim
-- is enabled, and it loads only when the first image is opened.

-- File extensions shown as images.
local formats = {
  "png",
  "jpg",
  "jpeg",
  "jpe",
  "jfif",
  "gif",
  "bmp",
  "webp",
  "tiff",
  "tif",
  "heic",
  "heif",
  "avif",
  "jxl",
  "ico",
  "icns",
  "svg",
  "tga",
  "psd",
  "qoi",
  "pdf",
  "mp4",
  "mov",
  "avi",
  "mkv",
  "webm",
}

return function(cfg)
  -- Autocmd patterns are case-sensitive: also match "PHOTO.JPG".
  local exts, patterns = {}, {}
  for _, ext in ipairs(formats) do
    for _, e in ipairs({ ext, ext:upper() }) do
      exts[#exts + 1] = e
      patterns[#patterns + 1] = "*." .. e
    end
  end
  return {
    "folke/snacks.nvim",
    enabled = cfg.ui.image.enabled,
    event = { { event = "BufReadCmd", pattern = patterns } },
    opts = {
      image = {
        formats = exts,
        -- Only image files; no pictures drawn inside Markdown.
        doc = { enabled = false },
      },
    },
    config = function(_, opts)
      require("snacks").setup(opts)
      -- snacks.nvim fills the image buffer with placeholder lines, which
      -- marked it modified: closing it then asked to save the picture.
      -- (BufModifiedSet does not fire for these changes in every case.)
      local attached = {} ---@type table<integer, true>
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("wraithvim_image", { clear = true }),
        pattern = "image",
        callback = function(args)
          if attached[args.buf] then
            return
          end
          attached[args.buf] = true
          vim.api.nvim_buf_attach(args.buf, false, {
            on_lines = function(_, buf)
              vim.schedule(function()
                if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "image" then
                  vim.bo[buf].modified = false
                end
              end)
            end,
            on_detach = function(_, buf)
              attached[buf] = nil
            end,
          })
        end,
      })
    end,
  }
end
