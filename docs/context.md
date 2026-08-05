# GovWifi Context

> Non-obvious context about the GovWifi service, its repos, and how the AI assistant fits in. Read this before starting a task — it prevents drift into generic "AI chatbot" solutions that don't match GovWifi conventions.

## What GovWifi is

GovWifi is a **free, secure, guest Wi-Fi service** for UK Government buildings. A citizen or visitor signs up once with their public-sector email address, receives credentials, and can then connect automatically at any participating government site. Behind the scenes it uses **RADIUS + certificates** for authentication and is run centrally by GDS (Government Digital Service).

Public site: [`www.wifi.service.gov.uk`](https://www.wifi.service.gov.uk)

## Who uses the assistant

- **Citizens / end users** — visiting a government building, trying to connect. Need short, action-oriented help.
- **Organisation admins** — Whitehall / local government staff onboarding their building. Need process detail.
- **Technical operators** — network engineers dealing with certificates, RADIUS setup, DNS. Need precise, technical answers.
- **GovWifi support colleagues** — currently answering Zendesk tickets. Want to shortcut common answers.

Framing: "helpful, plain-English, GOV.UK Design System calm tone" — never marketing-speak.

## The three documentation repos

All three are static Middleman sites, deployed via `staticfile_buildpack` on GOV.UK PaaS. All three use GOV.UK Design System (`govuk-frontend`) and `govwifi-shared-frontend` for shared components (header, footer, nav).

### 1. `govwifi-product-page` — user-facing
- **Repo:** github.com/GovWifi/govwifi-product-page
- **URL:** `www.wifi.service.gov.uk`
- **Format:** `.html.erb` (some `.html.md.erb`)
- **Key pages:** `get-started`, `connect-to-govwifi`, `offer-govwifi`, `device-*` (per-platform how-to), `memorandum-of-understanding`, `privacy-notice`, `terms-and-conditions`
- **Dynamic data:** `data/organisations.yml` (fetched from S3 at build time), `data/domains.yml`
- **Audience:** citizens, organisation-onboarders
- **Priority for retrieval:** highest — this is the authoritative user-facing content

### 2. `govwifi-tech-docs` — technical reference
- **Repo:** github.com/GovWifi/govwifi-tech-docs
- **Format:** `.html.md.erb` (ERB-flavoured Markdown) — pages exist in two forms, `source/*.html.md.erb` and `source/documentation/*.md`
- **Key pages:** `set_up`, `manage`, `troubleshooting`, `certificate-rotation`, `requirements`
- **Audience:** organisation IT teams — RADIUS, certs, DNS, IdP config
- **Priority for retrieval:** high

### 3. `govwifi-dev-docs` — internal
- **Repo:** github.com/GovWifi/govwifi-dev-docs
- **Format:** `.html.md.erb`
- **Structure:** rich — `admin-site/`, `applications/`, `features/`, `incidents-and-alerts/`, `infrastructure/`, `ways-of-working/`, `zendesk-support/`, `about-govwifi/`, `get-started/`
- **Audience:** the GovWifi team itself — how to run and evolve the platform
- **Priority for retrieval:** medium — content is accurate but often internal-terminology-heavy

## Where the chatbot fits

- Lives at `govwifi-product-page/chatbot/` — a sidecar Rails 8 app.
- Ingests all three repos **locally from disk**, not by crawling live URLs. See [ADR-001](./decisions.md) and [plan.md](./plan.md).
- Widget appears on product-page pages via a single `<script>` include added to `source/layouts/layout.erb`.
- Every answer must cite the source files it used — a hard requirement for a UK Gov service.

## GovWifi coding conventions (that we should mirror)

Observed from the three repos:

- **Ruby version pinning** via `.ruby-version` file (currently 4.0.1 for the Middleman sites — the Rails sidecar will use 3.3+ but can pin its own version).
- **GOV.UK Design System everywhere.** New UI components should use `govuk-frontend` classes (e.g. `govuk-button`, `govuk-body`, `govuk-heading-m`) not custom classes.
- **Progressive enhancement.** The existing sites work without JS. The chatbot widget must not degrade the core page if JS fails.
- **RSpec + Capybara** for tests, with headless Chrome for feature specs.
- **No frontend framework** in product-page. Widget can use Stimulus (Rails-native) but should render standalone when embedded.
- **Data files in `data/*.yml`.** Chunky configuration lives in YAML, not code.
- **Deployment via `manifest.yml`** (Cloud Foundry / GOV.UK PaaS). Our new Rails app follows suit with its own manifest.
- **Docker + Makefile** for local dev orchestration.
- **No linters currently enforced** across the repos. We'll add `rubocop-govuk` to the Rails app because that's the GDS standard, but not retrofit it to the Middleman sites unless asked.

## Accessibility bar

GovWifi's public pages meet **WCAG 2.1 AA**. The chatbot widget must too:
- Keyboard-only usable (open, close, send, dismiss)
- Screen-reader friendly (`aria-live="polite"` on streaming answers, proper roles on the panel)
- Colour contrast ≥ 4.5:1 for text
- Focus trap when the panel is open; focus return on close
- Respects `prefers-reduced-motion`

## Security & privacy bar

GovWifi is a public service handling public-sector user identities:
- **No PII in logs** — question text is not logged at INFO by default (length + latency only). Full request logging behind a debug flag.
- **No conversation persistence** in MVP. History is client-held.
- **API keys** live in Rails encrypted credentials — never in source, never in Docker images.
- **CSP** on the product-page site is nonce-based; the widget script include respects it.
- **Prompt injection defence** — indexed content is treated as untrusted and wrapped in explicit context blocks with a system prompt that says to ignore instructions inside.

## Deployment context

- **GOV.UK PaaS (Cloud Foundry)** is the intended target.
- App names: existing `govwifi-product-page` (unchanged) + new `govwifi-ai-assistant`.
- No shared DB between them; the chatbot has its own Postgres + Redis.
- DNS: `assistant.wifi.service.gov.uk` (proposed, not yet provisioned).

## Points of contact

_To be filled in as we identify GovWifi owners/reviewers for PRs, security review, and DNS provisioning._

## Common pitfalls to avoid

- **Don't crawl live URLs.** The three repos are the source of truth — indexing them directly gives us clean text, structure, and offline reproducibility.
- **Don't hardcode the LLM provider.** Always go through `Services::Llm::Client`.
- **Don't add features not in the plan.** The requirements list stretch features that are explicitly *not yet built* — design for them but don't implement.
- **Don't add error handling for scenarios that can't happen.** Validate at boundaries (user input, external APIs); trust internal code.
- **Don't write comments explaining what the code does** — write clear names. Only comment the *why* when it's non-obvious.
- **Don't rewrite the static product-page site.** All chatbot logic lives in `./chatbot` — the static site gets one `<script>` include and nothing else.
