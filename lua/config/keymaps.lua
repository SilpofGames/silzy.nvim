vim.g.mapleader      = " "
vim.g.maplocalleader = " "

local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true, noremap = true })
end

map("n", "<leader>w",  "<cmd>w<CR>",   "Save")
map("n", "<leader>q",  "<cmd>q<CR>",   "Quit")
map("n", "<leader>Q",  "<cmd>qa!<CR>", "Force Quit All")
map("n", "<leader>x",  "<cmd>x<CR>",   "Save & Quit")

map("n", "<C-h>", "<C-w>h", "Move to left window")
map("n", "<C-j>", "<C-w>j", "Move to lower window")
map("n", "<C-k>", "<C-w>k", "Move to upper window")
map("n", "<C-l>", "<C-w>l", "Move to right window")

map("n", "<C-Up>",    "<cmd>resize +2<CR>",          "Resize up")
map("n", "<C-Down>",  "<cmd>resize -2<CR>",          "Resize down")
map("n", "<C-Left>",  "<cmd>vertical resize -2<CR>", "Resize left")
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", "Resize right")

map("n", "<S-h>",      "<cmd>bprevious<CR>", "Prev buffer")
map("n", "<S-l>",      "<cmd>bnext<CR>",     "Next buffer")
map("n", "<leader>bd", "<cmd>bdelete<CR>",   "Delete buffer")

map("n", "<A-j>", "<cmd>m .+1<CR>==", "Move line down")
map("n", "<A-k>", "<cmd>m .-2<CR>==", "Move line up")
map("v", "<A-j>", ":m '>+1<CR>gv=gv", "Move selection down")
map("v", "<A-k>", ":m '<-2<CR>gv=gv", "Move selection up")

map("v", "<", "<gv", "Indent left")
map("v", ">", ">gv", "Indent right")

map("n", "<Esc>", "<cmd>noh<CR>", "Clear highlights")

map("n", "[d", vim.diagnostic.goto_prev,  "Prev diagnostic")
map("n", "]d", vim.diagnostic.goto_next,  "Next diagnostic")
map("n", "<leader>d", vim.diagnostic.open_float, "Float diagnostic")

map("n", "<leader>e", "<cmd>Neotree toggle<CR>", "Toggle file explorer")

map("n", "<leader>p", function()
  local ok, b = pcall(require, "telescope.builtin")
  if ok then
    b.find_files({ hidden = true, no_ignore = false })
  else
    vim.notify("[silzy] Telescope not loaded yet", vim.log.levels.WARN)
  end
end, "Find files")

map("n", "<leader>g", function()
  local ok, b = pcall(require, "telescope.builtin")
  if ok then b.live_grep({ additional_args = { "--hidden" } }) end
end, "Live grep")

map("n", "<leader>r", function()
  local ok, b = pcall(require, "telescope.builtin")
  if ok then b.oldfiles({ include_current_session = true }) end
end, "Recent files")

map("n", "<leader>b", function()
  local ok, b = pcall(require, "telescope.builtin")
  if ok then b.buffers() end
end, "Buffers")

map("n", "<leader>pm", "<cmd>SilzyOpen<CR>",      "Silzy: Plugin manager")
map("n", "<leader>pr", "<cmd>SilzyReload<CR>",    "Silzy: Reload config")
map("n", "<leader>ph", "<cmd>SilzyDashboard<CR>", "Silzy: Open dashboard")
