# Anchor Learning Execution Roadmap v2

## North Star

```text
Import trustworthy project or programming sources
-> build a verifiable knowledge base
-> learn through interview, tutor, and practice sessions
-> record weak points
-> schedule the next review
```

The product is a source-grounded personal learning agent. Runtime machinery is
valuable only when it protects or enables this learning loop.

## Agent Architecture Baseline

MVP uses one orchestrating learning agent with deterministic graph transitions
and specialist tools:

```text
retrieve -> plan -> teach/interview/practice -> verify -> reflect -> schedule
```

- Flutter remains the local-first client.
- SQLite stores sources, knowledge, learning memory, and durable sessions.
- Policy gates prevent unsupported or unverified content from entering formal
  learning.
- AI output is never treated as a source.
- Multi-agent execution, a remote graph backend, and vector storage are added
  only after a demonstrated need.

## Delivery Branches

### Branch 15: Engineering Verification and Golden Path

Status: completed on 2026-07-14.

- Restore the Flutter toolchain.
- Run dependency resolution, formatting, analysis, tests, and migration checks.
- Verify one complete project-import-to-review flow.
- Verified with 44 passing tests, zero analyzer errors or warnings, a reproducible
  source-grounded golden-path test, and an Android debug build/install/cold
  start on API 36.

### Branch 16: Project Source Ingestion v1

Status: completed on 2026-07-14.

- Import a local directory or ZIP before GitHub URL automation.
- Preserve file path, line range, content hash, and revision metadata.
- Let the user select relevant files and exclude generated or secret content.
- Verified with 51 passing tests, zero analyzer errors or warnings, successful
  directory and ZIP selection through Android DocumentsUI, and a debug
  build/install/cold start on API 36.
- Android directory access follows the official Storage Access Framework with
  persisted tree URI permission, `DocumentFile`, and `ContentResolver` reads.

### Branch 17: Project Understanding and Interview Loop

Status: completed on 2026-07-15.

- Produce architecture, data-flow, implementation, boundary, and trade-off
  learning units with code citations.
- Ask one interview question at a time.
- Evaluate the user's answer against cited project evidence.
- Send weak points and follow-up questions into review memory.
- Completed typed project-understanding units, explicit per-unit review,
  knowledge-only saves, a clickable code walkthrough, one-question interviews,
  grounded answer-gap follow-ups, and an atomic cited weak-point-to-review loop
  with focused next-interview entry.

### Branch 18: Programming Knowledge Learning Loop

Status: completed on 2026-07-15.

- Leaf 18.1: completed on 2026-07-15. Preferred official-document and
  source-code imports now require auditable URI, publisher, and revision data;
  SQLite v17 stores acquisition time, license metadata, and SHA-256 integrity
  hashes, with mobile provenance review and source-detail surfaces.
- Leaf 18.2: completed on 2026-07-15. SQLite v18 stores user-reviewed,
  citation-scoped prerequisite edges; stable topological paths expose evidence,
  tutor, readiness, and verified-practice actions for source-backed concepts.
- Leaf 18.3: completed on 2026-07-15. SQLite v19 stores cited tutor turns;
  layered explanations now advance through one-question-at-a-time answers,
  feedback, misconceptions, and source-bounded follow-ups.
- Leaf 18.4: completed on 2026-07-15. SQLite v20 separates open
  programming exercises and attempts from legacy string-answer questions;
  generated exercises require reviewable citations and human verification,
  four-dimensional evaluation produces readable misconceptions, grounded
  repair, and pending retests, and formal mastery rejects unverified or
  unsupported results.
- Leaf 18.5: completed on 2026-07-15. SQLite v21 stores auditable
  programming review actions; tutor and four-dimensional exercise weaknesses
  now close into low-mastery prerequisites, verified cited questions, and
  verified retests. The review screen exposes the weakness, prerequisite,
  citations, and next action, and a fixed official-document plus source-code
  fixture reproduces the complete Branch 18 learning loop.

### Branch 19: Correctness and Evaluation

Status: completed on 2026-07-15. Leaves 19.1 through 19.5 established the fixed
regression baseline, deterministic evidence ranking, claim-level citation
coverage, auditable persistence, evidence-insufficiency refusal gates, secure
provider-scoped credentials, Chat/Responses routing, a five-task provider/model
acceptance matrix, and an approval gate for formal learning calls. The complete
Android debug App builds and passes APK structure, ABI, package-metadata, and
v2-signature verification. The closure fixture measures Recall@1 1.0, MRR 1.0,
citation coverage 1.0, unsupported-claim rate 0.0, and refusal accuracy 1.0
across retrieval and all four grounded learning surfaces. Android acceptance
shows distinct grounded, partial, and refused states, inspectable ranking
reasons, and citation navigation to the highlighted source chunk. Production
keys remain deferred until a profile passes inside the App's normal client
channel. See `docs/correctness-golden-path.md`.

- Rank sources by trust and relevance.
- Measure citation coverage and unsupported-claim rate.
- Add fixed regression datasets for retrieval, answers, and interview feedback.
- Refuse or downgrade answers when evidence is insufficient.
- Add a provider/model acceptance matrix for structured JSON, coding, Chinese,
  context limits, and protocol support before a paid production key is used.
- Replace stale hard-coded model presets with capability-aware configuration;
  keep Chat Completions compatibility, add Responses API only where required,
  and move API keys out of plain `SharedPreferences` before production use.

### Branch 20: Unified Knowledge-Base Learning Agent

Status: complete. Leaves 20.1 through 20.6 were completed and Branch 20 was
closed on 2026-07-16.

- Use one planner and memory model for project and programming knowledge.
- Let retrieval, interview, tutor, practice, reflection, and scheduling share
  the same source-grounding contract.
- Leaf 20.1: make project, programming, and mixed interview knowledge scopes an
  explicit routing contract so a goal cannot silently select content from the
  wrong domain. Completed on 2026-07-15 without a database or checkpoint format
  change.
- Leaf 20.2: represent verified questions and verified programming exercises as
  one typed practice target selected and executed by the same planner.
  Completed on 2026-07-15 with additive version-1 checkpoint compatibility and
  no database schema change.
- Leaf 20.3: share one grounded-context contract across knowledge answers,
  tutoring, interviews, and exercise evaluation. Completed on 2026-07-15 with
  one deterministic context selector, quote-boundary gate, surface validation,
  and no database schema change.
- Leaf 20.4: expose one target-level memory timeline for answer, tutor,
  interview, exercise, reflection, and review records. Completed on 2026-07-15
  as a non-persistent read model over the existing schema, with legacy summary
  and citation-based target compatibility.
- Leaf 20.5: choose the next action deterministically from open follow-ups,
  evidence gaps, weak prerequisites, and due review work, with traceable reasons.
  Completed on 2026-07-15 with a fixed seven-level priority, stable tie-breaks,
  persisted candidate snapshots, original-plan checkpoint recovery, explicit
  blockers, and exact pending-programming-exercise verification routing.
- Leaf 20.6: close the branch with one Agent workspace, a fixed unified learning
  golden path, and Android acceptance. Completed on 2026-07-16 with one
  plan-first workspace, deterministic tool targets, a source-grounded closure
  fixture, three-scope Android acceptance, exact validation-data cleanup, and a
  clean cold-start check.

### Branch 21: Private Alpha Productization

Status: in progress. Leaves 21.1 through 21.5 were completed on 2026-07-16;
Leaf 21.6a readiness is implemented and the real Leaf 21.6 cohort is pending.

Branch outcome: ten interview-preparation developers can install Anchor Learning, reach a
first source-grounded learning turn, inspect a project interview outcome, export
or delete their data, and provide redacted feedback without developer help.

- Leaf 21.1: define the product promise, alpha persona, first-run contract,
  immutable local event model, metric hypotheses, release gate, and source-backed
  product research. Completed on 2026-07-16. The provider gate now has bounded
  per-case and whole-run timeouts; no newly supplied relay passed the five-task
  App matrix, so Anchor Learning currently has no approved default model profile.
- Leaf 21.2: implement a resumable, goal-led first run that reuses secure model
  setup, local project import, coverage review, and the unified Agent workspace.
  Completed on 2026-07-16 with a versioned orchestration record, legacy-user
  bootstrap, model-derived readiness, model-free local material persistence,
  pre-existing-source review transactions, Agent completion handoff, outcome
  preview, boundary-resume tests, and Android cold-start acceptance.
- Leaf 21.3: add schema-versioned local product events, privacy controls,
  redacted diagnostics, support-bundle export, and scoped data deletion.
  Completed on 2026-07-16 with schema v23 immutable events, allowlisted
  properties, local consent settings, event/support export, redaction, scoped
  deletion, anonymous-install rotation, fixed golden-path tests, and Android
  migration/export/deletion acceptance.
- Leaf 21.4: build the living project interview outcome from verified evidence,
  actual attempts, weak dimensions, open follow-ups, and scheduled review.
  Completed on 2026-07-16 with one shared deterministic read model, fixed
  four-state readiness rules, claim-level citation and quote validation,
  stable strongest-evidence selection, expandable outcome UI,
  Markdown/plain-text locator export, aggregate-only outcome events, first-run
  provider reuse, 206 passing tests, clean analysis, and Android four-state plus
  DocumentsUI export acceptance with exact database restoration.
- Leaf 21.5: close reliability and release controls for backup, recovery,
  accessibility, supported devices, versioning, and reproducible alpha checks.
  Completed on 2026-07-16 with SQLite snapshot/validation/migration/rollback,
  backup-before-delete, restore UX, shared provider refresh, version/about
  boundaries, large-text semantics, a source-backed release checklist, 215
  passing tests, and a complete Android Tier A export-delete-restore exercise.
- Leaf 21.6a: implement the cohort feedback and measurement path without
  claiming cohort results. Completed on 2026-07-16 with four feedback entry
  surfaces, explicit export-scope preview, opt-in redacted diagnostics,
  save-confirmed aggregate-only feedback events, overlap-safe metrics
  aggregation, an operator CLI, runbook, participant guide, report template,
  a fixed CLI fixture, 224 passing tests, clean error/warning analysis, and a
  complete Android build/install/feedback-save/feedback-cancel exercise with
  byte-for-byte database restoration.
- Leaf 21.6: run the ten-user private alpha, report activation, learning,
  retention, and reliability results, and make an evidence-linked go/no-go
  decision for the next branch. The anonymous recruitment register, per-phase
  session worksheet, issue log, decision log, and final evidence index are
  ready. Launch remains `HOLD` until one exact model profile passes the App
  matrix `5/5` and an Arm64 physical device passes the release smoke.

Remote graph execution, server-side idempotency, cloud sync, embeddings,
multi-user state, and multi-agent orchestration remain conditional tracks after
the alpha. They require the measured triggers in
`docs/private-alpha-product-contract.md`; they are not Branch 21 prerequisites.

## Trellis Guardrails

- A branch should contain 3-8 leaves and never exceed 10 without replanning.
- Every branch must end in a demonstrable user outcome.
- Infrastructure work requires a named user-flow blocker.
- Target effort split: 60% user workflow, 20% correctness/evaluation, 20%
  infrastructure.
- A leaf is complete only after applicable formatting, analysis, tests,
  migration checks, and source-backed documentation.
- Non-blocking polish moves to backlog instead of extending a branch forever.
- Interview study material follows verified implementation; it does not lead it.

## Explicitly Deferred

- Additional Branch 14 idempotency or result-cache abstractions.
- Multi-agent orchestration.
- Automatic GitHub cloning before local source ingestion works.
- Vector databases before retrieval evaluation proves FTS/local search is
  insufficient.
- Cloud accounts and synchronization before the local learning loop is stable.
