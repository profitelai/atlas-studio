#!/usr/bin/env bash
# Atlas · scan-packages.sh — SHALLOW pass over one git host. Lists & points; copies nothing.
#
#   scan-packages.sh <org-or-user>       # via GitHub CLI (gh)
#
# This is the "cheap, near-free" first pass from the proposal: it only enumerates
# what packages exist and where they live. A deep catalog + completeness manifest
# is written on demand, the first time you reuse a package — never pre-built.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$(cd "$HERE/.." && pwd)/packages/CATALOG.md"
ORG="${1:-}"
[ -n "$ORG" ] || { echo "usage: scan-packages.sh <github-org-or-user>" >&2; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "error: GitHub CLI 'gh' not found. Install it and 'gh auth login'." >&2; exit 1; }

echo ">> listing repos under '$ORG' (shallow — no clone)"
{
  echo "# Package catalog — $ORG"
  echo ""
  echo "_Shallow pass · $(date -u +%Y-%m-%dT%H:%M:%SZ). Points at source, copies nothing._"
  echo "_Deep catalog + completeness manifest are added per package, on first reuse._"
  echo ""
  echo "| Package | Source | Language | Updated | Deep-catalogued? |"
  echo "|---------|--------|----------|---------|------------------|"
  gh repo list "$ORG" --limit 500 --json name,url,primaryLanguage,updatedAt \
    --jq '.[] | "| \(.name) | [repo](\(.url)) | \(.primaryLanguage.name // "—") | \(.updatedAt[0:10]) | ⬜ not yet |"'
  echo ""
  echo "## How to deep-catalogue a package (on demand)"
  echo ""
  echo "When you're about to reuse one, create \`packages/<name>.md\` with a **completeness manifest**:"
  echo '```yaml'
  echo "id: auth-core"
  echo "source: git@github.com:$ORG/auth-core"
  echo "includes: [register, login, password_reset, email_templates, sessions]"
  echo "requires: [db: users table, env: SMTP_*, migrations]   # the parts that go missing"
  echo "variants: [standard, mobile(retention), financial(enhanced-security)]"
  echo "skill: skills/apply-auth-core.md"
  echo '```'
  echo "Then the agent can *verify a clone against the manifest* and hand you a 'what's missing' list."
} > "$OUT"

echo "   wrote $OUT"
grep -c '| \[repo\]' "$OUT" 2>/dev/null | sed 's/^/   repos listed: /' || true
