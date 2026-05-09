local silzy = require("silzy")

local function make_use(is_theme)
  return function(spec)
    if type(spec) == "string" then spec = { spec } end
    if is_theme then spec._is_theme = true end
    silzy.use(spec)
  end
end

local function load_file(path, env_extras)
  if vim.fn.filereadable(path) == 0 then return end
  local source, err = vim.fn.readfile(path)
  if not source then
    vim.notify("[silzy] Cannot read " .. path .. ": " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  local code = table.concat(source, "\n")
  local wrapped = "local use = ...\n" .. code
  local chunk, load_err = load(wrapped, "@" .. path)
  if not chunk then
    vim.notify("[silzy] Parse error in " .. path .. ": " .. tostring(load_err), vim.log.levels.ERROR)
    return
  end
  local ok, run_err = pcall(chunk, env_extras.use)
  if not ok then
    vim.notify("[silzy] Error in " .. path .. ": " .. tostring(run_err), vim.log.levels.ERROR)
  end
end

local base = vim.fn.stdpath("config") .. "/lua/core/"

load_file(base .. "plugins.lua",     { use = make_use(false) })
load_file(base .. "colorscheme.lua", { use = make_use(true)  })
