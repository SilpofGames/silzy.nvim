local M = {}

local languages = {
  { key = "1", icon = "☕", label = "Java",       id = "java"   },
  { key = "2", icon = "󰙱 ", label = "C",          id = "c"      },
  { key = "3", icon = "󰙲 ", label = "C++",        id = "cpp"    },
  { key = "4", icon = "󰌛 ", label = "C#",         id = "csharp" },
  { key = "5", icon = "🐍", label = "Python",     id = "python" },
  { key = "6", icon = "🌙", label = "Lua",        id = "lua"    },
  { key = "7", icon = "󰌞 ", label = "JavaScript", id = "js"     },
  { key = "8", icon = "󰛦 ", label = "TypeScript", id = "ts"     },
  { key = "9", icon = "🦀", label = "Rust",       id = "rust"   },
  { key = "0", icon = "🐹", label = "Go",         id = "go"     },
  { key = "r", icon = "💎", label = "Ruby",       id = "ruby"   },
  { key = "z", icon = "⚡", label = "Zig",        id = "zig"    },
  { key = "m", icon = "  ", label = "Minimal",    id = "minimal"},
}

local function open_native_wizard(callback)
  local selected = {}
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].buftype    = "nofile"
  vim.bo[buf].bufhidden  = "wipe"
  vim.bo[buf].modifiable = true

  local ns  = vim.api.nvim_create_namespace("silzy_wizard")
  local width = vim.o.columns

  local function center(str)
    local pad = math.floor((width - vim.fn.strwidth(str)) / 2)
    return string.rep(" ", math.max(pad, 0)) .. str
  end

  local function render()
    vim.bo[buf].modifiable = true
    local lines = { "", "", "" }
    table.insert(lines, center("  Choose your languages  (space = toggle, enter = confirm)"))
    table.insert(lines, "")
    table.insert(lines, center(string.rep("─", 44)))
    table.insert(lines, "")

    local item_lines = {}
    for _, lang in ipairs(languages) do
      local tick = selected[lang.id] and "  " or "  "
      local line = center(string.format("  %s  %s %s", tick, lang.icon, lang.label))
      table.insert(lines, line)
      table.insert(item_lines, { lnum = #lines - 1, lang = lang })
      table.insert(lines, "")
    end

    table.insert(lines, center(string.rep("─", 44)))
    table.insert(lines, "")
    local sel_labels = {}
    for _, lang in ipairs(languages) do
      if selected[lang.id] then table.insert(sel_labels, lang.label) end
    end
    local sel_str = #sel_labels > 0 and table.concat(sel_labels, ", ") or "none"
    table.insert(lines, center("Selected: " .. sel_str))
    table.insert(lines, "")

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false

    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for _, entry in ipairs(item_lines) do
      local hl = selected[entry.lang.id] and "DiagnosticOk" or "Comment"
      vim.api.nvim_buf_add_highlight(buf, ns, hl, entry.lnum, 0, -1)
    end

    return item_lines
  end

  local item_lines = render()

  vim.wo.number         = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn     = "no"
  vim.wo.cursorline     = false

  local function bmap(key, fn)
    vim.keymap.set("n", key, fn, { buffer = buf, silent = true, noremap = true })
  end

  bmap("j", function()
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    for _, e in ipairs(item_lines) do
      if e.lnum > row then vim.api.nvim_win_set_cursor(0, { e.lnum + 1, 0 }); return end
    end
    vim.api.nvim_win_set_cursor(0, { item_lines[1].lnum + 1, 0 })
  end)

  bmap("k", function()
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    for i = #item_lines, 1, -1 do
      if item_lines[i].lnum < row then vim.api.nvim_win_set_cursor(0, { item_lines[i].lnum + 1, 0 }); return end
    end
    vim.api.nvim_win_set_cursor(0, { item_lines[#item_lines].lnum + 1, 0 })
  end)

  bmap("<Space>", function()
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    for _, e in ipairs(item_lines) do
      if e.lnum == row then
        selected[e.lang.id] = not selected[e.lang.id]
        item_lines = render()
        return
      end
    end
  end)

  bmap("<CR>", function()
    local ids = {}
    for _, lang in ipairs(languages) do
      if selected[lang.id] then table.insert(ids, lang.id) end
    end
    if #ids == 0 then
      vim.notify("[silzy] Select at least one language", vim.log.levels.WARN)
      return
    end
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    vim.schedule(function() callback(ids) end)
  end)

  if item_lines[1] then
    vim.api.nvim_win_set_cursor(0, { item_lines[1].lnum + 1, 0 })
  end
end

function M.start(callback)
  open_native_wizard(function(ids)
    local labels = {}
    for _, lang in ipairs(languages) do
      if vim.tbl_contains(ids, lang.id) then
        table.insert(labels, lang.label)
      end
    end
    vim.notify("[silzy] Setting up for: " .. table.concat(labels, ", "), vim.log.levels.INFO)
    callback(ids)
  end)
end

return M
