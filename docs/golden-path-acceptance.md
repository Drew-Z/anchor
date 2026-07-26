# Golden Path Acceptance

## Purpose

This scenario verifies the product's core learning loop with one deterministic
fixture and no live AI or network dependency:

```text
project source
-> source-grounded knowledge point
-> citation-checked question
-> explicit user verification
-> cited interview feedback
-> persisted weak point
-> cited review action
-> next interview entry
```

The fixture studies Duoduo's own durable tool checkpoint implementation. The
project directory scanner imports these files on every run:

- `lib/services/agent/learning_agent_state.dart`
- `lib/services/agent/learning_agent_checkpoint.dart`

The AI responses are test inputs, never evidence. Every accepted project unit,
question, feedback citation, and review action must resolve to chunks built by
`ProjectSourceImportService` from the current files and snapshot revision.

## Fixed Inputs

- Fixture: `test/fixtures/golden_path/duoduo_checkpoint_fixture.json`
- Test: `test/golden_path_test.dart`
- Storage: a fresh in-memory SQLite schema v17 database
- AI boundary: a queued fake `OpenAIService` with five ordered JSON responses
- User decision: promote the citation-checked candidate from `pending` to
  `verified`
- Interview answer: intentionally omits the input snapshot invariant
- Review clock: `2026-07-14T03:00:00Z`

## Acceptance Steps

| Step | Input | Required output | Failure signal | Source basis |
| --- | --- | --- | --- | --- |
| 1. Import project material | Current project directory plus two selected source paths | Snapshot revision and two source chunks retain file/line locators | Missing selected file, unsafe import, or missing locator | Both selected project files |
| 2. Build project understanding | Imported chunks plus fixed project-understanding JSON | One typed `architecture` unit linked to both chunks | Empty unit, generic concept fallback, or invented chunk id | Both chunks |
| 3. Generate and precheck question | Knowledge point, chunks, generation JSON, verification JSON | One `pending` question with two supported citations | Invalid knowledge id, missing citation, or automatic promotion to verified | Both chunks |
| 4. Apply user review | Explicit `verified` decision | Transaction stores source, chunks, relations, deck, and verified question | Partial transaction or no-source normalization | User decision plus both chunks |
| 5. Run interview | Stored point/chunks and fixed interview JSON | One question retaining valid point and citation ids | Unsupported question is accepted | Both chunks |
| 6. Evaluate answer | User answer, interview question, cited chunks | Cited feedback, reference answer, and weak point | Empty feedback, invented weak point, or invented citation | Both chunks |
| 7. Close the weak point | Low score dimensions, session, turn, and fixed close time | Turn stores weak dimensions, project kind, citations, review question ids, and a next-interview prompt | Unmapped score, missing citation, or partial turn/question write | Persisted interview result and cited chunks |
| 8. Schedule review | Verified question and persisted review action | Queue exposes the same verified question under the weak point | Pending/no-source question enters formal review, or verified question is absent | Stored verified question |
| 9. Expose next actions | Persisted weak turn | Completion and history views expose source evidence, review, and interview retry actions | User cannot reach review or a focused next interview | Persisted review action |

## Repeatable Command

```powershell
$env:Path='D:\tools\flutter\bin;'+$env:Path
$env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'
flutter test test/golden_path_test.dart
```

The scenario is deterministic because selected paths, dates, ids, user input,
and model outputs are fixed. It intentionally validates the real project
scanner, project-understanding task, transactional ingestion, interview
evaluation, atomic review closure, mastery update, and review scheduler.

## Correctness Closure Scenario

Branch 19 adds a second deterministic path focused on retrieval quality,
claim-level citations, partial answers, refusal, and shared correctness metrics
across knowledge answers, tutor feedback, interview evaluation, and programming
exercise evaluation. Its fixed inputs, metric definitions, Android evidence,
remaining risks, and vector-retrieval triggers are documented in
`docs/correctness-golden-path.md`.
