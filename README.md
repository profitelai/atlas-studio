# Atlas Studio — project bundle

Spec-to-ship tooling for turning an idea into a build-ready spec. Each HTML file
is fully self-contained — open it in any browser (double-click), no server needed.

## Files
- **atlas-studio-builder.html** — the interactive Spec-to-Ship builder.
  One screen, project-type dropdown (website / web app / mobile / API), stages
  Principles → PRD → UX → MVP → Planning → Building → Launching → Go-live, voice
  input, live spec, and a Design Library style picker in the UX stage. Mobile type
  adds a Store Readiness stage. Three exports:
  - **Download / Copy** — the full spec as Markdown.
  - **Spec Kit ⤓** — a GitHub Spec Kit bundle (`constitution.md` + a
    `/speckit.specify`-ready spec with FR-numbered requirements, acceptance
    scenarios, and `[NEEDS CLARIFICATION]` markers).
  - **Build kit ⤓** — an agent-ready bundle: `AGENTS.md` (behaviour contract) +
    `tasks.json` (Ralph-style stories with `passes` flags) for a coding-agent loop.
- **atlas-design-library.html** — starter shelf of 6 distinct visual styles
  (Editorial, Brutalist, Soft Glass, Corporate, Luxury, Playful) with live
  full-screen previews and copyable design tokens.
- **atlas-studio-requirements.html** — the full requirements (meta-PRD) for the
  builder, synthesized from 6 leading tools (Spec Kit, OpenSpec, Ralph,
  Vibe-Coding Template, Loki Mode, AI Product Dev Toolkit).
- **atlas-engine-proposal.html** — the original Atlas engine proposal:
  infrastructure inventory + reusable-package catalog + autopilot watcher.
- **atlas-status.html** — living Status & Roadmap for the whole project.
- **atlas/** — the discovery engine: generic scan scripts (`collect.sh`,
  `scan-server.sh`, `scan-packages.sh`, `build-index.sh`). Output maps under
  `atlas/inventory/` are **gitignored** — they hold live server details and must
  never be committed to a public repo.

## Live versions (private to your Claude account)
- Builder:         https://claude.ai/code/artifact/25b54287-f07b-47d0-a4cc-66fd55b1d01d
- Design Library:  https://claude.ai/code/artifact/0b2e1797-6ba4-4288-a353-3249b16862da
- Requirements:    https://claude.ai/code/artifact/db8bfa21-c148-41a9-bff1-3f3f21f91589
- Engine proposal: https://claude.ai/code/artifact/7560e332-c52f-4d29-9fff-4ae6982f1b7d
- Status & Roadmap: https://claude.ai/code/artifact/a1baedcb-4bfa-40a6-8526-ea91f4ee71b7
