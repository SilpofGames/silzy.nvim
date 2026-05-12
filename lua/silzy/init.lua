local M = {}

M.version  = "0.1.0"
M._plugins = {}
M._loaded  = {}
M._profile = {}
M._initialized = false

local state_path   = vim.fn.stdpath("data") .. "/silzy/state.json"
local install_path = vim.fn.stdpath("data") .. "/silzy/plugins"

local function log(msg, level)
  level = level or vim.log.levels.INFO
  vim.notify("[silzy] " .. msg, level)
end

local function record_project()
  local cwd = vim.fn.getcwd()
  local function r_state()
    if vim.fn.filereadable(state_path) == 0 then return {} end
    local ok, data = pcall(vim.fn.readfile, state_path)
    if not ok then return {} end
    return vim.fn.json_decode(table.concat(data, "\n")) or {}
  end
  local function w_state(s)
    vim.fn.writefile({ vim.fn.json_encode(s) }, state_path)
  end
  local state = r_state()
  state.projects = state.projects or {}
  for i, p in ipairs(state.projects) do
    if p == cwd then table.remove(state.projects, i); break end
  end
  table.insert(state.projects, 1, cwd)
  if #state.projects > 10 then table.remove(state.projects) end
  w_state(state)
end

local function is_first_run()
  return vim.fn.filereadable(state_path) == 0
end

local function ensure_dirs()
  vim.fn.mkdir(install_path, "p")
  vim.fn.mkdir(vim.fn.fnamemodify(state_path, ":h"), "p")
end

local function read_state()
  if vim.fn.filereadable(state_path) == 0 then return {} end
  local ok, data = pcall(vim.fn.readfile, state_path)
  if not ok then return {} end
  local decoded = vim.fn.json_decode(table.concat(data, "\n"))
  return decoded or {}
end

local function write_state(state)
  vim.fn.writefile({ vim.fn.json_encode(state) }, state_path)
end

local function parse_spec(spec)
  if type(spec) == "string" then spec = { spec } end
  local id = spec[1]
  assert(type(id) == "string", "[silzy] Plugin spec must have a 'owner/repo' string as first element")
  local owner, name = id:match("^([^/]+)/([^/]+)$")
  assert(owner and name, "[silzy] Invalid plugin format: '" .. id .. "'")
  local alias     = spec.as or nil
  local safe_name = alias or (owner .. "-" .. name)
  return {
    id               = id,
    owner            = owner,
    name             = safe_name,
    opt              = spec.opt or false,
    branch           = spec.branch or "main",
    _explicit_branch = spec.branch ~= nil,
    tag              = spec.tag or nil,
    build            = spec.build or spec.run or nil,
    deps             = spec.dependencies or spec.requires or {},
    config           = spec.config or nil,
    init             = spec.init or nil,
    event            = spec.event or nil,
    cmd              = spec.cmd or nil,
    ft               = spec.ft or nil,
    keys             = spec.keys or nil,
    pin              = spec.pin or false,
    _is_theme        = spec._is_theme or false,
    dir              = install_path .. "/" .. safe_name,
  }
end

function M.use(spec)
  local ok, parsed = pcall(parse_spec, spec)
  if not ok then log(parsed, vim.log.levels.ERROR); return end
  if parsed.deps and #parsed.deps > 0 then
    for _, dep in ipairs(parsed.deps) do M.use(dep) end
  end
  M._plugins[parsed.id] = parsed
end

local function add_to_rtp(dir)
  if vim.fn.isdirectory(dir) == 1 then
    vim.opt.runtimepath:append(dir)
    local after = dir .. "/after"
    if vim.fn.isdirectory(after) == 1 then
      vim.opt.runtimepath:append(after)
    end
  end
end

local function load_plugin(plugin)
  if M._loaded[plugin.id] then return end
  local start_time = vim.loop.hrtime()
  M._loaded[plugin.id] = true
  if vim.fn.isdirectory(plugin.dir) == 0 then return end
  add_to_rtp(plugin.dir)
  if plugin.init then
    local ok, err = pcall(plugin.init)
    if not ok then log("init() error in " .. plugin.id .. ": " .. err, vim.log.levels.ERROR) end
  end
  if plugin.config and not plugin.opt then
    local ok, err = pcall(plugin.config)
    if not ok then log("config() error in " .. plugin.id .. ": " .. err, vim.log.levels.ERROR) end
  end
  local end_time = vim.loop.hrtime()
  M._profile[plugin.id] = (end_time - start_time) / 1e6
end

local function load_all_into_rtp()
  local handle = vim.loop.fs_scandir(install_path)
  if not handle then return end
  while true do
    local name, kind = vim.loop.fs_scandir_next(handle)
    if not name then break end
    if kind == "directory" then
      add_to_rtp(install_path .. "/" .. name)
    end
  end
end

function M.load_plugins()
  load_all_into_rtp()

  if M._first_run then
    vim.defer_fn(function()
      require("silzy.ui.wizard").start(function(chosen_langs)
        write_state({ langs = chosen_langs, installed_at = os.time() })
        require("silzy.langs").apply(chosen_langs, M.use)
        M.install(function()
          load_all_into_rtp()
          for _, plugin in pairs(M._plugins) do
            load_plugin(plugin)
          end
        end)
      end)
    end, 200)
    return
  end

  if M._auto_install then
    vim.defer_fn(function() M.install() end, 500)
  end

  local themes, rest = {}, {}
  for _, plugin in pairs(M._plugins) do
    if plugin._is_theme then
      table.insert(themes, plugin)
    else
      table.insert(rest, plugin)
    end
  end

  for _, plugin in ipairs(rest) do
    if not plugin.opt then load_plugin(plugin) end
  end

  for _, plugin in ipairs(themes) do
    load_plugin(plugin)
  end

  for _, plugin in pairs(M._plugins) do
    if plugin.opt then
      if plugin.event then
        local events = type(plugin.event) == "string" and { plugin.event } or plugin.event
        vim.api.nvim_create_autocmd(events, {
          once = true,
          callback = function() load_plugin(plugin) end,
        })
      end
      if plugin.cmd then
        local cmds = type(plugin.cmd) == "string" and { plugin.cmd } or plugin.cmd
        for _, cmd in ipairs(cmds) do
          vim.api.nvim_create_user_command(cmd, function(args)
            load_plugin(plugin)
            vim.cmd(cmd .. " " .. args.args)
          end, { nargs = "*" })
        end
      end
      if plugin.ft then
        local fts = type(plugin.ft) == "string" and { plugin.ft } or plugin.ft
        vim.api.nvim_create_autocmd("FileType", {
          pattern = fts,
          once = true,
          callback = function() load_plugin(plugin) end,
        })
      end
    end
  end
end

function M.install(on_done)
  local to_install = {}
  for _, plugin in pairs(M._plugins) do
    if vim.fn.isdirectory(plugin.dir) == 0 then
      table.insert(to_install, plugin)
    end
  end

  if #to_install == 0 then
    log("All plugins are up to date.")
    if on_done then on_done() end
    return
  end

  local total  = #to_install
  local done   = 0
  local failed = {}

  local function on_all_done()
    if #failed > 0 then
      log("Installed " .. (total - #failed) .. "/" .. total .. " plugins. Failed: " .. table.concat(failed, ", "), vim.log.levels.WARN)
    else
      log("All " .. total .. " plugins installed.")
    end
    if on_done then on_done() end
  end

  for _, plugin in ipairs(to_install) do
    local id  = plugin.id
    local url = "https://github.com/" .. id .. ".git"
    local args = { "git", "clone", "--depth=1", "--filter=blob:none" }
    if plugin.tag then
      vim.list_extend(args, { "--branch", plugin.tag })
    elseif plugin._explicit_branch then
      vim.list_extend(args, { "--branch", plugin.branch })
    end
    vim.list_extend(args, { url, plugin.dir })
    log("Installing " .. id .. "...")
    vim.fn.jobstart(args, {
      stdout_buffered = true,
      stderr_buffered = true,
      on_exit = vim.schedule_wrap(function(_, code)
        done = done + 1
        if code == 0 then
          log("✓ Installed " .. id)
          if plugin.build then
            local build_cmd = type(plugin.build) == "string" and { "sh", "-c", plugin.build } or plugin.build
            vim.fn.jobstart(build_cmd, { cwd = plugin.dir })
          end
        else
          table.insert(failed, id)
          vim.fn.delete(plugin.dir, "rf")
          log("✗ Failed to install " .. id, vim.log.levels.ERROR)
        end
        if done == total then on_all_done() end
      end),
    })
  end
end

function M.update()
  local to_update = {}
  for _, plugin in pairs(M._plugins) do
    if vim.fn.isdirectory(plugin.dir) == 1 and not plugin.pin then
      table.insert(to_update, plugin)
    end
  end
  if #to_update == 0 then log("No plugins to update."); return end
  local total = #to_update
  local done  = 0
  for _, plugin in ipairs(to_update) do
    local id = plugin.id
    vim.fn.jobstart({ "git", "-C", plugin.dir, "pull", "--ff-only" }, {
      stdout_buffered = true,
      stderr_buffered = true,
      on_exit = vim.schedule_wrap(function(_, code)
        done = done + 1
        if code == 0 then log("✓ Updated " .. id)
        else log("~ " .. id .. ": up to date") end
        if done == total then log("Update complete.") end
      end),
    })
  end
end

function M.clean()
  local handle = vim.loop.fs_scandir(install_path)
  if not handle then return end
  local registered = {}
  for _, p in pairs(M._plugins) do registered[p.name] = true end
  while true do
    local name, kind = vim.loop.fs_scandir_next(handle)
    if not name then break end
    if kind == "directory" and not registered[name] then
      vim.fn.delete(install_path .. "/" .. name, "rf")
      log("Cleaned: " .. name)
    end
  end
end

local function bootstrap_sync(id)
  local owner, name = id:match("^([^/]+)/(.+)$")
  local safe_name = owner .. "-" .. name
  local dir  = install_path .. "/" .. safe_name
  if vim.fn.isdirectory(dir) == 1 then return dir end
  vim.notify("[silzy] Bootstrapping " .. id .. "...", vim.log.levels.INFO)
  vim.fn.system({ "git", "clone", "--depth=1", "--filter=blob:none",
    "https://github.com/" .. id .. ".git", dir })
  if vim.v.shell_error ~= 0 then
    vim.notify("[silzy] Failed to bootstrap " .. id, vim.log.levels.ERROR)
    return nil
  end
  return dir
end

function M.setup(opts)
  M.config = opts or {}
  opts = M.config
  ensure_dirs()
  record_project()

  local snacks_dir  = bootstrap_sync("folke/snacks.nvim")
  local alpha_dir   = bootstrap_sync("goolord/alpha-nvim")
  local plenary_dir = bootstrap_sync("nvim-lua/plenary.nvim")
  
  if snacks_dir  then add_to_rtp(snacks_dir)  end
  if alpha_dir   then add_to_rtp(alpha_dir)   end
  if plenary_dir then add_to_rtp(plenary_dir) end

  vim.api.nvim_create_user_command("SilzyInstall",   function() M.install() end, {})
  vim.api.nvim_create_user_command("SilzyUpdate",    function() M.update()  end, {})
  vim.api.nvim_create_user_command("SilzyClean",     function() M.clean()   end, {})
  vim.api.nvim_create_user_command("SilzyDashboard", function() require("silzy.ui.dashboard").open() end, {})
  vim.api.nvim_create_user_command("SilzyOpen", function()
    require("silzy.ui.manager").open(M._plugins, install_path)
  end, {})
  vim.api.nvim_create_user_command("SilzyReload", function()
    M._loaded  = {}
    M._plugins = {}
    for k in pairs(package.loaded) do
      if k:match("^silzy") or k:match("^core") then
        package.loaded[k] = nil
      end
    end
    dofile(vim.fn.stdpath("config") .. "/init.lua")
    vim.notify("[silzy] Reloaded.", vim.log.levels.INFO)
  end, {})

  require("silzy.ui.dashboard").setup()

  local core_dir = vim.fn.stdpath("config") .. "/lua/core"
  local watch_handle = vim.loop.new_fs_event()
  local _debounce_timer = nil
  watch_handle:start(core_dir, { recursive = true }, vim.schedule_wrap(function(err, fname, _)
    if err or not fname then return end
    if not fname:match("%.lua$") then return end
    if _debounce_timer then
      _debounce_timer:stop()
      _debounce_timer:close()
    end
    _debounce_timer = vim.loop.new_timer()
    _debounce_timer:start(120, 0, vim.schedule_wrap(function()
      _debounce_timer:close()
      _debounce_timer = nil
      vim.notify("[silzy] " .. fname .. " changed — reloading...", vim.log.levels.INFO)
      M._loaded = {}
      M._plugins = {}
      for k in pairs(package.loaded) do
        if k:match("^silzy") or k:match("^core") then
          package.loaded[k] = nil
        end
      end
      dofile(vim.fn.stdpath("config") .. "/init.lua")
    end))
  end))

  M._initialized = true

  M._first_run = is_first_run()
  M._auto_install = opts.auto_install ~= false
end

return M
