# Duoduo Private Alpha Recruitment Register

## Storage Rule

Create a working copy outside the repository. The repository keeps only this
blank template. Do not record real names, contact details, API Keys, project
names, project paths, employer names, or source text.

Use participant codes:

- `S01-S02`: internal shakedown; never counted in formal metrics.
- `A01-A10`: fixed formal cohort denominator after invitation.

Do not replace a formal participant after seeing an outcome. Record declined or
withdrawn participants in the original row.

## Enrollment Gate

| Gate | Evidence | Owner | Status |
| --- | --- | --- | --- |
| Exact APK passes the release checklist | Build record locator | | `pending` |
| Arm64 physical-device smoke passes | Device record locator | | `pending` |
| Exact model profile passes App matrix `5/5` | Acceptance record locator | | `pending` |
| Participant guide is frozen for the cohort | Guide revision/date | | `pending` |
| Retention and deletion date is declared | Operations record locator | | `pending` |

No invitation may move to `invited` while any gate is pending or failed.

## Screener Register

Use `yes`, `no`, or `unknown` for eligibility fields. All five required fields
must be `yes` before invitation.

| Code | Track | Interview in 1-8 weeks | Permitted AI project | Legal processing permission | Wants explanation depth | Android + D7/D14 available | Eligibility | Invitation | Consent | D0 mode | D0 scheduled | D7 scheduled | D14 scheduled | Withdrawal status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| S01 | shakedown | | | | | | | | | observed | | | | |
| S02 | shakedown | | | | | | | | | observed | | | | |
| A01 | formal | | | | | | | | | observed | | | | |
| A02 | formal | | | | | | | | | observed | | | | |
| A03 | formal | | | | | | | | | observed | | | | |
| A04 | formal | | | | | | | | | observed | | | | |
| A05 | formal | | | | | | | | | observed | | | | |
| A06 | formal | | | | | | | | | self-serve | | | | |
| A07 | formal | | | | | | | | | self-serve | | | | |
| A08 | formal | | | | | | | | | self-serve | | | | |
| A09 | formal | | | | | | | | | self-serve | | | | |
| A10 | formal | | | | | | | | | self-serve | | | | |

Allowed invitation states: `not_contacted`, `screening`, `eligible`, `invited`,
`declined`, `withdrawn`, `complete`.

Allowed consent states: `not_requested`, `accepted`, `declined`, `withdrawn`.

## Cohort Freeze

- Freeze time:
- Alpha owner:
- Formal invited denominator:
- APK version and SHA-256:
- Exact provider/model/protocol profile label:
- App acceptance result and time:
- Arm64 device evidence locator:
- Retention deletion date:

The formal invited denominator must remain 10 in metrics and the final report,
including withdrawals.
