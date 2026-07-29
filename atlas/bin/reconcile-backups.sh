#!/usr/bin/env bash
# Atlas · reconcile-backups.sh — flag sites/databases that have no backup job.
#
#   reconcile-backups.sh <inventory.md> [--web-root PATH]
#
# Reads a single inventory FILE produced by collect.sh. It scans NOTHING live —
# it only reconciles what a map already records. Name-level & deterministic:
# a site is "covered" when one of its identifying tokens is a whole token in a
# backup job name. Blanket jobs (e.g. *_system_state) can't be judged by name —
# it says so.
set -uo pipefail

INV="${1:-}"; ROOT="/var/www"
[ "${2:-}" = "--web-root" ] && ROOT="${3:-/var/www}"
[ -f "$INV" ] || { echo "usage: reconcile-backups.sh <inventory.md> [--web-root PATH]" >&2; exit 2; }
lower(){ tr '[:upper:]' '[:lower:]'; }

# Sites: top-level dirs under the web root, minus defaults/noise.
SITES=$(grep -oE "$ROOT/[A-Za-z0-9._-]+" "$INV" | sed "s#$ROOT/##" | sort -u \
        | grep -vE '^(html|letsencrypt|[a-z])$')
# Backup jobs seen in cron/timers.
JOBS=$(grep -oE '[A-Za-z0-9_-]*backup[A-Za-z0-9_-]*\.(sh|py)' "$INV" | sort -u)
# Flatten job names into whole tokens; drop generic/orchestration words.
JOBTOK=$(printf '%s\n' "$JOBS" | sed -E 's/\.(sh|py)$//; s/[_-]+/ /g' | tr ' ' '\n' | lower \
        | grep -vE '^(backup|remote|daily|report|manager|vps|system|state|cron|db|dump|full)$' | grep -v '^$' | sort -u)

blanket=$(printf '%s\n' "$JOBS" | grep -iE 'system_state|vps|_all|full' | head -3 | paste -sd, - 2>/dev/null)

covered=0; gap=0; gaps=""
while IFS= read -r s; do
  [ -z "$s" ] && continue
  stoks=$(printf '%s\n' "$s" | sed -E 's/[.-]+/ /g' | tr ' ' '\n' | lower \
          | grep -vE '^(com|ca|net|org|io|www|site|local|stage|app|dev)$' | grep -v '^$')
  hit=""
  for t in $stoks; do
    [ ${#t} -lt 3 ] && continue
    printf '%s\n' "$JOBTOK" | grep -qx "$t" && { hit="$t"; break; }
  done
  if [ -n "$hit" ]; then covered=$((covered+1)); printf '  ✓ %-30s (via "%s")\n' "$s" "$hit"
  else gap=$((gap+1)); gaps="$gaps\n  ✗ $s"; fi
done <<EOF
$SITES
EOF

echo "Backup reconciliation — $(basename "$INV")"
echo "============================================================"
[ -n "$gaps" ] && { echo "NO matching backup job:"; printf "$gaps\n"; echo; }
echo "Summary: $covered covered · $gap without a named backup job."
[ -n "$blanket" ] && echo "Note: blanket job(s) present ($blanket) — may cover the gaps; verify their contents."
[ "$gap" -eq 0 ] && exit 0 || exit 1
