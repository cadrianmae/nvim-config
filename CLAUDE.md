# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is an **AstroNvim v4** configuration repository. AstroNvim is a Neovim distribution that provides a modular plugin architecture with centralized configuration through core plugins.

### Core Structure

```
~/.config/nvim/
├── init.lua                 # Bootstraps lazy.nvim and loads main config
├── lua/
│   ├── lazy_setup.lua       # Lazy.nvim plugin manager setup
│   ├── lang_policy.lua      # Baseline/eager/on-demand tooling install policy
│   ├── community.lua        # AstroCommunity plugin imports (non-language)
│   ├── polish.lua           # Final setup (filetypes, line endings)
│   └── plugins/             # Custom plugin configurations
│       └── lang/            # One file per language stack (see Language Bundles)
└── snippets/                # Custom LuaSnip snippets
```

### Configuration Hierarchy

1. **AstroNvim Core** - Base distribution (`AstroNvim/AstroNvim`)
2. **AstroCommunity** - Pre-configured community plugins (`lua/community.lua`)
3. **User Plugins** - Custom configurations (`lua/plugins/*.lua`)

Import order matters: Community plugins load before user plugins, allowing overrides.

## Plugin Configuration Patterns

### AstroCommunity Plugins

Located in `lua/community.lua`. Use full GitHub path syntax when customizing:

```lua
-- In community.lua (import)
{ import = "astrocommunity.motion.hop-nvim" }

-- In lua/plugins/hop.lua (customize)
return {
  "smoka7/hop.nvim",  -- Full GitHub path required
  opts = { ... }
}
```

**Never use shorthand names** like `"hop-nvim"` in plugin specs - lazy.nvim requires `"author/repo"` format.

### Core Plugin Customization

Three core plugins manage all AstroNvim configuration:

- **astrocore.lua** - Keymaps, vim options, autocommands
- **astrolsp.lua** - LSP server configs, handlers, keybindings
- **astroui.lua** - UI settings, icons, colorscheme

### Custom Plugin Structure

Files in `lua/plugins/` follow this pattern:

```lua
return {
  "author/plugin-name",
  event = "VeryLazy",  -- or ft, cmd, keys for lazy loading
  opts = { ... },      -- Merged with defaults
  config = function(_, opts)  -- When custom setup needed
    require("plugin").setup(opts)
  end,
}
```

**Using `config` function:** Must explicitly call `setup(opts)` - `opts` alone won't initialize the plugin.

### Language Bundles

Each language stack owns one file in `lua/plugins/lang/`. Adding a language
means adding a file; removing one means deleting it. Nothing about a language
lives anywhere else.

```lua
-- lua/plugins/lang/rust.lua
---@type LazySpec
return {
  { import = "astrocommunity.pack.rust" },
}
```

Tooling installs on first use — opening a `.rs` file installs rust-analyzer and
compiles the parser. A bundle that must work offline registers itself eagerly
instead:

```lua
require("lang_policy").eager { lsp = { "clangd" }, treesitter = { "c" } }
```

Editor-wide tooling that is not tied to one language goes in `M.baseline` in
`lua/lang_policy.lua`.

Project-specific overrides use `.neoconf.json`, which `neoconf.nvim` finds by
searching upward from the file — so it applies from any subdirectory of the
project:

```json
{
  "lspconfig": {
    "sqls": false,
    "basedpyright": {
      "python.analysis.typeCheckingMode": "off"
    }
  }
}
```

Worked example — `~/git/github.com/cadrianmae/tu856-4/.neoconf.json`, applying
to every module directory beneath it:

```json
{
  "lspconfig": {
    "sqlfluff": {
      "dialect": "postgres"
    },
    "basedpyright": {
      "python.analysis.typeCheckingMode": "basic",
      "python.analysis.diagnosticSeverityOverrides": {
        "reportMissingImports": "warning"
      }
    }
  }
}
```

Use `.neoconf.json` for settings and for disabling a server in one project. Do
not move language *bundles* into a project's `.lazy.lua`: on-demand
installation already makes an unused global bundle free, while a project-scoped
spec is removed by `:Lazy sync` (which cleans) whenever Neovim is opened
elsewhere, and churns `lazy-lock.json` in this repository. Reserve `.lazy.lua`
for a plugin that genuinely only ever applies to one project.

Note: `ft`, `event` and `keys` do nothing on an `{ import = ... }` block. Lazy's
`Spec:import` reads only `import`, `name`, `cond` and `enabled`.

A project that needs its own plugin specs uses `.lazy.lua`, which lazy finds by
walking upward from the cwd, so it applies from any subdirectory:

```lua
-- <project>/.lazy.lua
vim.opt.rtp:prepend(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h"))
return { { import = "myprojplugins" } }   -- <project>/lua/myprojplugins/*.lua
```

Three constraints: only the first `.lazy.lua` found is used (no merging of
nested files); it is read through `vim.secure.read`, so the first open prompts
for trust; and the module directory must not be named `plugins`, because import
specs are deduplicated by module name and this config already imports `plugins`
— a collision is skipped silently, with no error.

## Language Support

### Python
- LSP: **basedpyright** (not pyright) via `lua/plugins/lang/python.lua`
- Custom config disables pyright in astrolsp handlers
- Mason installs basedpyright automatically
- venv-selector integration configured

### Prolog
- Custom LSP setup via SWI-Prolog (`lua/plugins/lang/prolog.lua`)
- Filetype detection: `.pl`, `.pro`, `.P` → `prolog`
- Manual LSP config (not available in Mason)

### Go
- Bundle: `lua/plugins/lang/go.lua`
- **gopls installation issues:** Requires Go 1.26+, system has 1.25.11
- Workaround: `go env -w GOTOOLCHAIN=auto` then retry mason install

### SQL/CQL
- Bundle: `lua/plugins/lang/sql.lua`
- CQL language server for Cassandra
- Custom filetype for `.cql` files
- SQLFluff formatter configured for postgres dialect

## Key Customizations

### Hop.nvim (Motion Plugin)
EasyMotion-style navigation with `<leader><leader>` prefix:
- Uses DRY pattern with helper function
- Must call `hop.setup(opts)` in config function
- Group description uses `astroui.get_icon()` for icons

### Obsidian Integration
Two vault workspaces configured:
- `tu856`: Academic vault at `~/Documents/Computer Science TU856`
- `personal`: Personal vault at `~/Documents/The Nexus Vault`

### Custom Icons
Define custom icons in `astroui.lua`:
```lua
icons = {
  CustomIcon = "",
}
```
Access with: `require("astroui").get_icon("CustomIcon", 1, true)`

## Common Development Tasks

### Sync Plugins
```bash
# Start Neovim - lazy.nvim auto-installs on first run
nvim

# Inside Neovim
:Lazy sync         # Update all plugins
:Lazy clean        # Remove unused plugins
:Mason             # Manage LSP/formatters/linters
```

### Testing Configuration Changes
```bash
# Clean install test
rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
nvim  # Reinstalls everything
```

### Linting Lua Code
```bash
# Selene linter (config: selene.toml)
selene lua/

# Stylua formatter (config: .stylua.toml)
stylua lua/ --check
stylua lua/ --write
```

## File Conventions

- **Unix line endings only** - Enforced in `polish.lua`
- **Lazy loading** - Prefer `event`, `ft`, `cmd`, `keys` over eager loading
- **Documentation** - Use LSP hover (`:h <topic>`) for AstroNvim docs

## Troubleshooting

### Plugin Won't Load
1. Check full GitHub path used (not shorthand)
2. Verify lazy loading triggers (`ft`, `event`, etc.)
3. Check `lazy-lock.json` for version locks
4. Run `:Lazy restore` to reset to lockfile state

### LSP Issues
- Check `~/.local/share/nvim/mason/` for installed servers
- View logs: `:LspLog` or `~/.local/state/nvim/lsp.log`
- basedpyright: Ensure pyright is NOT in mason handlers

### Community Plugin Customization Not Working
- Ensure customization file uses full `"author/repo"` path
- Community import must come before user plugin in load order
- Check if plugin has a custom `name` field (like catppuccin)
