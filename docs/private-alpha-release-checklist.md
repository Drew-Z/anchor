# Duoduo Private Alpha Release Checklist

## Release Identity

- Product: Duoduo / 多多学
- Channel: Private Alpha
- App version: `1.0.0+1`
- Android package: `com.example.dlg_q`
- Database: SQLite `dlg_q.db`, schema `23`
- Distribution: direct debug APK sideload to invited testers only

This is not a production store release. The package identifier and debug signing
must be replaced before public distribution.

## Supported-Device Matrix

| Tier | Target | Status | Required evidence |
| --- | --- | --- | --- |
| A | Android API 36, x86_64 emulator, 1080x2400 / 420 dpi | Release exercise target | Build, install, migration, cold start, backup-delete-restore, export, screenshot, and log scan on every alpha build |
| B | Android API 24-35, Arm64 physical device | Cohort candidate | Run the short device smoke before enrolling that device; record API, ABI, viewport, install result, backup/restore result, and known OEM issue |
| Unsupported | Android API 23 and earlier | Do not install | Current Flutter 3.44 support starts at API 24 |
| Not release-supported | iOS, Windows, macOS, Linux, web | Deferred | Framework support does not imply Duoduo release support; no end-to-end acceptance has been completed |

The fixed Tier A device for Leaf 21.5 is `emulator-5554`, Android API 36,
x86_64, physical size 1080x2400, density 420.

An Arm64 emulator may verify that an Arm64 APK starts, but it does not replace
the Tier B physical-device gate. The physical gate also covers OEM document
pickers, secure storage, lifecycle behavior, input methods, filesystem behavior,
and real-device performance. On an x86_64 Windows host, Arm64 emulation may also
run without the acceleration available to the x86_64 system image.

## Backup Contract

The exported `.db` file includes:

- sources, chunks, knowledge points, questions, and exercises;
- learning sessions, answers/evaluations, attempts, review actions, and Agent
  checkpoints;
- local product events.

It excludes:

- model credentials and secure-storage values;
- provider, endpoint, protocol, model, and acceptance preferences;
- first-run progress and selected goal preferences;
- privacy preferences and anonymous-install preference state.

Accepted restore files must:

- be SQLite files no larger than 512 MB;
- use schema 12 through 23;
- pass `PRAGMA integrity_check`;
- contain the required baseline tables.

Restore stages and validates the candidate, creates an internal rollback
snapshot, replaces the live database, runs normal migrations, and validates the
current schema. Any failure after replacement triggers automatic rollback.

Stable user-facing error codes:

| Code | Meaning | Recovery |
| --- | --- | --- |
| `invalid_file` | Missing, oversized, unreadable, or non-SQLite input | Select an unmodified Duoduo `.db` export |
| `unsupported_schema` | Schema is outside 12-23 | Restore with a compatible app version first, then export again |
| `integrity_failure` | SQLite integrity check failed | Use another backup; do not retry the same damaged file |
| `missing_tables` | Required Duoduo tables are absent | Select a complete database backup, not a partial table export |
| `restore_failure` | Replacement, migration, or final validation failed | Confirm the UI reports automatic rollback; restart and verify current data |

## Automated Gate

Run from the repository root:

```powershell
& 'D:\tools\flutter\bin\dart.bat' format --output=none --set-exit-if-changed lib test tool
& 'D:\tools\flutter\bin\flutter.bat' analyze --no-pub --no-fatal-infos
& 'D:\tools\flutter\bin\flutter.bat' test --no-pub
git diff --check
```

Expected result:

- formatter exits zero without changing files;
- analyzer has zero errors and zero warnings;
- every test passes;
- `git diff --check` reports no whitespace errors.

Evaluate the release decision from explicit, machine-readable evidence:

```powershell
& 'D:\tools\flutter\bin\dart.bat' run tool\private_alpha_readiness.dart `
  --evidence test\fixtures\release\private_alpha_readiness_current.json `
  --format json
```

The command exits `0` only for `GO`, `2` for a valid `HOLD`, and `64` or `66`
for invalid input or an unreadable evidence file. A `GO` requires every field to
be `true`; emulator results, fixture tests, and shared public relay credentials
must not be recorded as physical-device, release-day acceptance, or controlled
credential evidence.

Schema v2 also requires structured automated_gate and android_build objects.
The CLI recomputes the repository-relative APK byte length and SHA-256 before
evaluating readiness. Missing APKs, paths outside the repository, identity
drift, zero tests, analyzer errors/warnings, failed formatting or diff checks,
non-arm64 declarations, and missing v2-signing declarations add explicit
blockers even when the legacy summary booleans are true. The structured evidence
must never contain credentials or credential-bearing URLs.
Schema v2 privacy_scan.paths explicitly lists each release evidence, feedback,
support, or event artifact that must be inspected. Every path must remain inside
the repository root. Findings are deduplicated and expose only a fixed category
plus repository-relative path; matching values, snippets, URL queries, tokens,
and resolved absolute paths are never retained or printed. API-key shapes,
credential headers, credential-bearing URL queries, private absolute paths,
JWTs, sensitive file names, missing/oversized files, and path escapes all block
readiness.
When controlled_credential_available is true, schema v2 must include a
controlled_credential object with exactly one non-secret binding for every
accepted primary or offered fallback profile. Each binding records only an
opaque CRED-* reference, credential scope, exact profile fingerprint, and
declarations for quota ownership/limits, revocation capability/ownership,
retention, and data handling. Shared-public scope, identifying references,
duplicate references, missing controls, profile/scope drift, unoffered bindings,
or the absence of release-day profile evidence block readiness. API keys,
credential-bearing URLs, names, and contact details are forbidden.
When release_day_acceptance_passed is true, schema v2 must include a
release_day_acceptance object. Each offered profile needs one fresh report for
the exact provider, sanitized HTTPS endpoint, protocol, model, profile
fingerprint, and APK SHA-256. The fixed five task IDs must each be passed in the
same run. Reports older than 24 hours, future timestamps, shared-public
credentials, endpoint userinfo/query/fragment, fingerprint drift, cross-APK
evidence, missing primary/fallback reports, or duplicate profile fingerprints
block readiness. The evidence must not include an API key or credential
reference.
When data_processing_owner_assigned is true, schema v2 must include anonymous
operator_pack evidence. It records only role codes, an opaque external
operations-record locator, and declarations for restricted access, retention,
deletion, and incident response; it must not contain names or contact details.
The verifier also requires the six approved blank operator templates, their
required headings, and their frozen SHA-256 values. Missing or changed templates
block readiness, ensuring filled participant records remain outside the
repository.
When cohort_completed is true, schema v2 must include anonymous cohort_evidence.
The formal denominator must remain exactly A01-A10; S01-S02 shakedown records,
replacement participants, duplicate codes, and denominator drift are forbidden.
Each participant records only a fixed track, terminal invitation/consent state,
D0/D7/D14 status, grounded-turn booleans, learning-claim enum, and opaque EV-*
references. The cohort must bind the exact release APK and the complete set of
release-day profile fingerprints, preserve withdrawals in the denominator, and
record an ordered freeze/final-decision timeline plus opaque COHORT-* and
REPORT-* references. A GO, CONDITIONAL GO, or NO-GO decision may close the
study; completion never means the product targets passed. Names, contact
details, credentials, project identifiers, private paths, source text, answers,
and model output are forbidden.
When all external gates are true, readiness also runs one release-consistency
check over the same parsed evidence and one captured evaluation time. The final
cohort decision must be GO; CONDITIONAL GO and NO-GO remain blockers rather than
being converted into release approval. Cohort operator_record_locator must
equal the operator pack external_record_locator. Every formal participant must
record the exact profile fingerprint and credential scope actually used, and
that pair must exist in both release-day acceptance and controlled-credential
bindings. Unrelated but individually well-formed records, profile drift, or
scope drift block readiness without exposing participant codes or record
contents.
When physical_device_passed is true, schema v2 must include
physical_device_evidence containing the executed preflight JSON plus its
completion time. The report must be PASSED, no more than 24 hours old, bound to
the exact release APK SHA-256, and describe a physical Arm64 device on API
24-35. Execution must have been requested and attempted; install, cold start,
and process checks must pass with zero PID-filtered runtime-log matches. READY,
emulator, x86, stale, future, old-APK, or partially executed reports block
readiness.
Review credential-shaped matches without printing secret values into release
notes. Only intentional short fake test values are allowed. Any real key,
Authorization header, private endpoint credential, `.env` content, or secure
storage export blocks the release.

The complete orchestration is implemented by a testable readiness evaluator.
It accepts one decoded evidence object, repository root, and explicit evaluation
time, then runs every parser, filesystem verifier, privacy scan, conditional
external gate, and cross-evidence consistency check before producing one report.
The CLI only reads arguments/files, formats that report, and maps GO/HOLD or
input errors to exit codes. An end-to-end test must build a temporary anonymous
bundle with a real temporary APK identity, clean scan artifact, frozen operator
templates, controlled fake references, release-day profiles, physical report,
and A01-A10 cohort; the complete bundle must reach GO, while changing only the
final decision to NO-GO must produce HOLD. Test fixtures never count as actual
release, device, credential, owner, or participant evidence.
The CLI process contract is covered independently from the evaluator. A real
subprocess must return 0 with parseable JSON for a complete GO bundle, 2 with
JSON or Markdown for a valid HOLD, 64 for argument/schema errors, and 66 for a
missing evidence file. JSON stdout contains only status and blocker codes;
Markdown contains the same bounded information. Neither stdout nor stderr may
echo provider endpoints, model names, credential references, operator record
locators, participant codes, or evidence bodies.
The operator-facing structural contract is
schema/private-alpha-readiness-v2.schema.json (JSON Schema Draft 2020-12).
Create a draft with tool/private_alpha_readiness_init.dart; it requires a real
repository-relative APK and positive test count, computes APK bytes/SHA-256, and
writes only below ignored build/. Format, diff, Arm64, and v2-signing claims
are false unless their explicit command flags are supplied. All five external
gates are always initialized false and no conditional evidence object is
invented. The generated file must evaluate to HOLD before real external evidence
is attached. See docs/private-alpha-readiness-evidence.md.
## Android Build Gate

The reproducible offline build used by this workspace is:

```powershell
Set-Location android
.\gradlew.bat :app:assembleDebug `
  '-Ptarget-platform=android-x64' `
  '-Pkotlin.incremental=false' `
  '-Pkotlin.compiler.execution.strategy=in-process' `
  --offline --no-daemon --max-workers=1
Set-Location ..
```

If Kotlin reports a stale generated cache, remove only the named generated
module cache after verifying its resolved path remains under this repository's
`build` directory. Never clear user source or the whole Gradle home as a first
response.

Record for every build:

- Gradle task count and success status;
- APK byte size and SHA-256;
- APK signature verification result;
- Flutter, Dart, Gradle, Android SDK, compile SDK, target SDK, and ABI.

## Android Install And Cold-Start Gate

Run the read-only preflight before installing on a physical candidate:

```powershell
& 'D:\tools\flutter\bin\dart.bat' run tool\private_alpha_device_preflight.dart `
  --serial <adb-serial> `
  --expected-sha256 <recorded-apk-sha256>
```

`READY` means the selected device is physical Arm64 on API 24-35 and the APK
hash matches. The default command does not install or launch anything. After
reviewing the report, execute the app-only smoke with the same arguments plus
`--execute`.

The execute path is intentionally limited to `adb install -r` for Duoduo,
force-stopping and launching `com.example.dlg_q`, checking its PID, and reading
logcat for that PID. It does not clear global logcat, inspect another package,
modify device settings, or create files in shared device storage.

```powershell
adb devices -l
adb install -r build\app\outputs\flutter-apk\app-debug.apk
adb shell am force-stop com.example.dlg_q
adb shell am start -W -n com.example.dlg_q/.MainActivity
```

Pass criteria:

- install succeeds without removing existing user data;
- launch state is cold and the process remains alive;
- first visible screen matches the stored onboarding state;
- logcat has no `FATAL EXCEPTION`, `AndroidRuntime: FATAL`, `E/flutter`, ANR,
  SQLite exception, database lock, or uncaught restore error.

## Migration And Interruption Gate

1. Preserve a byte-for-byte copy and SHA-256 of the pre-install device database.
2. Install over the existing app without clearing data.
3. Confirm `PRAGMA user_version = 23`, `PRAGMA integrity_check = ok`, and record
   every `PRAGMA foreign_key_check` row without silently repairing historical
   data.
4. Resume one first-run boundary and one active Agent checkpoint after force
   stop; both must keep the saved goal and original plan snapshot.
5. Restore the original device database after fixture validation and verify the
   restored SHA-256 matches the pre-test value.

## Backup, Delete, And Restore Gate

1. Open `我的 -> 设置 -> 本地数据与隐私`.
2. Export a database backup through Android DocumentsUI.
3. Select a database-backed deletion scope and verify the app offers `取消`,
   `直接删除`, and `备份后删除`.
4. Choose `备份后删除`, complete the save operation, and verify deletion does
   not start when the save dialog is canceled.
5. Verify the selected learning data is absent while excluded preferences remain.
6. Restore the saved `.db`, accept the replacement warning, and verify learning
   content, history, outcomes, review queues, and events refresh without an app
   restart.
7. Force stop and cold start; verify restored data remains present.
8. Repeat with an invalid file and an unsupported schema; verify stable error
   text and unchanged current data.
9. Exercise a post-replacement validation failure and verify automatic rollback.

## Export And Privacy Gate

- Export local events and confirm the JSON contains only allowlisted properties.
- Export a support bundle with Agent summary off and on.
- Export project interview outcome as Markdown and plain text.
- Open feedback from first run, Agent workspace, project outcome, and a visible
  error state; confirm each entry identifies its current surface.
- Confirm the feedback preview lists the exact export scope, diagnostics are off
  by default, and enabling them changes the preview before DocumentsUI opens.
- Cancel one feedback save and confirm no `feedback_submitted` event is added.
- Save one feedback export and confirm the JSON contains the explicit feedback
  text while the local event contains only category, severity, and consent.
- Confirm source-backed formal claims contain locators.
- Scan all exports for API keys, Authorization values, model prompts/responses,
  private absolute paths, URL queries, source bodies, and user answers.
- Remove every temporary export and fixture database from the device after
  acceptance.

## Cohort Metrics Gate

Aggregate participant event exports without modifying the fixed targets:

```powershell
& 'D:\tools\flutter\bin\dart.bat' run tool\private_alpha_metrics.dart `
  --invited 10 <event-export.json>...
```

- Keep each participant's latest export and allow overlapping exports; the CLI
  deduplicates by `event_id`.
- Before 10 observed users or the required observation window, retain
  `insufficient_data` even when provisional percentages look favorable.
- Put interview learning claims, crash-free starts, support interventions, and
  go/no-go rationale in `docs/private-alpha-report-template.md`; the CLI does
  not infer them.

## Accessibility And Visual Gate

- Run the 320x800 privacy and about-page widget regressions.
- Run the 200% text-scale regressions and confirm no overflow or exception.
- Confirm backup, restore, retry, delete, and about actions expose readable
  semantics and tap actions.
- On Tier A, capture screenshots and UI hierarchy for privacy backup, restore
  confirmation, delete preparation, restored state, and about/known limitations.
- Inspect screenshots for clipped text, incoherent overlap, inaccessible disabled
  states, and content hidden behind system insets.

## Go / No-Go

The build is `GO` only when every required gate above has evidence attached.
Any deferred item needs an owner, rationale, affected tester list, and recovery
instruction. Model availability is separate from local reliability: a candidate
may install and inspect local material without a model, but formal AI learning
is blocked until that exact provider/model/protocol profile passes the in-app
five-task acceptance matrix.

## Sources

- Flutter supported platforms, including Android API 24-36 for Flutter 3.44:
  https://docs.flutter.dev/reference/supported-platforms
- Android Storage Access Framework and system document picker:
  https://developer.android.com/guide/topics/providers/document-provider
- SQLite `VACUUM INTO` consistent snapshot and interruption caveat:
  https://www.sqlite.org/lang_vacuum.html
- Flutter accessibility guidance and release-checklist recommendation:
  https://docs.flutter.dev/ui/accessibility

Sources were fetched through `smart-search fetch` on 2026-07-16.

## Leaf 21.5 Recorded Evidence

Recorded on 2026-07-16 against Tier A `emulator-5554`:

- `flutter test --no-pub`: 215 tests passed;
- `flutter analyze --no-pub --no-fatal-infos`: 0 errors, 0 warnings,
  34 existing info lints;
- `git diff --check` and the credential-shaped review passed;
- Gradle 9.4.1 completed 203 tasks for `android-x64` using the offline command
  above;
- `build/app/outputs/flutter-apk/app-debug.apk`: 78,072,121 bytes,
  SHA-256 `ee166a61343c19b07ad31ca00b8adf3699a2f572006d72ab9ad523c3ff5fa6ab`,
  v2 debug signature verified;
- APK identity: `com.example.dlg_q`, version `1.0.0+1`, min SDK 24,
  target SDK 36, compile SDK 37;
- overwrite install preserved the schema 23 database; initial cold start was
  5.841 seconds;
- Android DocumentsUI completed database export, save-cancel protection,
  backup-then-delete, direct delete, and restore confirmation;
- deleting product events left exactly one new `data_deleted` event; restoring
  refreshed the two saved events without restart and survived a cold restart;
- the post-restore database reported schema 23 and `integrity_check = ok`;
- the final app-process log scan contained 66 lines and no Flutter,
  AndroidRuntime, ANR, SQLite, lock, or restore error match;
- screenshots and UI hierarchies are retained under `build/validation/leaf21_5_*`.

The pre-install database was restored byte-for-byte after acceptance. Its final
SHA-256 is `65872231a9a9ad7248368d6e760a07c359f2efd43e42ab5623e3df377904a892`.

## Leaf 21.6a Readiness Evidence

Recorded on 2026-07-16 before cohort enrollment:

- focused first-run, Agent workspace, outcome, and feedback regressions: 9 tests
  passed, including 320px at 200% text scale;
- full `flutter test --no-pub`: 224 tests passed;
- `flutter analyze --no-pub --no-fatal-infos`: 0 errors, 0 warnings, 34 existing
  info lints;
- the fixed one-participant JSON fixture produced Markdown and JSON reports with
  factual metrics and `insufficient_data` for every formal target;
- Gradle 9.1.0 completed 203 tasks offline after quoting the PowerShell `-P`
  arguments; the APK is 78,086,441 bytes with SHA-256
  `2f4235312dabe35d2f740206830818a022b3d7771c45224a6e840082b7777fde`, and
  APK Signature Scheme v2 verification passed;
- overwrite install preserved user data and cold start completed in 6.058
  seconds with a live process;
- canceling DocumentsUI left `feedback_submitted` at zero; a confirmed save
  exported the explicit test description plus opted-in redacted diagnostics and
  added exactly one event containing only category, severity, and consent;
- the device export and temporary files were removed, and the original schema
  23 database was restored with `integrity_check=ok` and SHA-256
  `65872231a9a9ad7248368d6e760a07c359f2efd43e42ab5623e3df377904a892`.

This is implementation and device readiness, not evidence that the cohort has
run. Pass one exact model provider/endpoint/protocol/model profile at `5/5`
before enrolling testers.

## Leaf 21.6 Arm64 Preflight Evidence

Recorded on 2026-07-16 against a physical OnePlus PGP110:

- full `flutter test --no-pub`: 232 tests passed; device-preflight focused
  regressions: 3 tests passed;
- `flutter analyze --no-pub --no-fatal-infos`: 0 errors, 0 warnings, 34 existing
  info lints; formatter, whitespace, and credential-shaped checks passed;
- device ABI `arm64-v8a`, Android API 35, physical size 1080x2412, density 480;
- the Arm64 debug APK was built from the same source with 203 actionable tasks
  and `BUILD SUCCESSFUL in 3m 45s`;
- APK size is 140,580,450 bytes, SHA-256 is
  `08c4621fe571df06cfd4970ac35b3a2050ef397317484a4a14ede16dbaa5166e`, and
  APK Signature Scheme v2 verification passed;
- APK inspection found `lib/arm64-v8a/libflutter.so`; the installed package
  reports primary ABI `arm64-v8a`, version `1.0.0` (1), min SDK 24, and target
  SDK 36;
- the read-only preflight returned `READY`; the explicit app-only run returned
  `PASSED` with install, cold start, process-alive, and PID-filtered log checks
  all passing;
- the first visible screen was the expected clean-install `1/6 目标` state with
  no clipping, overlap, or system-inset obstruction. Evidence is retained as
  `build/validation/leaf21_6_arm64_cold_start.*`; the device-side capture files
  were deleted.
- the no-model path displayed the exact provider/model/protocol blocker while
  keeping local import open. A dedicated ZIP made from repository test material
  imported successfully, persisted source locators and chunks, and reached
  `4/6 覆盖`; AI generation remained disabled without a `5/5` report;
- feedback export from the coverage screen saved an explicit Arm64 smoke
  description with diagnostics off. The JSON contained only the expected app
  and feedback sections, and the SQLite `feedback_submitted` event contained
  only `category`, `severity`, and `diagnostic_consent`;
- the exported feedback and fixture ZIP were removed from the phone. Local
  DocumentsUI dumps that could expose unrelated recent/download filenames were
  deleted instead of being retained as evidence.

Follow-up physical-device evidence recorded on 2026-07-17:

- the development-only `Grok 4.5 通道（主）` profile using Responses and model
  `grok-4.5` passed the App matrix at `5/5` in 66.1 seconds; the returned model
  identifier was `grok-4.5`;
- a separate custom Responses profile passed the short `5/5` matrix but failed
  the real project-generation flow twice with gateway `504`, so the short matrix
  alone was not treated as long-task stability evidence;
- the Grok profile completed project understanding, question generation, and
  citation precheck for the imported fixture without a gateway failure, yielding
  12 source-bound knowledge points and 12 questions;
- all 12 knowledge points and all 12 questions were manually reviewed. The App
  reached `6/6 结果`, saved one completed Agent Session, and the knowledge base
  ended with `待核验 0`;
- Android DocumentsUI exported a schema 23 database backup and restored the same
  backup through the App confirmation flow. Model credentials, model profile,
  acceptance report, first-run completion, and privacy preferences remained
  outside the restored database as designed;
- the final database reported schema 23, `integrity_check=ok`, zero foreign-key
  issues, 1 source, 4 source chunks, 12 knowledge points, 12 verified questions,
  1 completed learning session, and 33 product events;
- a final cold start opened the main five-tab App, the Grok profile still showed
  `5/5`, and PID-filtered logs contained no Fatal, Flutter, ANR, SQLite, integrity,
  or restore failure;
- the exported device backup, app-sandbox rollback fixtures, and local database
  inspection copies were deleted after verification.

Post-device follow-up implemented on 2026-07-17:

- review drafts can bulk-verify only questions that are still pending and retain
  at least one locally readable citation; deleted questions and manually selected
  no-source states are preserved, and the user must still save the review;
- the Knowledge Base pending tab requires confirmation, then applies all eligible
  question updates in one SQLite transaction and refreshes dependent read models;
- focused service, draft-widget, and rollback coverage passed, followed by all
  238 tests. Analyze completed with zero errors and warnings and 34 existing info
  lints; whitespace and credential-shaped checks passed;
- after the retrieval stress hardening, the current Arm64 APK is 140,589,086
  bytes with SHA-256
  `e8dbf4ec2c057303248a86920f552fdcb584a0b39ae5bfc271e2fb0a0078766a`,
  verifies with APK Signature Scheme v2, and contains only the Arm64 Flutter
  engine library;
- no device was listed by `adb devices -l` during this follow-up, so the new
  pending-tab confirmation flow still requires an app-only physical-device click
  check after the OnePlus is reconnected.

The Arm64 Tier B technical gate is complete. A shared public relay remains a
development credential only; formal participant invitations still require a
controlled or participant-owned profile with a current App `5/5` report and an
explicit data-handling owner.






