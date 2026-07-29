// Atlas Studio Live — local server that proxies to Claude.
// The API key stays here (server-side); the browser never sees it.
import 'dotenv/config';
import express from 'express';
import Anthropic from '@anthropic-ai/sdk';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Zero-arg client resolves credentials from the environment:
// ANTHROPIC_API_KEY, or an `ant auth login` profile.
const client = new Anthropic();

const MODEL = process.env.ATLAS_MODEL || 'claude-opus-5';

const SYSTEM = `You are Atlas, an expert product interviewer. You interview the user and build a complete Product Requirements Document (PRD) through a natural, adaptive conversation.

Rules:
- Ask exactly ONE focused question per turn. Keep it short and conversational (one or two sentences). Never present a list of questions.
- Adapt every question to what the user has already said. Never re-ask something answered; dig deeper where an answer is thin or vague.
- Cover, in a sensible adaptive order: the problem and who feels it; target users and their core job; scope and explicit non-goals; core functionality and the main flow; connections/dependencies to other systems; data and privacy; the user experience and key screens; the smallest MVP and its MEASURABLE success signal; risks. If it is a mobile app, also cover platforms, store listing, and data-retention specifics.
- Push back gently on non-measurable goals ("make it fast") — ask for a number, threshold, or concrete artifact.
- Be encouraging and concise. Do not lecture.
- When you have enough to write a solid PRD — or when the user says "generate", "done", "make the PRD", or similar — STOP asking and output the finished PRD as GitHub-flavored Markdown wrapped in a single <prd>...</prd> block. Use these sections: Overview, Problem, Users & Jobs, Scope & Non-goals, Functionality, Connections & Dependencies, Data & Privacy, UX & Flow, MVP & Success Metrics, Risks, Open Questions. Put any required-but-unanswered item under Open Questions as a checkbox.
- In your visible replies, never include internal or system XML tags other than the single <prd> block when you generate the final document.`;

const app = express();
app.use(express.json({ limit: '2mb' }));
app.use(express.static(path.join(__dirname, 'public')));

app.get('/api/health', (_req, res) => {
  res.json({ ok: true, model: MODEL, keyPresent: Boolean(process.env.ANTHROPIC_API_KEY) });
});

app.post('/api/chat', async (req, res) => {
  const { messages } = req.body || {};
  if (!Array.isArray(messages) || messages.length === 0) {
    return res.status(400).json({ error: 'messages[] is required' });
  }
  try {
    const response = await client.messages.create({
      model: MODEL,
      max_tokens: 4096,
      system: SYSTEM,
      messages,
    });
    const text = response.content
      .filter((b) => b.type === 'text')
      .map((b) => b.text)
      .join('');
    res.json({ text, stop_reason: response.stop_reason });
  } catch (err) {
    const status = err?.status || 500;
    const msg = err?.error?.error?.message || err?.message || 'request failed';
    console.error(`[api/chat] ${status}: ${msg}`);
    // 200 with an error field so the browser can render it inline
    res.status(200).json({ error: msg, status });
  }
});

const PORT = process.env.PORT || 4317;
app.listen(PORT, () => {
  const keyNote = process.env.ANTHROPIC_API_KEY
    ? 'ANTHROPIC_API_KEY detected.'
    : 'No ANTHROPIC_API_KEY set — will use an `ant auth login` profile if present, otherwise requests will fail. Add the key to .env.';
  console.log(`\n  Atlas Studio Live  →  http://localhost:${PORT}`);
  console.log(`  Model: ${MODEL}`);
  console.log(`  ${keyNote}\n`);
});
