-- Docker: dockerls and hadolint for Dockerfile and Containerfile.
-- On-demand: nothing installs until a Dockerfile is opened.
---@type LazySpec
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then vim.list_extend(opts.ensure_installed, { "dockerfile" }) end
    end,
  },
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      servers = { "dockerls" },
    },
  },
}
