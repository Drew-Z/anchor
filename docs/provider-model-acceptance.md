# Provider and Model Acceptance

Status: Leaf 21.6b is complete. Fixed-matrix acceptance, timeout hardening, and
isolated named candidate profiles are implemented as of 2026-07-16.

## Purpose

Anchor Learning does not treat a successful ping, a model-list response, or a familiar
model name as proof that a provider is suitable for formal learning tasks. A
provider/model/protocol combination becomes an approved learning profile only
after the same fixed task set passes inside the App's normal HTTP stack.

The approval identity is:

```text
provider id + sanitized base URL + requested model + API protocol
```

Changing any field requires a new acceptance run. A later failed run replaces
the previous result for the same identity, so a stale success cannot hide a
regression.

## Fixed Matrix

| Case | Contract | Deterministic check |
| --- | --- | --- |
| Structured JSON | Return one exact binary-search object | JSON parses, has exactly three expected fields and values |
| Chinese | Generate an original seven-character quatrain | JSON has a title and four lines with exactly seven Han characters each |
| Dart coding | Implement `sumEven` with two examples | Function name, even check, accumulation, and both expected examples are present |
| Claim grounding | Answer only from evidence `S1` | Every claim cites `S1` and its quote occurs verbatim in the supplied evidence |
| Evidence refusal | Answer a Python question from unrelated Dart evidence | Response is exactly a refusal with no claims |

All five cases are required. The report also records the requested and resolved
model names, protocol, per-case latency, provider-reported token usage,
estimated official OpenAI cost when a verified direct-API price is available,
and a structured failure category.

Blocking provider failures stop later cases to avoid wasting quota. Examples
include missing or invalid credentials, client restriction, unsupported model,
unsupported protocol, rate limiting, network failure, and upstream outage.

Each ordinary case has a 60-second runner timeout. The Dart coding case has a
120-second budget because reasoning-capable models can take longer to return a
complete function and both fixed examples. The complete matrix still has a
four-minute budget. A timeout is persisted as an actionable failed case and later
cases are skipped. Provider and unknown failures retain the actual elapsed request
time so the UI does not report a misleading zero-second failure.

A provider dashboard can still show a completed request after the App reports a
timeout. The runner deadline applies to when the App receives a usable complete
response, while a gateway may continue upstream generation after the local Future
has timed out. Such a late completion can still be billed by the provider, but it
does not satisfy the latency contract and is not counted as a passed case.

## Security Boundary

- API keys are provider-scoped and stored through `flutter_secure_storage`.
- Base URL, requested model, and protocol are stored under a provider-scoped
  `ai_profile.<provider>.*` namespace; they are not shared between profiles.
- Settings never read a saved key back into the text field.
- Acceptance reports contain no credential field.
- Saved endpoints remove user info, query parameters, and fragments before
  persistence, so a key embedded in a URL is not retained.
- Custom relay pricing is not inferred from official OpenAI prices.
- The App does not spoof Codex or another client identity to bypass a gateway.
- Android cleartext traffic is enabled only in the debug manifest for explicit
  development-node verification. Release builds keep the platform HTTPS default.

## Named Candidate Profiles

Anchor Learning exposes two durable operator-facing candidate slots:

- `custom_grok_primary`: `Grok 4.5 通道（主）`
- `custom_mimo_fallback`: `Mimo 通道（备）`

Each slot owns its base URL, requested model, API protocol, secure credential,
and acceptance-report identity. Switching the settings selection restores that
slot without copying or overwriting another slot. The generic `custom` provider
remains available for unrelated development configurations.

Both named slots start with Responses selected and with no endpoint, model, or
credential embedded in the App. The primary/fallback labels express an operator
preference only: Anchor Learning does not automatically retry, route, or fail over from
one profile to the other. A profile name, model name, or another profile's
`5/5` report never grants approval.

## Public Relay Observation

Historic user-provided public development credentials were evaluated only as
development candidates. They are not embedded in either named profile, are not
assumed to remain usable, and are not a production default.

External probes observed the following model names across the supplied relays:

```text
codex-auto-review
gpt-5.5
gpt-5.5-openai-compact
gpt-5.6-terra
gpt-5.6-luna
gpt-5.6-sol
MiniMax-M3
```

Real poem and small JSON tasks sometimes succeeded externally for `gpt-5.5` or
`gpt-5.6-sol`. Those results did not become App approvals:

- One HTTPS relay returned only `gpt-5.6-sol` from its model route but rejected
  normal Chat and Responses requests with HTTP 403.
- A second HTTPS relay completed earlier external Chat and Responses tasks, but
  the later App Chat matrix failed on the first case with an invalid-credential
  response and the host retest was rate limited. Its earlier pre-timeout
  Responses App run also failed to settle inside the automation window.
- The supplied HTTP development node previously completed one external poem,
  but its App `gpt-5.5 + Chat` matrix timed out on structured JSON and the host
  structured-task retest returned HTTP 503. Its model-list route was also not a
  reliable readiness signal. A later real-task retest returned an empty HTTP
  503 for `gpt-5.6-sol` through both Responses and Chat, for `gpt-5.5` through
  Chat, and for the authenticated model directory. No profile or credential was
  persisted from that retest.
- A later HTTP relay returned an empty HTTP 503 for the same real Chinese-poem
  task with `gpt-5.6-sol` through both Responses and Chat, and with `gpt-5.5`
  through Chat. The authenticated model directory returned the same empty 503.
  Requests used the normal development-client identity, and no endpoint,
  credential, profile, or response body was persisted.
- A fifth IP-address-only candidate did not complete the same poem task. Most
  requests sent to the supplied HTTP scheme returned a protocol error stating
  that plain HTTP reached an HTTPS port, while one `gpt-5.5` Chat request
  returned an empty HTTP 503. A temporary HTTPS diagnostic against the same
  IP and port then returned HTTP 403/421, a TLS handshake failure, and finally
  a refused connection, which indicates missing hostname/SNI routing or an
  unstable upstream rather than an App-ready API endpoint. No client identity
  was spoofed and no endpoint, credential, configuration, or response was
  persisted.
- A sixth IP-address-only candidate also failed the real Chinese-poem task.
  Both `gpt-5.6-sol` and `gpt-5.5` Responses requests sent to the supplied HTTP
  scheme returned the explicit protocol error that plain HTTP reached an HTTPS
  port. Retrying the same task over HTTPS with a Codex-style user agent reached
  Cloudflare but was rejected with HTTP 403 before any model output. This
  diagnostic does not satisfy the normal Dart/Dio client gate, and no endpoint,
  credential, configuration, or response was persisted.

The exact `1.0.0+2005` Grok-primary profile has now passed the five-task matrix
on the signed release APK. Anchor Learning still has durable Grok-primary and
Mimo-fallback candidate slots, but the Mimo fallback remains unapproved and no
slot implies an approved default for formal cohort use. Each populated slot must pass all five tasks in the normal
Dart/Dio client without identity spoofing. Approval belongs only to its exact
provider, sanitized endpoint, requested model, and protocol identity.

## Current Device Result

The signed formal-ID candidate `1.0.0+2005` completed the release-day technical
matrix on the physical OnePlus PGP110 after network connectivity was restored.
The App showed `5/5`, `117.3 seconds`, `8,325` tokens, and gateway model
`grok-4.6`. The sanitized artifact-bound record is
`docs/TECHNICAL_MODEL_ACCEPTANCE_2026-08-26_2005.md`. This run used a
participant-owned credential and does not satisfy controlled-credential governance.

On 2026-08-26, the previous Arm64 debug candidate (`1.0.0+2002`, APK SHA-256
`ceb89e37a22df7bb400e5795bbfda694f576a5cd5455f09ce3d3c48d838face4`) completed
the fixed matrix on a physical OnePlus PGP110 (Android 15 / API 35). The App's
normal Chat Completions path used gateway model `grok-4.6` and reported `5/5`
passed in 131.2 seconds with 8,271 total tokens. The five cases were structured
JSON, a Chinese regulated verse, Dart code with two examples, claim/citation
binding, and evidence-insufficient refusal.

This is historical technical-candidate evidence, not evidence for the current
`1.0.0+2005` build or release-day approval: the readiness
gate still requires a controlled credential scope, an assigned data-processing
owner, and the formal evidence record bound to the exact release artifact.

## Official Evidence

- [OpenAI latest model guide](https://developers.openai.com/api/docs/guides/latest-model.md):
  describes the GPT-5.6 `sol`, `terra`, and `luna` roles and recommends
  representative workload evaluation.
- [Migrate to Responses](https://developers.openai.com/api/docs/guides/migrate-to-responses.md):
  recommends Responses for new projects while Chat Completions remains
  supported.
- [Working with evals](https://developers.openai.com/api/docs/guides/evals):
  treats repeatable output criteria and usage capture as core reliability work.
- [OpenAI API pricing](https://developers.openai.com/api/docs/pricing):
  supplies the direct OpenAI standard token rates used by the optional cost
  estimator. Those rates are never applied to a custom relay.

Official pages were fetched with `smart-search fetch` on 2026-07-15. The broad
smart-search model route returned an upstream HTTP 429 during `doctor`, while
the configured official-page fetch capability succeeded; no native web-search
fallback was used.

## Verification

```text
flutter test --no-pub: 229 tests passed
provider/profile focused tests: 18 tests passed
flutter analyze --no-pub --no-fatal-infos: 0 errors, 0 warnings, 34 existing infos
```

Android verification first completed `:flutter_secure_storage:assembleDebug`
with 27 successful tasks and produced `flutter_secure_storage-debug.aar`. The
ordinary Wrapper still could not download Gradle 9.1.0, so the full App used the
cached Gradle 9.4.1 distribution. On Windows, incremental Kotlin compilation was
disabled and Gradle was limited to one in-process worker to avoid the existing
C:/D: cache-path failure.

An offline diagnostic identified Flutter engine Maven metadata as the apparent
Kotlin-task stall. The three already downloaded engine ABI JARs and embedding
artifact were exposed through a temporary, gitignored local Maven mirror under
`build/`; their SHA-1 values matched the Gradle content-addressed cache paths.
With that mirror, `:app:compileDebugKotlin` completed 87 tasks and
`:app:assembleDebug` completed 203 tasks with `BUILD SUCCESSFUL` in 1 minute 42
seconds. The resulting `app-debug.apk` is 165,967,277 bytes with SHA-256
`7dd826113663bbccfd507c12dd9dbd6f38e6d7dccde3a3514f7d691bb0e57720`.

APK inspection found 556 ZIP entries, `classes.dex`, and Flutter native
libraries for `arm64-v8a`, `armeabi-v7a`, and `x86_64`. Android build-tools 37
verified the debug certificate with APK Signature Scheme v2. Package metadata
is `cc.eu.playlab.anchor`, version `1.0.0` (1), min SDK 24, target SDK 36, and
compile SDK 37. AGP built-in Kotlin migration, compile-SDK support-range, and
SDK XML warnings remain non-blocking production-toolchain debt.

The 2026-07-16 goal-led first-run build completed the same 203 Gradle tasks in
32 seconds from the offline cache. That debug APK is 102,480,848 bytes
with SHA-256
`63d9b16dce740b4d8b05dc407ed8a9528730abd81b34f07db2b4a99d920e306c` and a
verified v2 signature. The installed database remains schema version 22 with an
`ok` integrity check. Failed public credentials were cleared through the App;
ordinary preferences contain no sensitive key names, and the repository scan
found no supplied credential values.

The Leaf 21.6b named-profile build completed 203 actionable tasks offline with
`BUILD SUCCESSFUL in 3m 45s`. The APK is 102,987,855 bytes with SHA-256
`73e3e6e88380eb3fa894a999ca6bf60a4d716e423faa6cf26a8eac734f3d924b` and a
verified v2 signature. Android UI and hierarchy evidence confirms that both
named slots default to Responses and contain no built-in endpoint, model, or
credential. Neither slot was saved during smoke testing, their profile-key
counts remained zero, and the pre-test schema-23 database was restored byte for
byte with SHA-256
`65872231a9a9ad7248368d6e760a07c359f2efd43e42ab5623e3df377904a892` and
`integrity_check=ok`.
