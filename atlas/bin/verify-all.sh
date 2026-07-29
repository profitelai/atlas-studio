#!/usr/bin/env bash
# Atlas · verify-all.sh — verify every catalogued package against its manifest.
# Used by the pre-commit hook so an incomplete clone can't land on main.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(git -C "$HERE" rev-parse --show-toplevel 2>/dev/null || (cd "$HERE/../.." && pwd))"
PKGDIR="$ROOT/atlas/packages"
VERIFY="$HERE/verify-package.sh"

fails=0; checked=0
shopt -s nullglob 2>/dev/null || true
for man in "$PKGDIR"/*.md; do
  case "$(basename "$man")" in CATALOG.md|README.md) continue;; esac
  grep -q '<!-- verify' "$man" || continue          # only manifests with checks
  src="$(grep -E '^[[:space:]]*source:' "$man" | head -1 \
        | sed -E 's/^[[:space:]]*source:[[:space:]]*//; s/[[:space:]]*#.*$//; s/[[:space:]]*$//')"
  name="$(basename "$man" .md)"
  if [ -z "$src" ]; then echo "!! $name: no 'source:' field"; fails=$((fails+1)); continue; fi
  tgt="$ROOT/$src"
  if [ ! -f "$tgt" ]; then echo "!! $name: source not found: $src"; fails=$((fails+1)); continue; fi
  checked=$((checked+1))
  out="$(bash "$VERIFY" "$man" "$tgt" 2>&1)"
  if [ $? -eq 0 ]; then
    echo "✓ $name → $src COMPLETE"
  else
    echo "$out"; fails=$((fails+1))
  fi
done

echo "------------------------------------------------------------"
if [ "$fails" -eq 0 ]; then
  echo "All $checked catalogued package(s) COMPLETE ✓"; exit 0
else
  echo "$fails package(s) INCOMPLETE ✗ — see above."; exit 1
fi
