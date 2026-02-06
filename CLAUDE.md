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
│   ├── community.lua        # AstroCommunity plugin imports (28+ plugins)
│   ├── polish.lua           # Final setup (filetypes, line endings)
│   └── plugins/             # Custom plugin configurations
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

## Language Support

### Python
- LSP: **basedpyright** (not pyright) via `lua/plugins/basedpyright.lua`
- Custom config disables pyright in astrolsp handlers
- Mason installs basedpyright automatically
- venv-selector integration configured

### Prolog
- Custom LSP setup via SWI-Prolog (`lua/plugins/prolog.lua`)
- Filetype detection: `.pl`, `.pro`, `.P` → `prolog`
- Manual LSP config (not available in Mason)

### Go
- **gopls installation issues:** Requires Go 1.25+, system has 1.24
- Workaround: `go env -w GOTOOLCHAIN=auto` then retry mason install

### SQL/CQL
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
