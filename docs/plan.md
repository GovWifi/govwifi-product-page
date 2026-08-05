# GovWifi AI Support Assistant — Master Plan

> **Status:** Planning complete. M1 (Rails scaffold) not yet started.
> **Owner:** Iram Shehzadi
> **Last updated:** 2026-08-05

## Project vision

Give every GovWifi user — from a citizen trying to connect for the first time to a Whitehall service owner onboarding their organisation — a single trustworthy place to ask questions in natural language and get grounded, cited answers drawn from official GovWifi documentation.

## Problem statement

GovWifi documentation is spread across three separate static Middleman sites (product-page, tech-docs, dev-docs). Users have to know *which* site to look on, then navigate its structure, then keyword-search. Support colleagues answer the same questions repeatedly in Zendesk. This is high-friction and doesn't scale as the service grows.

## Users

| Persona | Needs | Example question |
|---|---|---|
| **Citizen / end user** | Fast connection help | "How do I sign up?" |
| **Organisation admin / onboarder** | Onboarding walkthrough | "How do I onboard my organisation?" |
| **IT / network engineer** | Technical detail | "How do certificates work?" |
| **Product / developer** | Architecture context | "What identity providers are supported?" |
| **Support agent** | Fast answer lookup for tickets | "How do I troubleshoot onboarding?" |

## Success criteria

- **Grounded answers:** 100% of answers cite at least one source document, or explicitly say "I couldn't find that information."
- **Accuracy:** ≥90% of MVP evaluation questions rated correct against expected answer.
- **Latency:** P50 first-token < 1.5s; P95 full-answer < 8s on a warm cache.
- **Zero hallucination on unknowns:** on a curated set of "known-unknown" questions, the assistant declines to answer in ≥95% of cases.
- **Coverage:** 100% of pages in all three docs repos indexed and retrievable.

## Scope (MVP — Phase 1)

- Ingest **govwifi-product-page** source content.
- RAG pipeline: chunk → embed → vector store → retrieve → generate → cite.
- Chat widget embedded in the product-page site (floating button, chat panel).
- Streaming responses, citations, suggested questions.
- Evaluation harness page.

## Scope (Phase 2)

- Add **govwifi-tech-docs** and **govwifi-dev-docs** to the ingestion pipeline (no architectural change).

## Scope (Phase 3)

- Ingest **Zendesk ticket exports** as an additional (lower-priority) source.
- Retrieval ranking: product-page > tech-docs > dev-docs > zendesk.

## Non-goals

- No live web crawling — we index the source repos directly.
- No user-generated content (no chat log persistence beyond in-session, no accounts in MVP).
- No multi-turn tool use / agentic workflows.
- No fine-tuning; RAG only.
- No modification to the existing static-site publishing pipeline in Phase 1.

## Functional requirements

| ID | Requirement |
|---|---|
| FR-01 | User can open a floating chat panel from any product-page page |
| FR-02 | User can type a question and receive a streamed answer |
| FR-03 | Every answer displays a Sources panel with the file paths used |
| FR-04 | When no relevant context is retrieved, the assistant declines to answer |
| FR-05 | User can copy the answer, clear the conversation, and see suggested questions |
| FR-06 | An operator can run `bin/rails ai:index_docs` to re-index all sources |
| FR-07 | An operator can view an evaluation dashboard at `/evaluate` |
| FR-08 | The assistant works on mobile and meets WCAG 2.1 AA |

## Non-functional requirements

- **Security:** No PII stored server-side. API keys in environment/credentials, never in source. CSRF-protected. Rate-limited per IP.
- **Compliance:** Fits a UK Gov deployment pattern (GOV.UK PaaS / Cloud Foundry compatible; 12-factor).
- **Observability:** Structured logs, per-request latency + token-count metrics, error tracking hook.
- **Portability:** All LLM/embedding calls go through an abstraction — swap providers without touching business logic.
- **Reproducibility:** Docker-composable local stack; deterministic ingestion (content-hash keyed).

## MVP features

- Floating chat button + panel (GOV.UK Design System styling)
- Streaming answer with in-line loading indicator
- Citation panel per answer
- Suggested-question chips
- Copy answer / clear conversation
- `bin/rails ai:index_docs` rake task
- `/evaluate` page with question/expected/actual/sources/latency/feedback

## Stretch features (designed for, not built)

- Feedback thumbs up/down persisted
- Learning from approved answers
- Slack integration
- SSO / staff-only admin portal
- Analytics + token usage dashboard
- Cost tracking

## Technical architecture (summary)

See [architecture.md](./architecture.md) for the full picture.

- **App:** Rails 8, Hotwire (Turbo + Stimulus), served by Puma.
- **Data:** Postgres 16 with `pgvector` (via the `neighbor` gem).
- **Jobs:** Sidekiq + Redis (indexing jobs).
- **LLM:** `LlmClient` abstraction over Anthropic (default) and OpenAI.
- **Deployment:** Docker; PaaS-compatible manifest.
- **Product-page integration:** Single `<script>` include in `source/layouts/layout.erb`.

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| LLM hallucinates despite RAG | Medium | High | Strict system prompt; low temperature; require citations; evaluation harness |
| Retrieval misses relevant chunk | Medium | Medium | Chunk-overlap, heading-aware chunking, source-type ranking, hybrid search later |
| Docs drift ahead of index | High | Medium | `ai:index_docs` runnable on demand; scheduled job later |
| Cost creep on API tokens | Medium | Medium | Cache embeddings; content-hash idempotency; token budget per request |
| Product-page CSP blocks widget | Low | High | Test CSP; use inline nonces; document deployment prereqs |
| Vendor lock-in on Anthropic | Low | Medium | `LlmClient` abstraction; OpenAI path tested |

## Assumptions

- Anthropic API access is available (key provisioned).
- The three docs repos remain on GitHub under GovWifi org.
- GOV.UK PaaS is the intended deploy target (or a compatible container platform).
- Ruby 3.3+ acceptable for the new Rails app (product-page is on 4.0.x for the Middleman side — unrelated).

## Milestones

| ID | Name | Approval gate |
|---|---|---|
| M1 | Scaffold Rails 8 app at `./chatbot` | ⏳ |
| M2 | Ingestion pipeline (`rake ai:index_docs`) | ⏳ |
| M3 | Retrieval + Answering API | ⏳ |
| M4 | Chat widget UI | ⏳ |
| M5 | Evaluation page | ⏳ |
| M6 | Wire widget into product-page layout | ⏳ |

## Current progress

- ✅ Repository audit complete
- ✅ Architecture decisions locked in (see decisions.md)
- ✅ Docs scaffolded
- ⏳ M1 not yet started

## Next milestone

**M1 — Scaffold Rails 8 app at `./chatbot`.** See `tasks.md` for the per-commit breakdown.
