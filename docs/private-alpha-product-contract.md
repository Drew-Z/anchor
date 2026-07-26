# Duoduo Private Alpha Product Contract

Status: Leaves 21.1-21.5 completed; Leaf 21.6a readiness implemented; cohort pending

Date: 2026-07-16

## Product Promise

Duoduo helps a developer turn their own project code and authoritative
programming sources into a verifiable learning loop, so they can understand,
practice, and explain the project in an AI application interview.

The private alpha does not promise that generated content is automatically
correct. It promises that formal learning content is inspectable, source-bound,
human-verifiable, and able to refuse unsupported conclusions.

## Alpha Persona

Primary persona:

- Preparing for an AI application development interview in the next 1-8 weeks.
- Has at least one personal, course, freelance, or work-sample project built with
  substantial AI assistance or vibe coding.
- Can provide the local project files and, when needed, official documentation.
- Wants to explain architecture, data flow, implementation, boundaries, and
  trade-offs instead of memorizing a generated script.

The first cohort should exclude users who only want generic exam flashcards,
team knowledge management, autonomous code modification, or cloud collaboration.

## Jobs To Be Done

1. When I prepare for an interview, help me discover what my project actually
   does and point to the implementation that proves it.
2. When I cannot explain a technical choice, teach the missing programming
   concept from authoritative material and test whether I can apply it.
3. When I practice an answer, identify unsupported claims, weak reasoning, and
   missing project detail, then give me one evidence-backed next action.
4. When I return later, show what remains open, what is due for review, and what
   has improved across tutor, interview, and practice sessions.
5. Before the interview, give me a compact, auditable view of the project points
   I can explain, the evidence behind them, and the unresolved weak points.

## Product Principles

- `Source before synthesis`: model output never becomes a source.
- `Participation before reveal`: users attempt an answer before feedback and a
  reference answer are shown.
- `One target, one memory`: tutor, interview, exercise, reflection, and review
  contribute to the same target timeline.
- `One next action`: the product explains the selected action and does not expose
  several competing product centers.
- `Evidence insufficiency is useful`: partial answers and refusals are product
  outcomes, not hidden failures.
- `Local first, explicit sharing`: project data and events remain local unless
  the user explicitly exports a support or research bundle.
- `Measured upgrades`: cloud sync, vector retrieval, remote graph execution, and
  multi-agent roles require the trigger evidence already defined in Branch 21.

## Alpha Golden Path

```text
choose goal
-> configure an accepted model profile when AI work is required
-> import one local project
-> review project coverage and source provenance
-> verify at least one project learning unit
-> open the Agent workspace
-> answer one source-grounded tutor or interview question
-> inspect feedback and cited implementation
-> complete the selected follow-up or practice action
-> see the updated weak point and next review
-> open the project interview outcome
```

Activation is reached only after the first grounded learning turn is persisted.
Import completion or AI generation alone does not count as activation.

## First-Run Contract

The first run should be a short state machine, not a feature tour:

1. `Goal`: choose project interview, project understanding, or programming
   learning. Project interview is the recommended alpha path.
2. `Model readiness`: explain that local data is sent only to the configured
   provider for requested AI tasks; configure or reuse a provider profile and
   run the existing five-task acceptance matrix.
3. `Project import`: select a local directory or ZIP and show excluded files,
   selected files, revision, and locator coverage before generation.
4. `Coverage review`: ask what parts matter for the interview and let the user
   include/exclude areas before saving verified units.
5. `First session`: enter the unified Agent workspace with one selected next
   action and complete one grounded turn.
6. `Outcome preview`: show the first proven project claim, its code evidence,
   the user's current answer quality, and the next action.

The user can pause after every durable boundary. Restarting resumes the same
plan snapshot rather than restarting onboarding.

## Project Interview Outcome

The private-alpha outcome artifact is a living read model, not an AI-generated
document stored as truth. It includes:

- Project goal and selected interview scope.
- Architecture, data flow, implementation, boundary, and trade-off units that
  the user explicitly verified.
- For each unit: confidence/mastery, strongest evidence, latest interview score,
  weak dimensions, open follow-up, and next review.
- The user's latest answer and a concise evidence-grounded reference outline.
- A clear state: `ready`, `needs practice`, `evidence gap`, or `not assessed`.
- Export to Markdown/plain text with source locators and a generated-at time.

It must never label a unit ready solely because the model generated a polished
answer. Readiness requires user participation plus a supported evaluation or a
completed verified practice target.

## Event Model

Events are immutable local product records with this common envelope:

```text
event_id
event_name
schema_version
occurred_at
anonymous_install_id
app_version
platform
flow_id
goal
target_id (optional)
session_id (optional)
properties_json (allowlisted, no source text or user answer by default)
```

Required Alpha events:

| Event | When emitted | Required properties |
| --- | --- | --- |
| `onboarding_started` | Goal selection first appears | entry point |
| `goal_selected` | User confirms a learning goal | goal |
| `model_readiness_viewed` | Model readiness step opens | configured provider/protocol booleans |
| `model_acceptance_completed` | Existing acceptance run ends | passed, failure category, case count, latency bucket; never key or raw response |
| `project_import_started` | User chooses import path | directory/zip/tree type |
| `project_scan_completed` | Safe scan finishes | selected, excluded, total byte buckets, duration bucket |
| `project_import_failed` | Import cannot proceed | stable failure code, phase |
| `coverage_review_completed` | User confirms source coverage | included/excluded counts, locator coverage |
| `verified_content_saved` | Source-grounded review transaction commits | source, point, question, exercise counts |
| `agent_workspace_viewed` | Unified workspace becomes visible | goal, scope, next-action type, blocker code |
| `grounded_turn_completed` | Tutor/interview/practice evaluation persists | surface, disposition, citation count, duration bucket |
| `follow_up_completed` | Selected next action closes | action type, target type |
| `review_scheduled` | A durable review action is created | target type, due bucket |
| `outcome_viewed` | Project interview outcome opens | ready/weak/gap/unassessed counts |
| `outcome_exported` | User exports outcome | format, included citation count |
| `feedback_submitted` | User submits alpha feedback | category, severity, consent-to-attach-diagnostics |
| `support_bundle_exported` | User explicitly exports diagnostics | included sections, redaction version |
| `data_deleted` | User confirms local deletion | data scopes, result |

No event contains API keys, source bodies, file contents, raw user answers, raw
model output, absolute private paths, or URLs with query parameters. File paths
used for product measurement are reduced to extension/category/count data.

## Alpha Metrics

The metric groups borrow the HEART goal-to-signal-to-metric method. The numeric
targets below are Duoduo hypotheses to validate with the first cohort.

### North Star

`Weekly grounded learning closures`: distinct users who complete a grounded turn
and then complete or schedule its deterministic next action in the same week.

This measures a learning closure rather than content generation or chat volume.

### Activation

- `Time to first grounded turn`: median <= 15 minutes among users who begin
  project import; investigate every session over 30 minutes.
- `Import-to-activation conversion`: >= 60% in a cohort of at least 10 people.
- `Evidence coverage at activation`: 100% of formal claims in the first turn
  pass the existing claim gate or appear as partial/refused.

### Engagement And Retention

- At least 50% of activated users complete a second grounded closure within
  seven days.
- At least 30% of invited users independently return in week two.
- Track tutor/interview/practice mix, but do not optimize raw session count.

### Task Success

- >= 90% of started local-project imports reach coverage review without support.
- >= 90% of selected executable next actions open the intended target.
- >= 95% of persisted grounded turns expose at least one valid citation when
  their disposition is `grounded`.
- 100% of evidence-insufficient formal tasks become partial/refused or a visible
  blocker; none silently proceed as grounded.

### Learning Outcome

- Each activated user completes one baseline project answer and one later answer
  for the same target after tutor/practice/review.
- The alpha report shows per-dimension score change and evidence coverage; it
  does not claim causal learning improvement from a small uncontrolled sample.
- Product success requires at least 6 of 10 interviewed alpha users to report
  that they can explain one project decision more concretely and point to its
  implementation after using Duoduo.

### Reliability And Trust

- Zero credential leakage in repository, event records, support bundles, or
  exported outcomes.
- Crash-free app starts >= 99% during alpha; every crash or ANR receives a
  reproducible issue or explicit non-reproducible status.
- Database migrations preserve an exportable backup and pass integrity checks.
- 100% of feedback/support exports show the user what will be included.

## Alpha Feedback Contract

The app should provide a small feedback action from onboarding, Agent workspace,
outcome view, and visible error states. Feedback categories are:

- Could not import or configure.
- Source/evidence is wrong or missing.
- Explanation or evaluation is unhelpful.
- Next action is wrong or confusing.
- Interface or accessibility problem.
- Feature request.

The default export contains category, severity, current screen, app/schema
version, the user's explicit description, and stable error codes. Diagnostics
are off by default and require separate explicit consent. The preview states
the exact export scope before DocumentsUI opens. Raw source text, API keys,
model prompts/responses, and private absolute paths are never attached.

The local `feedback_submitted` event is recorded only after DocumentsUI reports
a saved export. It contains category, severity, and diagnostic-consent state,
but never the user's feedback text. Canceling the save records no feedback
event.

The research cadence for the first 10 users is:

1. Observe five first-run sessions before expanding scope.
2. Interview each activated user after the first outcome view.
3. Review event funnels and failures weekly.
4. Change one major onboarding or learning assumption per iteration.
5. Keep a decision log linking each product change to evidence or user findings.

## Private Alpha Release Gate

All items are required unless explicitly deferred with an owner and rationale:

- One supported Android installation path and a documented version number.
- Goal-led first run reaches the existing local import and model-acceptance flows.
- Pause/resume works across all onboarding durable boundaries.
- Project interview outcome accurately reads existing verified data and memory.
- Required event records are local, schema-versioned, redacted, and exportable.
- Feedback and support-bundle export are explicit and redacted.
- User can export the project interview outcome and delete local learning data.
- Fixed unit/widget/golden-path tests pass; Android build, install, cold start,
  database integrity, credential scan, and screenshot checks pass.
- Known limitations state that AI may make mistakes, formal content requires
  evidence, custom relay compatibility is empirical, and backups are the user's
  responsibility until cloud sync exists.

## Trellis Productization Sequence

### Leaf 21.1: Product contract and alpha acceptance matrix

Outputs are this contract, the source-backed research, event definitions, metric
hypotheses, and the release gate. The implementation hardening in this leaf is
limited to bounded model-acceptance execution and debug-only relay diagnostics.

Completed on 2026-07-16. No tested public relay currently satisfies the five
fixed App tasks, so the alpha has no approved default model profile. Release
requires at least one user-owned credential or controlled proxy profile to pass
all five tasks through the normal App client. A ping, model list, external poem,
or one successful task never substitutes for this gate.

### Leaf 21.2: Goal-led first run

- Implement the resumable first-run state machine.
- Reuse secure provider setup, model acceptance, local project import, coverage
  review, and unified Agent workspace.
- Acceptance: a clean install reaches a persisted grounded turn without hidden
  setup or developer intervention.

Completed on 2026-07-16. The six-step flow persists only versioned orchestration
metadata while deriving model acceptance, project evidence, verified content,
and completed sessions from their existing stores. Project source and chunks can
be saved and inspected without a model; AI generation remains visibly blocked
until the current provider/model/protocol profile passes the five-task matrix.
Existing local users are marked complete without deleting or rewriting their
data, while an in-progress Agent session continues to use its original durable
checkpoint and plan snapshot.

### Leaf 21.3: Local product events and privacy controls

- Add schema-versioned local events, event inspection/export, consent settings,
  data deletion, and redacted support bundles.
- Acceptance: the golden path produces the exact expected event sequence and no
  forbidden content appears in persisted/exported payloads.

Completed on 2026-07-16. SQLite schema v23 now stores immutable, allowlisted
product events with a schema-versioned envelope and local dedupe key. The App
provides event inspection/export, separate local-event and Agent-summary
consent, redacted support-bundle export, and scoped deletion for learning
history, source-backed content, product events, model configuration/credentials,
and first-run state. API keys, Authorization values, source bodies, answers,
model output, private absolute paths, and URL query parameters are rejected or
redacted. Deleting product-event history rotates the anonymous install ID and
retains only the new `data_deleted` audit event; provider refreshes are scoped
to the deleted data so hidden tabs cannot immediately recreate unrelated
events. `outcome_viewed` and `outcome_exported` are wired by Leaf 21.4;
`feedback_submitted` is wired by Leaf 21.6a.

### Leaf 21.4: Project interview outcome

- Build the living outcome read model, readiness rules, target detail, and
  Markdown/plain-text export.
- Acceptance: readiness is derived from verified evidence and actual attempts,
  and every exported formal statement links to stored source locators.

Completed on 2026-07-16. One deterministic read model now serves the Agent
workspace, the full outcome screen, and first-run outcome preview. The four
states are fixed: `ready`, `needs_practice`, `evidence_gap`, and
`not_assessed`. Ready requires real user participation plus either a fully
grounded four-dimension interview evaluation with every score at least 4/5 or
a qualifying verified practice result; model-generated text and mastery alone
never qualify. Citation scope, verbatim quotes, practice evidence, strongest
evidence ordering, and reference-answer claims are validated deterministically.
Markdown/plain-text exports carry generated time and `[S*]` locators.
`outcome_viewed` and `outcome_exported` persist only aggregate counts, format,
and citation count. Unit, Widget, SQLite, first-run, event-privacy, full test,
analyzer, APK, Android four-state UI, DocumentsUI export, database-integrity,
and exact restore checks pass.

### Leaf 21.5: Reliability and release controls

- Add backup/export before destructive operations, recovery UX, version/about,
  accessibility checks, supported-device matrix, and the alpha checklist.
- Acceptance: migration, cold-start, interruption, deletion, export, and restore
  exercises are reproducible on the selected Android targets.

Completed on 2026-07-16. SQLite backup now uses a validated
`VACUUM INTO` snapshot; restore stages and validates schema 12-23 candidates,
creates a rollback snapshot, reopens through normal migrations, revalidates the
current schema, and rolls back automatically after replacement failures. The
privacy screen supports backup, restore confirmation, and backup-before-delete;
database-backed Riverpod read models refresh after restore. A versioned Private
Alpha about page states supported platforms, backup scope, model requirements,
and current Agent boundaries. Narrow-screen, 200% text-scale, semantic-action,
real SQLite migration, invalid-file, and rollback regressions pass. The
supported-device matrix and reproducible gate are maintained in
`docs/private-alpha-release-checklist.md`; the Tier A Android exercise and exact
database restoration completed this leaf.

### Leaf 21.6a: Cohort readiness implementation

- Add explicit redacted feedback export at onboarding, Agent workspace,
  project outcome, and visible error states.
- Add deterministic local metrics aggregation, an operator CLI, participant
  guidance, an operations runbook, and a fixed report template.
- Acceptance: feedback text exists only in the user-reviewed export; event
  telemetry remains allowlisted; overlapping exports deduplicate; immature
  cohorts remain `insufficient_data`.

Implemented on 2026-07-16. Focused UI regressions pass across all four entry
surfaces, including a 320px viewport at 200% text scale. The full suite has 224
passing tests; Analyzer reports zero errors and warnings with 34 existing info
lints. The metrics CLI was exercised against a fixed one-participant export and
correctly calculated factual counts while retaining `insufficient_data` for all
five formal targets. The fresh Android candidate built successfully, installed
over existing data, opened the feedback flow, preserved zero feedback events
after a canceled save, and recorded one aggregate-only event after a confirmed
save. The exported JSON contained the explicit test description and opted-in
redacted diagnostics. The original device database was then restored
byte-for-byte and the App stopped.

### Leaf 21.6: Ten-user private alpha

- Run the cohort, review metrics and interviews, close blocking findings, and
  record go/no-go decisions for the next branch.
- Acceptance: all release gates pass and the activation, learning, reliability,
  and retention results are reported without redefining failed targets.

The operator pack is ready: anonymous recruitment and consent register,
per-phase session worksheet, severity-based issue log, single-assumption
decision log, runbook, participant guide, and final evidence index. Current
launch status is `HOLD` until one exact model profile passes `5/5` in the App and
an Arm64 physical device completes the release smoke. No formal cohort evidence
exists yet.

## Conditional Tracks After Alpha

- Add more source formats only when failed imports are a leading activation
  blocker; prioritize Markdown/HTML/PDF separately, not as one parser project.
- Add cloud sync only when cross-device continuity is a repeated user need.
- Add vector retrieval only when the fixed retrieval benchmark fails at actual
  corpus scale.
- Add remote graph execution only when tools need remote concurrency,
  long-running work, or cross-process recovery.
- Add multi-agent orchestration only when independent permissions, isolated
  state ownership, or measured parallel work cannot fit the current contracts.
- Evaluate payment only after repeat use and outcome value are demonstrated.
