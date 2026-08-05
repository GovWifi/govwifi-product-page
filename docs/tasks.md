# Implementation Tasks

> Living backlog. Tick items as they land on the `chatbot` branch. Every unchecked item is fair game once its milestone starts.

Legend: `[ ]` pending · `[~]` in progress · `[x]` done

---

## M0 — Documentation & setup

- [x] Clone product-page, tech-docs, dev-docs into `~/Documents/my-work/govwifi/`
- [x] Create `chatbot` branch on product-page; push to origin
- [x] Repository audit
- [x] Architectural decisions (see decisions.md)
- [x] Scaffold `docs/` (plan, architecture, tasks, decisions, ai-log, evaluation, README, context)

## M1 — Scaffold companion Rails 8 app (`./chatbot`)

- [x] `chore(chatbot): add Rails 8 app scaffold` (Postgres, Puma, Propshaft, Turbo, Stimulus)
- [x] `chore(chatbot): add pgvector + neighbor gem for vector storage`
- [x] `chore(chatbot): add LLM client, background job, and testing gems`
- [x] `chore(chatbot): add docker-compose for local dev`
- [x] `docs(chatbot): replace default Rails README with local dev guide`
- [ ] **Approval gate M1**

## M2 — Ingestion pipeline

- [x] `test(chatbot): RSpec / FactoryBot / WebMock / VCR bootstrap`
- [x] `feat(chatbot): Document + Chunk models with pgvector storage`
- [x] `feat(chatbot): LlmClient abstraction with Anthropic + OpenAI adapters` (+ ADR-006)
- [x] `feat(chatbot): loaders for md, html.erb, html.md.erb, html, pdf, txt` + dispatcher
- [x] `feat(chatbot): Sources::LocalRepo + Chunker` (nav/footer stripping handled inside HtmlLoader — no separate Normalizer needed)
- [x] `feat(chatbot): Embedder, Pipeline, jobs, ai:index_docs rake task`
- [x] `test: RSpec coverage — loaders, chunker, pipeline (idempotency), embedder, job`
- [ ] **First real run against product-page** (needs OPENAI_API_KEY; run manually)
- [ ] **Approval gate M2**

## M3 — Retrieval + Answering API

- [x] `feat(chatbot): Retriever + Ranker with pgvector cosine + source_type weighting`
- [x] `feat(chatbot): PromptBuilder + AnswerService orchestrator`
- [x] `feat(chatbot): POST /api/chat non-streaming JSON endpoint` (+ CORS)
- [x] `feat(chatbot): SSE streaming branch on the same endpoint`
- [x] `feat(chatbot): per-IP rate limiting on /api/chat via rack-attack`
- [x] `test: RSpec — retriever, ranker, prompt, answer service, request specs, streaming, rate limiting`
- [ ] **Approval gate M3**

## M4 — Chat widget UI

- [ ] `feat(widget): floating bottom-right button, Stimulus controller, GOV.UK styling`
- [ ] `feat(widget): chat panel — message list, input, suggested questions`
- [ ] `feat(widget): SSE consumption + streaming render + loading indicator`
- [ ] `feat(widget): citation panel component (deduped, links)`
- [ ] `feat(widget): copy answer, clear conversation actions`
- [ ] `feat(widget): accessibility — aria-live, focus trap, keyboard nav, WCAG AA colour contrast`
- [ ] `feat(widget): responsive mobile layout`
- [ ] `feat(widget): bundle widget.js + widget.css for external embed`
- [ ] `test: Capybara feature spec — open, ask, receive answer with citations`
- [ ] **Approval gate M4**

## M5 — Evaluation page

- [ ] `feat(eval): Evaluation + EvaluationRun models + migrations`
- [ ] `feat(eval): /evaluate index view — table of evals, run button per row`
- [ ] `feat(eval): EvaluationRunJob — runs one question, records latency + citations`
- [ ] `feat(eval): rake ai:evaluate — runs all, prints summary`
- [ ] `feat(eval): thumbs up/down feedback capture`
- [ ] `test: RSpec feature spec — /evaluate flow`
- [ ] Seed with initial ~10 evaluation questions (see evaluation.md)
- [ ] **Approval gate M5**

## M6 — Wire widget into product-page layout

- [ ] `feat: add widget script include to source/layouts/layout.erb`
- [ ] Verify no CSP conflicts in product-page's existing setup
- [ ] Update product-page README section on the assistant
- [ ] Manual QA on desktop + mobile
- [ ] **Approval gate M6**

## Phase 2 — additional sources (post-MVP)

- [ ] Add `govwifi-tech-docs` path to `config/ai_sources.yml`
- [ ] Add `govwifi-dev-docs` path to `config/ai_sources.yml`
- [ ] Re-run `ai:index_docs`
- [ ] Expand evaluation set for tech/dev-docs questions

## Phase 3 — Zendesk ingestion (post-MVP)

- [ ] ADR: Zendesk export format + PII strategy
- [ ] `feat(ingest): Sources::ZendeskExport loader`
- [ ] Retrieval ranker: apply zendesk source_type_priority weighting
- [ ] Redaction pass for PII before embedding
- [ ] Evaluation set covering ticket-derived Q&A

## Later — designed for, not yet built

- [ ] Feedback thumbs up/down persisted
- [ ] Slack integration
- [ ] Auth (GOV.UK SSO)
- [ ] Analytics dashboard
- [ ] Token usage / cost dashboard
- [ ] Admin portal
