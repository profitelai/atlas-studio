---
name: apply-legal-pages
description: Drop the legal/policy pages (privacy, terms, data-retention) into a site with the right product variant, completely and correctly, then verify against the completeness manifest.
---

# Skill: apply legal-pages

Applies the [`legal-pages`](../packages/legal-pages.md) package. It is a
**template, not legal advice** — the value is the reusable structure, slots, and
variant logic. Always have the final copy reviewed by qualified counsel.

## Inputs to gather first
- **Product type / variant**: `standard`, `mobile` (app permissions & store data), or `financial` (enhanced security, longer retention). Pick per the app being shipped.
- **Slots**: company/legal name, effective date, jurisdiction, privacy contact email.
- **Retention rules**: confirm each row of the retention table against the product's actual practice and legal requirements.

## Steps

1. **Copy the source, don't retype it.** Take `components/legal-pages.html` from the
   catalog. If embedding, lift `<style>` + `<main id="legalPages">` + `<script>` as one unit.

2. **Set the variant.** On the root element set `data-variant="mobile"` (or `financial`/`standard`).
   The script hides the non-matching `[data-variant-only]` blocks and rows on load. For a
   financial + mobile product, keep both blocks and set the primary variant that regulators care about.

3. **Swap copy via the slots only** — never restructure:
   - `data-slot="company" | "effectiveDate" | "jurisdiction" | "contact"` → real values.
   - Review each clause; add product-specific ones inside a new `data-variant-only="…"` block, not inline.

4. **Reconcile the retention table.** Every row in `#retentionTable` must match what the
   product actually does. Add/remove rows to reflect reality — an inaccurate retention page is a liability.

5. **Match the theme.** If the host site sets `data-theme`, the tokens follow it. Otherwise
   override the `:root` brand vars (`--brand`, `--brand-ink`) to the site's palette.

6. **Verify against the completeness manifest — hard gate.** Run:
   ```bash
   atlas/bin/verify-package.sh atlas/packages/legal-pages.md <your-clone-file>
   ```
   It must print `COMPLETE ✓` (exit 0). Then check the two acceptance cases in a browser:
   - Switch tabs → only one `[data-doc]` visible at a time.
   - Variant = `financial` → financial clauses + 7-year retention row appear; `standard` hides mobile & financial blocks.

7. **Keep the template notice** until counsel signs off, then replace it with the approved effective-date line.

## Done when
Both acceptance checks pass, every manifest box is ticked, the retention table matches
reality, and the copy has been reviewed by counsel (or explicitly flagged as pending review).
