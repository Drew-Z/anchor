# Duoduo Private Alpha Report

## Decision

- Decision: `GO | CONDITIONAL GO | NO-GO`
- Decision date:
- Alpha owner:
- Release build version:
- APK SHA-256:
- Decision summary:

Do not complete this section until D14 evidence is available. Failed targets
remain failed; do not redefine denominators or activation.

## Cohort

| Field | Value |
| --- | --- |
| Invited | 10 |
| Consented | |
| Withdrew | |
| Completed D0 | |
| Completed D7 | |
| Completed D14 interview | |
| Observed sessions | 5 planned |
| Self-serve sessions | 5 planned |

## Release And Model Evidence

| Item | Result | Evidence locator |
| --- | --- | --- |
| Leaf 21.5 release gate | | |
| Arm64 physical-device smoke | | |
| Candidate channel label | | |
| Exact model and protocol | | |
| App five-task acceptance | | |
| Acceptance run time | | |
| Credential handling reviewed | | |

Do not include API Keys or credential-bearing URLs.

Use evidence IDs from `docs/private-alpha-session-worksheet.md`,
`docs/private-alpha-issue-log.md`, and `docs/private-alpha-decision-log.md`.

## Quantitative Results

Generate the event-derived section with:

```powershell
& 'D:\tools\flutter\bin\dart.bat' run tool\private_alpha_metrics.dart `
  --invited 10 --format markdown <event-exports...>
```

Paste the generated report below without editing its target statuses.

<!-- generated metrics -->

## Manual Metrics

| Metric | Fixed target | Result | Status | Evidence |
| --- | --- | --- | --- | --- |
| Users reporting a more concrete project explanation with implementation locator | >= 6/10 interviewed | | | |
| Crash-free App starts | >= 99% | | | |
| Started imports reaching coverage review without support | >= 90% | | | |
| Selected executable actions opening intended target | >= 90% | | | |
| Feedback/support exports showing included fields | 100% | | | |
| Credential leaks | 0 | | | |

## Participant Outcomes

| Code | D0 activation | Minutes | Observer help | D7 closure | D14 interview | Main blocker | Learning claim supported? |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| A01 | | | | | | | |
| A02 | | | | | | | |
| A03 | | | | | | | |
| A04 | | | | | | | |
| A05 | | | | | | | |
| A06 | | | | | | | |
| A07 | | | | | | | |
| A08 | | | | | | | |
| A09 | | | | | | | |
| A10 | | | | | | | |

## Learning Evidence

For each participant claiming improvement, record one decision they can explain,
the later answer or interview note, and the implementation locator they can
identify. Do not claim causal learning improvement from this uncontrolled
sample.

| Code | Project decision | Baseline gap | Later explanation change | Implementation locator | Confidence |
| --- | --- | --- | --- | --- | --- |
| | | | | | |

## Reliability And Privacy Incidents

| ID | Severity | Build | Phase | Stable code | Reproduced | Recovery | Owner | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| | | | | | | | | |

Confirm separately:

- repository and export credential scans;
- database integrity and backup availability;
- every crash/ANR reproduction status;
- collected-file retention and deletion completion.

## Qualitative Findings

### Repeated Activation Blockers

### Evidence And Trust Findings

### Wrong Or Confusing Next Actions

### Interface And Accessibility Findings

### Requests That Do Not Justify Infrastructure Expansion

## Next-Branch Decision

For every proposed capability, cite measured evidence and the existing trigger:

| Proposal | Repeated evidence | Existing trigger met? | Decision |
| --- | --- | --- | --- |
| More source formats | | Failed imports lead activation blockers | |
| Cloud sync | | Repeated cross-device continuity need | |
| Vector retrieval | | Fixed benchmark fails at actual corpus scale | |
| Remote graph runtime | | Remote concurrency/long-task/recovery need | |
| Multi-agent architecture | | Independent permission/state/parallel benefit cannot fit current contracts | |

## Open Actions

| Action | Severity | Owner | Due | Blocks next release? |
| --- | --- | --- | --- | --- |
| | | | | |

## Evidence Index

| Evidence ID | Type | Participant or aggregate scope | Storage locator | Retention deletion date |
| --- | --- | --- | --- | --- |
| | `session | event export | feedback | support | issue | decision` | | | |
