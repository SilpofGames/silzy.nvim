# silzy.nvim Windows Installer
# Run with: iwr -useb https://raw.githubusercontent.com/SilpofGames/silzy.nvim/main/scripts/install.ps1 | iex

$ErrorActionPreference = "Stop"

$REPO_URL      = "https://github.com/SilpofGames/silzy.nvim.git"
$NVIM_DATA     = "$env:LOCALAPPDATA\nvim-data"
$SILZY_DIR     = "$NVIM_DATA\silzy"
$MANAGER_DIR   = "$SILZY_DIR\manager"
$PLUGINS_DIR   = "$SILZY_DIR\plugins"
$NVIM_CONFIG   = "$env:LOCALAPPDATA\nvim"

Write-Host ""
Write-Host "  silzy.nvim installer for Windows" -ForegroundColor Cyan
Write-Host ""

if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
    Write-Host "[silzy] ERROR: Neovim not found. Install it from https://neovim.io" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[silzy] ERROR: git not found. Install it from https://git-scm.com" -ForegroundColor Red
    exit 1
}

Write-Host "[silzy] Neovim found." -ForegroundColor Green

if (Test-Path $NVIM_CONFIG) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backup = "$NVIM_CONFIG.bak.$timestamp"
    Write-Host "[silzy] Backing up existing config to $backup" -ForegroundColor Yellow
    Move-Item $NVIM_CONFIG $backup
    Write-Host "[silzy] Backup done." -ForegroundColor Green
}

Write-Host "[silzy] Cloning silzy.nvim..." -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path $SILZY_DIR  | Out-Null
New-Item -ItemType Directory -Force -Path $PLUGINS_DIR | Out-Null

if (Test-Path $MANAGER_DIR) {
    Remove-Item $MANAGER_DIR -Recurse -Force
}

git clone --depth=1 --filter=blob:none $REPO_URL $MANAGER_DIR
if ($LASTEXITCODE -ne 0) {
    Write-Host "[silzy] ERROR: Failed to clone silzy.nvim." -ForegroundColor Red
    exit 1
}
Write-Host "[silzy] Manager cloned." -ForegroundColor Green

Write-Host "[silzy] Setting up config..." -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path "$NVIM_CONFIG\lua\config" | Out-Null
New-Item -ItemType Directory -Force -Path "$NVIM_CONFIG\lua\core"   | Out-Null

Copy-Item "$MANAGER_DIR\lua\config\options.lua"     "$NVIM_CONFIG\lua\config\options.lua"
Copy-Item "$MANAGER_DIR\lua\config\keymaps.lua"     "$NVIM_CONFIG\lua\config\keymaps.lua"
Copy-Item "$MANAGER_DIR\lua\core\init.lua"          "$NVIM_CONFIG\lua\core\init.lua"
Copy-Item "$MANAGER_DIR\lua\core\plugins.lua"       "$NVIM_CONFIG\lua\core\plugins.lua"
Copy-Item "$MANAGER_DIR\lua\core\colorscheme.lua"   "$NVIM_CONFIG\lua\core\colorscheme.lua"

$MANAGER_DIR_ESCAPED = $MANAGER_DIR.Replace("\", "\\")

$initLua = @"
vim.opt.runtimepath:prepend("$MANAGER_DIR_ESCAPED")

require("config.options")
require("config.keymaps")

if vim.fn.filereadable(vim.fn.stdpath("config") .. "/lua/config/keybinds.lua") == 1 then
  require("config.keybinds")
end

local silzy = require("silzy")
silzy.setup({ auto_install = true })

require("core")

silzy.load_plugins()
"@

Set-Content -Path "$NVIM_CONFIG\init.lua" -Value $initLua
Write-Host "[silzy] Config written." -ForegroundColor Green

Write-Host "[silzy] Pre-installing snacks.nvim..." -ForegroundColor Cyan
git clone --depth=1 --filter=blob:none "https://github.com/folke/snacks.nvim.git" "$PLUGINS_DIR\folke-snacks.nvim" 2>$null
git clone --depth=1 --filter=blob:none "https://github.com/nvim-lua/plenary.nvim.git" "$PLUGINS_DIR\nvim-lua-plenary.nvim" 2>$null

Write-Host ""
Write-Host "[silzy] Recommended tools:" -ForegroundColor Cyan
Write-Host "  fd       - winget install sharkdp.fd"
Write-Host "  ripgrep  - winget install BurntSushi.ripgrep.MSVC"
Write-Host "  lazygit  - winget install JesseDuffield.lazygit"
Write-Host "  nerd-font - https://www.nerdfonts.com"
Write-Host ""
Write-Host "[silzy] Done! Run: nvim" -ForegroundColor Green
Write-Host ""
