local M = {}

function M.open(plugins, install_path)
  local lines = {
    "  silzy.nvim — Plugin Status",
    string.rep("─", 62),
    "",
  }

  local installed, missing = {}, {}

  for id, plugin in pairs(plugins) do
    local dir_ok = vim.fn.isdirectory(plugin.dir) == 1
    if dir_ok then
      table.insert(installed, { id = id, plugin = plugin })
    else
      table.insert(missing, { id = id, plugin = plugin })
    end
  end

  table.sort(installed, function(a, b) return a.id < b.id end)
  table.sort(missing,   function(a, b) return a.id < b.id end)

  table.insert(lines, string.format("  ✓ Installed  (%d)", #installed))
  table.insert(lines, "")
  for _, entry in ipairs(installed) do
    local lazy = entry.plugin.opt and "  [lazy]" or ""
    table.insert(lines, string.format("    ✓  %-40s%s", entry.id, lazy))
  end

  if #missing > 0 then
    table.insert(lines, "")
    table.insert(lines, string.format("  ✗ Missing  (%d)  — run :SilzyInstall", #missing))
    table.insert(lines, "")
    for _, entry in ipairs(missing) do
      table.insert(lines, string.format("    ✗  %s", entry.id))
    end
  end

  table.insert(lines, "")
  table.insert(lines, string.rep("─", 62))
  table.insert(lines, "  [i] Install missing   [u] Update all   [c] Clean   [q] Close")

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype    = "nofile"
  vim.bo[buf].filetype   = "silzy-status"

  local ns = vim.api.nvim_create_namespace("silzy_status")
  for i, line in ipairs(lines) do
    if line:match("^  ✓") then
      vim.api.nvim_buf_add_highlight(buf, ns, "DiagnosticOk",    i - 1, 0, -1)
    elseif line:match("^  ✗") then
      vim.api.nvim_buf_add_highlight(buf, ns, "DiagnosticError", i - 1, 0, -1)
    elseif line:match("^    ✓") then
      vim.api.nvim_buf_add_highlight(buf, ns, "DiagnosticOk",    i - 1, 0, 6)
    elseif line:match("^    ✗") then
      vim.api.nvim_buf_add_highlight(buf, ns, "DiagnosticError", i - 1, 0, 6)
    elseif line:match("silzy.nvim") then
      vim.api.nvim_buf_add_highlight(buf, ns, "Title",           i - 1, 0, -1)
    end
  end

  local width  = 66
  local height = math.min(#lines + 2, vim.o.lines - 4)
  local row    = math.floor((vim.o.lines - height) / 2)
  local col    = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row      = row,
    col      = col,
    width    = width,
    height   = height,
    style    = "minimal",
    border   = "rounded",
    title    = " silzy.nvim ",
    title_pos = "center",
  })

  vim.wo[win].cursorline = true

  local opts = { buffer = buf, silent = true, noremap = true }
  local silzy = require("silzy")

  vim.keymap.set("n", "q", function() vim.api.nvim_win_close(win, true) end, opts)
  vim.keymap.set("n", "<Esc>", function() vim.api.nvim_win_close(win, true) end, opts)
  vim.keymap.set("n", "i", function()
    vim.api.nvim_win_close(win, true)
    silzy.install()
  end, opts)
  vim.keymap.set("n", "u", function()
    vim.api.nvim_win_close(win, true)
    silzy.update()
  end, opts)
  vim.keymap.set("n", "c", function()
    vim.api.nvim_win_close(win, true)
    silzy.clean()
  end, opts)
end

return M
