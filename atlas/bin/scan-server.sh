#!/usr/bin/env bash
# Atlas · scan-server.sh — run the read-only collector on a host and save its map.
#
#   scan-server.sh local                 # scan THIS machine
#   scan-server.sh user@host [name]      # scan a remote host over SSH
#   scan-server.sh -f hosts.txt          # scan every "user@host [name]" line in a file
#
# Nothing is written to the target. Output lands in atlas/inventory/<name>.md.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
COLLECT="$HERE/collect.sh"
OUTDIR="$(cd "$HERE/.." && pwd)/inventory"
mkdir -p "$OUTDIR"
[ -f "$COLLECT" ] || { echo "error: collect.sh not found next to this script" >&2; exit 1; }

scan_one() {
  local target="$1" name="${2:-}"
  if [ "$target" = "local" ]; then
    name="${name:-$(hostname -s 2>/dev/null || echo localhost)}"
    echo ">> scanning local host → inventory/$name.md"
    bash "$COLLECT" > "$OUTDIR/$name.md"
  else
    name="${name:-${target##*@}}"; name="${name//[^A-Za-z0-9._-]/_}"
    echo ">> scanning $target → inventory/$name.md"
    # Stream the collector into the remote shell; capture stdout to a temp file,
    # and only commit it on success so a failed SSH never leaves an empty map.
    # BatchMode (no prompts) by default so multi-host runs never hang.
    # Set ATLAS_INTERACTIVE=1 to allow SSH to prompt for a password/passphrase.
    local batch="-o BatchMode=yes"; [ "${ATLAS_INTERACTIVE:-0}" = "1" ] && batch=""
    # Optional explicit key, so no ~/.ssh/config change is needed: ATLAS_SSH_KEY=/path/to/key
    local keyopt=""; [ -n "${ATLAS_SSH_KEY:-}" ] && keyopt="-i ${ATLAS_SSH_KEY} -o IdentitiesOnly=yes"
    local tmp; tmp="$(mktemp "$OUTDIR/.$name.XXXXXX")"
    if ssh $batch $keyopt -o ConnectTimeout=15 "$target" 'bash -s' < "$COLLECT" > "$tmp" && [ -s "$tmp" ]; then
      mv "$tmp" "$OUTDIR/$name.md"
    else
      rm -f "$tmp"
      echo "   !! ssh to $target failed (check key / BatchMode / hostname)"; return 1
    fi
  fi
  echo "   done ($(wc -l < "$OUTDIR/$name.md" | tr -d ' ') lines)"
}

if [ "${1:-}" = "-f" ]; then
  [ -n "${2:-}" ] || { echo "usage: scan-server.sh -f hosts.txt" >&2; exit 1; }
  while read -r target name _; do
    [ -z "$target" ] && continue; case "$target" in \#*) continue;; esac
    scan_one "$target" "$name" || true
  done < "$2"
elif [ -n "${1:-}" ]; then
  scan_one "$1" "${2:-}"
else
  echo "usage:" >&2
  echo "  scan-server.sh local" >&2
  echo "  scan-server.sh user@host [name]" >&2
  echo "  scan-server.sh -f hosts.txt" >&2
  exit 1
fi

echo ">> updating INDEX.md"
bash "$HERE/build-index.sh" 2>/dev/null || true
