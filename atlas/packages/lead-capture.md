# Package: lead-capture

_First catalogued package. This is a **reference** — it points at the source and
lists what "complete" means, so a clone can be verified, not eyeballed._

```yaml
id: lead-capture
source: components/lead-capture.html        # canonical, self-contained (no build step)
kind: ui-component / landing-page
includes: [hero (headline + subhead + 3 value props), lead form (name/email/phone),
           client-side validation, success state, late-bound onLead hook,
           light/dark theming, responsive layout]
requires: []                                 # self-contained; NO backend, NO external requests
optional: [window.onLead(payload) handler to persist leads to a CRM/endpoint]
variants: [standard]                          # future: gated-content, newsletter, book-a-call
skill: skills/apply-lead-capture.md
origin: built via Spec Kit pipeline — specs/002-lead-capture-landing (in spec-demo)
```

## Completeness manifest — the parts that go missing when you clone by eye

A clone is only correct if **every** box below is present. Verify against this list.

- [ ] **Markup**: hero block + `<form id="leadForm">` with name/email/phone fields and a `#success` block.
- [ ] **Copy slots**: `data-slot="eyebrow|headline|subhead|props"` present (so copy is swappable without touching structure).
- [ ] **CSS tokens**: `:root` light vars + `@media (prefers-color-scheme:dark)` + `[data-theme]` overrides.
- [ ] **Validation JS**: `validEmail()` + `validate()` + inline `.err` boxes with `aria-invalid` + `aria-live`.
- [ ] **Success state**: form hidden, `#success` shown, personalized message, `#successMsg`.
- [ ] **Double-submit guard**: `submitting` flag + disabled button during submit.
- [ ] **Late-bound hook**: `emitLead()` reads `window.onLead` at submit time (NOT at init).
- [ ] **Self-contained**: no external `<script src>` / `<link href>` / font/CDN — CSP-safe.

## Acceptance (must still pass after any clone/edit)

1. Valid name + email → form replaced by success state; `onLead(payload)` receives `{name,email,phone,submittedAt}`.
2. Invalid/empty email → inline error, submit blocked, `aria-invalid="true"`.

## Reuse

Don't copy-by-eye — run [skills/apply-lead-capture.md](../skills/apply-lead-capture.md).
