# Future Plugin Additions

Potential plugins to add to the AstroNvim configuration when needed.

## High Priority (ADHD/Autism-Friendly)

### Git Visual Feedback
**Plugin:** `astrocommunity.git.gitsigns-nvim`

```lua
-- In community.lua under Git section:
{ import = "astrocommunity.git.gitsigns-nvim" },
```

**Why:** Shows changed lines in gutter (non-jarring visual feedback)
**Benefit:** See git changes without running commands

---

### Better File Navigation
**Plugin:** `astrocommunity.file-explorer.oil-nvim`

```lua
-- In community.lua under File Explorer:
{ import = "astrocommunity.file-explorer.oil-nvim" },
```

**Why:** Edit filesystem like a buffer (lower cognitive load than netrw menus)
**Benefit:** File operations feel like text editing - more intuitive

---

### Visual Indent Guides
**Plugin:** `astrocommunity.indent.indent-blankline-nvim`

```lua
-- In community.lua under Indent:
{ import = "astrocommunity.indent.indent-blankline-nvim" },
```

**Why:** Shows code structure visually (helps with nesting/context)
**Benefit:** Easier to see code blocks and nesting levels at a glance

---

### Better UI Notifications
**Plugin:** `astrocommunity.utility.noice-nvim`

```lua
-- In community.lua under Utility:
{ import = "astrocommunity.utility.noice-nvim" },
```

**Why:** Smooth, non-intrusive notifications (ADHD-friendly)
**Benefit:** Less jarring visual interruptions during work

---

## Medium Priority

### Debugger for Python/Go
**Plugin:** `astrocommunity.debugging.nvim-dap-python`

```lua
-- In community.lua under Debugging:
{ import = "astrocommunity.debugging.nvim-dap-python" },
```

**Why:** Visual debugging for FYP and academic projects
**Benefit:** Step through code instead of print debugging

---

### Project Switching
**Plugin:** `astrocommunity.project.project-nvim`

```lua
-- In community.lua under Project:
{ import = "astrocommunity.project.project-nvim" },
```

**Why:** Quick switching between academic projects
**Benefit:** Less context switching overhead

---

### Code Context in Winbar
**Plugin:** `astrocommunity.bars-and-lines.dropbar-nvim`

```lua
-- In community.lua under Bars and Lines:
{ import = "astrocommunity.bars-and-lines.dropbar-nvim" },
```

**Why:** Shows current function/class in top bar
**Benefit:** Always know where you are in the code

---

## Already Have (For Reference)

✅ Copilot (Alt+Enter word-by-word, Alt+} full suggestion)
✅ Hop (EasyMotion-style navigation)
✅ Trouble (diagnostics)
✅ Todo-comments
✅ Obsidian integration
✅ Markdown tools (render, preview, TOC, word count)
✅ Spell check (en_gb)
✅ Auto-save (excludes claudecode diffs)
✅ ClaudeCode (tmux split 25% right)
✅ Snacks.nvim (terminal support)
✅ Vim-tmux-navigator

---

## Snacks.nvim Features to Explore

Currently using: `terminal`, `bigfile`, `quickfile`, `image`

snacks.nvim is a modular plugin collection - enable only what you want in `lua/plugins/snacks.lua`.

### High Impact Features

#### Dashboard
**What:** Beautiful startup screen with recent files, projects, shortcuts

```lua
-- In snacks.lua opts:
dashboard = {
  enabled = true,
  preset = {
    keys = {
      { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
      { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
      { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
      { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
      { icon = " ", key = "q", desc = "Quit", action = ":qa" },
    },
  },
},
```

**Why:** Visual context on startup (reduced decision fatigue)
**ADHD-Friendly:** Clear options, muscle memory shortcuts

---

#### Notifier
**What:** Pretty, non-intrusive notification system (replaces default messages)

```lua
-- In snacks.lua opts:
notifier = {
  enabled = true,
  timeout = 3000, -- Auto-dismiss after 3s
  style = "compact",
},
```

**Why:** Smooth animations, less jarring than default
**ADHD-Friendly:** Non-intrusive, automatically dismissed

**Note:** Consider enabling this instead of `astrocommunity.utility.noice-nvim` (similar functionality, less overhead)

---

#### Indent Guides (snacks.indent)
**What:** Visual indent lines with scope highlighting

```lua
-- In snacks.lua opts:
indent = {
  enabled = true,
  animate = {
    enabled = false, -- Disable animations to reduce distraction
  },
},
```

**Why:** Shows code structure visually
**ADHD-Friendly:** Clear nesting context at a glance

**Alternative:** `astrocommunity.indent.indent-blankline-nvim` (more features, more config)

---

#### GitBrowse
**What:** Open current file/line in GitHub/GitLab with `<Leader>go`

```lua
-- In snacks.lua opts:
gitbrowse = { enabled = true },
```

**Why:** Quick jump to remote repo
**Benefit:** Less context switching to check code online

---

#### Picker
**What:** Modern fuzzy finder (alternative to Telescope)

```lua
-- In snacks.lua opts:
picker = {
  enabled = true,
  sources = {
    files = { hidden = true }, -- Include hidden files
  },
},
```

**Why:** Faster, better UI than Telescope
**Trade-off:** If already using Telescope, might conflict

---

### Medium Impact Features

#### Zen Mode
**What:** Distraction-free writing/coding mode

```lua
-- In snacks.lua opts:
zen = {
  enabled = true,
  toggles = {
    dim = true,
    git_signs = false,
    diagnostics = false,
  },
},
```

**Why:** Focus mode for deep work
**ADHD-Friendly:** Reduces visual noise

**Note:** Already have `astrocommunity.editing-support.zen-mode-nvim` - check if redundant

---

#### Scroll (Smooth Scrolling)
**What:** Animated scrolling with easing

```lua
-- In snacks.lua opts:
scroll = {
  enabled = true,
  animate = {
    duration = { step = 15, total = 150 }, -- Fast animation
    easing = "linear",
  },
},
```

**Why:** Visual continuity when scrolling
**Autism-Friendly:** Predictable, smooth motion (less jarring)

---

#### Words (LSP References)
**What:** Highlights other occurrences of word under cursor

```lua
-- In snacks.lua opts:
words = { enabled = true },
```

**Why:** See all usages of a variable/function
**Benefit:** Context awareness without running commands

---

#### Statuscolumn
**What:** Enhanced status column (line numbers, git signs, folds)

```lua
-- In snacks.lua opts:
statuscolumn = { enabled = true },
```

**Why:** Better visual information density
**Benefit:** More context in the gutter

---

#### LazyGit Integration
**What:** LazyGit in a floating terminal with theme sync

```lua
-- In snacks.lua opts:
lazygit = {
  enabled = true,
  configure = true, -- Auto-configure LazyGit colors
},
```

**Why:** Visual git interface in Neovim
**Benefit:** Git without leaving editor

---

### Advanced Features

#### Rename (LSP File Rename)
**What:** Rename files with LSP-aware import updates

```lua
-- In snacks.lua opts:
rename = { enabled = true },
```

**Why:** Rename files without breaking imports
**Benefit:** Safe refactoring

---

#### Debug (Profiler)
**What:** Performance profiling and debugging utilities

```lua
-- In snacks.lua opts:
debug = { enabled = true },
```

**Why:** Profile slow startups, debug issues
**Use Case:** Troubleshooting only

---

#### Scratch (Scratch Buffers)
**What:** Quick throwaway buffers for notes/calculations

```lua
-- In snacks.lua opts:
scratch = { enabled = true },
```

**Why:** Quick scratch space without creating files
**ADHD-Friendly:** Low friction for quick thoughts

---

### Configuration Template

```lua
-- In lua/plugins/snacks.lua
return {
  "folke/snacks.nvim",
  opts = {
    -- Currently enabled
    terminal = {},
    bigfile = { enabled = true },
    quickfile = { enabled = true },
    image = { enabled = true },

    -- High impact additions
    dashboard = { enabled = true },
    notifier = { enabled = true, timeout = 3000 },
    indent = { enabled = true, animate = { enabled = false } },
    gitbrowse = { enabled = true },

    -- Medium impact additions
    scroll = { enabled = true },
    words = { enabled = true },
    statuscolumn = { enabled = true },

    -- As needed
    -- zen = { enabled = true },
    -- picker = { enabled = true },
    -- lazygit = { enabled = true },
    -- rename = { enabled = true },
    -- scratch = { enabled = true },
  },
}
```

---

### Conflict Considerations

**Before enabling:**
- `snacks.indent` vs `indent-blankline-nvim` - Choose one
- `snacks.notifier` vs `noice-nvim` - Choose one (snacks is lighter)
- `snacks.picker` vs Telescope - Can coexist but redundant
- `snacks.zen` vs `zen-mode-nvim` - Already have zen-mode-nvim in community.lua

---

### Quick Win Snacks Package

Start with these ADHD/Autism-friendly features:

```lua
opts = {
  -- Already enabled
  terminal = {},
  bigfile = { enabled = true },
  quickfile = { enabled = true },
  image = { enabled = true },

  -- Add these:
  notifier = { enabled = true, timeout = 3000 },
  indent = { enabled = true, animate = { enabled = false } },
  gitbrowse = { enabled = true },
  scroll = { enabled = true },
  words = { enabled = true },
}
```

**Impact:** Visual feedback, reduced cognitive load, smooth UX
**Trade-off:** Minimal - all lightweight utilities

---

## Installation Notes

When adding plugins from AstroCommunity:

1. Add import to appropriate section in `lua/community.lua`
2. Run `:Lazy sync` in Neovim
3. Restart Neovim if needed
4. Test functionality
5. Commit changes with descriptive message

## Quick Win Package

To add the top 4 most impactful plugins at once:

```lua
-- In community.lua, add to appropriate sections:

-- Bars and Lines (if using dropbar)
{ import = "astrocommunity.bars-and-lines.dropbar-nvim" },

-- Git
{ import = "astrocommunity.git.gitsigns-nvim" },

-- File Explorer
{ import = "astrocommunity.file-explorer.oil-nvim" },

-- Indent
{ import = "astrocommunity.indent.indent-blankline-nvim" },

-- Utility
{ import = "astrocommunity.utility.noice-nvim" },
```

These provide visual feedback and reduce cognitive load without adding workflow complexity.
