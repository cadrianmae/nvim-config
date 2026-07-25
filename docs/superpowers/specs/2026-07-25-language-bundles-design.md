# Language Bundles and On-Demand Tooling

Date: 2026-07-25
Status: Approved, not yet implemented
Repo: `~/.config/nvim` (AstroNvim v4)

## Problem

The config supports many languages, and each one taxes the others. Adding a
language means editing four or five files; removing one means hunting through
the same four or five for orphans. Every configured language pre-installs its
tooling whether or not it is ever used.

Measured state before any change:

| Thing | Amount |
|---|---|
| Mason packages | 40 (1.3 GB) |
| Lazy plugin repos | 108 (1.1 GB) |
| Startup, `~/.config/nvim` | 101 ms |
| Startup, `snappy-fyp` | 130 ms |

The user's stated goal: make a multi-language programmer's life less cluttered.
The irritation is Mason auto-installing, Treesitter parsers, and cmp sources for
languages not in use. Not startup speed.

## Goals

1. One file per language stack. Adding a language is one new file; removing one
   is `rm` of that file, with nothing stranded elsewhere.
2. "Configured" stops meaning "installed". Tooling downloads on first use.
3. A declared set of languages that stay installed regardless, for offline work.
4. No startup regression.

## Non-goals

- Reducing startup time. Startup is a regression guard, not a target.
- Gating the plugin layer. Measured: dormant-language plugin repos total 16 MB
  out of 1081 MB, so detection machinery is not justified.
- Project detection from marker files. Rejected: false positives, `:Lazy clean`
  hazard, and it misses a lone source file outside a matching project.
- A bespoke project override file. `neoconf.nvim` already covers the need.

## Evidence

**Disk, by layer.** `copilot.lua` is 771 MB, 71% of the entire lazy directory
and unrelated to languages. Language-specific plugin repos total 76 MB, of which
60 MB is markdown tooling in daily use. Dormant-language repos: 16 MB.

**Languages actually in use**, from scanning all 35 repos under
`~/git/github.com/cadrianmae/` by repo count and last commit date:

| Language | Repos | Most recent | Tier |
|---|---|---|---|
| markdown | ~30 | current | eager |
| json / yaml / toml | ~28 | current | eager |
| bash | 12 | 2026-07 | eager |
| C | 1 (tu856-4) | 2026-07 | eager |
| lua | 3 + this config | 2026-04 | eager |
| html / css / js | ~15 | 2026-07 | on-demand |
| python | 12 | 2026-07 | on-demand |
| typescript | 6 | 2026-07 | on-demand |
| gdscript | 2 | 2026-07-13 | on-demand |
| qml | 1 | 2026-07-15 | on-demand |
| go | 3 | 2026-04 | on-demand |
| java / kotlin | 1 (+ upcoming mod work) | 2023 / upcoming | on-demand |
| tex | 2 | 2026-04 | on-demand |
| sql / cql | 1 (tu856-4) | 2026-07 | on-demand |
| R / quarto | 1 (tu856-4) | 2026-07 | on-demand |
| prolog | 1 (tu856-4) | 2026-07 | on-demand |
| mcfunction | 1 | 2025-10 | on-demand |

Editor history (`v:oldfiles`) was checked first and proved misleading: it
covered a short, C-heavy window and showed no Go, TypeScript or Godot activity
despite all three being current. Repo scanning corrected this.

Minecraft *mod* work (Java/Kotlin/Gradle) is upcoming and distinct from the
existing datapack support (mcfunction, Spyglass LSP).

## Design

### 1. Language bundles

One file per language stack, in a directory imported last so bundles can
override anything above them.

```
lua/
  lang_policy.lua              -- baseline + accumulator (plain module, not a spec)
  community.lua                -- non-language plugins only
  plugins/
    astrocore.lua ...          -- non-language config
    lang/
      c.lua python.lua go.lua jvm.lua ...
```

```lua
-- lua/lazy_setup.lua
{ import = "community" },
{ import = "plugins" },
{ import = "plugins.lang" },   -- explicit: lazy's lsmod does not recurse into subdirs
```

Verified in `lazy.nvim/lua/lazy/core/util.lua:310` (`lsmod`): a directory import
reads only `.lua` files at that level, plus a subdirectory's `init.lua` if one
exists. `plugins/lang/` therefore needs its own import line, which also gives
the ordering the policy layer depends on.

Bundles wrap their AstroCommunity pack rather than replacing it, so the curated
defaults (DAP wiring, extra plugins) are kept and local overrides sit beside
them in the same file.

The unit is a **stack**, not strictly a language: `jvm.lua` owns Java, Kotlin
and Gradle; `web.lua` owns TypeScript, JavaScript, HTML and CSS. The rule is
"one file you can delete to remove a capability".

This matches the LazyVim `lua/lazyvim/plugins/extras/lang/<lang>.lua` convention
and AstroCommunity's own `pack.<lang>` module-per-language layout.

### 2. Install policy

Two settings, both confirmed present in the currently locked versions
(`nvim-treesitter` on `master` has `auto_install`, default `false`;
`mason-lspconfig` v1.32.0 has `automatic_installation`, default `false`;
Neovim 0.11.6):

```lua
opts = { auto_install = true }             -- nvim-treesitter
opts = { automatic_installation = true }   -- mason-lspconfig
```

`ensure_installed` changes meaning: from "everything I might use" to "what must
work offline".

The packs *append* to those same lists, so a short list is not enough on its
own. Something must overwrite last. The mechanism is an `opts` function, which
runs at plugin-load time and therefore after all spec parsing:

```lua
-- lua/lazy_setup.lua, after all imports
local policy = require "lang_policy"

{ "nvim-treesitter/nvim-treesitter", opts = function(_, o)
    o.ensure_installed = policy.resolve "treesitter"
    o.auto_install = true
  end },
{ "williamboman/mason-lspconfig.nvim", opts = function(_, o)
    o.ensure_installed = policy.resolve "lsp"
    o.automatic_installation = true
  end },
-- same shape for mason-null-ls (tools) and mason-nvim-dap (dap)
```

### 3. File shapes

`lua/lang_policy.lua` holds the editor-wide baseline and collects registrations
from eager bundles. It is a plain module, not a spec, so it cannot live in
`plugins/lang/` — lazy would try to import it as a spec.

```lua
local M = {}

-- Editor-wide baseline: installed regardless of which languages are configured.
M.baseline = {
  treesitter = { "lua", "vim", "vimdoc", "markdown", "markdown_inline", "bash" },
  lsp        = { "lua_ls", "marksman" },
  tools      = { "stylua", "prettierd", "markdownlint-cli2" },
  dap        = {},
}

local eager = { treesitter = {}, lsp = {}, tools = {}, dap = {} }

--- Called by a language bundle that wants its tooling pre-installed.
function M.eager(spec) end

--- baseline plus everything registered by eager bundles
function M.resolve(key) end

return M
```

A bundle opts into eager installation with one line:

```lua
-- lua/plugins/lang/c.lua
-- C: clangd + codelldb. Eager: coursework, must survive being offline.
require("lang_policy").eager { lsp = { "clangd" }, treesitter = { "c" }, dap = { "codelldb" } }

return {
  { import = "astrocommunity.pack.cpp" },
}
```

```lua
-- lua/plugins/lang/go.lua
-- Go: on-demand. gopls installs on first *.go open.
return {
  { import = "astrocommunity.pack.go" },
}
```

The only difference between eager and on-demand is the presence of that line.

Ordering is safe because bundle files execute during `{ import = "plugins.lang" }`
(spec-parse time), while `opts` functions run at plugin-load time. The
accumulator is always complete before anything reads it.

### 4. Project overrides

No new mechanism. `neoconf.nvim` ships with AstroNvim and is already installed.
It resolves settings via `lspconfig.util.root_pattern`, which searches upward
from the file and falls back to the `.git` root — so opening
`tu856-4/labs/week3/foo.c` picks up `tu856-4/.neoconf.json`.

```json
{ "lspconfig": { "sqls": false, "basedpyright": { "python.analysis.typeCheckingMode": "off" } } }
```

With on-demand installation, per-project *enabling* is automatic: open a file of
that type and the tooling arrives. Only disabling needs an override, and
neoconf covers it.

`exrc = true` is already set, so `.nvim.lua` also works, but Neovim reads it
from the current directory only with no upward search. neoconf is the right
tool for the sub-directory case.

Note: `exrc` is currently set inside `lua/plugins/minecraft-datapack.lua` — a
language file setting a global option. It moves to `astrocore.lua` as part of
this work.

## Migration

Each step is its own commit on a branch, independently revertible.

**Step 1 — prove the mechanism, change no behaviour.** Create `lang_policy.lua`
and the overwrite specs, populated with exactly what is installed today.
Verify `:Mason` still shows 40 packages and startup is unchanged. This is where
the astrolsp risk gets settled.

**Step 2 — flip to on-demand.** Shrink the baseline to the eager tier, enable
`auto_install` and `automatic_installation`. Verify `:Mason` drops to ~10, then
open a `.go` file and confirm gopls downloads and attaches.

**Step 3 — move packs into bundles, one at a time.** Least-used first
(`prolog`, `r`, `sql`, `minecraft`), most-used last (`c`, `python`, `web`), so
early breakage lands on a language not being used mid-task. After each: a clean
`Lazy! check`, open a file of that type, confirm the expected LSP client.

Mapping of what exists today to where it lands:

| Today | Becomes |
|---|---|
| `community.lua` pack.python + `plugins/basedpyright.lua` | `plugins/lang/python.lua` |
| `community.lua` pack.cpp + clangd/codelldb entries in `mason.lua` | `plugins/lang/c.lua` (eager) |
| `community.lua` pack.typescript | `plugins/lang/web.lua` |
| `community.lua` pack.go | `plugins/lang/go.lua` |
| `community.lua` pack.sql + `plugins/cql-filetype.lua` | `plugins/lang/sql.lua` |
| `community.lua` pack.quarto + `plugins/r.lua` | `plugins/lang/r.lua` |
| `community.lua` pack.godot | `plugins/lang/godot.lua` |
| `community.lua` pack.lua | `plugins/lang/lua.lua` (eager) |
| `community.lua` pack.markdown + markdown plugin configs | `plugins/lang/markdown.lua` (eager) |
| `plugins/prolog.lua` | `plugins/lang/prolog.lua` |
| `plugins/minecraft-datapack.lua` (minus its `exrc` setting) | `plugins/lang/minecraft.lua` |
| `plugins/godotdev.lua` (dead code) | deleted |
| `exrc` setting in `plugins/minecraft-datapack.lua` | `plugins/astrocore.lua` |

**Step 4 — new bundles.** `jvm.lua` (Java + Kotlin + Gradle) and `qml.lua`.
Neither exists today; QML is an existing gap, not one this refactor creates —
there is no AstroCommunity pack for it, so it stays hand-rolled like Prolog.

**Step 5 — cleanup.** `:MasonUninstall` orphans, remove the two stale
`*.cloning` directories, delete the dead `plugins/godotdev.lua` (already
short-circuited with `if true then return {} end`), move `exrc` to
`astrocore.lua`.

## Verification

| Metric | Before | Target |
|---|---|---|
| Mason packages | 40 (1.3 GB) | ~10, refilling on use |
| Startup, `~/.config/nvim` | 101 ms | <= 101 ms |
| Startup, `snappy-fyp` | 130 ms | <= 130 ms |
| Files touched to add a language | 4-5 | 1 |
| Files touched to remove a language | 4-5 | 1 |

Startup measured with `nvim --startuptime <file> +qa </dev/null`, averaged over
three runs. Note that `--startuptime` produces no output under `--headless`.

Per-language check: open a file of that type, confirm the expected client via
`:LspInfo`, confirm the parser loaded via `:InspectTree`.

## Risks

1. **AstroLSP re-adds servers after the overwrite.** AstroNvim does its own
   Mason wiring, so the overwrite may be undone. Fallback: move the overwrite
   into an astrolsp `opts` function. Settled in step 1 before anything depends
   on it.
2. **`auto_install` needs a compiler and network on first open.** The eager tier
   is the offline safety net; C, markdown, lua and bash stay local.
3. **`automatic_installation` may not behave as documented.** Fallback: keep a
   slightly larger eager list.
4. **First open of a dormant language pauses** while tooling downloads. Accepted
   trade for 1.3 GB to ~300 MB.

## Resolved: `ft` on an import block

Settled from source rather than by experiment. In
`lazy.nvim/lua/lazy/core/plugin.lua:118-210`, `Spec:import` reads only `import`,
`name`, `cond` and `enabled`. Imported modules are handed to `Spec:normalize`
with no inheritance of parent fields, and `self.importing` is used only to
attribute error messages. Every other key on an import block — `ft`, `event`,
`keys` — is discarded.

Consequences:

1. `{ import = "astrocommunity.pack.go", ft = "go" }` would not defer anything.
   The overwrite mechanism in section 2 is required, not merely preferred.
2. `cond` and `enabled` *do* work on import blocks (lines 136-141 return early,
   so the module is never read). This is not used here — the plugin layer is
   deliberately not gated — but it is the correct mechanism should that change.
3. Three existing `ft` keys in `community.lua` are no-ops: on the
   `render-markdown-nvim`, `obsidian-nvim` and `zen-mode-nvim` imports. Whether
   those plugins lazy-load still depends on the packs' own specs; the keys
   themselves do nothing. They are removed during migration to avoid implying a
   guarantee that is not there.
