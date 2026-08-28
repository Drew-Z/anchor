# Anchor Learning Private Alpha Issue Log

## Rules

Keep the working issue log outside the repository. Use participant codes,
stable phases, error codes, aggregate descriptions, and evidence locators only.
Never paste credentials, credential-bearing URLs, source text, private paths,
raw answers, or raw model output.

## Register

| ID | Opened UTC | Severity | Build | Participant code | Phase | Stable code | Reproduction | Owner | Status | Stop condition active? |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| PA-001 | | | | | | | | | | |

Allowed statuses: `new`, `triaging`, `reproduced`, `fixing`, `fixed`,
`verified`, `deferred`, `closed`.

## Issue Record

- ID:
- Severity: `P0 | P1 | P2 | P3`
- Build version and APK SHA-256:
- Participant code:
- Phase and stable error code:
- Expected result:
- Observed result, without private content:
- Minimal reproduction steps:
- Reproduction status and device:
- Recovery offered to participant:
- Data integrity result:
- Credential/privacy review result:
- Owner:
- Fix or decision evidence:
- Verification build and result:
- Final status:

## Severity And Required Action

| Severity | Meaning | Required action |
| --- | --- | --- |
| P0 | Credential exposure, unrecoverable data loss, unsafe source disclosure | Stop the cohort immediately; preserve minimal evidence; notify the alpha and privacy owners |
| P1 | Crash/ANR, repeated import failure, activation impossible, restore failure | Pause invitations; reproduce, fix, rebuild, and rerun the release gate |
| P2 | Workaround exists but success or trust is materially reduced | Assign owner and triage within 24 hours |
| P3 | Polish, wording, or non-blocking request | Record for post-alpha prioritization |

## Stop Decision

Complete this block for every P0, every P1, and any repeated blocker.

- Decision time:
- Decision owner:
- `continue | pause invitations | stop cohort`:
- Trigger:
- Affected participant codes:
- Recovery instructions:
- Build allowed for new sessions:
- Resume criteria:
- Decision log ID:

Two participants encountering the same P1 activation blocker requires a pause,
even if a third participant has a workaround.
