use { "catppuccin/nvim",
  as = "catppuccin",
  config = function()
    require("catppuccin").setup({
      flavour = "mocha",
      transparent_background = false,
      integrations = {
        telescope  = true,
        neotree    = true,
        treesitter = true,
        native_lsp = { enabled = true },
      },
    })
    vim.cmd("colorscheme catppuccin")
  end,
}
