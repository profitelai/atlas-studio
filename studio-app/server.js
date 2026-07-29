// Atlas Studio Live — local server that proxies to your LLM provider.
// Works with EITHER an OpenAI key or an Anthropic key. The key stays here
// (server-side); the browser never sees it.
import 'dotenv/config';
import express from 'express';
import Anthropic from '@anthropic-ai/sdk';
import OpenAI from 'openai';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// A blank `KEY=` line (as shipped in .env.example) would otherwise shadow a
// real credential and confuse detection — drop empties so detection is accurate.
for (const k of ['OPENAI_API_KEY', 'ANTHROPIC_API_KEY']) {
  if (!(process.env[k] || '').trim()) delete process.env[k];
}

const HAS_OPENAI = !!process.env.OPENAI_API_KEY;
const HAS_ANTHROPIC = !!process.env.ANTHROPIC_API_KEY;

// Provider: explicit ATLAS_PROVIDER wins; else OpenAI if its key is present;
// else Anthropic (works with an `ant auth login` profile too).
const PROVIDER = (process.env.ATLAS_PROVIDER || (HAS_OPENAI ? 'openai' : 'anthropic')).toLowerCase();
const OPENAI_MODEL = process.env.OPENAI_MODEL || 'gpt-4o';
const ANTHROPIC_MODEL = process.env.ATLAS_MODEL || 'claude-opus-5';
const MODEL = PROVIDER === 'openai' ? OPENAI_MODEL : ANTHROPIC_MODEL;

const SYSTEM = `You are Atlas, an expert product interviewer. You interview the user and build a complete Product Requirements Document (PRD) through a natural, adaptive conversation.

Rules:
- Ask exactly ONE focused question per turn. Keep it short and conversational (one or two sentences). Never present a list of questions.
- Adapt every question to what the user has already said. Never re-ask something answered; dig deeper where an answer is thin or vague.
- Cover, in a sensible adaptive order: the problem and who feels it; target users and their core job; scope and explicit non-goals; core functionality and the main flow; connections/dependencies to other systems; data and privacy; the user experience and key screens; the smallest MVP and its MEASURABLE success signal; risks. If it is a mobile app, also cover platforms, store listing, and data-retention specifics.
- Push back gently on non-measurable goals ("make it fast") — ask for a number, threshold, or concrete artifact.
- Be encouraging and concise. Do not lecture.
- When you have enough to write a solid PRD — or when the user says "generate", "done", "make the PRD", or similar — STOP asking and output the finished PRD as GitHub-flavored Markdown wrapped in a single <prd>...</prd> block. Use these sections: Overview, Problem, Users & Jobs, Scope & Non-goals, Functionality, Connections & Dependencies, Data & Privacy, UX & Flow, MVP & Success Metrics, Risks, Open Questions. Put any required-but-unanswered item under Open Questions as a checkbox.
- In your visible replies, never include internal or system XML tags other than the single <prd> block when you generate the final document.`;

// Lazy clients so a missing key produces a friendly message at request time
// instead of crashing the server at startup.
let anthropic = null, openai = null;
function getAnthropic() { if (!anthropic) anthropic = new Anthropic(); return anthropic; }
function getOpenAI() { if (!openai) openai = new OpenAI(); return openai; }

async function ask(messages) {
  if (PROVIDER === 'openai') {
    const r = await getOpenAI().chat.completions.create({
      model: OPENAI_MODEL,
      messages: [{ role: 'system', content: SYSTEM }, ...messages],
    });
    return r.choices?.[0]?.message?.content || '';
  }
  const r = await getAnthropic().messages.create({
    model: ANTHROPIC_MODEL, max_tokens: 4096, system: SYSTEM, messages,
  });
  return r.content.filter((b) => b.type === 'text').map((b) => b.text).join('');
}

const KEY_NAME = PROVIDER === 'openai' ? 'OPENAI_API_KEY' : 'ANTHROPIC_API_KEY';

const app = express();
app.use(express.json({ limit: '2mb' }));
app.use(express.static(path.join(__dirname, 'public')));

app.get('/api/health', (_req, res) => {
  res.json({ ok: true, provider: PROVIDER, model: MODEL, keyPresent: PROVIDER === 'openai' ? HAS_OPENAI : HAS_ANTHROPIC });
});

app.post('/api/chat', async (req, res) => {
  const { messages } = req.body || {};
  if (!Array.isArray(messages) || messages.length === 0) {
    return res.status(400).json({ error: 'messages[] is required' });
  }
  try {
    const text = await ask(messages);
    res.json({ text });
  } catch (err) {
    const status = err?.status || 500;
    let msg = err?.error?.error?.message || err?.error?.message || err?.message || 'request failed';
    if (/Could not resolve authentication|api key|apiKey|OPENAI_API_KEY|ANTHROPIC_API_KEY/i.test(msg) && !(err?.status)) {
      msg = `No ${PROVIDER === 'openai' ? 'OpenAI' : 'Anthropic'} credentials found. Open studio-app/.env, set ${KEY_NAME}=your-key, then restart the server.`;
    } else if (status === 401) {
      msg += ` — check that ${KEY_NAME} in studio-app/.env is a valid key, then restart.`;
    }
    console.error(`[api/chat] ${status}: ${msg}`);
    // 200 with an error field so the browser can render it inline
    res.status(200).json({ error: msg, status });
  }
});

const PORT = process.env.PORT || 4317;
app.listen(PORT, () => {
  const key = (PROVIDER === 'openai' ? HAS_OPENAI : HAS_ANTHROPIC);
  console.log(`\n  Atlas Studio Live  →  http://localhost:${PORT}`);
  console.log(`  Provider: ${PROVIDER}   Model: ${MODEL}`);
  console.log(`  ${key ? `${KEY_NAME} detected.` : `No ${KEY_NAME} set — add it to studio-app/.env (or, for Anthropic, run \`ant auth login\`).`}\n`);
});
