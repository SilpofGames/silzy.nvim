#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
BLU='\033[0;34m'
BLD='\033[1m'
RST='\033[0m'

info()    { echo -e "${BLU}[silzy]${RST} $*"; }
success() { echo -e "${GRN}[silzy] ✓${RST} $*"; }
warn()    { echo -e "${YLW}[silzy] !${RST} $*"; }
error()   { echo -e "${RED}[silzy] ✗${RST} $*" >&2; exit 1; }

echo -e "${BLD}"
cat <<'EOF'
███████╗██╗██╗     ███████╗██╗   ██╗    ███╗   ██╗██╗   ██╗██╗███╗   ███╗
██╔════╝██║██║     ╚══███╔╝╚██╗ ██╔╝    ████╗  ██║██║   ██║██║████╗ ████║
███████╗██║██║       ███╔╝  ╚████╔╝     ██╔██╗ ██║██║   ██║██║██╔████╔██║
╚════██║██║██║      ███╔╝    ╚██╔╝      ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
███████║██║███████╗███████╗   ██║       ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
╚══════╝╚═╝╚══════╝╚══════╝   ╚═╝       ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
                                                                         
                       Neovim Package Manager
EOF
echo -e "${RST}"

command -v nvim &>/dev/null || error "Neovim is not installed. Install it first: https://neovim.io"
command -v git  &>/dev/null || error "git is not installed."

NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
SILZY_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/silzy"
SILZY_MANAGER_DIR="$SILZY_DATA_DIR/manager"
SILZY_PLUGINS_DIR="$SILZY_DATA_DIR/plugins"
REPO_URL="https://github.com/SilpofGames/silzy.nvim.git"

if [[ -d "$NVIM_CONFIG_DIR" ]]; then
  BACKUP_DIR="${NVIM_CONFIG_DIR}.bak.$(date +%Y%m%d_%H%M%S)"
  warn "Existing config found. Backing up to $BACKUP_DIR"
  mv "$NVIM_CONFIG_DIR" "$BACKUP_DIR"
  success "Backup done."
fi

info "Cloning silzy.nvim manager..."
mkdir -p "$SILZY_DATA_DIR"
mkdir -p "$SILZY_PLUGINS_DIR"
if [[ -d "$SILZY_MANAGER_DIR" ]]; then
  warn "Manager already exists, updating..."
  rm -rf "$SILZY_MANAGER_DIR"
fi
git clone --depth=1 --filter=blob:none "$REPO_URL" "$SILZY_MANAGER_DIR" \
  || error "Failed to clone silzy.nvim from $REPO_URL"
success "Manager cloned to $SILZY_MANAGER_DIR"

info "Creating config structure..."
mkdir -p "$NVIM_CONFIG_DIR/lua/config"
mkdir -p "$NVIM_CONFIG_DIR/lua/core"

info "Copying config files..."
cp "$SILZY_MANAGER_DIR/lua/config/options.lua"     "$NVIM_CONFIG_DIR/lua/config/options.lua"
cp "$SILZY_MANAGER_DIR/lua/config/keymaps.lua"     "$NVIM_CONFIG_DIR/lua/config/keymaps.lua"
cp "$SILZY_MANAGER_DIR/lua/core/init.lua"          "$NVIM_CONFIG_DIR/lua/core/init.lua"
cp "$SILZY_MANAGER_DIR/lua/core/plugins.lua"       "$NVIM_CONFIG_DIR/lua/core/plugins.lua"
cp "$SILZY_MANAGER_DIR/lua/core/colorscheme.lua"   "$NVIM_CONFIG_DIR/lua/core/colorscheme.lua"
success "Config files copied."

info "Writing init.lua..."
ESCAPED_MANAGER_DIR=$(printf '%s\n' "$SILZY_MANAGER_DIR" | sed 's/[[\.*^$()+?{|]/\\&/g')
cat > "$NVIM_CONFIG_DIR/init.lua" << INIT_LUA
vim.opt.runtimepath:prepend("$SILZY_MANAGER_DIR")

require("config.options")
require("config.keymaps")

if vim.fn.filereadable(vim.fn.stdpath("config") .. "/lua/config/keybinds.lua") == 1 then
  require("config.keybinds")
end

local silzy = require("silzy")
silzy.setup({ auto_install = true })

require("core")

silzy.load_plugins()
INIT_LUA
success "init.lua written."

info "Pre-installing snacks.nvim and plenary.nvim..."
git clone --depth=1 --filter=blob:none \
  "https://github.com/folke/snacks.nvim.git" \
  "$SILZY_PLUGINS_DIR/folke-snacks.nvim" 2>/dev/null && success "snacks.nvim ready." || warn "snacks.nvim clone failed (will retry on first nvim open)"

git clone --depth=1 --filter=blob:none \
  "https://github.com/nvim-lua/plenary.nvim.git" \
  "$SILZY_PLUGINS_DIR/nvim-lua-plenary.nvim" 2>/dev/null && success "plenary.nvim ready." || warn "plenary.nvim clone failed (will retry on first nvim open)"

echo ""
info "Recommended tools:"
echo "  fd       — pacman -S fd            / apt install fd-find"
echo "  ripgrep  — pacman -S ripgrep       / apt install ripgrep"
echo "  lazygit  — pacman -S lazygit"
echo "  nerd-font — https://www.nerdfonts.com"
echo ""
success "silzy.nvim installed! Run: nvim"
echo ""
