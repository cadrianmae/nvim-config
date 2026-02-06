-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.
--
-- Categories organized to match https://astronvim.github.io/astrocommunity/

---@type LazySpec
return {
  "AstroNvim/astrocommunity",

  -- ========================================================================
  -- AI
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#ai

  -- ========================================================================
  -- Bars and Lines
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#bars-and-lines

  -- ========================================================================
  -- Code Runner
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#code-runner

  -- ========================================================================
  -- Color
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#color

  -- ========================================================================
  -- Colorscheme
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#colorscheme
  {
    import = "astrocommunity.colorscheme.catppuccin",
  },

  -- ========================================================================
  -- Comment
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#comment

  -- ========================================================================
  -- Completion
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#completion
  { import = "astrocommunity.completion.copilot-lua-cmp" },

  -- ========================================================================
  -- Debugging
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#debugging

  -- ========================================================================
  -- Diagnostics
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#diagnostics
  { import = "astrocommunity.diagnostics.trouble-nvim" },

  -- ========================================================================
  -- Docker
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#docker

  -- ========================================================================
  -- Editing Support
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#editing-support
  { import = "astrocommunity.editing-support.todo-comments-nvim" },
  { import = "astrocommunity.editing-support.auto-save-nvim" },
  { import = "astrocommunity.editing-support.text-case-nvim" }, -- ga + motion (e.g., gaciw for camelCase)
  { import = "astrocommunity.editing-support.conform-nvim" },
  {
    import = "astrocommunity.editing-support.zen-mode-nvim",
    ft = { "markdown", "tex" },
  },

  -- ========================================================================
  -- File Explorer
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#file-explorer

  -- ========================================================================
  -- Fuzzy Finder
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#fuzzy-finder

  -- ========================================================================
  -- Game
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#game

  -- ========================================================================
  -- Git
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#git

  -- ========================================================================
  -- Icon
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#icon

  -- ========================================================================
  -- Indent
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#indent

  -- ========================================================================
  -- Keybinding
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#keybinding

  -- ========================================================================
  -- LSP
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#lsp
  { import = "astrocommunity.lsp.lsp-signature-nvim" },

  -- ========================================================================
  -- Markdown and LaTeX
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#markdown-and-latex
  {
    import = "astrocommunity.markdown-and-latex.render-markdown-nvim",
    ft = "markdown",
  },
  {
    import = "astrocommunity.markdown-and-latex.glow-nvim", -- terminal markdown preview (no Node.js needed)
    ft = "markdown",
  },
  { import = "astrocommunity.markdown-and-latex.markdown-preview-nvim" },

  -- ========================================================================
  -- Media
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#media
  { import = "astrocommunity.media.cord-nvim" },
  { import = "astrocommunity.media.image-nvim" },

  -- ========================================================================
  -- Motion
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#motion
  { import = "astrocommunity.motion.nvim-surround" },
  { import = "astrocommunity.motion.hop-nvim" },
  -- hop-nvim configured separately in plugins/hop.lua with custom EasyMotion-style keys

  -- ========================================================================
  -- Neovim Lua Development
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#neovim-lua-development

  -- ========================================================================
  -- Note Taking
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#note-taking
  {
    import = "astrocommunity.note-taking.obsidian-nvim",
    ft = "markdown",
  },

  -- ========================================================================
  -- Pack
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#pack
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.markdown" },
  { import = "astrocommunity.pack.python" }, -- pyright + ruff + black
  { import = "astrocommunity.pack.godot" },
  { import = "astrocommunity.pack.go" },
  { import = "astrocommunity.pack.typescript" },
  { import = "astrocommunity.pack.sql" },

  -- ========================================================================
  -- Programming Language Support
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#programming-language-support
  { import = "astrocommunity.programming-language-support.kulala-nvim" }, -- HTTP client for .http files

  -- ========================================================================
  -- Project
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#project

  -- ========================================================================
  -- Quickfix
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#quickfix

  -- ========================================================================
  -- Recipes
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#recipes
  { import = "astrocommunity.recipes.vscode" },

  -- ========================================================================
  -- Register
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#register

  -- ========================================================================
  -- Remote Development
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#remote-development

  -- ========================================================================
  -- Scrolling
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#scrolling
  { import = "astrocommunity.scrolling.mini-animate" },

  -- ========================================================================
  -- Search
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#search

  -- ========================================================================
  -- Session
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#session

  -- ========================================================================
  -- Snippet
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#snippet

  -- ========================================================================
  -- Split and Window
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#split-and-window

  -- ========================================================================
  -- Startup
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#startup

  -- ========================================================================
  -- Syntax
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#syntax

  -- ========================================================================
  -- Terminal Integration
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#terminal-integration
  { import = "astrocommunity.terminal-integration.vim-tmux-navigator" },

  -- ========================================================================
  -- Test
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#test

  -- ========================================================================
  -- Utility
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#utility

  -- ========================================================================
  -- Workflow
  -- ========================================================================
  -- https://astronvim.github.io/astrocommunity/#workflow

  -- import/override with your plugins folder
}
