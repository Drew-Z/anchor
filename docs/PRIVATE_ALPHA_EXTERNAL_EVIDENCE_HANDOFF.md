# Private Alpha External Evidence Handoff

This checklist is the shortest path from the current technical `GO` to a
readiness evaluation. It contains no release evidence itself. Filled records,
credentials, names, contact details, source files, answers, and model output
must remain in the access-controlled operations directory outside this
repository.

## Current Bound Identity

- Product: `Anchor Learning / 锚学`
- Candidate: `1.0.0+2005`
- Arm64 APK SHA-256:
  `641a1a107c687e4903b3c64a65111c4eeff88804d2cc056374026fafa29c54b3`
- Current release-day profile fingerprints:
  - primary `grok-4.6`: `56632da5ea078a596fa6b941751b9bdfb15dcc0ace860653831f05516055a056`
  - fallback `glm-5.3-flash`: `c8a89bf232de988c8bdd9ded8abaae99c6133d4ddd1af8a7363d475c8db5a32f`
- Current technical credential scope: `participantOwned`
- Readiness status: `GO`
- Current blocker: none; technical readiness evaluator returns `GO`

The 2026-09-15 Windhub model and physical-device reports are the current
identity-bound technical records for candidate `1.0.0+2005`. Re-run both real
checks again if the APK, endpoint, protocol, model, or credential scope changes.

## 1. Controlled Credential

Status: completed through opaque references `CRED-PRIMARY-2005` and
`CRED-FALLBACK-2005` on `2026-09-15`. The external records are access-restricted
and the repository contains no API key.

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

The release-day five-task report must be rerun with the exact controlled
profile and signed APK if either controlled profile changes. Do not use a ping,
model-list result, or external script as a substitute.

## 2. Data-Processing Owner

Status: completed through opaque reference `OPS-ALPHA-2005`; the operator pack
remains unchanged and access-restricted.
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

## 3. Optional Formal Cohort A01-A10

If a research cohort is run, recruit and freeze exactly ten formal participants.
`S01-S02` are shakedown records and never count toward the denominator. Preserve
withdrawals in the denominator and do not replace participants after observing
outcomes. This study is optional and does not control technical release readiness.

For each `A01` through `A10`, collect outside the repository:

- eligibility, invitation, and consent state;
- D0, D7, and D14 status;
- whether a persisted grounded turn was completed;
- opaque `EV-*` evidence references;
- exact APK SHA-256, profile fingerprint, and credential scope used.

Freeze the cohort with an opaque `COHORT-*` reference, keep the formal
denominator at `10`, record the ordered decision timeline, and publish an
opaque `REPORT-*` final report reference. A final `CONDITIONAL GO` or `NO-GO`
does not affect technical readiness; only a real research decision should be
recorded when an optional study is run.

## Final Validation

If an optional cohort record exists:

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

4. Treat `GO` as valid when the technical evaluator returns no blockers and the
   evidence is bound to the exact APK/profile identity above. Cohort evidence is
   not required for that result.

Recruitment may begin only as separately authorized research. Do not fabricate
participant records or treat optional cohort notes as release approval.
