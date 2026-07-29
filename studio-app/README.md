# Atlas Studio Live — voice AI interviewer

A **local** app that runs on your machine. The AI (Claude) interviews you with
adaptive questions, **speaks them aloud**, listens to your **spoken answers**,
and **writes a full PRD** you can download — all driven by a small Node server
that keeps your API key private (the browser never sees it).

- 🔊 **AI talks** — questions are spoken aloud (browser speech, no extra service/key). Toggle with the **Voice** button.
- 🎤 **You talk** — tap the mic and answer by voice (or type).
- ✍️ **AI writes** — a live PRD builds in the side panel; **Download .md** or **Copy** anytime.
- 🔒 **Private** — your `ANTHROPIC_API_KEY` stays on the server; nothing is exposed to the page.

## Run it (3 steps)

```bash
cd studio-app
npm install
```

Add your key (get one at https://console.anthropic.com → API Keys):

```bash
cp .env.example .env
# then edit .env and paste your key after ANTHROPIC_API_KEY=
```

> Already used `ant auth login`? You can skip the key — the app uses your CLI profile automatically.

Start it:

```bash
npm start
```

Open **http://localhost:4317** — Atlas greets you and starts the interview.

## Notes
- **Model:** defaults to `claude-opus-5`. Override with `ATLAS_MODEL=claude-sonnet-5` in `.env` for a cheaper/faster run.
- **Voice output** uses your browser's built-in speech synthesis — works offline, no TTS service needed. Voice quality depends on the browser/OS.
- **Voice input** uses the browser Speech Recognition API (best in Chrome); it falls back to typing where unavailable.
- **Port:** set `PORT=xxxx` in `.env` to change it.

## How it fits Atlas
This is the "live-AI interviewer" version of Atlas Studio — the same spec-building
idea as `atlas-studio-builder.html`, but with a real backend so the AI asks
*unlimited adaptive* questions and drafts the PRD in conversation, instead of a
fixed question set. The exported PRD feeds the same Spec Kit / Build kit flow.
