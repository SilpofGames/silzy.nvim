# silzy.nvim

> A modern, opinionated Neovim package manager — inspired by Lazy.nvim, batteries included.

```
███████╗██╗██╗     ███████╗██╗   ██╗    ███╗   ██╗██╗   ██╗██╗███╗   ███╗
██╔════╝██║██║     ╚══███╔╝╚██╗ ██╔╝    ████╗  ██║██║   ██║██║████╗ ████║
███████╗██║██║       ███╔╝  ╚████╔╝     ██╔██╗ ██║██║   ██║██║██╔████╔██║
╚════██║██║██║      ███╔╝    ╚██╔╝      ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
███████║██║███████╗███████╗   ██║       ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
╚══════╝╚═╝╚══════╝╚══════╝   ╚═╝       ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝                                         
```

## Features

- **First-run wizard** — interactive language picker on first launch (Java, Python, Rust, Go, …)
- **Bundled dashboard** — powered by `snacks.nvim` with working New File / Find File (Telescope) / Quit
- **Bundled essentials** — Telescope + Neo-tree installed out of the box
- **Lazy loading** — load plugins by event, filetype, or command
- **Simple spec syntax** — `silzy.use { "owner/repo", ... }`
- **Plugin status UI** — `:SilzyStatus` floating window
- **One-line installer**

---

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/SilpofGames/silzy.nvim/main/scripts/install.sh | bash
```

Then open Neovim:

```bash
nvim
```

The first-run wizard appears automatically. Pick your language and silzy installs everything.

---

## Manual Bootstrap (alternative)

Add this to the top of `~/.config/nvim/init.lua`:

```lua
local silzy_path = vim.fn.stdpath("data") .. "/silzy/manager"
if vim.fn.empty(vim.fn.glob(silzy_path)) > 0 then
  vim.fn.system({
    "git", "clone", "--depth=1", "--filter=blob:none",
    "https://github.com/SilpofGames/silzy.nvim.git",
    silzy_path,
  })
end
vim.opt.runtimepath:prepend(silzy_path)
```

---

## Usage

### Registering plugins

```lua
local silzy = require("silzy")

silzy.setup({ auto_install = true })

-- Basic
silzy.use { "folke/tokyonight.nvim" }

-- With config
silzy.use {
  "nvim-lualine/lualine.nvim",
  config = function()
    require("lualine").setup()
  end,
}

-- Lazy-load by event
silzy.use {
  "folke/todo-comments.nvim",
  event = "BufReadPost",
  config = function()
    require("todo-comments").setup()
  end,
}

-- Lazy-load by filetype
silzy.use {
  "someone/markdown-preview.nvim",
  ft = "markdown",
}

-- Lazy-load by command
silzy.use {
  "someone/some-plugin.nvim",
  cmd = "SomeCommand",
}

-- With dependencies
silzy.use {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("telescope").setup()
  end,
}

-- Pin to a tag (won't be updated)
silzy.use {
  "someone/stable-plugin.nvim",
  tag = "v1.2.3",
  pin = true,
}

-- With a build step
silzy.use {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
}
```

### Organising plugins in files

Put one plugin per file inside `lua/core/plugins/`:

```
~/.config/nvim/
├── init.lua
└── lua/
    ├── config/
    │   ├── options.lua
    │   └── keymaps.lua
    └── core/
        ├── init.lua          ← auto-loads all files below
        └── plugins/
            ├── snacks.lua    ← bundled dashboard
            ├── telescope.lua ← bundled finder
            ├── neotree.lua   ← bundled file tree
            └── mytheme.lua   ← your own plugins
```

Each file can either **return a spec table**:

```lua
-- lua/core/plugins/mytheme.lua
return {
  "folke/tokyonight.nvim",
  config = function()
    vim.cmd("colorscheme tokyonight")
  end,
}
```

Or **call `silzy.use` directly**:

```lua
-- lua/core/plugins/tools.lua
local silzy = require("silzy")
silzy.use { "folke/which-key.nvim", event = "VeryLazy" }
silzy.use { "lukas-reineke/indent-blankline.nvim" }
```

---

## Commands

| Command | Description |
|---|---|
| `:SilzyInstall` | Install all missing plugins |
| `:SilzyUpdate` | Update all installed plugins |
| `:SilzyClean` | Remove plugins no longer registered |
| `:SilzyStatus` | Open the plugin status window |
| `:SilzySetup` | Re-run the first-run wizard |

### Default keymaps

| Key | Action |
|---|---|
| `<leader>pi` | Install plugins |
| `<leader>pu` | Update plugins |
| `<leader>pc` | Clean plugins |
| `<leader>ps` | Plugin status |
| `<leader>ff` | Find files (Telescope) |
| `<leader>fg` | Live grep |
| `<leader>e` | Toggle file tree (Neo-tree) |
| `<C-t>` | Toggle terminal |
| `<leader>z` | Zen mode |

---

## Language presets

The first-run wizard configures one of these presets automatically:

| Language | LSP | Extras |
|---|---|---|
| Java | `jdtls` | neotest-java |
| C / C++ | `clangd` | clangd_extensions, cmake-tools |
| C# | `omnisharp` | csharp.nvim |
| Python | `pyright` | venv-selector, nvim-dap-python |
| Lua | `lua_ls` | lazydev.nvim |
| JavaScript | `ts_ls` | package-info |
| TypeScript | `ts_ls` | tsc.nvim, package-info |
| Rust | `rust-analyzer` | rustaceanvim, crates.nvim |
| Go | `gopls` | go.nvim |
| Ruby | `solargraph` | nvim-dap-ruby |
| Zig | `zls` | zig-tools.nvim |
| Minimal | — | just LSP + Treesitter |

---

## Requirements

- Neovim ≥ 0.9.0
- git
- Recommended: `fd`, `ripgrep`, `lazygit`, a Nerd Font

---

## License

MIT
