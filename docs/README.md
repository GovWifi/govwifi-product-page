# GovWifi AI Support Assistant

A Retrieval-Augmented Generation (RAG) chatbot embedded into the GovWifi Product Pages. Answers user questions using **only** official GovWifi documentation, with source citations under every answer.

> **Status:** In active development. Planning complete. Code scaffolding starts at Milestone M1.
> **Home:** `govwifi-product-page/chatbot/` (Rails 8 sidecar) with living docs at `govwifi-product-page/docs/`.
> **Branch:** `chatbot` — see [never-push-master rule](#contributing).

---

## Overview

GovWifi documentation is spread across three static Middleman sites:

- **`govwifi-product-page`** — user-facing product marketing + how-to
- **`govwifi-tech-docs`** — technical reference for onboarding organisations
- **`govwifi-dev-docs`** — internal developer and admin documentation

Users today have to know *which* site their answer lives on. The assistant lets them ask in natural language and get a grounded answer with links to the source pages.

**MVP goal:** answer questions like *"How do I sign up?"*, *"How do I onboard my organisation?"*, *"How do certificates work?"*, drawing only from indexed GovWifi documentation and refusing (rather than hallucinating) when it doesn't know.

## Architecture

- **Sidecar Rails 8 app** at `./chatbot` (Postgres + pgvector, Sidekiq, Hotwire).
- **Ingestion pipeline** — `rake ai:index_docs` reads local `.md`, `.html.md.erb`, `.html.erb`, `.html`, `.pdf`, `.txt` files → chunks → embeds → stores in pgvector.
- **Retrieval + answering** — `POST /api/chat` returns a streamed answer with a `citations` payload.
- **Widget** — single `<script src=".../widget.js">` include added to the product-page layout. GOV.UK Design System styling.
- **LLM abstraction** — Claude (Anthropic) by default, OpenAI behind the same interface.

Full detail in [`docs/architecture.md`](./architecture.md). The reasoning behind each choice is in [`docs/decisions.md`](./decisions.md).

## Setup

**Prerequisites**
- Docker + Docker Compose (recommended local path)
- Ruby 3.3+ (if running Rails outside Docker)
- Node 20+ (for the widget bundle)
- An Anthropic API key (or OpenAI API key for the fallback provider)

**Install (Docker path — recommended, after M1 lands)**
```bash
cd chatbot
cp .env.example .env             # then edit with your ANTHROPIC_API_KEY
docker-compose up --build
```

The Rails app will be available on `http://localhost:3000`. Postgres and Redis run alongside.

## Indexing documents

Every time GovWifi documentation is updated, re-index by running:

```bash
bin/rails ai:index_docs
```

This walks the sources configured in `config/ai_sources.yml`:

```yaml
- source_type: product-page
  path: ../source
- source_type: tech-docs
  path: ../../govwifi-tech-docs/source
- source_type: dev-docs
  path: ../../govwifi-dev-docs/source
```

Idempotent: only re-embeds files whose content hash has changed.

## Running locally

- Rails app: `http://localhost:3000`
- Evaluation harness: `http://localhost:3000/evaluate`
- Widget bundle: `http://localhost:3000/widget.js`

**Product-page dev server (unchanged):** `make server` from `govwifi-product-page/` root.

**Testing the widget in-context:**
```bash
CHATBOT_WIDGET_URL=http://localhost:3000/widget.js make server
```

## Future roadmap

- **Phase 2:** Add tech-docs and dev-docs to the ingestion pipeline (no arch change).
- **Phase 3:** Ingest Zendesk ticket exports as an additional (lower-priority) source.
- **Later:** Thumbs-up/down feedback, learning from approved answers, Slack integration, SSO auth, analytics, token/cost dashboard, admin portal.

See [`docs/plan.md`](./plan.md) for the full plan, and [`docs/tasks.md`](./tasks.md) for the live backlog.

## Contributing

- All work happens on the **`chatbot`** branch. Never push to `master`/`main`.
- Before starting any task, read `docs/plan.md`, `docs/tasks.md`, and `docs/architecture.md`.
- Any architectural change requires a new ADR in `docs/decisions.md` **before** implementation.
- After completing a feature: update `plan.md` (progress), tick items in `tasks.md`, append to `ai-log.md`, and update this README if user-facing behaviour changed.
- Milestone approval is gated — see the checklist in `tasks.md`.

## Where to find things

| I want to… | File |
|---|---|
| Understand the vision, scope, milestones | [`docs/plan.md`](./plan.md) |
| Read the architecture in depth | [`docs/architecture.md`](./architecture.md) |
| See the current backlog | [`docs/tasks.md`](./tasks.md) |
| Learn why we chose X | [`docs/decisions.md`](./decisions.md) |
| See past working sessions | [`docs/ai-log.md`](./ai-log.md) |
| Test AI quality | [`docs/evaluation.md`](./evaluation.md) |
| Understand GovWifi as a system | [`docs/context.md`](./context.md) |
