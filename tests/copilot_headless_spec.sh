#!/usr/bin/env bash
# Run with: bash tests/copilot_headless_spec.sh
#
# Copilot's node server is torn down by Neovim's LSP client only if the
# initialise handshake completed. A headless Neovim that exits sooner leaves
# the process orphaned to init, holding 250-600 MB, with nothing to reap it.
# Rapid headless runs -- which this repository's own verification does
# constantly -- stack those orphans until the machine runs out of memory.
#
# Case 1 (headless) is the one that matters here and is FIXED: `cond` in
# lua/plugins/user.lua stops Copilot starting when no UI is attached, so this
# repository's own verification can no longer stack orphans.
#
# Case 2 (a UI that quits within a second or two) is reported as [KNOWN] rather
# than failing the suite. It cannot be fixed from this config: the server is
# spawned detached, before Neovim registers an LSP client for it, so at
# VimLeavePre there is no client for any handler to stop -- verified by
# instrumentation, and the reason two attempted fixes were reverted. Closing it
# needs the server command wrapped in something like `setpriv --pdeathsig TERM`
# so the kernel reaps it, which means overriding copilot.lua's internals.
#
# Attribution is deliberate: only processes carrying this run's marker are ever
# touched, so a live interactive session's Copilot is never killed.

set -u

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATTERN='nvim/lazy/copilo[t]'
failures=0

copilot_pids() { pgrep -f "$PATTERN" 2>/dev/null || true; }

# Attribution by an inherited environment marker.
#
# Parent id does not work: the server is spawned detached, so it reparents to
# init immediately and looks identical to an orphan from any other Neovim.
# Session id does not work either, for the same reason -- detaching gives it a
# fresh session. "Appeared recently" is worse still: a live interactive editor
# restarting its own Copilot would be misread as our leak, and killing that
# silently stops a real session's suggestions.
#
# A child process inherits its parent's environment, and /proc/<pid>/environ
# keeps a copy. Stamping a unique token into the environment of the Neovim we
# launch therefore marks every server it spawns, however it detaches.
has_marker() { tr '\0' '\n' < "/proc/$1/environ" 2>/dev/null | grep -qx "COPILOT_ORPHAN_PROBE=$2"; }

# Run Neovim with a marker and report the copilot servers it left behind.
# $1: a shell command that runs nvim. Prints "pid(rssKB)" per survivor.
survivors_of_run() {
  local runner="$1" token
  token="probe_$$_${RANDOM}_$(date +%s)"

  COPILOT_ORPHAN_PROBE="$token" bash -c "$runner" >/dev/null 2>&1

  # A completed handshake tears the server down well inside this window.
  sleep 20

  for pid in $(copilot_pids); do
    if has_marker "$pid" "$token"; then
      local rss
      rss=$(awk '/VmRSS/{print $2}' "/proc/$pid/status" 2>/dev/null || echo 0)
      printf '%s(%skB) ' "$pid" "$rss"
    fi
  done
}

probe=$(mktemp /tmp/copilot_probe_XXXXXX.lua)
printf 'local x = 1\n' > "$probe"

# Case 1: headless, the mode this repository's own verification runs in.
leaked=$(survivors_of_run "cd '$CONFIG_DIR' && nvim --headless '+e $probe' +qa </dev/null")
if [ -n "$leaked" ]; then
  failures=$((failures + 1))
  echo "[FAIL] headless run orphaned copilot process(es): $leaked"
  for pid in $leaked; do kill "${pid%%(*}" 2>/dev/null; done
  echo "       (orphans killed so the test leaves no residue)"
else
  echo "[OK]   headless run left no orphaned copilot process"
fi

# Case 2: a real UI that quits before the LSP handshake completes. The server is
# spawned inside vim.lsp.start before the client is registered, so if Neovim
# exits in that window there is no client for any VimLeavePre handler to stop.
if ! command -v script >/dev/null 2>&1; then
  echo "[SKIP] ui-mode case needs the 'script' command for a pty"
else
  leaked_ui=$(survivors_of_run "cd '$CONFIG_DIR' && script -qec \"nvim '+e $probe' +qa\" /dev/null")
  if [ -n "$leaked_ui" ]; then
    echo "[KNOWN] ui run that quit early orphaned copilot process(es): $leaked_ui"
    echo "        Not a regression and not counted as a failure -- see the note"
    echo "        at the top of this file. Killing the orphan(s) now."
    for pid in $leaked_ui; do kill "${pid%%(*}" 2>/dev/null; done
  else
    echo "[OK]   ui run that quit early left no orphaned copilot process"
  fi
fi

rm -f "$probe"

if [ "$failures" -gt 0 ]; then
  echo
  echo "$failures test(s) failed"
  exit 1
fi
echo
echo "all tests passed"
