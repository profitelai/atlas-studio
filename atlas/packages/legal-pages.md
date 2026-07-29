# Package: legal-pages

_Second catalogued package. A **reference** that points at the source and defines
what "complete" means, so a clone can be verified, not eyeballed. It is a
**template**, not legal advice — the reusable structure/slots are what's catalogued._

```yaml
id: legal-pages
source: components/legal-pages.html          # canonical, self-contained (no build step)
kind: ui-component / policy-documents
includes: [privacy policy, terms of service, data-retention doc + retention table,
           tabbed navigation, swappable copy slots, light/dark theming, responsive]
requires: []                                 # self-contained; NO backend, NO external requests
optional: [set data-variant on the root to preselect a product type]
variants: [standard, mobile, financial]      # mobile = app data/permissions; financial = enhanced security
skill: skills/apply-legal-pages.md
origin: built as the second Atlas reusable package (legal/policy set with variants)
```

## Completeness manifest — the parts that go missing when you clone by eye

A clone is only correct if **every** box below is present.

- [ ] **Three docs**: sections `data-doc="privacy" | "terms" | "retention"`, switched by `data-doc-tab` tabs.
- [ ] **Retention table**: `#retentionTable` with category / period / reason rows.
- [ ] **Copy slots**: `data-slot="company" | "effectiveDate" | "jurisdiction" | "contact"` (swap copy without touching structure).
- [ ] **Variants**: root `data-variant=`, plus `data-variant-only="mobile"` and `data-variant-only="financial"` blocks that show/hide.
- [ ] **Variant logic**: `applyVariant()` toggles variant-only blocks; `showDoc()` switches the active document.
- [ ] **Theming**: `:root` light vars + `@media (prefers-color-scheme:dark)` + `[data-theme]` overrides.
- [ ] **Self-contained**: no external `<script src>` / `<link href>` / font / CDN — CSP-safe.
- [ ] **Template note**: keeps the "not legal advice — have counsel review" notice.

## Acceptance (must still pass after any clone/edit)

1. Clicking the Terms tab hides Privacy and shows Terms (only one `[data-doc]` visible).
2. Setting variant = `financial` reveals the financial-only clauses and the 7-year retention row; `standard` hides both mobile- and financial-only blocks.

## Verify (machine-checkable)

Run `bin/verify-package.sh packages/legal-pages.md <clone-file>`. Each line is
`label :: pattern` (ERE). A `!` prefix means the pattern MUST be absent.

<!-- verify
privacy-doc :: data-doc="privacy"
terms-doc :: data-doc="terms"
retention-doc :: data-doc="retention"
retention-table :: id="retentionTable"
slot-company :: data-slot="company"
slot-date :: data-slot="effectiveDate"
slot-contact :: data-slot="contact"
variant-root :: data-variant="standard"
variant-mobile :: data-variant-only="mobile"
variant-financial :: data-variant-only="financial"
apply-variant-fn :: function applyVariant\(
doc-switch-fn :: function showDoc\(
theme-dark :: prefers-color-scheme:dark
theme-attr :: \[data-theme=
template-note :: not legal advice
no-external-script :: !<script[^>]+src=
no-external-css :: !<link[^>]+href=
-->

## Reuse

Don't copy-by-eye — run [skills/apply-legal-pages.md](../skills/apply-legal-pages.md).
