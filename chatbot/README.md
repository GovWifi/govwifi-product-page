# chatbot/ — GovWifi AI Support Assistant (Rails 8 sidecar)

The Rails app that powers the GovWifi AI Support Assistant. Deploys separately from the static [`govwifi-product-page`](../) site; embeds via a `<script>` tag added to the product-page layout.

For the **project-level** README (vision, roadmap, ADRs), see [`../docs/`](../docs/).

## Stack

- **Ruby** 3.3, **Rails** 8.1
- **Postgres 16** with `pgvector` (via the `neighbor` gem)
- **Sidekiq** on **Redis 7** for background indexing jobs
- **Hotwire** (Turbo + Stimulus), Import Maps, Propshaft
- **RSpec** with FactoryBot, WebMock, VCR
- **Anthropic** (default) and **OpenAI** SDKs behind `Services::Llm::Client`

## Prerequisites

- Docker or Podman with Compose support
- (Optional) A local Ruby 3.3 install for running rake tasks outside Docker

## Quick start

```bash
# From this directory
cp .env.example .env
# Edit .env — at minimum set ANTHROPIC_API_KEY

docker compose build
docker compose up -d postgres redis
docker compose run --rm web bin/rails db:prepare
docker compose up web sidekiq
```

The app is now at [http://localhost:3000](http://localhost:3000).

## Everyday commands

| Task | Command |
|---|---|
| Rails console | `docker compose run --rm web bin/rails console` |
| Run migrations | `docker compose run --rm web bin/rails db:migrate` |
| Run test suite | `docker compose run --rm web bin/rspec` |
| Re-index docs (M2+) | `docker compose run --rm web bin/rails ai:index_docs` |
| Sidekiq only | `docker compose up sidekiq` |
| Tail logs | `docker compose logs -f web` |
| Reset DB | `docker compose run --rm web bin/rails db:drop db:create db:migrate` |

## Environment variables

Documented in [`.env.example`](./.env.example). Never commit `.env`.

| Variable | Purpose |
|---|---|
| `LLM_PROVIDER` | `anthropic` (default) or `openai` |
| `ANTHROPIC_API_KEY` | Required when `LLM_PROVIDER=anthropic` |
| `OPENAI_API_KEY` | Required when `LLM_PROVIDER=openai` |
| `DATABASE_URL` | Provided by the platform in production; docker-compose sets it in dev |
| `REDIS_URL` | Sidekiq queue backend |

## Directory conventions

```
app/
├── controllers/api/       # JSON/SSE endpoints (M3)
├── services/              # PORO service objects (M2/M3)
│   ├── ingest/            # loaders, normalizer, chunker
│   ├── llm/               # client + provider adapters
│   ├── retrieval/         # retriever, ranker
│   └── answering/         # prompt builder, answer service
├── jobs/                  # Sidekiq jobs
└── javascript/controllers # Stimulus controllers (widget UI, M4)

config/
├── ai_sources.yml         # Configured doc sources (M2)
└── initializers/
    ├── sidekiq.rb
    └── llm.rb             # Arrives in M2
```

## Testing

RSpec is the only test runner. Feature specs use Capybara + headless Chrome (added in M4 when we start rendering UI).

```bash
docker compose run --rm web bin/rspec                       # all specs
docker compose run --rm web bin/rspec spec/services/ingest  # focused
```

External APIs (Anthropic, OpenAI) are stubbed with WebMock/VCR. **Never** run the real APIs in the test suite.

## Deployment

Deployed as a **second Cloud Foundry / GOV.UK PaaS application**, independent of the static product-page. The production `Dockerfile` (Rails-generated, at repo root) is the deploy artifact. Manifest additions land in a later milestone.

Never push to `master`. All work is on the `chatbot` branch — see [contributing notes](../docs/README.md#contributing).

## Where to find things

- [Project plan](../docs/plan.md)
- [Architecture](../docs/architecture.md)
- [Live task backlog](../docs/tasks.md)
- [ADRs](../docs/decisions.md)
- [GovWifi context](../docs/context.md) — read this before starting a task
