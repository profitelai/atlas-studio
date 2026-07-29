---
name: apply-auth-ui
description: Drop the authentication UI (sign in / create account / reset password) into a site, completely and correctly, wire the backend hooks, then verify against the completeness manifest.
---

# Skill: apply auth-ui

Applies the [`auth-ui`](../packages/auth-ui.md) package. Front-end only — the
backend is late-bound, so the same UI works with any auth provider. Follow every
step; the verify step is what stops the "rebuilt it and missed a part" cycle.

## Inputs to gather first
- **Target**: where the auth card should live (a route, a modal, a page section).
- **Copy**: titles/subtitles per view; brand palette (`--brand`, `--brand-ink`).
- **Auth backend**: what `onSignIn` / `onSignUp` / `onResetPassword` should call (your API, Supabase, Firebase, Auth0…).

## Steps

1. **Copy the source, don't retype it.** Take `components/auth-ui.html`. If embedding,
   lift `<style>` + `<main class="wrap">` + `<script>` as one unit.

2. **Swap copy via slots** — `data-slot="signin-title" | "signin-sub"` and each view's
   heading/lede. Never restructure the forms or rename the ids the script relies on.

3. **Wire the backend hooks.** Define them **before** submit (any time after load). Each
   returns a Promise; a rejection shows the inline error, success shows the success state:
   ```html
   <script>
     window.onSignIn = function(p){ return api.signIn(p.email, p.password); };
     window.onSignUp = function(p){ return api.signUp(p); };
     window.onResetPassword = function(p){ return api.sendReset(p.email); };
   </script>
   ```
   Leave any unset → that action logs its payload to the console (safe default for a demo).

4. **Enforce password policy server-side too.** The strength meter and 8-char check are UX,
   not security — your backend MUST re-validate. Never trust client validation alone.

5. **Match the theme.** If the host sets `data-theme`, tokens follow it; otherwise override
   the `:root` brand vars.

6. **Verify against the completeness manifest — hard gate.** Run:
   ```bash
   atlas/bin/verify-package.sh atlas/packages/auth-ui.md <your-clone-file>
   ```
   It must print `COMPLETE ✓` (exit 0). Then the two acceptance checks in a browser:
   - Create-account with mismatched passwords → blocked with inline error; matching → success, `onSignUp` fires.
   - Sign-in with a bad email → inline error, `aria-invalid="true"`, submit blocked.

## Security notes (do not skip)
- Client validation is UX only — **re-validate and rate-limit on the server**.
- Never log or store raw passwords; send over HTTPS to a backend that hashes them.
- For reset, always show the same "if that email exists…" message (no account enumeration).

## Done when
Both acceptance checks pass, every manifest box is ticked, and the three hooks reach
your real auth backend (or log to console if intentionally unset).
