use { "goolord/alpha-nvim",
  requires = { "nvim-tree/nvim-web-devicons" },
}

use { "hrsh7th/nvim-cmp",
  requires = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
  },
  config = function()
    local cmp = require("cmp")
    cmp.setup({
      snippet = { expand = function(args) require("luasnip").lsp_expand(args.body) end },
      mapping = cmp.mapping.preset.insert({
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then cmp.select_next_item()
          elseif require("luasnip").expand_or_jumpable() then require("luasnip").expand_or_jump()
          else fallback() end
        end, { "i", "s" }),
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" },
      }, {
        { name = "buffer" },
        { name = "path" },
      })
    })

    -- Cmdline completion
    cmp.setup.cmdline(":", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = "path" }
      }, {
        { name = "cmdline" }
      })
    })
  end
}

use { "folke/snacks.nvim",
  config = function()
    local function get_fetch_cmd()
      local cmds = { "fastfetch", "neofetch", "screenfetch" }
      for _, c in ipairs(cmds) do
        if vim.fn.executable(c) == 1 then
          if c == "fastfetch" then return "fastfetch --raw" end
          if c == "neofetch" then return "neofetch --off" end
          return c
        end
      end
      return nil
    end

    local fetch_cmd = get_fetch_cmd()
    local dashboard_sections = {
      { section = "header" },
      { section = "keys", gap = 1, padding = 1 },
      { 
        text = { { " silzy.nvim v0.1.0 ", hl = "Special" } },
        padding = 1,
        indent = 8,
      },
    }

    if fetch_cmd then
      table.insert(dashboard_sections, {
        section = "terminal",
        cmd = fetch_cmd,
        hl = "header",
        padding = 1,
        indent = 8,
      })
    end

    require("snacks").setup({
      indent       = { enabled = true },
      notifier     = { enabled = true, timeout = 3000, style = "compact" },
      scroll       = { enabled = true },
      input        = { enabled = true },
      statuscolumn = { enabled = true },
      words        = { enabled = true },
      terminal     = { enabled = true },
      gitbrowse    = { enabled = true },
      scope        = { enabled = true },
      zen          = { enabled = true },
      dim          = { enabled = true },
      bigfile      = { enabled = true },
      quickfile    = { enabled = true },
      picker       = { enabled = false },
      rename       = { enabled = true },
      dashboard    = {
        sections = dashboard_sections,
      },
    })
    local map = function(lhs, fn, desc, mode)
      vim.keymap.set(mode or "n", lhs, fn, { desc = desc, silent = true })
    end
    map("<leader>un", function() Snacks.notifier.hide()         end, "Dismiss Notifications")
    map("<leader>nh", function() Snacks.notifier.show_history() end, "Notification History")
    map("<leader>gb", function() Snacks.gitbrowse()             end, "Git Browse")
    map("<leader>gl", function() Snacks.lazygit()               end, "Lazygit")
    map("<leader>z",  function() Snacks.zen()                   end, "Toggle Zen Mode")
    map("<leader>dd", function() Snacks.dim()                   end, "Toggle Dim Mode")
    map("<leader>rn", function() Snacks.rename.rename_file()    end, "Rename File")
    map("<C-t>",      function() Snacks.terminal.toggle()       end, "Toggle Terminal", { "n", "t" })
    map("]]",         function() Snacks.words.jump(1)           end, "Next Reference")
    map("[[",         function() Snacks.words.jump(-1)          end, "Prev Reference")
  end,
}

use { "nvim-lua/plenary.nvim" }
use { "nvim-tree/nvim-web-devicons" }

use { "nvim-telescope/telescope.nvim",
  requires = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons" },
  config = function()
    local actions = require("telescope.actions")
    require("telescope").setup({
      defaults = {
        prompt_prefix    = "   ",
        selection_caret  = "  ",
        path_display     = { "truncate" },
        sorting_strategy = "ascending",
        layout_config    = {
          horizontal = { prompt_position = "top", preview_width = 0.55 },
          width = 0.87, height = 0.80,
        },
        mappings = {
          i = {
            ["<C-n>"] = actions.cycle_history_next,
            ["<C-p>"] = actions.cycle_history_prev,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<Esc>"] = actions.close,
          },
        },
      },
      pickers = {
        find_files = {
          hidden       = true,
          no_ignore    = false,
          find_command = vim.fn.executable("fd") == 1
            and { "fd", "--type", "f", "--hidden", "--exclude", ".git", "--strip-cwd-prefix" }
            or  { "find", ".", "-type", "f", "-not", "-path", "*/.git/*" },
        },
        live_grep = { additional_args = { "--hidden", "--glob", "!.git" } },
        oldfiles  = { include_current_session = true },
      },
    })
  end,
}

use { "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  requires = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    vim.g.loaded_netrw       = 1
    vim.g.loaded_netrwPlugin = 1
    require("neo-tree").setup({
      close_if_last_window = true,
      popup_border_style   = "rounded",
      enable_git_status    = true,
      enable_diagnostics   = true,
      use_popups_for_input = true,
      source_selector = {
        winbar          = false,
        statusline      = false,
      },
      default_component_configs = {
        indent = {
          indent_size = 2, padding = 1, with_markers = true,
          indent_marker = "│", last_indent_marker = "└",
          expander_collapsed = "", expander_expanded = "",
        },
        icon = {
          folder_closed = " ",
          folder_open   = " ",
          folder_empty  = " ",
          default       = " ",
        },
        git_status = {
          symbols = {
            added = "✚", modified = "", deleted = "✖", renamed = "",
            untracked = "", ignored = "", unstaged = "", staged = "", conflict = "",
          },
        },
      },
      window = {
        position = "left", width = 35,
        mappings = {
          ["<space>"] = "toggle_node", ["<2-LeftMouse>"] = "open",
          ["<cr>"]    = "open",        ["S"] = "open_split",
          ["s"]       = "open_vsplit", ["t"] = "open_tabnew",
          ["C"]       = "close_node",  ["z"] = "close_all_nodes",
          ["R"]       = "refresh",     ["a"] = "add",
          ["A"]       = "add_directory", ["d"] = "delete",
          ["r"]       = "rename",      ["y"] = "copy_to_clipboard",
          ["x"]       = "cut_to_clipboard", ["p"] = "paste_from_clipboard",
          ["c"]       = "copy",        ["m"] = "move",
          ["q"]       = "close_window", ["?"] = "show_help",
          ["H"]       = "toggle_hidden",
        },
      },
      filesystem = {
        filtered_items = {
          visible         = true,
          hide_dotfiles   = false,
          hide_gitignored = false,
          hide_hidden     = false,
        },
        follow_current_file    = { enabled = true },
        use_libuv_file_watcher = true,
        bind_to_cwd            = true,
        cwd_target = {
          sidebar   = "tab",
          current   = "window",
        },
      },
      name = {
        trailing_slash    = false,
        use_git_status_colors = true,
        highlight         = "NeoTreeFileName",
      },
    })
  end,
}

use { "akinsho/bufferline.nvim",
  requires = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("bufferline").setup({
      options = {
        mode              = "buffers",
        separator_style   = "slant",
        always_show_bufferline = true,
        show_buffer_close_icons = true,
        show_close_icon   = false,
        color_icons       = true,
        diagnostics       = "nvim_lsp",
        offsets = {
          {
            filetype   = "neo-tree",
            text       = "  Files",
            highlight  = "Directory",
            separator  = true,
          },
        },
      },
    })
  end,
}

use { "stevearc/aerial.nvim",
  requires = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  config = function()
    require("aerial").setup({
      on_attach = function(bufnr)
        vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr, desc = "Prev symbol" })
        vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr, desc = "Next symbol" })
      end,
      layout = {
        max_width     = { 40, 0.2 },
        min_width     = 30,
        default_direction = "right",
        placement     = "edge",
      },
      attach_mode   = "global",
      backends      = { "treesitter", "lsp" },
      show_guides   = true,
      guides = {
        mid_item   = "├─ ",
        last_item  = "└─ ",
        nested_top = "│  ",
        whitespace = "   ",
      },
      filter_kind = {
        "Class", "Constructor", "Enum", "Function",
        "Interface", "Module", "Method", "Struct",
      },
    })
    vim.keymap.set("n", "<leader>a", "<cmd>AerialToggle<CR>", { desc = "Toggle Symbols" })
  end,
}

use { "nvim-lualine/lualine.nvim",
  requires = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local function lsp_name()
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      if #clients == 0 then return "" end
      return " " .. clients[1].name
    end

    local colors = {
      blue   = "#89b4fa",
      cyan   = "#89dceb",
      black  = "#181825",
      white  = "#cdd6f4",
      red    = "#f38ba8",
      violet = "#cba6f7",
      grey   = "#313244",
      dark   = "#1e1e2e",
    }

    require("lualine").setup({
      options = {
        theme            = "catppuccin",
        globalstatus     = true,
        component_separators = { left = ">", right = "<" },
        section_separators  = { left = "", right = "" },
        disabled_filetypes  = { statusline = { "dashboard", "silzy-dashboard", "alpha" } },
      },
      sections = {
        lualine_a = {
          { "mode", padding = { left = 1, right = 1 } },
        },
        lualine_b = {
          { "filename", 
            color = { bg = colors.grey, fg = colors.white },
          },
          { "branch", icon = " ", 
            color = { bg = colors.dark, fg = colors.white },
          },
        },
        lualine_c = { "%=" },
        lualine_x = {
          { "diagnostics", color = { bg = colors.dark } },
          { lsp_name, icon = " ", 
            color = { bg = colors.grey, fg = colors.blue },
          },
        },
        lualine_y = {
          { "filetype", color = { bg = colors.dark, fg = colors.white } },
        },
        lualine_z = {
          { "location", color = { bg = colors.blue, fg = colors.black } },
          { function() return "|" end, padding = { left = 0, right = 0 } },
        },
      },
      inactive_sections = {
        lualine_a = { "filename" },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = { "location" },
      },
    })
  end,
}

use { "lukas-reineke/indent-blankline.nvim",
  config = function()
    require("ibl").setup({
      indent = { char = "│" },
      scope  = { enabled = true },
    })
  end,
}
