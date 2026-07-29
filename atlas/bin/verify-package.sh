#!/usr/bin/env bash
# Atlas · verify-package.sh — check a clone against a package's completeness manifest.
# The reconciliation idea from discovery, applied to reuse: instead of eyeballing a
# clone, run its manifest's checks and get an exact "what's missing" list.
#
#   verify-package.sh <manifest.md> <clone-file>
#
# Manifest carries a machine-checkable block:
#   <!-- verify
#   label :: ERE-pattern        # pattern MUST be present
#   label :: !ERE-pattern       # pattern MUST be absent
#   -->
set -uo pipefail

MAN="${1:-}"; TARGET="${2:-}"
[ -f "$MAN" ] || { echo "usage: verify-package.sh <manifest.md> <clone-file>" >&2; exit 2; }
[ -f "$TARGET" ] || { echo "error: clone file not found: $TARGET" >&2; exit 2; }

checks="$(awk '/<!-- verify/{f=1;next} /-->/{f=0} f' "$MAN")"
[ -n "$checks" ] || { echo "error: no <!-- verify ... --> block in $MAN" >&2; exit 2; }

pass=0; fail=0; missing=""
echo "Verifying $(basename "$TARGET") against $(basename "$MAN")"
echo "------------------------------------------------------------"
while IFS= read -r line; do
  case "$line" in ""|\#*) continue;; esac
  label="${line%% ::*}"; pat="${line#*:: }"
  label="$(printf '%s' "$label" | sed 's/[[:space:]]*$//')"
  if [ "${pat#!}" != "$pat" ]; then          # negative check: must be ABSENT
    pat="${pat#!}"
    if grep -Eq "$pat" "$TARGET"; then
      printf '  ✗ %-24s (found forbidden: %s)\n' "$label" "$pat"; fail=$((fail+1)); missing="$missing\n  - $label"
    else printf '  ✓ %-24s\n' "$label"; pass=$((pass+1)); fi
  else                                        # positive check: must be PRESENT
    if grep -Eq "$pat" "$TARGET"; then
      printf '  ✓ %-24s\n' "$label"; pass=$((pass+1))
    else printf '  ✗ %-24s (missing: %s)\n' "$label" "$pat"; fail=$((fail+1)); missing="$missing\n  - $label"; fi
  fi
done <<EOF
$checks
EOF

echo "------------------------------------------------------------"
if [ "$fail" -eq 0 ]; then
  echo "COMPLETE ✓  — $pass/$pass checks passed. Safe to ship this clone."
  exit 0
else
  echo "INCOMPLETE ✗  — $pass passed, $fail MISSING:"; printf "$missing\n"
  echo "Fix the above before shipping (this is the 'missed a part' check)."
  exit 1
fi
