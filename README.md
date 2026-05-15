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

**A high-performance, modular Neovim engine with built-in package management, live hot-reloading, and an interactive UI ecosystem.**

![Neovim](https://img.shields.io/badge/Neovim-0.9+-green?logo=neovim&logoColor=white)
![License](https://img.shields.io/github/license/SilpofGames/silzy.nvim)
![GitHub Stars](https://img.shields.io/github/stars/SilpofGames/silzy.nvim?style=flat)

</div>

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

---

## Technical Overview

silzy.nvim is not just a configuration; it's a micro-framework for Neovim. It features a custom plugin manager engine that supports lazy-loading, dependency management, and a dedicated UI for maintenance.

### Core Architecture
- **State Engine:** Persistent state management via JSON (`state.json`).
- **Bootstrap Layer:** Automatic synchronization of core dependencies (`snacks.nvim`, `alpha-nvim`, `plenary.nvim`).
- **UI System:** Floating window manager for plugin status, logs, and colorscheme previews.
- **Language Presets:** Automated LSP and tool configuration via specialized "dev" plugins.

---

## Configuration API

Initialize silzy by calling `setup` in your `init.lua`.

```lua
require("silzy").setup({ 
  auto_install = true, 
  dashboard    = "snacks", -- "snacks" (default), "alpha", "native", "auto"
  fetch        = true,     -- System info in snacks dashboard
})
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `auto_install` | `boolean` | `true` | Installs missing plugins on startup. |
| `dashboard` | `string` | `"snacks"` | The preferred dashboard engine. |
| `fetch` | `boolean` | `true` | If `true`, runs `fastfetch`/`neofetch` in the dashboard terminal. |

---

## Core API Reference (`silzy`)

### `M.setup(opts)`
Initializes the silzy ecosystem. Creates necessary directories, records the current project in history, bootstraps core plugins, and sets up filesystem watchers for live reloading.

### `M.use(spec)`
Registers a plugin to the engine. Supports packer.nvim-style syntax.
- **`spec`**: `string` or `table` containing plugin metadata.
- **Supported Fields**: `id`, `requires`, `branch`, `tag`, `build`, `config`, `init`, `event`, `cmd`, `ft`, `opt`, `pin`.

### `M.load_plugins()`
The main execution loop for plugin loading. It handles runtime path (RTP) injection and triggers `init()` and `config()` functions based on lazy-loading constraints.

### `M.install(on_done)`
Asynchronously clones missing plugins from GitHub.
- **`on_done`**: `function` (optional) callback executed after all installs finish.

### `M.update()`
Performs a `git pull --ff-only` on all tracked, unpinned plugins.

### `M.clean()`
Garbage collection for the plugin directory. Removes any folders that are not registered via `M.use`.

---

## UI API Reference (`silzy.ui`)

### `dashboard.open()`
Triggers the dashboard interface based on the configured preference.
- Supports **Native** (buffer-based), **Snacks** (terminal + keys), and **Alpha**.

### `manager.open(plugins, install_path)`
Launches the advanced floating manager.
- **Tabs**: `Plugins`, `Colorschemes`, `Profiler`, `Log`.
- **Features**: Live colorscheme preview with palette dots (● ● ●), startup profiling per plugin, and real-time installation logs.

### `status.open(plugins, install_path)`
A lightweight alternative to the manager, providing a quick summary of installed vs. missing plugins.

### `wizard.start(callback)`
Initializes the first-run experience.
- Interactive multi-select UI for language support.
- **`callback`**: Receives an array of selected language IDs.

---

## Language Ecosystem (`silzy.langs`)

### `M.apply(ids, use)`
Programmatically applies language presets.
- **`ids`**: `string` or `table` of language identifiers.
- **`use`**: The registration function (usually `require("silzy").use`).

### `M.list()`
Returns a list of all currently supported language presets.

| ID | Language | Default LSP |
|----|----------|-------------|
| `c` | C/C++ | `clangd` |
| `go` | Go | `gopls` |
| `java` | Java | `jdtls` |
| `lua` | Lua | `lua_ls` |
| `php` | PHP | `intelephense` |
| `python` | Python | `pyright` |
| `ruby` | Ruby | `solargraph` |
| `rust` | Rust | `rust-analyzer` |
| `web` | HTML/CSS/JS | `ts_ls`, `html`, `cssls` |

---

## File System Structure

```
~/.config/nvim/
├── init.lua                 ← Entry point (calls silzy.setup)
├── lua/
│   ├── config/
│   │   ├── options.lua      ← Global Vim options & Autopairs
│   │   ├── keymaps.lua      ← Primary engine keymaps
│   │   └── keybinds.lua     ← User-defined keybinds
│   ├── core/
│   │   ├── init.lua         ← Core loader
│   │   ├── plugins.lua      ← Plugin definitions (use 'use')
│   │   └── colorscheme.lua  ← Colorscheme definition
│   └── silzy/               ← The silzy.nvim engine core
```

---

## Internal State & Persistence
Silzy maintains its state in `~/.local/share/nvim/silzy/state.json`. This includes:
- **`projects`**: A stack of the last 10 opened directories for the project switcher.
- **`langs`**: The languages selected during the wizard phase.
- **`installed_at`**: Unix timestamp of the initial setup.

---

## Key Bindings (Summary)

| Scope | Key | Action |
|-------|-----|--------|
| **Global** | `<leader>pm` | Open Plugin Manager |
| **Global** | `<leader>ph` | Open Dashboard |
| **Global** | `<C-t>` | Toggle Terminal (Snacks) |
| **Manager** | `Tab` | Switch Tabs |
| **Manager** | `i` / `u` / `c` | Install / Update / Clean |
| **Manager** | `Enter` | (Colorschemes) Apply and persist |

---

## License
MIT — made by [SilpofGames](https://github.com/SilpofGames)
