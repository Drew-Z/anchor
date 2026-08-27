# Private Alpha External Evidence Handoff

This checklist is the shortest path from the current technical `HOLD` to a
readiness evaluation. It contains no release evidence itself. Filled records,
credentials, names, contact details, source files, answers, and model output
must remain in the access-controlled operations directory outside this
repository.

## Current Bound Identity

- Product: `Anchor Learning / 锚学`
- Candidate: `1.0.0+2005`
- Arm64 APK SHA-256:
  `74dcfb95cd9c123b51d9b35678ffd0153d23654bf6a5597de1070880d667207b`
- Current release-day profile fingerprint:
  `a8cfa8bca5eb59e87a45da8e63dd60244493a5392d451a4c15c7db8206ece4c4`
- Current technical credential scope: `participantOwned`
- Readiness status: `HOLD`
- Current blocker: `cohort_pending`

## 1. Controlled Credential

Status: completed through opaque reference `CRED-PRIMARY-2005` on
`2026-08-26`. The external record is access-restricted and the repository
contains no API key.

Create one external credential record for every profile that will be offered
to participants. The record must provide an opaque reference such as
`CRED-PRIMARY-001`; never copy the API key into the readiness JSON or this
repository.

Required non-secret assertions:

- exact profile fingerprint matching the release-day acceptance record;
- scope matching the release-day report; the current governed scope is
  `participantOwned`, while `sharedPublic` is never accepted;
- quota owner and enforceable quota limit;
- revocation capability and revocation owner;
- retention policy and data-handling policy;
- access restrictions and an external record locator owned by the operator.

The release-day five-task report must be rerun with this exact controlled
profile and the exact signed APK if the controlled profile differs from the
current participant-owned technical run. Do not use a ping, model-list result,
or external script as a substitute.

## 2. Data-Processing Owner

Status: completed through opaque reference `OPS-ALPHA-2005` on `2026-08-26`.
The same external governance record assigns `alphaOwner`, `privacyReviewer`,
`reliabilityOwner`, and data-processing responsibility.

Assign the real operational role responsible for provider data handling and
incident response. The repository evidence stores only role codes and an
opaque operations locator, for example `OPS-ALPHA-001`.

The external operator pack must confirm:

- required role codes are assigned;
- access is restricted to the named operators;
- retention and deletion dates are declared;
- incident response and escalation procedure are documented;
- all six repository templates remain unchanged and filled records stay outside
  Git.

Do not enter a fictional person, email, phone number, or placeholder as proof
of assignment.

## 3. Formal Cohort A01-A10

Recruit and freeze exactly ten formal participants. `S01-S02` are shakedown
records and never count toward the denominator. Preserve withdrawals in the
denominator and do not replace participants after observing outcomes.

For each `A01` through `A10`, collect outside the repository:

- eligibility, invitation, and consent state;
- D0, D7, and D14 status;
- whether a persisted grounded turn was completed;
- opaque `EV-*` evidence references;
- exact APK SHA-256, profile fingerprint, and credential scope used.

Freeze the cohort with an opaque `COHORT-*` reference, keep the formal
denominator at `10`, record the ordered decision timeline, and publish an
opaque `REPORT-*` final report reference. A final `CONDITIONAL GO` or `NO-GO`
remains a readiness blocker; only a final `GO` can clear the cohort gate.

## Final Validation

After the formal cohort record exists:

1. Update only `build/validation/private-alpha-readiness.json` with anonymous
   bindings and opaque locators.
2. Keep every filled study artifact outside the repository and run the privacy
   scan over the evidence paths.
3. Run:

   ```powershell
   & dart.bat run tool\private_alpha_readiness.dart `
     --evidence build\validation\private-alpha-readiness.json `
     --format json
   ```

4. Treat `GO` as valid only when the evaluator returns no blockers and the
   evidence is bound to the exact APK/profile identity above.

Recruitment may now begin under the operations runbook. Keep readiness at
`HOLD` until the formal D0/D7/D14 cohort record and final decision exist.
