local opt = vim.opt

opt.number         = true
opt.relativenumber = true
opt.signcolumn     = "yes"
opt.cursorline     = true
opt.termguicolors  = true
opt.showmode       = false
opt.laststatus     = 3      -- global statusline
opt.cmdheight      = 1
opt.pumheight      = 10
opt.scrolloff      = 8
opt.sidescrolloff  = 8
opt.splitbelow     = true
opt.splitright     = true
opt.wrap           = false

opt.tabstop        = 2
opt.shiftwidth     = 2
opt.softtabstop    = 2
opt.expandtab      = true
opt.smartindent    = true
opt.shiftround     = true

opt.hlsearch       = false
opt.incsearch      = true
opt.ignorecase     = true
opt.smartcase      = true

opt.swapfile       = false
opt.backup         = false
opt.undofile       = true
opt.undodir        = vim.fn.stdpath("data") .. "/undo"

opt.updatetime     = 200
opt.timeoutlen     = 300
opt.redrawtime     = 10000

opt.completeopt    = { "menuone", "noselect" }
opt.shortmess:append("c")

opt.fileencoding   = "utf-8"

opt.clipboard      = "unnamedplus"

opt.fillchars      = { eob = " " }

opt.foldmethod     = "expr"
opt.foldexpr       = "nvim_treesitter#foldexpr()"
opt.foldenable     = false
opt.foldlevel      = 99

local pairs_map = {
  ["("] = ")",
  ["["] = "]",
  ["{"] = "}",
  ['"'] = '"',
  ["'"] = "'",
  ["`"] = "`",
}

for open, close in pairs(pairs_map) do
  vim.keymap.set("i", open, function()
    local col  = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_get_current_line()
    local next  = line:sub(col + 1, col + 1)

    if open == close then
      if next == open then
        return "<Right>"
      end
      return open .. close .. "<Left>"
    end

    if next == close then
      return open .. close .. "<Left>"
    end

    return open .. close .. "<Left>"
  end, { expr = true, silent = true })

  if open ~= close then
    vim.keymap.set("i", close, function()
      local col  = vim.api.nvim_win_get_cursor(0)[2]
      local line = vim.api.nvim_get_current_line()
      local next  = line:sub(col + 1, col + 1)
      if next == close then return "<Right>" end
      return close
    end, { expr = true, silent = true })
  end
end

vim.keymap.set("i", "<BS>", function()
  local col  = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  local prev = line:sub(col, col)
  local next = line:sub(col + 1, col + 1)
  local pair_map = { ["("] = ")", ["["] = "]", ["{"] = "}", ['"'] = '"', ["'"] = "'", ["`"] = "`" }
  if pair_map[prev] and pair_map[prev] == next then
    return "<BS><Del>"
  end
  return "<BS>"
end, { expr = true, silent = true })

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() > 0 then
      vim.defer_fn(function()
        local ok_neo = pcall(vim.cmd, "Neotree show")
        local ok_aerial = pcall(vim.cmd, "AerialOpen")
        if ok_aerial then
          vim.cmd("wincmd p")
        end
      end, 100)
    end
  end,
})
