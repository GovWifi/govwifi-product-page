# AI Development Log

> Append-only diary. One entry per working session. Newest at the top.

---

## 2026-08-05 — M4: Chat widget UI

**Goal:** Ship a floating chat widget that streams answers from `/api/chat`, renders citations, and is accessible on desktop and mobile — as a single embeddable file.

**Files changed**
- `chatbot/public/widget.js` — the whole widget (shell, CSS, SSE, streaming render, citations, copy, clear, suggestions, focus trap, ARIA, responsive)
- `chatbot/app/controllers/widget_demo_controller.rb` — dev-only route to render the widget standalone
- `chatbot/app/views/widget_demo/show.html.erb` — bare HTML page mounting the widget
- `chatbot/config/routes.rb` — `get "widget_demo"`
- `chatbot/spec/requests/widget_demo_spec.rb` — smoke tests for the demo route and widget.js delivery

**Summary**
Five widget commits + one docs commit:
1. `feat(widget): add shell, floating button, and panel skeleton`
2. `feat(widget): SSE consumption, streaming render, form submit, history`
3. `feat(widget): citation panel, copy, clear, suggested questions`
4. `feat(widget): accessibility polish — focus trap, Escape, ARIA updates`
5. `test(widget): smoke tests for the demo route and widget.js delivery`

**Problems encountered**
- **Stimulus vs vanilla.** The task list said "Stimulus controller". Reality: Stimulus expects Rails to render the HTML with `data-controller="..."`, but the widget mounts itself into a *different* origin's DOM (product-page is a static Middleman site). Using Stimulus would force an ES-module build step and mean multiple network fetches for the widget bundle.
- **CSS collisions.** The widget will live inside product-page which already loads `govuk-frontend`. If we reuse `.govuk-button` etc., we couple our layout to a specific CSS version we don't control.
- **Real JS-driven UI tests.** Selenium + headless Chrome would give us end-to-end coverage but we don't have a Chrome binary in the current sandbox, and adding one to `Dockerfile.dev` is a heavy prerequisite for M4.

**Solutions**
- **Vanilla JS in one IIFE at `public/widget.js`.** All class names prefixed `.gwa-`. CSS inlined into the JS as a template literal, injected at boot as a `<style>` tag. Zero build step, one file, one `<script>` include.
- **Own GOV.UK-matched palette** (green `#00703c`, focus yellow `#ffdd00`, black text). Looks native to product-page but does not depend on `govuk-frontend` being loaded on the host.
- **API URL derived from the widget's own `<script src>`** — the same file works when served from `assistant.wifi.service.gov.uk` and when served from `/widget.js` locally.
- **SSE via `fetch()` + `ReadableStream`** rather than `EventSource` (which doesn't support POST). Multi-line `data:` accumulation handled.
- **Client-side history array.** Sent with each request; no server-side persistence (matches plan.md non-goals).
- **`aria-modal` toggled on open/close** (inline dialog pattern), focus trap on Tab/Shift+Tab, Escape closes, previously-focused element restored on close. Matches WAI-ARIA APG "Modal Dialog Example".
- **Smoke tests, not full UI tests, for now.** `GET /widget_demo` returns HTML with the script tag; production returns 404; `GET /widget.js` returns the bundle containing the expected identifiers. Real Capybara + headless Chrome tests are deferred — logged in tasks.md.

**Technical decisions**
- Single-file widget, no build step, no framework.
- Inline CSS in JS, not a separate `widget.css`, so the embed contract is one line.
- `role="log"` + `aria-live="polite"` on the messages container so streaming answers announce naturally.
- `aria-busy` set to `"true"` during a request to pause screen-reader announcements while the answer is still forming.
- Citations render *after* the streamed answer, deduplicated by (source_type, path), formatted as `source_type/relative_path` per the requirements' example.

**Next steps**
- Await M4 approval.
- Start M5: evaluation harness (Evaluation model, /evaluate page, EvaluationRunJob, rake ai:evaluate, seed set from `docs/evaluation.md`).

---

## 2026-08-05 — M3: Retrieval + Answering API

**Goal:** Wire retrieval + prompt construction + LLM call into a `POST /api/chat` endpoint that supports both JSON and SSE, with per-IP rate limiting.

**Files changed**
- Retrieval: `app/services/retrieval/{ranker,retriever}.rb` + specs
- Answering: `app/services/answering/{prompt_builder,answer_service}.rb` + specs
- API: `app/controllers/api/{base_controller,chat_controller}.rb`, `config/routes.rb`, `config/initializers/cors.rb`
- Rate limiting: `config/initializers/rack_attack.rb`, `config/application.rb`
- Gemfile: `+ rack-cors`
- Specs: `spec/requests/api/*`, `spec/services/{retrieval,answering}/*`

**Summary**
Five feature commits + one docs commit:
1. `feat(chatbot): add Retriever with pgvector cosine + source_type ranking`
2. `feat(chatbot): add PromptBuilder + AnswerService orchestrator`
3. `feat(chatbot): add POST /api/chat non-streaming JSON endpoint`
4. `feat(chatbot): add SSE streaming branch to POST /api/chat`
5. `feat(chatbot): add per-IP rate limiting on /api/chat via rack-attack`

**Problems encountered**
- Rate-limiting specs are naturally flaky (shared middleware state across examples). Went through several designs — file-level reload of the initializer, dynamic throttle override — before settling on a `ClimateControl`-style env-swap that reloads `rack_attack.rb` per-test.
- Deciding whether to send citations before or after the streamed answer. Went with *after* to match the visual "answer, then sources" pattern and to let the widget render the citation panel once the answer settles.

**Solutions**
- **Neighbor gem's cosine distance** is converted to similarity via `1 - distance`. Result Data objects carry both raw similarity and the source-priority-adjusted score so ranking is explicit and testable.
- **Over-fetch** by 2× k at pgvector query time so re-ranking can reorder without losing narrowly-beaten strong candidates.
- **PromptBuilder** wraps chunks in `<context source="..." source_type="...">` blocks and explicitly instructs the model to ignore instructions inside those blocks (prompt-injection defence, per architecture.md §8).
- **Short-circuit on empty retrieval**: both `AnswerService#call` and `#stream` return the `UNKNOWN_ANSWER` phrase without calling the LLM. Saves cost and guarantees the exact refusal wording.
- **Semantic events, not SSE strings**: AnswerService yields `Events::Token / Citations / Done` Data objects; the controller translates to SSE. Clean separation of concerns, straightforward to unit-test the service without any HTTP framework in scope.
- **X-Accel-Buffering: no** header on the SSE branch defends against nginx buffering the whole stream and delivering it as one chunk.

**Technical decisions**
- `ActionController::API` for the API controllers (not `ApplicationController`). Cleaner, no session/CSRF machinery.
- `ActionController::Live` mixed in for streaming — the same endpoint serves both JSON and SSE, branching on `Accept: text/event-stream`.
- Rate limits (20 req / 60s per IP) are ENV-driven so we can turn the knob without a code deploy.
- CORS origins default to Middleman's `:4567` + Rails' `:3000` for dev; production sets `CORS_ALLOWED_ORIGINS` explicitly.

**Next steps**
- Await M3 approval.
- Start M4: chat widget UI (floating button, chat panel, streaming, citation panel, accessibility, mobile).

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
