return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true, -- show dotfiles
          ignored = false, -- hide gitignored files
          exclude = { "*Google Drive*" },
        },
        files = {
          hidden = true, -- show dotfiles
          ignored = false, -- hide gitignored files
          exclude = { "*Google Drive*" },
        },
        grep = {
          hidden = true, -- show dotfiles
          ignored = false, -- hide gitignored files
          exclude = { "*Google Drive*" },
        },
      },
    },
  },
}
