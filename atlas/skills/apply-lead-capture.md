---
name: apply-lead-capture
description: Drop the lead-capture landing page into a target site, completely and correctly, then verify it against the completeness manifest.
---

# Skill: apply lead-capture

Applies the [`lead-capture`](../packages/lead-capture.md) package. Follow every
step — the verify step is what stops the "rebuilt it and missed a part" cycle.

## Inputs to gather first
- **Target**: where the page should live (a route, a file, or a section to embed).
- **Copy**: eyebrow, headline, subhead, three value props, form heading, fine print.
- **Lead destination**: the endpoint/CRM the lead should go to (or "log only" for now).

## Steps

1. **Copy the source, don't retype it.** Take `components/lead-capture.html` from the
   catalog. If embedding, lift `<style>` + `<main class="wrap">` + `<script>` as one unit.

2. **Swap copy via the slots only** — never restructure:
   - `data-slot="eyebrow" | "headline" | "subhead"` → text.
   - `data-slot="props"` → exactly three `<li><span class="tick">✓</span> …</li>`.
   - Form heading + `.fineprint` → target's wording.

3. **Wire the lead destination.** Define `window.onLead` **before** submit (any time after load):
   ```html
   <script>
     window.onLead = function(payload){
       return fetch("/api/leads", {method:"POST", headers:{"Content-Type":"application/json"}, body: JSON.stringify(payload)});
     };
   </script>
   ```
   Return a Promise; a rejection shows the retry error state. No endpoint yet → leave it unset (logs to console).

4. **Match the theme.** If the host site sets `data-theme`, the tokens already follow it.
   Otherwise override the `:root` brand vars (`--brand`, `--brand-ink`) to the site's palette.

5. **Verify against the completeness manifest** in [packages/lead-capture.md](../packages/lead-capture.md).
   Tick every box. Then run the two acceptance checks in a browser:
   - Submit a **valid** name+email → success state shows, `onLead` fires with the payload.
   - Submit an **invalid** email → inline error, submit blocked.

6. **Report what's missing.** If any manifest box fails, list it explicitly rather than
   silently shipping — that report is the point of the catalog.

## Done when
Both acceptance checks pass, every manifest box is ticked, and leads reach the
configured destination (or log to console if intentionally unset).
