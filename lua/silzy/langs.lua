local M = {}

local presets = {

  c = function(use)
    use { "SilpofGames/c-dev",
      config = function()
        require("c-dev").setup({
          compiler = "gcc",
          default_flags = "-Wall -Wextra -g",
          auto_format = true,
          build_dir = "build",
          valgrind_flags = "--leak-check=full --show-leak-kinds=all --track-origins=yes",
        })
      end,
    }
    use { "neovim/nvim-lspconfig",
      requires = {
        "hrsh7th/nvim-cmp",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
      },
      config = function()
        local cmp     = require("cmp")
        local luasnip = require("luasnip")
        cmp.setup({
          snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
          mapping = cmp.mapping.preset.insert({
            ["<C-b>"]     = cmp.mapping.scroll_docs(-4),
            ["<C-f>"]     = cmp.mapping.scroll_docs(4),
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<CR>"]      = cmp.mapping.confirm({ select = true }),
            ["<Tab>"]     = cmp.mapping(function(fallback)
              if cmp.visible() then cmp.select_next_item()
              elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
              else fallback() end
            end, { "i", "s" }),
          }),
          sources = cmp.config.sources({
            { name = "nvim_lsp" }, { name = "luasnip" },
          }, { { name = "buffer" }, { name = "path" } }),
        })
        require("lspconfig").clangd.setup({
          capabilities = require("cmp_nvim_lsp").default_capabilities(),
          cmd = {
            "clangd", "--background-index", "--clang-tidy",
            "--header-insertion=iwyu", "--completion-style=detailed",
            "--function-arg-placeholders", "--fallback-style=llvm",
          },
        })
      end,
    }
  end,

  go = function(use)
    use { "SilpofGames/go-dev",
      config = function() require("go-dev").setup() end,
    }
    use { "neovim/nvim-lspconfig",
      config = function() require("lspconfig").gopls.setup({}) end,
    }
  end,

  java = function(use)
    use { "SilpofGames/java-dev",
      config = function() require("java-dev").setup() end,
    }
    use { "mfussenegger/nvim-jdtls" }
  end,

  lua = function(use)
    use { "SilpofGames/lua-dev",
      config = function() require("lua-dev").setup() end,
    }
    use { "neovim/nvim-lspconfig",
      config = function()
        require("lspconfig").lua_ls.setup({
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace   = { library = vim.api.nvim_get_runtime_file("", true) },
            },
          },
        })
      end,
    }
  end,

  php = function(use)
    use { "SilpofGames/php-dev",
      config = function() require("php-dev").setup() end,
    }
    use { "neovim/nvim-lspconfig",
      config = function() require("lspconfig").intelephense.setup({}) end,
    }
  end,

  python = function(use)
    use { "SilpofGames/py-dev",
      config = function()
        require("py-dev").setup({ python_cmd = "python3", venv_name = ".venv" })
      end,
    }
    use { "neovim/nvim-lspconfig",
      requires = { "hrsh7th/nvim-cmp", "hrsh7th/cmp-nvim-lsp" },
      config = function()
        local cmp = require("cmp")
        cmp.setup({ sources = cmp.config.sources({ { name = "nvim_lsp" } }) })
        require("lspconfig").pyright.setup({
          capabilities = require("cmp_nvim_lsp").default_capabilities(),
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "strict",
                autoSearchPaths  = true,
                useLibraryCodeForTypes = true,
              },
            },
          },
        })
      end,
    }
  end,

  ruby = function(use)
    use { "SilpofGames/ruby-dev",
      config = function() require("ruby-dev").setup() end,
    }
    use { "neovim/nvim-lspconfig",
      config = function() require("lspconfig").solargraph.setup({}) end,
    }
  end,

  rust = function(use)
    use { "SilpofGames/rust-dev",
      config = function() require("rust-dev").setup() end,
    }
    use { "neovim/nvim-lspconfig",
      config = function()
        require("lspconfig").rust_analyzer.setup({
          settings = {
            ["rust-analyzer"] = { checkOnSave = { command = "clippy" } },
          },
        })
      end,
    }
  end,

  web = function(use)
    use { "SilpofGames/web-dev",
      config = function()
        require("web-dev").setup({ port = 3000 })
      end,
    }
    use { "neovim/nvim-lspconfig",
      config = function()
        local lspconfig = require("lspconfig")
        lspconfig.html.setup({})
        lspconfig.cssls.setup({})
        lspconfig.ts_ls.setup({})
      end,
    }
  end,
}

function M.apply(ids, use)
  if type(ids) == "string" then ids = { ids } end
  local seen = {}
  for _, id in ipairs(ids) do
    if presets[id] and not seen[id] then
      seen[id] = true
      presets[id](use)
    else
      if not presets[id] then
        vim.notify("[silzy] Unknown language preset: " .. id, vim.log.levels.WARN)
      end
    end
  end
end

function M.list()
  return vim.tbl_keys(presets)
end

return M
