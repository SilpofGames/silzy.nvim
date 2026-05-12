<div align="center">

```
                           
  ▄▄▄▄▄     ▄▄             
 ██▀▀▀▀█▄    ██            
 ▀██▄  ▄▀ ▀▀ ██            
   ▀██▄▄  ██ ██ ▀▀▀██ ██ ██
 ▄   ▀██▄ ██ ██   ▄█▀ ██▄██
 ▀██████▀▄██▄██▄▄██▄▄▄▄▀██▀
                        ██ 
                      ▀▀▀  
```

**A modern Neovim package manager — packer syntax, first-run wizard, live reload, and a built-in UI.**

![Neovim](https://img.shields.io/badge/Neovim-0.9+-green?logo=neovim&logoColor=white)
![License](https://img.shields.io/github/license/SilpofGames/silzy.nvim)
![GitHub Stars](https://img.shields.io/github/stars/SilpofGames/silzy.nvim?style=flat)

</div>

---

## Features

- **First-run wizard** — multi-select language picker on first launch
- **Packer.nvim syntax** — `use { "owner/repo", config = function() ... end }`
- **Auto-installs LSPs and tools** per selected language
- **Custom dashboards** — supports native, [snacks.nvim](https://github.com/folke/snacks.nvim), and [alpha-nvim](https://github.com/goolord/alpha-nvim)
- **Plugin manager UI** — `<leader>pm` with Plugins / Colorschemes / Log tabs
- **Colorscheme picker** — browse and apply colorschemes live with color previews (● ● ●), persists to file
- **Modern status bar** — Catppuccin "pill" style with sharp separators (`|`, ``, `>`)
- **Command Autocomplete** — built-in completion for commands and paths via `nvim-cmp`
- **Live reload** — any change to `lua/core/` reloads Neovim automatically
- **Bundled essentials** — Telescope, Neo-tree, Bufferline, Lualine, Aerial, snacks.nvim, alpha-nvim
- **Native autopairs** — `(` → `()`, `{` → `{}`, `"` → `""` out of the box

---

## Configuration

You can customize silzy.nvim behavior in your `init.lua`:

```lua
local silzy = require("silzy")

silzy.setup({ 
  auto_install = true, 
  dashboard    = "auto", -- Options: "auto", "snacks", "alpha", "native"
  fetch        = true,   -- Show system info (fastfetch/neofetch) in snacks dashboard
})
```

| Option | Default | Description |
|--------|---------|-------------|
| `auto_install` | `true` | Automatically install missing plugins on startup |
| `dashboard` | `"auto"` | Preferred dashboard plugin. "auto" prefers snacks > alpha > native |
| `fetch` | `true` | Enable/Disable system info (terminal section) in snacks dashboard |

---

## Install

**Linux / macOS:**

```bash
curl -fsSL https://raw.githubusercontent.com/SilpofGames/silzy.nvim/main/scripts/install.sh | bash
```

**Windows (PowerShell):**

```powershell
iwr -useb https://raw.githubusercontent.com/SilpofGames/silzy.nvim/main/scripts/install.ps1 | iex
```

Then open Neovim — the first-run wizard appears automatically.

---

## First-run wizard

On first launch, a language picker appears. Press `Space` to toggle languages, `Enter` to confirm. You can select multiple languages.

**Available languages:**

| Key | Language | LSP | Plugin |
|-----|----------|-----|--------|
| `1` | C | clangd | [SilpofGames/c-dev](https://github.com/SilpofGames/c-dev) |
| `2` | Go | gopls | [SilpofGames/go-dev](https://github.com/SilpofGames/go-dev) |
| `3` | Java | jdtls | [SilpofGames/java-dev](https://github.com/SilpofGames/java-dev) |
| `4` | Lua | lua_ls | [SilpofGames/lua-dev](https://github.com/SilpofGames/lua-dev) |
| `5` | PHP | intelephense | [SilpofGames/php-dev](https://github.com/SilpofGames/php-dev) |
| `6` | Python | pyright | [SilpofGames/py-dev](https://github.com/SilpofGames/py-dev) |
| `7` | Ruby | solargraph | [SilpofGames/ruby-dev](https://github.com/SilpofGames/ruby-dev) |
| `8` | Rust | rust-analyzer | [SilpofGames/rust-dev](https://github.com/SilpofGames/rust-dev) |
| `9` | Web (HTML/CSS/JS) | html + cssls + ts_ls | [SilpofGames/web-dev](https://github.com/SilpofGames/web-dev) |

---

## File structure

```
~/.config/nvim/
├── init.lua                 ← entry point
└── lua/
    ├── config/
    │   ├── options.lua      ← editor options and autopairs
    │   ├── keymaps.lua      ← global keymaps
    │   └── keybinds.lua     ← your custom keybinds (optional)
    └── core/
        ├── init.lua         ← loads plugins.lua and colorscheme.lua
        ├── plugins.lua      ← your plugins
        └── colorscheme.lua  ← your colorscheme
```

---

## Plugin syntax

`lua/core/plugins.lua` uses packer.nvim-compatible syntax:

```lua
use { "folke/which-key.nvim",
  config = function()
    require("which-key").setup()
  end,
}

use { "nvim-lualine/lualine.nvim",
  requires = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("lualine").setup({ options = { theme = "auto" } })
  end,
}

use { "ThePrimeagen/harpoon",
  branch = "harpoon2",
  requires = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup()
    vim.keymap.set("n", "<leader>ha", function() harpoon:list():add() end)
  end,
}
```

Supported fields: `requires`, `branch`, `tag`, `run`, `as`, `config`, `init`, `event`, `cmd`, `ft`, `opt`, `pin`

---

## Colorscheme syntax

`lua/core/colorscheme.lua`:

```lua
use { "catppuccin/nvim",
  as = "catppuccin",
  config = function()
    require("catppuccin").setup({ flavour = "mocha" })
    vim.cmd("colorscheme catppuccin-mocha")
  end,
}
```

```lua
use { "sainnhe/everforest",
  config = function()
    vim.g.everforest_background = "hard"
    vim.g.everforest_transparent_background = 2
    vim.cmd("colorscheme everforest")
    local groups = {
      "Normal", "NormalNC", "NormalFloat", "SignColumn",
      "StatusLine", "EndOfBuffer", "LineNr",
    }
    for _, g in ipairs(groups) do
      vim.api.nvim_set_hl(0, g, { bg = "NONE", ctermbg = "NONE" })
    end
  end,
}
```

```lua
use { "ellisonleao/gruvbox.nvim",
  config = function()
    require("gruvbox").setup({ contrast = "hard" })
    vim.cmd("colorscheme gruvbox")
  end,
}
```

---

## Custom keybinds

Add your own keybinds in `lua/config/keybinds.lua` — it's loaded automatically:

```lua
local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true, noremap = true })
end

map("n", "<leader>x", "<cmd>bd<CR>", "Close buffer")
map("n", "<C-s>", "<cmd>w<CR>", "Save file")
```

---

## Keymaps

### Navigation

| Key | Action |
|-----|--------|
| `<leader>p` | Find files (Telescope) |
| `<leader>g` | Live grep |
| `<leader>r` | Recent files |
| `<leader>b` | Buffers |
| `<leader>e` | Toggle file explorer (Neo-tree) |
| `<leader>a` | Toggle symbols panel (Aerial) |

### silzy.nvim

| Key | Action |
|-----|--------|
| `<leader>pm` | Open plugin manager |
| `<leader>pr` | Reload config |
| `<leader>ph` | Open dashboard |

### Plugin manager UI (`<leader>pm`)

| Key | Action |
|-----|--------|
| `Tab` | Cycle tabs (Plugins → Colorschemes → Log) |
| `i` | Install missing plugins |
| `u` | Update all plugins |
| `c` | Clean unused plugins |
| `r` | Reload config |
| `s` | Go to Colorschemes tab |
| `j` / `k` | Navigate (in Colorschemes tab) |
| `Enter` | Apply colorscheme (writes to colorscheme.lua) |
| `q` | Close |

### Snacks.nvim

| Key | Action |
|-----|--------|
| `<C-t>` | Toggle terminal |
| `<leader>z` | Zen mode |
| `<leader>dd` | Dim mode |
| `<leader>gb` | Git browse |
| `<leader>gl` | Lazygit |
| `<leader>rn` | Rename file |

---

## Commands

| Command | Action |
|---------|--------|
| `:SilzyInstall` | Install missing plugins |
| `:SilzyUpdate` | Update all plugins |
| `:SilzyClean` | Remove unused plugins |
| `:SilzyOpen` | Open plugin manager UI |
| `:SilzyReload` | Reload config |
| `:SilzyDashboard` | Open dashboard |

---

## Bundled plugins

Installed automatically with silzy.nvim:

- **[folke/snacks.nvim](https://github.com/folke/snacks.nvim)** — dashboard, terminal, zen, notifier, git browse
- **[nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)** — fuzzy finder
- **[nvim-neo-tree/neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim)** — file explorer
- **[akinsho/bufferline.nvim](https://github.com/akinsho/bufferline.nvim)** — buffer tabs
- **[nvim-lualine/lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)** — statusline
- **[stevearc/aerial.nvim](https://github.com/stevearc/aerial.nvim)** — symbols/outline panel
- **[lukas-reineke/indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim)** — indent guides

---

## Requirements

- Neovim ≥ 0.9
- git
- Recommended: `fd`, `ripgrep`, `lazygit`, a [Nerd Font](https://www.nerdfonts.com)

---

## License

MIT — made by [SilpofGames](https://github.com/SilpofGames)
