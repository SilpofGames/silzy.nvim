local silzy_path = vim.fn.stdpath("data") .. "/silzy/manager"
if vim.fn.empty(vim.fn.glob(silzy_path)) > 0 then
  vim.fn.system({
    "git", "clone", "--depth=1", "--filter=blob:none",
    "https://github.com/yourusername/silzy.nvim.git",
    silzy_path,
  })
end
vim.opt.runtimepath:prepend(silzy_path)

require("config.options")
require("config.keymaps")

if vim.fn.filereadable(vim.fn.stdpath("config") .. "/lua/config/keybinds.lua") == 1 then
  require("config.keybinds")
end

local silzy = require("silzy")
silzy.setup({ auto_install = true })

require("core")

silzy.load_plugins()
