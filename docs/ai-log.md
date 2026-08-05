# AI Development Log

> Append-only diary. One entry per working session. Newest at the top.

---

## 2026-08-05 — M2: Ingestion pipeline

**Goal:** Land the full local-repo → chunks → embeddings → pgvector pipeline as a re-runnable `bin/rails ai:index_docs` task, with idempotency and full RSpec coverage.

**Files changed**
- `chatbot/.rspec`, `chatbot/spec/{spec_helper,rails_helper}.rb`, `chatbot/spec/support/{webmock,vcr}.rb`
- Migrations: `20260805000002_enable_pgcrypto.rb`, `20260805000003_create_documents.rb`, `20260805000004_create_chunks.rb`
- Models: `app/models/{document,chunk}.rb`
- LLM: `app/services/llm/{client,anthropic_adapter,open_ai_adapter}.rb`, `config/initializers/llm.rb`
- Loaders: `app/services/ingest/{loaded_document,loaders}.rb` + `loaders/{erb_stripper,front_matter,markdown_loader,html_loader,html_erb_loader,md_erb_loader,pdf_loader,txt_loader}.rb`
- Sources + chunker: `app/services/ingest/{sources/local_repo,chunker}.rb`, `config/ai_sources.yml`
- Pipeline: `app/services/ingest/{embedder,pipeline}.rb`
- Jobs: `app/jobs/{index_document_job,reindex_all_job}.rb`
- Rake: `lib/tasks/ai.rake` (ai:index_docs, ai:dry_run)
- Config: `config/application.rb` (queue_adapter :sidekiq outside test)
- ADR: `docs/decisions.md` (ADR-006)
- Specs across the tree

**Summary**
Seven feature/test commits + one ADR + one docs-update commit:
1. `docs: add ADR-006 splitting chat and embedding provider concerns`
2. `test(chatbot): add RSpec, FactoryBot, WebMock, VCR bootstrap`
3. `feat(chatbot): add Document + Chunk models with pgvector storage`
4. `feat(chatbot): add LlmClient abstraction with Anthropic + OpenAI adapters`
5. `feat(chatbot): add ingest loaders for md, html.erb, html.md.erb, html, pdf, txt`
6. `feat(chatbot): add Sources::LocalRepo + Chunker`
7. `feat(chatbot): add Embedder, Pipeline, jobs, and ai:index_docs rake task`

**Problems encountered**
- Anthropic doesn't have a first-party embedding endpoint — coupling chat + embed providers would force us into Voyage or force a re-embed on every LLM swap.
- Uncertainty over whether the `anthropic` gem name (and its API surface) would resolve cleanly on rubygems; would have blocked `bundle install` at first build.
- Chunker with heading awareness had a subtle bug on the initial regex — needed to handle "text before the first heading" as a section with an empty heading chain.

**Solutions**
- **ADR-006**: split chat/embed provider config. Default chat = Anthropic, default embed = OpenAI (1536-dim vector column).
- Removed both `anthropic` and `ruby-openai` gems; wrote Faraday-based adapters directly. Cleaner, no SDK drift, consistent style across providers.
- Chunker `split_by_headings` explicitly appends a trailing section for the pre-heading buffer, then handles the mid-file heading transitions.

**Technical decisions**
- Faraday-only LLM adapters (no SDK gems): stable API, streaming implemented via `req.options.on_data` on both providers.
- Idempotency via `raw_content_hash` on Document — hash the raw file bytes (not the loaded/stripped text), so ERB whitespace edits still trigger re-embedding when a reviewer expects them to.
- HTML loader strips `script`, `style`, `nav`, `footer`, `aside`, `.govuk-cookie-banner` and prefers `<main>`/`#content`/`<article>` over `<body>` — no separate Normalizer service needed.
- Chunker returns `Data`-defined `ChunkAttrs` PORO (not AR objects) — keeps the chunker decoupled from persistence for easier unit testing.
- `rake ai:index_docs` runs sync by default (dev-friendly, no Sidekiq needed for a first run); `ASYNC=1` fans out to Sidekiq.
- No PII in log lines from `IndexDocumentJob` — logs source_type/relative_path and chunk count only, matching the docs/context.md security bar.

**Next steps**
- Await M2 approval.
- Do a first real run of `rake ai:index_docs` against product-page (requires `OPENAI_API_KEY`) to validate the end-to-end flow before starting M3.
- On approval, start M3: Retriever + Ranker + PromptBuilder + `POST /api/chat`.

---

## 2026-08-05 — M1: Rails 8 sidecar scaffold

**Goal:** Land the empty-but-runnable Rails 8 app at `./chatbot`, wired for Postgres + pgvector, Sidekiq, and the LLM SDKs, orchestrated by docker-compose.

**Files changed**
- Added `chatbot/` (full Rails 8.1 scaffold, ~71 files)
- Added `chatbot/db/migrate/20260805000001_enable_pgvector.rb`
- Added `chatbot/.env.example`, `chatbot/Dockerfile.dev`, `chatbot/docker-compose.yml`
- Added `chatbot/config/initializers/sidekiq.rb`
- Modified `chatbot/config/database.yml` (env-driven config)
- Modified `chatbot/Gemfile` (neighbor, anthropic, ruby-openai, sidekiq, redis, faraday, nokogiri, commonmarker, pdf-reader, rack-attack, dotenv-rails, rspec-rails, factory_bot, faker, webmock, vcr)
- Replaced `chatbot/README.md` with a local dev guide

**Summary**
Five commits landed on the `chatbot` branch:
1. `chore(chatbot): add Rails 8 app scaffold`
2. `chore(chatbot): add pgvector + neighbor gem for vector storage`
3. `chore(chatbot): add LLM client, background job, and testing gems`
4. `chore(chatbot): add docker-compose for local dev`
5. `docs(chatbot): replace default Rails README with local dev guide`

**Problems encountered**
- No Ruby installed locally on the workstation. First attempt to `rails new` via podman failed on `--css=none` (invalid enum value in Rails 8.1).
- `rails new` skipped `.gitignore` due to `--skip-git`; the parent product-page `.gitignore` doesn't cover Rails needs.

**Solutions**
- Retried `rails new` without the invalid `--css=none`; the default (empty CSS) is what we want anyway. GOV.UK Design System comes in with the widget in M4.
- Added a Rails-appropriate `chatbot/.gitignore` including `/config/master.key` to keep the master key out of git.

**Technical decisions**
- Used `pgvector/pgvector:pg16` image in docker-compose — ships with the extension pre-installed. Cleaner than a plain postgres image + custom init.
- Kept the production Dockerfile that `rails new` produced (thruster-based) and added a separate `Dockerfile.dev` for the docker-compose flow. Two files, clear intent, no branching in a single Dockerfile.
- Rubocop kept as rails-omakase for now. `rubocop-govuk` was considered but omakase is fine at this stage; can swap in later without an ADR-worthy change.

**Next steps**
- Await M1 approval.
- On approval, start M2: `Document` + `Chunk` ActiveRecord models with pgvector, then loaders + chunker + embedder + rake task.

---

## 2026-08-05 — Repository audit, architecture, docs scaffolding

**Goal:** Understand the three GovWifi repos, decide on an integration approach for the AI Support Assistant, and lay down living documentation before any code.

**Files changed**
- Created `docs/plan.md`
- Created `docs/architecture.md`
- Created `docs/tasks.md`
- Created `docs/decisions.md` (ADR-001 through ADR-005)
- Created `docs/ai-log.md` (this file)
- Created `docs/evaluation.md`
- Created `docs/README.md`
- Created `docs/context.md`

**Summary**
- Cloned `govwifi-product-page`, `govwifi-tech-docs`, `govwifi-dev-docs` into `~/Documents/my-work/govwifi/`.
- Created `chatbot` branch on product-page and pushed to origin.
- Audited all three repos: all are static Middleman sites (Ruby 4.0.1, ERB templates, GOV.UK Design System). None have a backend.
- Decided on companion Rails 8 app at `product-page/chatbot/` (ADR-001). Claude default LLM (ADR-002). Postgres + pgvector (ADR-003). Widget via single `<script>` include (ADR-004). In-repo docs (ADR-005).
- Broke the plan into six milestones (M1–M6) with approval gates between each.

**Problems encountered**
- Middleman is fully static — cannot host any dynamic behaviour. Rewriting it to Rails would have massive blast radius on the live public service.
- Voyage vs OpenAI embedding dimensions differ (1024 vs 1536). Documented in ADR-002; migration path noted.

**Solutions**
- Sidecar Rails app pattern (ADR-001) preserves the static site untouched.
- `LlmClient` abstraction (ADR-002) makes provider switching a config change.
- Content-hash idempotency for ingestion means re-embedding is a bounded, resumable operation.

**Technical decisions**
See `decisions.md` ADR-001 through ADR-005.

**Next steps**
- Await approval on the plan.
- Then start M1: scaffold the Rails 8 app at `./chatbot`, five small commits as listed in `tasks.md`.

---

## Template

Copy for the next entry:

```
## YYYY-MM-DD — Short title

**Goal:**

**Files changed**
-

**Summary**
-

**Problems encountered**
-

**Solutions**
-

**Technical decisions**
-

**Next steps**
-
```
