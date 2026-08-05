# Evaluation

> How we measure the assistant's quality over time. This document is both the manual test log and the seed for the automated evaluation harness at `/evaluate`.

## What we measure

| Metric | Target | How we measure |
|---|---|---|
| Correctness | ≥90% of eval questions rated correct | Human rating against `expected_answer` |
| Unknown-question refusal | ≥95% decline rate on known-unknowns | Curated set of out-of-scope questions |
| Retrieval precision | Top-3 chunks include the expected doc in ≥85% of cases | Compare retrieved paths vs `expected_sources` |
| Latency P50 | First token < 1.5s | Instrumented in `AnswerService` |
| Latency P95 | Full answer < 8s | Same |
| Citation presence | 100% of confident answers cite ≥1 source | Assert in request specs |

## Rating scale

- **Correct** — matches the expected answer semantically; citations are appropriate
- **Partial** — factually correct but misses a key point, OR correct with weak citations
- **Incorrect** — factually wrong, hallucinated, or cited unrelated sources
- **Refused** — assistant said "I couldn't find that information" (correct behaviour if question is out of scope; incorrect if scope-relevant)

## Evaluation entry template

Every evaluation record has this shape (persisted in the `evaluations` and `evaluation_runs` tables):

```
Question:            How do I sign up for GovWifi?
Expected answer:     Users sign up by going to www.wifi.service.gov.uk, entering their
                     government/public-sector email address, and following the
                     instructions in the confirmation email...
Expected sources:    product-page/source/get-started.html.erb
                     product-page/source/check-organisation-email-address.html.erb
---
Actual answer:       [populated by run]
Documents retrieved: [populated by run]
Correct/Partial/Incorrect/Refused: [rated by human]
Latency (ms):        [populated by run]
Feedback:            [thumbs up/down + free text]
Notes:               Any regression context, model version, prompt version, etc.
```

## Seed evaluation set (MVP, ~10 questions)

Populated at the start of M5. To be extended over time.

### Product-page questions

1. **Q:** How do I sign up for GovWifi?
   **Expected:** Steps from the get-started page; email domain check.
   **Expected sources:** `product-page/source/get-started*`, `product-page/source/check-organisation-email-address.html.erb`

2. **Q:** How do I onboard my organisation?
   **Expected:** Reference the offer-govwifi flow; MoU requirement.
   **Expected sources:** `product-page/source/offer-govwifi.html.erb`, `product-page/source/memorandum-of-understanding.html.erb`

3. **Q:** How do I connect on an iPhone?
   **Expected sources:** `product-page/source/device-iphone-or-ipad.html.erb`

4. **Q:** How do I connect on Windows?
   **Expected sources:** `product-page/source/device-windows.html.erb`

5. **Q:** How do I troubleshoot Windows?
   **Expected sources:** `product-page/source/device-windows-troubleshoot.html.erb`

### Tech-docs questions (Phase 2)

6. **Q:** How does GovWifi authentication work?
   **Expected sources:** `tech-docs/source/documentation/introduction.md`, `tech-docs/source/documentation/set_up.md`

7. **Q:** How do certificates work?
   **Expected sources:** `tech-docs/source/certificate-rotation.html.md.erb`

### Dev-docs questions (Phase 2)

8. **Q:** What identity providers are supported?
   **Expected sources:** `dev-docs/source/applications/*`, `dev-docs/source/features/*`

9. **Q:** How do I troubleshoot onboarding?
   **Expected sources:** Multiple across dev-docs `admin-site/`

### Known-unknowns (decline-rate check)

10. **Q:** What's the weather in London today?
    **Expected:** Assistant declines — "I couldn't find that information in the GovWifi documentation."

11. **Q:** When was Sadiq Khan elected?
    **Expected:** Assistant declines.

12. **Q:** How do I connect to Eduroam?
    **Expected:** Assistant declines (not GovWifi).

## Running evaluations

- **Manually:** Visit `/evaluate`, click "Run" on individual rows or "Run all".
- **CLI:** `bin/rails ai:evaluate` — runs all evaluations, writes a report to `tmp/eval-<timestamp>.md`.
- **CI (future):** Same rake task, fail the build if correctness drops below threshold.

## Historical results

_Empty — populated as evaluation runs happen._

| Date | Model | Prompt v. | Corr% | Refuse% | P50 (ms) | P95 (ms) | Notes |
|---|---|---|---|---|---|---|---|

## Feedback intake

Widget captures thumbs up/down on every answer. Down-votes are inspected weekly and become new evaluation entries. This is the mechanism by which the eval set grows to reflect real usage.
