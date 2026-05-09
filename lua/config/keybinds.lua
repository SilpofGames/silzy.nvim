local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true, noremap = true })
end

map("n", "<leader>hello", function()
  vim.notify("keybinds.lua works!", vim.log.levels.INFO)
end, "Example keybind")
