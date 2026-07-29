#!/usr/bin/env bash
# Atlas · build-index.sh — regenerate INDEX.md, the map an agent loads first.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
INV="$ROOT/inventory"; PKG="$ROOT/packages"; IDX="$ROOT/INDEX.md"

{
  echo "# Atlas INDEX — source of truth"
  echo ""
  echo "_Generated $(date -u +%Y-%m-%dT%H:%M:%SZ). Deterministic, read-only discovery. Agents read this first._"
  echo ""
  echo "## Servers"
  echo ""
  if ls "$INV"/*.md >/dev/null 2>&1; then
    echo "| Host | Sites (server_names) | Apps found | Scanned |"
    echo "|------|----------------------|------------|---------|"
    for f in "$INV"/*.md; do
      name="$(basename "$f" .md)"
      sites=$(grep -cE '^[[:space:]]+- ' "$f" 2>/dev/null || true); sites=${sites:-0}
      apps=$(grep -cE '^[[:space:]]+- .+ →' "$f" 2>/dev/null || true); apps=${apps:-0}
      when=$(grep -m1 'Scanned (UTC)' "$f" | sed -E 's/.*\*\* //' || echo "—")
      echo "| [$name](inventory/$name.md) | ~$sites names | ~$apps | $when |"
    done
  else
    echo "_No inventories yet. Run \`bin/scan-server.sh local\` or \`bin/scan-server.sh user@host\`._"
  fi
  echo ""
  echo "## Packages"
  echo ""
  if [ -f "$PKG/CATALOG.md" ]; then
    n=$(grep -c '| \[repo\]' "$PKG/CATALOG.md" 2>/dev/null || echo 0)
    echo "- [Package catalog](packages/CATALOG.md) — $n repos listed (shallow)."
    deep=$(ls "$PKG"/*.md 2>/dev/null | grep -v CATALOG.md | wc -l | tr -d ' ')
    echo "- Deep-catalogued (with completeness manifest): $deep"
  else
    echo "_No package catalog yet. Run \`bin/scan-packages.sh <org>\`._"
  fi
} > "$IDX"
echo "   wrote $IDX"
