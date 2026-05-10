<div align="center">

```
███████╗██╗██╗     ███████╗██╗   ██╗    ███╗   ██╗██╗   ██╗██╗███╗   ███╗
██╔════╝██║██║     ╚══███╔╝╚██╗ ██╔╝    ████╗  ██║██║   ██║██║████╗ ████║
███████╗██║██║       ███╔╝  ╚████╔╝     ██╔██╗ ██║██║   ██║██║██╔████╔██║
╚════██║██║██║      ███╔╝    ╚██╔╝      ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
███████║██║███████╗███████╗   ██║       ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
╚══════╝╚═╝╚══════╝╚══════╝   ╚═╝       ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
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
- **Built-in dashboard** — auto-detects snacks.nvim if installed
- **Plugin manager UI** — `<leader>pm` with Plugins / Colorschemes / Log tabs
- **Colorscheme picker** — browse and apply colorschemes live, persists to file
- **Live reload** — any change to `lua/core/` reloads Neovim automatically
- **Bundled essentials** — Telescope, Neo-tree, Bufferline, Lualine, Aerial, snacks.nvim
- **Native autopairs** — `(` → `()`, `{` → `{}`, `"` → `""` out of the box

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/SilpofGames/silzy.nvim/main/scripts/install.sh | bash
```

Then open Neovim — the first-run wizard appears automatically.

---

## First-run wizard

On first launch, a language picker appears. Press `Space` to toggle languages, `Enter` to confirm. You can select multiple languages.

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

~/.config/nvim/                                                                                       
├── init.lua                                                        
└── lua/                                                       
├── config/                                                       
│   ├── options.lua                                                       
│   ├── keymaps.lua                                                       
│   └── keybinds.lua     ← your custom keybinds (optional)                                                       
└── core/                                                       
├── init.lua                                                       
├── plugins.lua      ← your plugins                                                       
└── colorscheme.lua  ← your colorscheme                                                       

---

## Plugin syntax

```lua
use { "folke/which-key.nvim",
  config = function()
    require("which-key").setup()
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
  end,
}
```

---

## Custom keybinds

```lua
local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true, noremap = true })
end

map("n", "<leader>x", "<cmd>bd<CR>", "Close buffer")
map("n", "<C-s>", "<cmd>w<CR>", "Save file")
```

---

## Keymaps

| Key | Action |
|-----|--------|
| `<leader>p` | Find files |
| `<leader>g` | Live grep |
| `<leader>r` | Recent files |
| `<leader>b` | Buffers |
| `<leader>e` | Toggle file explorer |
| `<leader>a` | Toggle symbols panel |
| `<leader>pm` | Open plugin manager |
| `<leader>pr` | Reload config |
| `<leader>ph` | Open dashboard |
| `<C-t>` | Toggle terminal |
| `<leader>z` | Zen mode |
| `<leader>gl` | Lazygit |

### Plugin manager (`<leader>pm`)

| Key | Action |
|-----|--------|
| `Tab` | Cycle tabs |
| `i` | Install missing plugins |
| `u` | Update all plugins |
| `c` | Clean unused plugins |
| `r` | Reload config |
| `s` | Colorschemes tab |
| `j` / `k` | Navigate colorschemes |
| `Enter` | Apply colorscheme |
| `q` | Close |

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

- [folke/snacks.nvim](https://github.com/folke/snacks.nvim)
- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [nvim-neo-tree/neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim)
- [akinsho/bufferline.nvim](https://github.com/akinsho/bufferline.nvim)
- [nvim-lualine/lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
- [stevearc/aerial.nvim](https://github.com/stevearc/aerial.nvim)
- [lukas-reineke/indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim)

---

## Requirements

- Neovim ≥ 0.9
- git
- Recommended: `fd`, `ripgrep`, `lazygit`, a [Nerd Font](https://www.nerdfonts.com)

---

## License

MIT — made by [SilpofGames](https://github.com/SilpofGames)
