local M = {}
local api = vim.api

local STATE = {
  plugins       = {},
  log           = {},
  active        = {},
  buf           = nil,
  win           = nil,
  ns            = api.nvim_create_namespace("silzy_manager"),
  tab           = "plugins",
  cs_cursor     = 1,
  cs_list       = {},
  cs_current    = nil,
}

local TABS = { "plugins", "colorschemes", "log" }

local function ts() return os.date("%H:%M:%S") end

local function box(str, w)
  local pad = math.max(math.floor((w - vim.fn.strwidth(str)) / 2), 0)
  return string.rep(" ", pad) .. str
end

local function save_colorscheme(name)
  local cs_file = vim.fn.stdpath("config") .. "/lua/core/colorscheme.lua"
  if vim.fn.filereadable(cs_file) == 0 then return end

  local lines = vim.fn.readfile(cs_file)
  local new_lines = {}
  local found = false

  for _, line in ipairs(lines) do
    local stripped = line:gsub("%s+", "")
    if stripped:match("vim%.cmd%(") and stripped:match("colorscheme") then
      local indent = line:match("^(%s*)")
      table.insert(new_lines, indent .. string.format('vim.cmd("colorscheme %s")', name))
      found = true
    else
      table.insert(new_lines, line)
    end
  end

  if found then
    vim.fn.writefile(new_lines, cs_file)
  else
    vim.notify("[silzy] Could not find colorscheme line in colorscheme.lua", vim.log.levels.WARN)
  end
end

local function get_installed_colorschemes()
  local install_path = vim.fn.stdpath("data") .. "/silzy/plugins"
  local schemes = {}
  local handle = vim.loop.fs_scandir(install_path)
  if not handle then return schemes end
  while true do
    local name, kind = vim.loop.fs_scandir_next(handle)
    if not name then break end
    if kind == "directory" then
      local colors_dir = install_path .. "/" .. name .. "/colors"
      local ch = vim.loop.fs_scandir(colors_dir)
      if ch then
        while true do
          local fname, fkind = vim.loop.fs_scandir_next(ch)
          if not fname then break end
          if fkind == "file" and fname:match("%.vim$") or fname:match("%.lua$") then
            local cs_name = fname:gsub("%.vim$", ""):gsub("%.lua$", "")
            table.insert(schemes, { name = cs_name, plugin = name })
          end
        end
      end
    end
  end
  table.sort(schemes, function(a, b) return a.name < b.name end)
  return schemes
end

local function render()
  if not STATE.buf or not api.nvim_buf_is_valid(STATE.buf) then return end

  local win_w = api.nvim_win_get_width(STATE.win)
  local lines  = {}
  local hls    = {}

  local function hl(lnum, group, col_s, col_e)
    table.insert(hls, { lnum = lnum, group = group, col_s = col_s, col_e = col_e or -1 })
  end

  local function push(str, group)
    table.insert(lines, str)
    if group then hl(#lines - 1, group, 0) end
  end

  push("")
  push(box("  silzy.nvim", win_w), "Title")
  push(box(string.rep("─", math.min(win_w - 2, 60)), win_w), "Comment")
  push("")

  local tab_labels = { plugins = "  Plugins", colorschemes = "  Colorschemes", log = "  Log" }
  local tab_line = ""
  for _, t in ipairs(TABS) do
    if STATE.tab == t then
      tab_line = tab_line .. "  [" .. tab_labels[t] .. "]  "
    else
      tab_line = tab_line .. "   " .. tab_labels[t] .. "   "
    end
  end
  push(box(tab_line, win_w))
  hl(#lines - 1, "Special", 0)
  push(box(string.rep("─", math.min(win_w - 2, 60)), win_w), "Comment")
  push("")

  if STATE.tab == "plugins" then
    local installed, missing, working = {}, {}, {}
    for id, plugin in pairs(STATE.plugins) do
      if STATE.active[id] then
        table.insert(working, { id = id, plugin = plugin })
      elseif vim.fn.isdirectory(plugin.dir) == 1 then
        table.insert(installed, { id = id, plugin = plugin })
      else
        table.insert(missing, { id = id, plugin = plugin })
      end
    end
    table.sort(installed, function(a, b) return a.id < b.id end)
    table.sort(missing,   function(a, b) return a.id < b.id end)
    table.sort(working,   function(a, b) return a.id < b.id end)

    if #working > 0 then
      push("  ⟳ Installing / Updating", "DiagnosticWarn")
      for _, e in ipairs(working) do push("    ⟳  " .. e.id, "DiagnosticWarn") end
      push("")
    end

    push(string.format("  ✓ Installed  (%d)", #installed), "DiagnosticOk")
    push("")
    for _, e in ipairs(installed) do
      local lazy = e.plugin.opt and "  lazy" or ""
      push(string.format("    ✓  %-42s%s", e.id, lazy), "DiagnosticOk")
    end

    if #missing > 0 then
      push("")
      push(string.format("  ✗ Missing  (%d)", #missing), "DiagnosticError")
      push("")
      for _, e in ipairs(missing) do push("    ✗  " .. e.id, "DiagnosticError") end
    end

    push("")
    push(box(string.rep("─", math.min(win_w - 2, 60)), win_w), "Comment")
    push(box("i = install   u = update   c = clean   r = reload   Tab = next tab   q = close", win_w), "Comment")
    push("")

  elseif STATE.tab == "colorschemes" then
    STATE.cs_list = get_installed_colorschemes()
    STATE.cs_current = vim.g.colors_name or ""

    if #STATE.cs_list == 0 then
      push(box("No colorschemes installed.", win_w), "Comment")
    else
      push("  Installed colorschemes  —  Enter to apply", "Comment")
      push("")
      for i, cs in ipairs(STATE.cs_list) do
        local is_active  = cs.name == STATE.cs_current
        local is_cursor  = i == STATE.cs_cursor
        local prefix = is_active and "  " or "   "
        local line = string.format("%s%-32s  %s", prefix, cs.name, cs.plugin)
        push(line)
        local lnum = #lines - 1
        if is_cursor and is_active then
          hl(lnum, "Title", 0)
        elseif is_cursor then
          hl(lnum, "PmenuSel", 0)
        elseif is_active then
          hl(lnum, "DiagnosticOk", 0)
        else
          hl(lnum, "Normal", 0)
        end
      end
    end

    push("")
    push(box(string.rep("─", math.min(win_w - 2, 60)), win_w), "Comment")
    push(box("j/k = navigate   Enter = apply   Tab = next tab   q = close", win_w), "Comment")
    push("")

  else
    local shown = math.min(#STATE.log, api.nvim_win_get_height(STATE.win) - 12)
    local start = math.max(1, #STATE.log - shown + 1)
    for i = start, #STATE.log do
      local entry = STATE.log[i]
      push("  " .. entry.time .. "  " .. entry.msg, entry.group)
    end
    if #STATE.log == 0 then push(box("no log entries yet", win_w), "Comment") end
    push("")
    push(box(string.rep("─", math.min(win_w - 2, 60)), win_w), "Comment")
    push(box("Tab = next tab   q = close", win_w), "Comment")
    push("")
  end

  vim.bo[STATE.buf].modifiable = true
  api.nvim_buf_set_lines(STATE.buf, 0, -1, false, lines)
  api.nvim_buf_clear_namespace(STATE.buf, STATE.ns, 0, -1)
  for _, h in ipairs(hls) do
    api.nvim_buf_add_highlight(STATE.buf, STATE.ns, h.group, h.lnum, h.col_s, h.col_e)
  end
  vim.bo[STATE.buf].modifiable = false
end

local function log_entry(msg, group)
  table.insert(STATE.log, { time = ts(), msg = msg, group = group or "Normal" })
  vim.schedule(render)
end

function M.open(plugins, install_path)
  STATE.plugins    = plugins
  STATE.log        = {}
  STATE.active     = {}
  STATE.tab        = "plugins"
  STATE.cs_cursor  = 1
  STATE.cs_list    = {}

  if STATE.buf and api.nvim_buf_is_valid(STATE.buf) then
    api.nvim_buf_delete(STATE.buf, { force = true })
  end

  STATE.buf = api.nvim_create_buf(false, true)
  vim.bo[STATE.buf].buftype   = "nofile"
  vim.bo[STATE.buf].bufhidden = "wipe"
  vim.bo[STATE.buf].filetype  = "silzy-manager"

  local width  = math.min(72, vim.o.columns - 4)
  local height = math.min(38, vim.o.lines - 4)
  local row    = math.floor((vim.o.lines   - height) / 2)
  local col    = math.floor((vim.o.columns - width)  / 2)

  STATE.win = api.nvim_open_win(STATE.buf, true, {
    relative  = "editor",
    row = row, col = col,
    width = width, height = height,
    style     = "minimal",
    border    = "rounded",
    title     = " silzy.nvim ",
    title_pos = "center",
  })

  vim.wo[STATE.win].cursorline = true
  vim.wo[STATE.win].wrap       = false

  render()

  local silzy = require("silzy")
  local opts  = { buffer = STATE.buf, silent = true, noremap = true }

  local function close()
    if STATE.win and api.nvim_win_is_valid(STATE.win) then
      api.nvim_win_close(STATE.win, true)
    end
  end

  local function next_tab()
    for i, t in ipairs(TABS) do
      if t == STATE.tab then
        STATE.tab = TABS[(i % #TABS) + 1]
        render()
        return
      end
    end
  end

  local function do_install()
    STATE.tab = "log"
    log_entry("Starting install...", "DiagnosticInfo")
    local orig_log = vim.notify
    vim.notify = function(msg, level)
      local group = "Normal"
      if msg:match("✓") then group = "DiagnosticOk"
      elseif msg:match("✗") then group = "DiagnosticError"
      elseif msg:match("Installing") then
        group = "DiagnosticWarn"
        local id = msg:match("Installing (.+)%.%.%.")
        if id then STATE.active[id] = true end
      end
      log_entry(msg:gsub("%[silzy%] ", ""), group)
    end
    silzy.install(function()
      vim.notify = orig_log
      STATE.active = {}
      log_entry("Done.", "DiagnosticOk")
      STATE.tab = "plugins"
      render()
    end)
    render()
  end

  local function do_update()
    STATE.tab = "log"
    log_entry("Starting update...", "DiagnosticInfo")
    local orig_log = vim.notify
    vim.notify = function(msg, _)
      local group = msg:match("✓") and "DiagnosticOk" or "Normal"
      log_entry(msg:gsub("%[silzy%] ", ""), group)
    end
    silzy.update()
    vim.defer_fn(function()
      vim.notify = orig_log
      log_entry("Update complete.", "DiagnosticOk")
      STATE.tab = "plugins"
      render()
    end, 8000)
    render()
  end

  local function do_clean()
    silzy.clean()
    log_entry("Clean complete.", "DiagnosticOk")
    render()
  end

  local function do_reload()
    close()
    local s = require("silzy")
    s._loaded  = {}
    s._plugins = {}
    for k in pairs(package.loaded) do
      if k:match("^silzy") or k:match("^core") then
        package.loaded[k] = nil
      end
    end
    dofile(vim.fn.stdpath("config") .. "/init.lua")
    vim.notify("[silzy] Reloaded.", vim.log.levels.INFO)
  end

  vim.keymap.set("n", "q",     close,    opts)
  vim.keymap.set("n", "<Esc>", close,    opts)
  vim.keymap.set("n", "<Tab>", next_tab, opts)
  vim.keymap.set("n", "i",     do_install, opts)
  vim.keymap.set("n", "u",     do_update,  opts)
  vim.keymap.set("n", "c",     do_clean,   opts)
  vim.keymap.set("n", "r",     do_reload,  opts)

  vim.keymap.set("n", "p", function()
    STATE.tab = "plugins"; render()
  end, opts)
  vim.keymap.set("n", "l", function()
    STATE.tab = "log"; render()
  end, opts)
  vim.keymap.set("n", "s", function()
    STATE.tab = "colorschemes"
    STATE.cs_list   = get_installed_colorschemes()
    STATE.cs_cursor = 1
    for i, cs in ipairs(STATE.cs_list) do
      if cs.name == (vim.g.colors_name or "") then
        STATE.cs_cursor = i
        break
      end
    end
    render()
  end, opts)

  vim.keymap.set("n", "j", function()
    if STATE.tab == "colorschemes" and #STATE.cs_list > 0 then
      STATE.cs_cursor = math.min(STATE.cs_cursor + 1, #STATE.cs_list)
      render()
    else
      vim.cmd("normal! j")
    end
  end, opts)

  vim.keymap.set("n", "k", function()
    if STATE.tab == "colorschemes" and #STATE.cs_list > 0 then
      STATE.cs_cursor = math.max(STATE.cs_cursor - 1, 1)
      render()
    else
      vim.cmd("normal! k")
    end
  end, opts)

  vim.keymap.set("n", "<CR>", function()
    if STATE.tab == "colorschemes" and #STATE.cs_list > 0 then
      local cs = STATE.cs_list[STATE.cs_cursor]
      if cs then
        local ok, err = pcall(vim.cmd, "colorscheme " .. cs.name)
        if ok then
          STATE.cs_current = cs.name
          save_colorscheme(cs.name)
          log_entry("Applied colorscheme: " .. cs.name, "DiagnosticOk")
          render()
        else
          log_entry("Failed to apply " .. cs.name .. ": " .. tostring(err), "DiagnosticError")
        end
      end
    end
  end, opts)
end

return M
