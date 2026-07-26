# Private Alpha Readiness Evidence

## Purpose

The readiness evidence file is an anonymous release-control artifact. It links
one APK identity to automated checks and, only after they exist, physical-device,
credential, operator, release-day model, and formal cohort evidence.

It must never contain API keys, credential-bearing URLs, names, contact details,
private source paths, source text, participant answers, or model output.

## Initialize A Draft

Run the initializer only after an APK and an actual test count exist:

```powershell
& 'D:\tools\flutter\bin\dart.bat' run tool\private_alpha_readiness_init.dart `
  --apk build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk `
  --tests-passed 307 `
  --analyzer-errors 0 `
  --analyzer-warnings 0 `
  --format-passed `
  --diff-check-passed `
  --arm64-only `
  --v2-signed
```

The default output is
`build/validation/private-alpha-readiness.json`. The initializer computes APK
bytes and SHA-256 from the file. It does not create physical-device, credential,
owner, release-day, or cohort evidence, and initializes all five gates as false.

Boolean flags are explicit declarations. Omit a flag when that check has not
actually passed. Never add a flag to make the draft look cleaner.

## Evaluate The Draft

```powershell
& 'D:\tools\flutter\bin\dart.bat' run tool\private_alpha_readiness.dart `
  --evidence build/validation/private-alpha-readiness.json `
  --format json
```

A newly initialized draft must return `HOLD`. Add a conditional evidence object
only after its real gate has passed, then set the matching top-level boolean to
true. Filled cohort and operations records remain outside the repository; the
readiness file stores only approved anonymous codes and opaque locators.

## Schema And Authority

The structural contract is
`schema/private-alpha-readiness-v2.schema.json`, using JSON Schema Draft
2020-12. It provides editor and external-tool validation for required fields,
types, enums, hashes, references, paths, and gate-dependent objects.

The Dart evaluator remains authoritative for rules JSON Schema cannot prove,
including actual APK bytes/SHA-256, repository path containment, template file
hashes/headings, privacy scanning, endpoint canonicalization, profile
fingerprints, freshness, physical-device semantics, fixed cohort identity, and
cross-evidence consistency.

Test fixtures and initialized drafts are not release evidence. A `GO` result is
valid only when every true gate is backed by the real external evidence required
by the release checklist.
