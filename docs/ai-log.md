# AI Development Log

> Append-only diary. One entry per working session. Newest at the top.

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
