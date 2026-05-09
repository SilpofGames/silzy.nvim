local M = {}

local function common(use)
  use { "williamboman/mason.nvim",
    config = function()
      require("mason").setup({ ui = { border = "rounded" } })
    end,
  }
  use { "williamboman/mason-lspconfig.nvim" }
  use { "neovim/nvim-lspconfig" }
  use { "hrsh7th/nvim-cmp",
    requires = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
      "onsails/lspkind.nvim",
    },
    config = function()
      local cmp     = require("cmp")
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")
      require("luasnip.loaders.from_vscode").lazy_load()
      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        formatting = { format = lspkind.cmp_format({ mode = "symbol_text", maxwidth = 50 }) },
        mapping = cmp.mapping.preset.insert({
          ["<C-k>"]   = cmp.mapping.select_prev_item(),
          ["<C-j>"]   = cmp.mapping.select_next_item(),
          ["<C-d>"]   = cmp.mapping.scroll_docs(-4),
          ["<C-f>"]   = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"]   = cmp.mapping.abort(),
          ["<CR>"]    = cmp.mapping.confirm({ select = false }),
          ["<Tab>"]   = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
        window = {
          completion    = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
      })
    end,
  }
  use { "nvim-treesitter/nvim-treesitter",
    run = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        auto_install  = true,
        highlight     = { enable = true },
        indent        = { enable = true },
        ensure_installed = { "lua", "vim", "vimdoc", "query" },
      })
    end,
  }
  use { "nvimtools/none-ls.nvim", requires = { "nvim-lua/plenary.nvim" } }
  use { "numToStr/Comment.nvim", config = function() require("Comment").setup() end }
  use { "lewis6991/gitsigns.nvim", config = function() require("gitsigns").setup() end }
  use { "windwp/nvim-autopairs",
    config = function()
      local autopairs = require("nvim-autopairs")
      autopairs.setup({ check_ts = true })
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local ok, cmp = pcall(require, "cmp")
      if ok then cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done()) end
    end,
  }
end

local function setup_lsp(servers)
  local ok_mason, mason_lsp = pcall(require, "mason-lspconfig")
  local ok_lsp,   lspconfig = pcall(require, "lspconfig")
  if not ok_mason or not ok_lsp then return end

  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
  if ok_cmp then capabilities = cmp_lsp.default_capabilities(capabilities) end

  mason_lsp.setup({ ensure_installed = vim.tbl_keys(servers) })
  mason_lsp.setup_handlers({
    function(server)
      local opts = servers[server] or {}
      opts.capabilities = capabilities
      lspconfig[server].setup(opts)
    end,
  })
end

local lang_servers = {
  java       = { jdtls = {} },
  c          = { clangd = {} },
  cpp        = { clangd = {} },
  csharp     = { omnisharp = {} },
  python     = { pyright = {}, ruff_lsp = {} },
  lua        = { lua_ls = { settings = { Lua = { diagnostics = { globals = { "vim" } }, workspace = { checkThirdParty = false } } } } },
  js         = { ts_ls = {}, eslint = {} },
  ts         = { ts_ls = {}, eslint = {} },
  rust       = { rust_analyzer = {} },
  go         = { gopls = {} },
  ruby       = { solargraph = {} },
  zig        = { zls = {} },
  minimal    = {},
}

local lang_extras = {
  java = function(use)
    use { "mfussenegger/nvim-jdtls" }
    use { "nvim-neotest/neotest", requires = { "rcasia/neotest-java" } }
  end,
  c = function(use)
    use { "p00f/clangd_extensions.nvim" }
  end,
  cpp = function(use)
    use { "p00f/clangd_extensions.nvim" }
    use { "Civitasv/cmake-tools.nvim" }
  end,
  csharp = function(use)
    use { "iabdelkareem/csharp.nvim", requires = { "Tastyep/structlog.nvim" } }
  end,
  python = function(use)
    use { "linux-cultist/venv-selector.nvim" }
    use { "mfussenegger/nvim-dap-python" }
  end,
  lua = function(use)
    use { "folke/lazydev.nvim" }
  end,
  js = function(use)
    use { "vuki656/package-info.nvim" }
    use { "b0o/schemastore.nvim" }
  end,
  ts = function(use)
    use { "vuki656/package-info.nvim" }
    use { "dmmulroy/tsc.nvim" }
    use { "b0o/schemastore.nvim" }
  end,
  rust = function(use)
    use { "mrcjkb/rustaceanvim" }
    use { "saecki/crates.nvim" }
  end,
  go = function(use)
    use { "ray-x/go.nvim", requires = { "ray-x/guihua.lua" } }
  end,
  ruby = function(use)
    use { "suketa/nvim-dap-ruby" }
  end,
  zig = function(use)
    use { "NTBBloodbath/zig-tools.nvim" }
  end,
}

function M.apply(ids, use)
  if type(ids) == "string" then ids = { ids } end
  common(use)

  local merged_servers = {}
  local seen = {}

  for _, id in ipairs(ids) do
    local servers = lang_servers[id] or {}
    for name, opts in pairs(servers) do
      merged_servers[name] = opts
    end
    if lang_extras[id] and not seen[id] then
      seen[id] = true
      lang_extras[id](use)
    end
  end

  if next(merged_servers) then
    use { "neovim/nvim-lspconfig",
      config = function() setup_lsp(merged_servers) end,
    }
  end
end

function M.list()
  return vim.tbl_keys(lang_servers)
end

return M
