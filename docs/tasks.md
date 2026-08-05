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

- [ ] `chore: add chatbot/ Rails 8 app scaffold` (Postgres, Puma, Rspec, Rubocop-govuk)
- [ ] `chore: add pgvector extension + neighbor gem + placeholder migration`
- [ ] `chore: add anthropic + openai gems, credentials scaffold`
- [ ] `chore: docker-compose service definitions (postgres, redis, rails, sidekiq)`
- [ ] `docs: chatbot/README with local dev instructions` (in-app, links back to /docs)
- [ ] **Approval gate M1**

## M2 — Ingestion pipeline

- [ ] `feat(ingest): Document + Chunk ActiveRecord models with pgvector`
- [ ] `feat(ingest): Sources::LocalRepo with config/ai_sources.yml`
- [ ] `feat(ingest): MarkdownLoader, ErbLoader, HtmlLoader, PdfLoader, TxtLoader`
- [ ] `feat(ingest): Normalizer (strip nav/footer, resolve heading chain)`
- [ ] `feat(ingest): Chunker (recursive, heading-aware, ~800 tokens / 100 overlap)`
- [ ] `feat(llm): LlmClient abstraction + Anthropic adapter + OpenAI adapter`
- [ ] `feat(ingest): Embedder service (batched, retries)`
- [ ] `feat(ingest): IndexDocumentJob + ReindexAllJob`
- [ ] `feat(rake): ai:index_docs task, idempotent by content_hash`
- [ ] `test: RSpec — loaders, chunker, ingest pipeline`
- [ ] Run against product-page; verify Documents + Chunks populated
- [ ] **Approval gate M2**

## M3 — Retrieval + Answering API

- [ ] `feat(retrieval): Retriever with cosine similarity, k=8, threshold=0.2`
- [ ] `feat(retrieval): Ranker with source_type weighting`
- [ ] `feat(prompt): PromptBuilder with strict system prompt + context blocks`
- [ ] `feat(answer): AnswerService orchestrator`
- [ ] `feat(api): POST /api/chat non-streaming (JSON response)`
- [ ] `feat(api): SSE streaming variant (token + citations + done events)`
- [ ] `feat(api): rack-attack rate limiting`
- [ ] `test: RSpec request specs — happy path, unknown-answer path, citation shape`
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
