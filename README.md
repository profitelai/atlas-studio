# Atlas

Turn an idea into a **build-ready spec by talking to it** — then hand that spec
straight into a real build, reusing what you've built before, on infrastructure
you can actually see. Atlas is the system that does that, in parts you can use
independently or as one pipeline.

## The end-to-end flow

```
  🎙️ talk ──► live AI interview ──► PRD ──► Save to project
                (studio-app)                    │
                                                ▼
                                      specs/<name>-speckit.md          ← lands in this repo
                                                │
                        ┌───────────────────────┼────────────────────────┐
                        ▼                        ▼                        ▼
              Spec Kit /speckit.specify   Ralph build loop        atlas/ catalog
              → plan → tasks → build      (stories that pass)     (reuse packages)
                                                                        ▲
                        real-server discovery ──► atlas/inventory ──────┘
                        (atlas/bin scan scripts)   (what you already run)
```

## What's here

### `studio-app/` — the live voice interviewer  *(the main app)*
A local Node app: Claude interviews you with adaptive questions, **speaks** them
aloud (natural OpenAI voice, or the browser's), **listens** to your spoken
answers (hands-free mode), and **writes a PRD** live. One **Save to project**
click drops a PRD **and** a ready-to-run Spec Kit bundle into `specs/`.

```bash
cd studio-app
npm install
cp .env.example .env      # then paste ONE key: OPENAI_API_KEY= or ANTHROPIC_API_KEY=
npm start                 # → http://localhost:4317
```
Works with an OpenAI key (default `gpt-4o`) or an Anthropic key (default
`claude-opus-5`) — auto-detected. See `studio-app/README.md` for voice options.

### `atlas-studio-builder.html` — the offline builder
The same idea as a single self-contained web page (double-click to open, no
server). Project-type-aware stages (web / mobile / API), voice input, a Design
Library style picker, and three exports: Markdown spec, **Spec Kit** bundle, and
**Build kit** (`AGENTS.md` + `tasks.json` for a Ralph-style loop).

### `atlas/` — the discovery engine + reusable-package catalog
- **`bin/`** — read-only server discovery (`scan-server.sh local | user@host`,
  `collect.sh`, `scan-packages.sh`, `build-index.sh`). Maps domains, subdomains,
  nested apps, databases, cron, certs — so backups/audits stop missing sites.
- **`packages/` + `components/` + `skills/`** — catalogued reusable building
  blocks (auth UI, lead-capture, legal/policy pages) with completeness manifests.
- **`bin/verify-package.sh` / `verify-all.sh`** — deterministic "did the clone
  drop a part?" check; a pre-commit gate (`.githooks/pre-commit`, opt-in) blocks
  incomplete packages.
- **`inventory/`, `INDEX.md`, `packages/CATALOG.md`** are **gitignored** — they
  hold live server details and must never reach a public repo.

### `specs/` — the hand-off point
Where a saved PRD lands as `<name>-prd.md` + `<name>-speckit.md`, ready for Spec
Kit / Ralph / the catalog. (Not gitignored — commit only what you want public.)

### Strategy & reference (HTML, self-contained)
- **`atlas-design-library.html`** — 6 distinct visual styles, live previews + tokens.
- **`atlas-studio-requirements.html`** — the meta-PRD, synthesized from 6 leading tools.
- **`atlas-engine-proposal.html`** — the original inventory + catalog + autopilot proposal.
- **`atlas-status.html`** — living Status & Roadmap.

## Where it stands
- ✅ **Capture** — voice interviewer + offline builder
- ✅ **Output** — PRD + Spec Kit / Build kit bundles, saved into `specs/`
- ✅ **Reuse** — package catalog with a deterministic verifier
- ◐ **Build** — Spec Kit + Ralph run the spec (both usable in-repo)
- ⬜ **Discovery on a real server** — scripts staged; point at a `user@host`
- ⬜ **Autopilot / benchmark engine** — the "become the best" pillar

## Live versions (private to your Claude account)
- Builder:          https://claude.ai/code/artifact/25b54287-f07b-47d0-a4cc-66fd55b1d01d
- Design Library:   https://claude.ai/code/artifact/0b2e1797-6ba4-4288-a353-3249b16862da
- Requirements:     https://claude.ai/code/artifact/db8bfa21-c148-41a9-bff1-3f3f21f91589
- Engine proposal:  https://claude.ai/code/artifact/7560e332-c52f-4d29-9fff-4ae6982f1b7d
- Status & Roadmap: https://claude.ai/code/artifact/a1baedcb-4bfa-40a6-8526-ea91f4ee71b7

## Security
`.env` is gitignored at every level — keys stay local. Discovery output
(`atlas/inventory/*`, `INDEX.md`, `packages/CATALOG.md`) is gitignored too.
