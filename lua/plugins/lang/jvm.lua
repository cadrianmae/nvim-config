-- JVM: Java, Kotlin and Gradle, for Minecraft mod work. One bundle rather than
-- two files because they arrive together and share the build tooling -- a
-- build.gradle.kts belongs to both.
-- On-demand: jdtls is one of the largest Mason packages, so it stays
-- uninstalled until a .java or .kt file is opened.
---@type LazySpec
return {
  { import = "astrocommunity.pack.java" },
  { import = "astrocommunity.pack.kotlin" },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then vim.list_extend(opts.ensure_installed, { "groovy" }) end
    end,
  },
}
