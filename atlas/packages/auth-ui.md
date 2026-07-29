# Package: auth-ui

_Third catalogued package — the register / login / reset UI you named first. A
**reference** that points at the source and defines what "complete" means, so a
clone is verified, not eyeballed. Front-end only; the backend is late-bound._

```yaml
id: auth-ui
source: components/auth-ui.html              # canonical, self-contained (no build step)
kind: ui-component / authentication
includes: [sign-in form, create-account form, reset-password form, tabbed switching,
           email + password validation, password strength meter, show/hide password,
           confirm-password match, inline errors (aria), success state,
           double-submit guard, light/dark theming, responsive]
requires: []                                 # self-contained; NO backend, NO external requests
optional: [window.onSignIn / window.onSignUp / window.onResetPassword handlers → return a Promise]
variants: [standard]                          # future: social-login, magic-link, 2FA step
skill: skills/apply-auth-ui.md
origin: built as the third Atlas reusable package (the "size package" — user auth)
```

## Completeness manifest — the parts that go missing when you clone by eye

A clone is only correct if **every** box below is present.

- [ ] **Three forms**: `#signinForm`, `#signupForm`, `#resetForm`, switched by `showView()` via `data-view-link`.
- [ ] **Validation**: `validEmail()`, min-length password, confirm-password (`data-role="confirm"`) match; inline `.err` with `aria-invalid` + `aria-live`.
- [ ] **Password UX**: strength meter (`data-role="strength"`) + show/hide toggle (`data-action="toggle-pw"`).
- [ ] **Late-bound hooks**: `callHook` reads `window[name]` at submit time — `onSignIn` / `onSignUp` / `onResetPassword`. Unset → logs to console.
- [ ] **Double-submit guard**: `submitting` flag + disabled button during submit.
- [ ] **Success state**: `data-role="success"` block shown after a successful action.
- [ ] **Theming**: `:root` light vars + `@media (prefers-color-scheme:dark)` + `[data-theme]` overrides.
- [ ] **Self-contained**: no external `<script src>` / `<link href>` / font / CDN — CSP-safe.

## Acceptance (must still pass after any clone/edit)

1. Create-account with mismatched passwords → inline "Passwords don't match", submit blocked; matching + valid email → success state, `onSignUp` receives `{name,email,password}`.
2. Sign-in with a bad email → inline error, `aria-invalid="true"`, submit blocked.

## Verify (machine-checkable)

Run `bin/verify-package.sh packages/auth-ui.md <clone-file>`. Each line is
`label :: pattern` (ERE). A `!` prefix means the pattern MUST be absent.

<!-- verify
signin-form :: id="signinForm"
signup-form :: id="signupForm"
reset-form :: id="resetForm"
view-switch :: function showView\(
email-validate :: function validEmail\(
confirm-field :: data-role="confirm"
strength-meter :: data-role="strength"
password-toggle :: data-action="toggle-pw"
inline-error-aria :: aria-invalid
aria-live :: aria-live=
double-submit-guard :: submitting
late-bound-hook :: window\[name\]
hook-signin :: "onSignIn"
hook-signup :: "onSignUp"
hook-reset :: "onResetPassword"
success-state :: data-role="success"
theme-dark :: prefers-color-scheme:dark
theme-attr :: \[data-theme=
no-external-script :: !<script[^>]+src=
no-external-css :: !<link[^>]+href=
-->

## Reuse

Don't copy-by-eye — run [skills/apply-auth-ui.md](../skills/apply-auth-ui.md).
