<div align="center">

# silzy.nvim

**A modern Neovim package manager — packer syntax, lazy loading, first-run wizard.**

![Neovim](https://img.shields.io/badge/Neovim-0.9+-green?logo=neovim)
![License](https://img.shields.io/github/license/YOURUSERNAME/silzy.nvim)

</div>

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/SilpofGames/silzy.nvim/main/scripts/install.sh | bash
```

Then open Neovim — the first-run wizard appears automatically.

---

## Usage

### plugins.lua

```lua
use { "folke/which-key.nvim",
  config = function()
    require("which-key").setup()
  end,
}

use { "nvim-lualine/lualine.nvim",
  requires = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("lualine").setup()
  end,
}
```

### colorscheme.lua

```lua
use { "catppuccin/nvim",
  as = "catppuccin",
  config = function()
    require("catppuccin").setup({ flavour = "mocha" })
    vim.cmd("colorscheme catppuccin-mocha")
  end,
}
```

---

## Keymaps

| Key | Action |
|-----|--------|
| `<leader>pm` | Open plugin manager |
| `<leader>pr` | Reload config |
| `<leader>ph` | Open dashboard |
| `<leader>p`  | Find files |
| `<leader>e`  | File explorer |
| `<leader>g`  | Live grep |

---

## Commands

| Command | Action |
|---------|--------|
| `:SilzyOpen` | Open plugin manager UI |
| `:SilzyInstall` | Install missing plugins |
| `:SilzyUpdate` | Update all plugins |
| `:SilzyClean` | Remove unused plugins |
| `:SilzyReload` | Reload config |
| `:SilzyDashboard` | Open dashboard |

---

## Requirements

- Neovim ≥ 0.9
- git
- Recommended: `fd`, `ripgrep`, `lazygit`, a Nerd Font
