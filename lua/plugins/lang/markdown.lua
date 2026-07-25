-- Markdown: the pack plus the render, preview and TOC plugins. Parsers and
-- marksman are in the lang_policy baseline -- markdown is used in nearly every
-- repo, so it must work offline.
--
-- The `ft` keys that used to sit on these import blocks were no-ops: lazy's
-- Spec:import reads only `import`, `name`, `cond` and `enabled`, and discards
-- everything else. Lazy-loading is whatever each pack declares internally.
---@type LazySpec
return {
  { import = "astrocommunity.pack.markdown" },
  { import = "astrocommunity.markdown-and-latex.render-markdown-nvim" },
  { import = "astrocommunity.markdown-and-latex.glow-nvim" },
  { import = "astrocommunity.markdown-and-latex.markdown-preview-nvim" },
}
