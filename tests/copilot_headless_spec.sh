#!/usr/bin/env bash
# Run with: bash tests/copilot_headless_spec.sh
#
# Copilot's node server is torn down by Neovim's LSP client only if the
# initialise handshake completed. A headless Neovim that exits sooner leaves
# the process orphaned to init, holding 250-600 MB, with nothing to reap it.
# Rapid headless runs -- which this repository's own verification does
# constantly -- stack those orphans until the machine runs out of memory.
#
# This test asserts that a headless run leaves no orphaned copilot process.
# It only ever inspects processes it can prove are orphans (reparented away
# from a live Neovim), so a running interactive session is never touched.

set -u

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATTERN='nvim/lazy/copilo[t]'
failures=0

copilot_pids() { pgrep -f "$PATTERN" 2>/dev/null || true; }

# An orphan has been reparented away from the Neovim that spawned it.
is_orphan() {
  local ppid
  ppid=$(awk '{print $4}' "/proc/$1/stat" 2>/dev/null) || return 1
  local pcomm
  pcomm=$(cat "/proc/$ppid/comm" 2>/dev/null || echo GONE)
  [ "$pcomm" != "nvim" ]
}

before=" $(copilot_pids | tr '\n' ' ') "

probe=$(mktemp /tmp/copilot_probe_XXXXXX.lua)
printf 'local x = 1\n' > "$probe"
(cd "$CONFIG_DIR" && nvim --headless "+e $probe" +qa </dev/null >/dev/null 2>&1)
rm -f "$probe"

# Generous grace: a completed handshake tears down well inside this window.
sleep 20

leaked=""
for pid in $(copilot_pids); do
  case "$before" in
    *" $pid "*) continue ;; # predates this test, not ours to judge
  esac
  if is_orphan "$pid"; then
    rss=$(awk '/VmRSS/{print $2}' "/proc/$pid/status" 2>/dev/null || echo 0)
    leaked="$leaked $pid(${rss}kB)"
  fi
done

if [ -n "$leaked" ]; then
  failures=$((failures + 1))
  echo "[FAIL] headless run orphaned copilot process(es):$leaked"
  for pid in $leaked; do kill "${pid%%(*}" 2>/dev/null; done
  echo "       (orphans killed so the test leaves no residue)"
else
  echo "[OK]   headless run left no orphaned copilot process"
fi

if [ "$failures" -gt 0 ]; then
  echo
  echo "$failures test(s) failed"
  exit 1
fi
echo
echo "all tests passed"
