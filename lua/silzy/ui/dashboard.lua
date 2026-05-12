local M = {}

local header = {
  "                           ",
  "  ▄▄▄▄▄     ▄▄             ",
  " ██▀▀▀▀█▄    ██            ",
  " ▀██▄  ▄▀ ▀▀ ██            ",
  "   ▀██▄▄  ██ ██ ▀▀▀██ ██ ██",
  " ▄   ▀██▄ ██ ██   ▄█▀ ██▄██",
  " ▀█████▀▄██▄██▄▄██▄▄▄▄▀██▀",
  "                        ██ ",
  "                      ▀▀▀  ",
}

local snacks_keys = {
  { icon = " ", key = "n", desc = "New File",    action = function() vim.cmd("enew") end },
  { icon = " ", key = "f", desc = "Find File",   action = function()
      vim.defer_fn(function()
        local ok, b = pcall(require, "telescope.builtin")
        if ok then b.find_files({ hidden = true }) end
      end, 50)
    end },
  { icon = " ", key = "r", desc = "Recent Files", action = function()
      vim.defer_fn(function()
        local ok, b = pcall(require, "telescope.builtin")
        if ok then b.oldfiles({ include_current_session = true }) end
      end, 50)
    end },
  { icon = " ", key = "q", desc = "Quit",         action = function() vim.cmd("qa") end },
}

local function center(str, width)
  local pad = math.floor((width - vim.fn.strwidth(str)) / 2)
  return string.rep(" ", math.max(pad, 0)) .. str
end

local function open_native()
  if vim.fn.argc() > 0 then return end
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  if name ~= "" then return end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if #lines > 1 or (#lines == 1 and lines[1] ~= "") then return end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].buftype    = "nofile"
  vim.bo[buf].bufhidden  = "wipe"
  vim.bo[buf].swapfile   = false
  vim.bo[buf].filetype   = "silzy-dashboard"
  vim.bo[buf].modifiable = true

  local width = vim.o.columns
  local ns    = vim.api.nvim_create_namespace("silzy_dashboard")

  local menu = {
    { key = "n", label = "  New File",     fn = function() vim.cmd("enew") end },
    { key = "f", label = "  Find File",    fn = function()
        vim.defer_fn(function()
          local ok, b = pcall(require, "telescope.builtin")
          if ok then b.find_files({ hidden = true })
          else vim.ui.input({ prompt = "file: " }, function(q) if q then vim.cmd("edit " .. q) end end) end
        end, 50)
      end },
    { key = "r", label = "  Recent Files", fn = function()
        vim.defer_fn(function()
          local ok, b = pcall(require, "telescope.builtin")
          if ok then b.oldfiles({ include_current_session = true }) end
        end, 50)
      end },
    { key = "q", label = "  Quit",         fn = function() vim.cmd("qa") end },
  }

  local lines = {}
  local top_pad = math.max(math.floor((vim.o.lines - #header - #menu * 2 - 7) / 2), 1)

  for _ = 1, top_pad do table.insert(lines, "") end
  for _, h in ipairs(header) do table.insert(lines, center(h, width)) end

  table.insert(lines, "")
  local divider = center(string.rep("─", 28), width)
  table.insert(lines, divider)
  table.insert(lines, "")

  local menu_line_indices = {}
  for _, item in ipairs(menu) do
    table.insert(lines, center(item.label, width))
    table.insert(menu_line_indices, { line_nr = #lines - 1, item = item })
    table.insert(lines, "")
  end

  table.insert(lines, divider)
  table.insert(lines, "")
  table.insert(lines, center("silzy.nvim", width))
  table.insert(lines, "")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  for i = 1, #header do
    vim.api.nvim_buf_add_highlight(buf, ns, "Function", top_pad + i - 1, 0, -1)
  end

  local div1 = top_pad + #header
  local div2 = top_pad + #header + 2 + #menu * 2
  vim.api.nvim_buf_add_highlight(buf, ns, "Comment", div1, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, ns, "Comment", div2, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, ns, "Comment", #lines - 2, 0, -1)

  for _, entry in ipairs(menu_line_indices) do
    vim.api.nvim_buf_add_highlight(buf, ns, "Identifier", entry.line_nr, 0, -1)
  end

  local function bmap(key, fn)
    vim.keymap.set("n", key, fn, { buffer = buf, silent = true, noremap = true })
  end

  for _, item in ipairs(menu) do
    bmap(item.key, function()
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
      vim.schedule(item.fn)
    end)
  end

  for _, key in ipairs({ "i", "a", "o", "x", "d", "c", "u", "p", "v", "V", "<C-v>" }) do
    bmap(key, function() end)
  end

  vim.wo.cursorline     = false
  vim.wo.number         = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn     = "no"
  vim.wo.statuscolumn   = ""

  local hl_cur = nil
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = function()
      if hl_cur then pcall(vim.api.nvim_buf_del_extmark, buf, ns, hl_cur) end
      local row = vim.api.nvim_win_get_cursor(0)[1] - 1
      hl_cur = vim.api.nvim_buf_set_extmark(buf, ns, row, 0, { line_hl_group = "CursorLine" })
    end,
  })

  bmap("<CR>", function()
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    for _, entry in ipairs(menu_line_indices) do
      if entry.line_nr == row then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
        vim.schedule(entry.item.fn)
        return
      end
    end
  end)

  bmap("j", function()
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    for _, entry in ipairs(menu_line_indices) do
      if entry.line_nr > row then
        vim.api.nvim_win_set_cursor(0, { entry.line_nr + 1, 0 })
        return
      end
    end
    vim.api.nvim_win_set_cursor(0, { menu_line_indices[1].line_nr + 1, 0 })
  end)

  bmap("k", function()
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    for i = #menu_line_indices, 1, -1 do
      if menu_line_indices[i].line_nr < row then
        vim.api.nvim_win_set_cursor(0, { menu_line_indices[i].line_nr + 1, 0 })
        return
      end
    end
    vim.api.nvim_win_set_cursor(0, { menu_line_indices[#menu_line_indices].line_nr + 1, 0 })
  end)

  local mid = menu_line_indices[math.ceil(#menu_line_indices / 2)]
  if mid then pcall(vim.api.nvim_win_set_cursor, 0, { mid.line_nr + 1, 0 }) end
end

local function open_with_snacks()
  require("snacks").dashboard.open({
    preset = {
      header = table.concat(header, "\n"),
      keys   = snacks_keys,
    },
    sections = {
      { section = "header" },
      { section = "keys", gap = 1, padding = 1 },
      { text = { { "\n  silzy.nvim\n", hl = "Comment" } }, padding = 1 },
    },
  })
end

local function open_with_alpha()
  local ok, alpha = pcall(require, "alpha")
  if not ok then return open_native() end
  local dashboard = require("alpha.themes.dashboard")
  
  -- Clear existing header to avoid duplicates if re-opened
  dashboard.section.header.val = header
  dashboard.section.buttons.val = {
    dashboard.button("n", "  New File",     ":enew<CR>"),
    dashboard.button("f", "  Find File",    ":Telescope find_files<CR>"),
    dashboard.button("r", "  Recent Files", ":Telescope oldfiles<CR>"),
    dashboard.button("q", "  Quit",         ":qa<CR>"),
  }
  dashboard.section.footer.val = { " ", "silzy.nvim" }
  dashboard.section.footer.opts.hl = "Comment"
  
  alpha.setup(dashboard.opts)
  vim.cmd("Alpha")
end

function M.setup()
  vim.api.nvim_create_autocmd("VimEnter", {
    once     = true,
    callback = function()
      if vim.fn.argc() > 0 then return end
      vim.schedule(function()
        M.open()
      end)
    end,
  })
end

function M.open()
  local config = require("silzy").config or {}
  local preferred = config.dashboard or "auto"

  if preferred == "snacks" then
    return open_with_snacks()
  elseif preferred == "alpha" then
    return open_with_alpha()
  elseif preferred == "native" then
    return open_native()
  end

  -- auto detection
  local has_snacks = pcall(require, "snacks.dashboard")
  if has_snacks then
    open_with_snacks()
  else
    local has_alpha = pcall(require, "alpha")
    if has_alpha then
      open_with_alpha()
    else
      open_native()
    end
  end
end

return M
