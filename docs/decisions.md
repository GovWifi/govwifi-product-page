# Architecture Decision Records

> Every entry is dated and immutable. When a decision is superseded, write a **new** ADR that references the old one — don't rewrite history.

---

## ADR-001 — Companion Rails app rather than rewriting product-page

**Date:** 2026-08-05
**Status:** Accepted

### Context

The GovWifi product-page is a live public-facing static Middleman site deployed via `staticfile_buildpack` on GOV.UK PaaS. It has no backend, no database, no dynamic layer. A RAG chatbot requires: a live API, an embeddings store, background jobs, and LLM calls — none of which are possible in a static site.

Three integration shapes were considered.

### Decision

Build a **companion Rails 8 application at `govwifi-product-page/chatbot/`** (nested inside the product-page repo but with its own `Gemfile`, `manifest.yml`, and deployment). The static product-page site is unchanged apart from a single `<script>` tag in its layout that loads the widget.

### Alternatives considered

1. **Full rewrite of product-page as a Rails app.** Rejected — highest blast radius on a live public service. Adds weeks of work unrelated to the assistant itself. Risks regressing production behaviour.
2. **Separate GitHub repo (`govwifi-ai-assistant`).** Rejected for MVP — cleaner separation, but adds admin overhead (org permissions, CI setup, release coordination). Can be extracted later if we outgrow the mono-repo.
3. **Sinatra / Rack sidecar in product-page.** Rejected — the user requirements explicitly ask for Rails + Hotwire + Sidekiq. Sinatra would force us to reinvent scaffolding that Rails gives for free.

### Consequences

- **Positive:** Product-page deployment pipeline untouched. Two deployable units, independent lifecycles. Familiar Rails conventions for future contributors.
- **Positive:** Extraction to a separate repo later is a `git mv` away — the `chatbot/` dir is self-contained.
- **Negative:** Two apps in one repo can confuse newcomers. Mitigated by clear `chatbot/README.md` and this doc.
- **Negative:** Widget served cross-origin in production — requires CORS setup and CSP tuning on the static site.

---

## ADR-002 — Claude (Anthropic) as default LLM, via an abstraction

**Date:** 2026-08-05
**Status:** Accepted

### Context

The requirements call for "OpenAI or Claude API abstraction layer." We need a primary, but must not lock in.

### Decision

**Claude (`claude-sonnet-4-6`) is the default** for chat completion. All calls go through a `Services::Llm::Client` abstraction with `AnthropicAdapter` and `OpenAiAdapter` implementations. Provider is selectable via `ENV["LLM_PROVIDER"]` (default `anthropic`).

For embeddings, we pick per-provider: `voyage-3` when the provider is Anthropic (Voyage is Anthropic's recommended partner), `text-embedding-3-small` for OpenAI.

### Alternatives considered

1. **OpenAI default.** Reasonable — the embedding model is cheaper. But Claude Sonnet 4.6 is stronger on citation-faithfulness (an explicit success criterion) and the assistant knowledge cutoff aligns with UK government sensitivity requirements.
2. **Bedrock / Vertex-hosted.** Deferred — adds cloud-provider coupling before we know which platform GovWifi will land on. The abstraction leaves the door open.
3. **Locally hosted open model (Llama/Mistral).** Rejected for MVP — quality gap, ops burden. Reconsider if data-residency requirements harden.

### Consequences

- **Positive:** Strong citation behaviour out of the box.
- **Positive:** Swap providers by changing one env var + running migrations if embedding dimension differs.
- **Negative:** Voyage embedding vector dimension differs from OpenAI (1024 vs 1536) — the `Chunk.embedding` column type must be re-created on provider switch. Migration path is documented; not a routine operation.

---

## ADR-003 — Postgres + pgvector for the vector store

**Date:** 2026-08-05
**Status:** Accepted

### Context

We need vector similarity search over ~1k–10k documentation chunks initially, scaling to ~50k with tech/dev-docs and Zendesk.

### Decision

Use **Postgres 16 with the `pgvector` extension**, accessed via the `neighbor` gem for ActiveRecord integration. Similarity uses cosine distance. HNSW index on the `embedding` column.

### Alternatives considered

1. **Qdrant sidecar.** Rejected for MVP — better at very large scale but adds a service. Overkill at our chunk count.
2. **Chroma / Weaviate.** Same reasoning — extra ops without clear benefit at this scale.
3. **Elasticsearch with vector search.** Rejected — our team knows Postgres; ES is another service to run.
4. **SQLite + sqlite-vss.** Rejected — Rails deployment convention on PaaS is Postgres; multi-instance Rails needs a shared store.

### Consequences

- **Positive:** One data layer to run. Familiar backup/restore. Transactional consistency between metadata and vectors.
- **Positive:** HNSW is fast enough at our scale (single-digit ms per query).
- **Negative:** Re-embedding at scale requires a plan (batched, resumable) — accounted for in idempotent design.
- **Negative:** If we later exceed ~500k chunks, we'll need to reassess. Extraction to a dedicated vector DB is bounded: swap the `Retriever` implementation, keep the API.

---

## ADR-004 — Widget embedded via single `<script>` include

**Date:** 2026-08-05
**Status:** Accepted

### Context

We need the chatbot UI to appear on product-page pages. The static site builds at deploy time; we don't want to rebuild the site every time the chatbot's UI changes.

### Decision

Ship a **single `widget.js` bundle** from the Rails app (with `widget.css` inlined or side-loaded). Add one line to `source/layouts/layout.erb`:

```erb
<script src="<%= ENV.fetch('CHATBOT_WIDGET_URL', 'https://assistant.wifi.service.gov.uk/widget.js') %>" defer></script>
```

The bundle self-mounts into a container it creates, initialised after `DOMContentLoaded`.

### Alternatives considered

1. **Inline the widget assets** into `source/` at product-page build time. Tightly couples the two projects; every widget change forces a product-page redeploy.
2. **Iframe embed.** Simpler CSP isolation, but harder to style consistently with GOV.UK Design System and worse for accessibility (focus jumps).
3. **Web component `<govwifi-assistant>`**. Attractive future direction (shadow DOM isolation), but Middleman + govuk-frontend patterns are progressive-enhancement vanilla; Web Component adds unfamiliarity for the maintainers.

### Consequences

- **Positive:** Widget iterates independently of the product-page release cadence.
- **Positive:** Matches how `govuk-frontend` and `gaap-analytics` are loaded today (script tags in `layout.erb`).
- **Negative:** CORS/CSP setup required on both sides. Documented in `architecture.md §8`.
- **Negative:** A widget-side breakage takes down the widget everywhere at once. Mitigated by widget fetching a versioned URL and by graceful degradation (widget catches its own errors and hides).

---

## ADR-005 — Docs live inside product-page repo, not a separate wiki

**Date:** 2026-08-05
**Status:** Accepted

### Context

Living documentation must not drift from code. Options: GitHub Wiki, a separate `govwifi-ai-assistant-docs` repo, or in-repo `docs/`.

### Decision

**All documentation lives in `govwifi-product-page/docs/`** on the `chatbot` branch, promoted to `main` as milestones are approved.

### Alternatives considered

1. **GitHub Wiki.** Rejected — separate from PRs, no code-review of doc changes, hard to require updates in the same commit as code changes.
2. **`chatbot/docs/`** inside the Rails app. Considered — but placing docs one level up keeps them discoverable even if the Rails app is later extracted.

### Consequences

- **Positive:** Doc updates ship in the same PR as the code they describe. Reviewers can enforce the "no stale docs" rule.
- **Negative:** If the Rails app is extracted to its own repo, docs need to move with it. Acceptable — it's a `git mv`.

---

## Template for new ADRs

Copy the block below and paste at the top when adding an ADR.

```
## ADR-NNN — Title

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Superseded by ADR-XXX

### Context
Why is this decision needed? What forces are at play?

### Decision
What did we decide? Be specific.

### Alternatives considered
1. **Name.** Why rejected.
2. **Name.** Why rejected.

### Consequences
- **Positive:** ...
- **Negative:** ...
```
