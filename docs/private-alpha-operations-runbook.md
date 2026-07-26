# Duoduo Private Alpha Operations Runbook

## Purpose

This runbook executes Leaf 21.6 without changing the targets defined in
`docs/private-alpha-product-contract.md`. Internal shakedown participants do not
count toward the formal ten-user cohort.

Formal cohort work must not begin until every entry gate below has an owner and
recorded evidence.

Current launch status on 2026-07-17: `HOLD FOR CONTROLLED CREDENTIAL`.

- Implementation and Tier A emulator acceptance are complete.
- A development-only Grok primary profile using Responses and `grok-4.5` passed
  the App matrix at `5/5`, completed the real project-generation flow, and kept
  its acceptance record after database restore.
- Arm64 physical install, cold start, process, App-log, first-screen, local
  project import, feedback export, model acceptance, onboarding, database backup,
  and database restore checks pass.
- The current credential is a shared public relay. Formal invitations must not be
  sent until a controlled or participant-owned exact profile passes the same
  `5/5` check and has a named data-handling owner.

## Roles

| Role | Responsibility |
| --- | --- |
| Alpha owner | Release decision, participant scheduling, stop decisions, final report |
| Session observer | Observe the first five sessions without leading the participant |
| Reliability owner | Triage crashes, ANRs, database, import, restore, and model failures |
| Privacy reviewer | Review every requested feedback/support export and deletion request |

One person may hold several roles, but each session record must name the active
owner and observer.

## Entry Gate

- Leaf 21.5 release checklist remains green for the exact APK being distributed.
- APK version, byte size, SHA-256, package, signing status, and supported Android
  range are recorded.
- At least one Arm64 physical device completes install, cold start, model
  acceptance, project import, feedback export, backup, and restore smoke.
- The feedback action is visible from first run, Agent workspace, project
  interview outcome, and reusable error states.
- Canceling feedback export records no `feedback_submitted` event.
- Diagnostic attachment is off by default and requires explicit consent.
- Recruitment register, participant guide, session worksheet, issue log,
  decision log, and report template are ready before invitations are sent.

## Operator Files

Keep blank templates in the repository and filled study records outside it:

| Artifact | Repository template |
| --- | --- |
| Recruitment and consent register | `docs/private-alpha-recruitment-register.md` |
| Participant instructions | `docs/private-alpha-participant-guide.md` |
| Per-phase session record | `docs/private-alpha-session-worksheet.md` |
| Reliability/privacy issue register | `docs/private-alpha-issue-log.md` |
| Product and stop decisions | `docs/private-alpha-decision-log.md` |
| Final D14 report | `docs/private-alpha-report-template.md` |

The working study directory must be outside the repository, organized by
participant code, access-limited to the named operators, and deleted on the
declared retention date.

Initialize the release-control draft with the procedure in
docs/private-alpha-readiness-evidence.md. Keep generated and filled readiness
files under ignored build/ or in the external operations directory; never
commit participant evidence or credentials. Validate the final file with
tool/private_alpha_readiness.dart before changing invitation status.
## Candidate Model Gate

Use `Grok 4.5 通道（主）` as the first candidate and `Mimo 通道（备）` as the
fallback candidate. These are isolated configuration slots, not embedded relay
definitions: each starts without an endpoint, model, or credential. The labels
set the operator's evaluation order only; the App does not automatically fail
over between them.

Configure and approve the two channels separately. Neither channel is
considered stable or approved from anecdotal availability, and a `5/5` report
for one channel does not approve the other.

For every exact provider, endpoint, protocol, and model combination:

1. Select the intended named profile, then enter its endpoint, model, protocol,
   and credential only through the App settings and secure-storage flow.
2. Run the App five-task matrix: structured JSON, Chinese seven-character poem,
   Dart programming, claim-to-citation binding, and evidence-insufficient
   refusal.
3. Require `5/5` in one completed run. A model list, ping, external script, or
   partial run does not count.
4. Record channel label, model, protocol, run time, passed count, latency bucket,
   and failure category. Do not record the API Key or a credential-bearing URL.
5. Repeat the acceptance check on the release day and after any provider,
   endpoint, protocol, or model change. If both primary and fallback will be
   offered to participants, both require their own current `5/5` report.

Shared public credentials are unsuitable for the formal cohort because quota,
ownership, retention, and revocation cannot be controlled. Prefer participant-
owned credentials or a controlled proxy with an explicit data-handling policy.

## Recruitment Screener

Recruit 12 people: two internal shakedown participants and ten formal alpha
participants. The formal cohort should answer yes to all required questions:

1. Is an AI application development interview expected within 1-8 weeks?
2. Is there a local personal, course, freelance, or work-sample project built
   with substantial AI assistance or vibe coding?
3. Can the participant legally provide the selected local files to the App and
   configured model provider?
4. Does the participant want to explain architecture, data flow, implementation,
   boundaries, and trade-offs rather than memorize generated answers?
5. Can the participant use a supported Android device and return for D7 and D14
   follow-up?

Exclude people seeking only generic flashcards, autonomous code modification,
team knowledge management, or cloud collaboration.

Assign participant codes `A01` through `A10`. Real names, API Keys, project
paths, and source text must not appear in the cohort worksheet or issue titles.

## Consent Script

Before installation, state the following in plain language:

- Project and learning data are local SQLite data unless the participant starts
  an AI task or explicitly exports a file.
- Requested AI task content is sent to the participant's configured provider.
- Product events remain local until the participant exports them.
- Feedback details are exported only after the system save dialog completes.
- Diagnostics are optional, redacted, and require a separate checkbox.
- Participation may stop at any time; local learning data and events can be
  exported or deleted from the privacy screen.
- Private source files, employer-confidential code, and credentials must not be
  used in the study.

Record consent as `accepted`, `declined`, or `withdrawn`; do not record a legal
name inside App exports.

## Study Schedule

| Phase | Participants | Mode | Required evidence |
| --- | --- | --- | --- |
| Shakedown | 2, not counted | Observed | Installation and flow defects only |
| D0 observed | A01-A05 | Observer present | Timing, interventions, blockers, event export |
| D0 self-serve | A06-A10 | Guide only | Independent completion or stable blocker |
| D7 | Activated users | Independent return | Second grounded closure or reason absent |
| D14 | A01-A10 | Interview | Learning claim, trust, reliability, continued-use decision |

Do not replace participants after seeing outcomes. A withdrawal remains in the
denominator as invited and is documented as withdrawn.

## D0 Task Script

The observer reads the task, then stays silent unless the participant is blocked
for five minutes or asks to stop.

1. Install and open the recorded APK.
2. Select project interview preparation.
3. Configure an approved model profile and confirm the visible `5/5` report.
4. Import one permitted local project directory or ZIP.
5. Review selected/excluded files and locator coverage.
6. Verify at least one source-grounded learning unit. When several generated
   questions are pending, use bulk verification only after checking the question,
   answer, explanation, and that the cited local evidence is readable.
7. Open the Agent workspace and answer one tutor or interview question.
8. Inspect feedback and cited implementation.
9. Complete or schedule the selected deterministic next action.
10. Open the project interview outcome.
11. Export local product events.
12. Submit one feedback export, with diagnostics off unless the participant
    independently chooses to attach them.

Import completion or generated content alone does not count as activation.
Activation requires a persisted `grounded_turn_completed` event.

## Observation Rules

- Record the first point of hesitation, not every click.
- Record every observer intervention with time and reason.
- Never enter a participant credential or choose project files for them.
- Do not explain hidden product architecture during the task.
- A visible partial/refused answer is a valid product outcome when evidence is
  insufficient.
- Capture screenshots only with explicit consent and after checking for private
  paths, source text, answers, and credentials.

## Issue Severity

| Severity | Definition | Action |
| --- | --- | --- |
| P0 | Credential exposure, unrecoverable data loss, unsafe source disclosure | Stop cohort immediately |
| P1 | Crash/ANR, repeated import failure, activation impossible, restore failure | Pause new invitations; fix and reissue build |
| P2 | Workaround exists but task success or trust is materially reduced | Triage within 24 hours |
| P3 | Polish, wording, or non-blocking feature request | Record for post-alpha backlog |

Every P0/P1 needs build identity, participant code, stable phase/error code,
reproduction status, recovery action, and owner. Do not attach credentials or
source bodies.

## Export Collection

Request only the minimum evidence needed:

- Product event export after D0 and D7.
- Feedback JSON when the participant chooses to submit feedback.
- Support bundle only for a reproducible issue and only with explicit consent.
- Project interview outcome only when the participant wants to discuss its
  usefulness; it is not required for metric aggregation.

Store files under a participant-code directory outside the repository. Do not
rename files with real names or project names. Delete collected files after the
retention period stated to participants.

## Metrics Command

From the repository root:

```powershell
& 'D:\tools\flutter\bin\dart.bat' run tool\private_alpha_metrics.dart `
  --invited 10 `
  --format markdown `
  <event-export-1.json> <event-export-2.json>
```

The tool deduplicates overlapping exports by `event_id`. It reports
`insufficient_data` until the formal cohort and observation window are large
enough. Interview learning claims, crash-free starts, support interventions, and
withdrawals remain manual report fields.

## Stop Conditions

Stop or pause the cohort when any condition occurs:

- Any P0 issue.
- The approved model profile no longer passes `5/5` for two consecutive checks.
- Two participants encounter the same P1 activation blocker.
- A backup or restore operation changes data outside its documented scope.
- A requested export contains a credential, private absolute path, source body,
  raw answer, or raw model output outside an explicitly consented artifact.

Do not weaken a target, remove a failed participant, or change the activation
definition to continue the study.

