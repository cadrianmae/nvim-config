-- Bash: bashls, shellcheck and shfmt, for the shell scripts in ~/.config and
-- across the repos. The `bash` parser is in the lang_policy baseline already.
-- On-demand: nothing installs until a .sh, .bash or .zsh file is opened.
---@type LazySpec
return {
  { import = "astrocommunity.pack.bash" },
}
