local M = {}
local api = vim.api

local STATE = {
  plugins  = {},
  log      = {},
  active   = {},
  buf      = nil,
  win      = nil,
  ns       = api.nvim_create_namespace("silzy_manager"),
  tab      = "plugins",
}

local function ts() return os.date("%H:%M:%S") end

local function box(str, w)
  local pad = math.max(math.floor((w - vim.fn.strwidth(str)) / 2), 0)
  return string.rep(" ", pad) .. str
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

  local tabs = { plugins = "  Plugins", log = "  Log" }
  local tab_line = ""
  for _, t in ipairs({ "plugins", "log" }) do
    if STATE.tab == t then
      tab_line = tab_line .. "  [" .. tabs[t] .. "]  "
    else
      tab_line = tab_line .. "   " .. tabs[t] .. "   "
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
    table.sort(installed, function(a,b) return a.id < b.id end)
    table.sort(missing,   function(a,b) return a.id < b.id end)
    table.sort(working,   function(a,b) return a.id < b.id end)

    if #working > 0 then
      push("  ⟳ Installing / Updating", "DiagnosticWarn")
      for _, e in ipairs(working) do
        push("    ⟳  " .. e.id, "DiagnosticWarn")
      end
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
      for _, e in ipairs(missing) do
        push("    ✗  " .. e.id, "DiagnosticError")
      end
    end

    push("")
    push(box(string.rep("─", math.min(win_w - 2, 60)), win_w), "Comment")
    push(box("i = install   u = update   c = clean   r = reload   q = close", win_w), "Comment")
    push("")

  else
    local shown = math.min(#STATE.log, api.nvim_win_get_height(STATE.win) - 12)
    local start = math.max(1, #STATE.log - shown + 1)
    for i = start, #STATE.log do
      local entry = STATE.log[i]
      push("  " .. entry.time .. "  " .. entry.msg, entry.group)
    end
    if #STATE.log == 0 then
      push(box("no log entries yet", win_w), "Comment")
    end
    push("")
    push(box(string.rep("─", math.min(win_w - 2, 60)), win_w), "Comment")
    push(box("p = plugins tab   q = close", win_w), "Comment")
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
  STATE.plugins = plugins
  STATE.log     = {}
  STATE.active  = {}
  STATE.tab     = "plugins"

  if STATE.buf and api.nvim_buf_is_valid(STATE.buf) then
    api.nvim_buf_delete(STATE.buf, { force = true })
  end

  STATE.buf = api.nvim_create_buf(false, true)
  vim.bo[STATE.buf].buftype   = "nofile"
  vim.bo[STATE.buf].bufhidden = "wipe"
  vim.bo[STATE.buf].filetype  = "silzy-manager"

  local width  = math.min(70, vim.o.columns - 4)
  local height = math.min(36, vim.o.lines - 4)
  local row    = math.floor((vim.o.lines   - height) / 2)
  local col    = math.floor((vim.o.columns - width)  / 2)

  STATE.win = api.nvim_open_win(STATE.buf, true, {
    relative  = "editor",
    row = row, col = col,
    width = width, height = height,
    style  = "minimal",
    border = "rounded",
    title  = " silzy.nvim ",
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
    vim.notify("[silzy] Reloading...", vim.log.levels.INFO)
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

  vim.keymap.set("n", "q",     close,      opts)
  vim.keymap.set("n", "<Esc>", close,      opts)
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
  vim.keymap.set("n", "<Tab>", function()
    STATE.tab = STATE.tab == "plugins" and "log" or "plugins"
    render()
  end, opts)
end

return M
