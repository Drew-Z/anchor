# Current Development State

Updated: 2026-09-08. This is the current execution pointer, not a release approval.

## Development Mode

- Codex owns the complete development loop, including UI implementation and emulator verification, under `../AGENTS.md`.
- Canonical checkout: `D:\workspace4Cursor\learn\anchor`, branch `codex/anchor-web-demo`.
- Transition baseline: `173a6c9a039fba27f8ad439a870f6306f66bc0f2`.
- Workflow migration commit: `54ab396` (`docs: switch Anchor development to Codex only`). Current code is the canonical branch HEAD; the transition baseline is not a reset target.
- Continued from task `01a01e2e-d37b-7760-8934-ae0b4dd72be9` through `01a07cfd-0714-73c0-bc13-a10f2bdf8784` and `01a07de8-546a-7062-8a37-c4f5048298ce` on 2026-09-08. The checkpoint-card verification and DL-001/DL-002/DL-003 are complete. Current task: `01a07e0b-378b-78a2-9041-605bca5892b6`, resumed at `584c4e9` with clean tracked files.
- The old `anchor-web-productization-loop` automation was removed on 2026-09-05. The new Codex-only heartbeat below was enabled on 2026-09-08 after two manually completed leaves; other projects' automations are unrelated.
- Claude task `20260905-135936-e5d2eef4` failed before editing. Its initial agent and both recovery sessions have been stopped. Its provider failures and exhausted retries are historical evidence, not a current development blocker or a task to resume.

## Continuous Development Pointer

- Root task: `anchor-development-loop`, defined in [DEVELOPMENT_LOOP.md](DEVELOPMENT_LOOP.md). This section is the single execution pointer.
- Round: 5. Phase: `analyzing`. Active leaf: none. DL-001 through DL-004 are complete. The next concrete candidate is the knowledge-library header/accessibility defect observed during DL-004 emulator acceptance.
- Latest application verification: DL-004; 16 search widget checks, 21 related service checks and 417 full Flutter tests passed. Analysis found no issues; formatting, debug APK and diff checks passed. Actual emulator interaction at normal and narrow/200% text verified query and save isolation. Its separate pre-existing header overflow is documented below and is not claimed as a passing layout gate. The earlier Web check remains 75 unit tests and 93 Playwright tests (168 total); Web code was unchanged. These are local results, not remote CI or release approval. Historical coverage percentages were not remeasured.
- Current assessment: DL-004 prevents late answer/record callbacks from contaminating a newer request, including A → B → A. Its device checks exposed an existing accessibility defect in unchanged layout code; this now takes precedence over speculative cleanup.
- Scheduling: `ACTIVE` heartbeat `anchor` ("Anchor 持续开发主任务"), every 30 minutes, now bound to task `01a07e0b-378b-78a2-9041-605bca5892b6`. The existing automation was backed up, updated through the app API, and verified with a TOML parse: only its target task and update timestamp changed; no automation remains bound to the previous task. The name, prompt, interval, enabled state and creation timestamp were preserved. Current handoff backup: `D:\Agent\codex\automations\anchor\automation.toml.20260908-064943-resume-400-handoff.bak` (SHA-256 verified). The earlier `automation.toml.20260908-061146-thread-handoff.bak` remains retained.
- Scheduled wake-ups at 06:05 and 06:41 Asia/Shanghai failed with HTTP 400 before a new leaf began. The continuation repair below is installed; the user's subsequent "continue" resumes Round 4 at DL-004. Future runs read the root rules and this pointer.

### Continuation transport repair (2026-09-08)

- The 06:41 failure is tied to an unpaired `function_call_output` named `codex_app.automation_update`: Desktop 0.153.4 inserts the heartbeat with no `call_id`, and the configured Responses upstream rejects `input`. A small synthetic request reproduced the same 400; the identical heartbeat as an external message completed successfully on the same model/provider. The issue reproduces without a long conversation or a subagent.
- Installed a local compatibility relay at `D:\Agent\codex\tools\responses-compat-proxy`. It converts only this named, unpaired `<heartbeat>` event into a user-role message, retaining its full text and order. It leaves ordinary tools, model selection, reasoning settings, authentication, upstream errors and stored session history unchanged. Historical heartbeat entries are normalized when resent, so a failed heartbeat need not require another new task.
- Codex user configuration now uses `http://127.0.0.1:18317/v1`; the relay forwards to the same existing upstream at port 8317. Only `model_providers.custom.base_url` changed. Backup: `D:\Agent\codex\backups\config.toml.20260908-072032-heartbeat-compat.bak`, with SHA-256 verified. Context limits and credentials were not changed.
- The relay runs outside the desktop process under the limited current-user logon task `CodexResponsesCompat`; its hidden Node process was started and its health endpoint verified. This task starts the local transport at login; the existing `anchor` heartbeat remains the development scheduler. No replacement cron or new recurring project task was created.
- Verification: 13 local transport checks passed, including normal tool preservation, gzip/deflate/Brotli/zstd input, streaming without buffering, cancellation, error passthrough and no automatic replay. A live sequence of heartbeat → ordinary follow-up → another heartbeat completed with exact expected answers, HTTP 200 and `response.completed` for all three requests on `gpt-6-astra`. A fresh, read-only, ephemeral Codex process then used the saved configuration, returned `CONFIG_READY` and exited 0; relay counters confirmed the added traffic. Evidence is in the relay's `live-verification.json` and `repair-evidence.json`; these are transport checks, not Flutter or release acceptance.
- Desktop reload is now verified: this task's request log entries `55893429`, `55893609` and `55893623` use `http://127.0.0.1:18317/v1/responses` (timestamps 1788834913–1788834940). This replaces the earlier port-8317 observation; no further restart is requested for this repair. The relay's separate startup task remains responsible for the transport across desktop restarts.
- Independent rate limiting was observed in one synthetic probe as an SSE `error` with `rate_limit_exceeded` despite HTTP 200. That attempt was not counted as success; the later three-request sequence above completed. The compatibility relay does not remove upstream rate limits or change retry policy.
- Application code was unchanged in the transport repair. Preserve its 406-test DL-003 baseline as dated evidence; the newer DL-004 Flutter checks below belong to the separate product leaf.

### Completed Leaf DL-001 — Checkpoint header readability

- Commit: `575b4dd`. Root workflow setup: `4db0ac9`.
- Goal/output: keep the complete title, phase label and delete action readable and operable at 390px / 100% and 320px / 200%, without splitting `Session` inside the word.
- Inputs: `_AgentResumeCheckpointCard`, the existing unknown-tool-outcome fixture and `anchor-checkpoint-20260908-large.png`. The title, phase and delete action currently compete in one row.
- Owned files: `lib/features/agent/agent_home_screen.dart`, `test/agent_home_navigation_widget_test.dart`, this state document and the current-queue summary in `NEXT_STEPS.md`.
- Preserve: user-facing strings, goal/message wrapping, callbacks, routes, checkpoint state and database behavior.
- Acceptance: a regression that fails on the original narrow/large-text layout; targeted Agent tests; full Flutter tests; analysis and formatting; debug APK and real emulator screenshots at both configurations; primary/cancel and delete actions; App-PID framework logs; `git diff --check`.
- Status: `completed` on 2026-09-08. The word-level regression failed on the original 320px / 200% header. The title now has its own row, with phase/delete below it; both `Agent` and `Session` remain whole words at both tested scales.
- Verification: 18 targeted Agent tests and 401 full Flutter tests passed, zero failures. Analysis: no issues found. Dart format: two files checked, zero changes. Debug APK build and `git diff --check` passed. The existing readability tests were strengthened, so the test count did not increase.
- UI acceptance: the newly built APK ran on Android 16 / API 36 at 1080x2400 / 100% and 840x2400 / 200%, density 420. The complete header, phase, goal/message, metadata and primary button were visible; `Session` occupied one line at 200%. The decision dialog opened and "稍后处理" returned without changing revision 1. The delete action opened confirmation and removed the synthetic session.
- Fixture boundary: reused `_unknownOutcomeCheckpoint(_plan())` through the production codec with unique ID `ui-checkpoint-dl001-20260908-01a07cfd`. A temporary exporter passed its readiness/message checks. State and trace counts were 0 before injection, 1 during acceptance, and 0 after UI deletion; SQLite `quick_check=ok`. No source import or model request was performed.
- App PID 3778: `zoneMismatchLines=0`, `layoutOverflowLines=0`, `frameworkErrorLines=0`, including the final check after dialog, deletion and display restoration. Restored 1080x2400, density 420 and font scale 1.0; shut down the emulator and confirmed ADB has no devices.
- Retained screenshots under `D:\Agent\codex\visualizations\2026\09\07\01a07cfd-0714-73c0-bc13-a10f2bdf8784`: `anchor-loop-dl001-20260908-normal.png`, `anchor-loop-dl001-20260908-large.png`, and `anchor-loop-dl001-20260908-large-dialog.png`.

### Completed Leaf DL-002 — Search and validation architecture accuracy

- Commit: `7bffde1`.
- Baseline: `575b4dd`, clean tracked files after DL-001. The two protected user reports remain untracked and unchanged.
- Goal/output: describe the implemented search paths and question-review boundary accurately so the next root assessment does not plan from nonexistent BM25/embedding or automatic-verification behavior.
- Inputs: `KnowledgeSearchService._score`, `HybridKnowledgeSearchService.search`, search providers/preferences, both import screens, `CitationVerificationTask`, `QuestionValidator` and `SourceGroundedIngestionService`.
- Owned files: `docs/architecture/SYSTEM_OVERVIEW.md`, `docs/CURRENT_STATE.md`, `docs/NEXT_STEPS.md`.
- Acceptance: every corrected claim matches its cited symbol; distinguish default lexical search, optional query expansion/RRF and lexical answer context; distinguish model citation precheck, project-only local quality warnings and final review status. Check local links and `git diff --check`. No product code changes or repeat full test runs for this documentation leaf.
- Status: `completed` on 2026-09-08. Corrected the scoped sections and reviewed the diff against the call sites. Text import proceeds directly from citation precheck to review; project import adds local quality warnings. Citation verification asks the model about support but does not copy its reason into the explanation.
- Verification: 39 local Markdown/code references resolve; fenced blocks are balanced; `git diff --check` passes. Confirmed the unclosed historical code fence in `NEXT_STEPS.md` existed at `575b4dd`, and closed it without reconstructing its unfinished example. Only the three owned documentation files changed, so the passing Flutter/Web baselines remain applicable and were not repeated.

### Completed Leaf DL-003 — Search and answer evidence consistency

- Commit: `5d0d579` (`fix(search): align answer evidence with expanded results`).
- Baseline: `c6503ce`; only this task's handoff update to this state document was present before the leaf. The two protected user reports remain unchanged and untracked.
- Goal: reproduce the original-query/expanded-query discrepancy and, if confirmed, select answer evidence from the same completed search branch shown by the knowledge library.
- Inputs: `knowledgeHybridSearchReportProvider`, `knowledgeAnswerGroundedContextProvider`, the screen's `augmented` result selection, and the synthetic English checkpoint corpus with a Chinese query and fake rewrite provider. Existing widget tests override answer context independently and do not exercise this integration.
- Output: a source-backed rewrite hit can enable the answer action with its real local chunk, source, locator and quote boundary; ordinary local results remain usable while a rewrite is pending, disabled or failed. No live model call is needed for this regression.
- Owned files: `lib/core/providers/providers.dart`, `test/hybrid_knowledge_search_service_test.dart`, `test/knowledge_base_search_widget_test.dart`, `docs/architecture/SYSTEM_OVERVIEW.md`, `docs/CURRENT_STATE.md`, `docs/NEXT_STEPS.md`.
- Acceptance: prove a provider/widget regression fails on the original implementation; verify augmented evidence, default-off behavior, pending/failure fallback and preference changes; run targeted search/context/widget tests, full Flutter tests, analysis, formatting and `git diff --check`. Preserve existing citation and source validation. The product change is provider wiring; no screen layout change is planned.
- Pre-fix reproduction: two provider regressions failed (rewrite-only context was empty; completed expansion did not add its chunk), while the four original service tests and default-off/fallback checks passed. The real-provider widget regression also failed: the rewritten source was visible and the augmented badge was present, but the answer button callback was null.
- Status: `completed` on 2026-09-08. The context provider observes the report state and chooses the same `augmented` branch as the screen, retaining the immediate lexical path otherwise. Both search consumers share the existing query-family report, so selecting context does not issue a second rewrite request.
- Verification: 22 targeted search/context/widget/adapter/preference tests and 406 full Flutter tests passed with zero failures. `flutter analyze --no-pub --no-fatal-infos`: no issues. Dart format: three files checked, zero changes. Local Markdown links: 10 checked, none missing. `git diff --check` passed.
- Regression evidence: a Chinese query with no local lexical hit now selects the rewritten checkpoint chunk with the original source, trust level, locator and exact-text boundary. A pending rewrite leaves existing local evidence executable; completion, opt-out and opt-in update the selected chunks. Default-off makes no rewrite call; failure retains the lexical evidence. The widget regression uses real search/context providers and verifies the visible hit, augmented badge, enabled answer action and one available source chunk. No live request or persistent data write is involved.
- Test harness note: an initial default-off provider test timed out without an active subscription when a dependency completed. It now holds the same subscriptions as the UI; the pending-rewrite regression separately requires local context to return before the controlled rewrite future completes. All final checks above passed after that correction.

### Completed Leaf DL-004 — Query-scoped answer completion

- Baseline: `d1e30f2a613cd68a6972f9eb9a5bcb985e581015`, clean tracked files on `codex/anchor-web-demo` (ahead 55). No Dart, Flutter, Gradle or emulator process was running at entry. The two protected reports remain untracked with their recorded SHA-256 hashes unchanged.
- Goal: verify and, if reproduced, prevent an answer or record completion from a superseded query/request from altering the current answer panel or starting an obsolete record write.
- Inputs: `_KnowledgeSearchTabState._setQuery`, `_answerQuestion`, `_recordKnowledgeAnswer` and the existing search widget tests. Editing immediately clears answer state but delays `_query`; completion currently checks only that committed string. Returning to the same text and starting a new answer also needs distinct request ownership.
- Output: query edits immediately invalidate pending answer work; the current committed query remains answerable after debounce. Stale success/failure results and record acknowledgements cannot change the new answer. A record write already started for an accepted answer may finish for that original answer, without changing the current panel.
- Owned files: `lib/features/knowledge_base/knowledge_base_screen.dart`, `test/knowledge_base_search_widget_test.dart`, `docs/CURRENT_STATE.md`, `docs/NEXT_STEPS.md`. Any emulator harness is temporary and uses fake tasks, synthetic evidence and an in-memory repository; it must not use live model credentials or stored user data.
- Acceptance: first demonstrate failure on the original implementation using controlled answer/save futures; cover completion before/after debounce, query A → B → A, current retries and disposal. Run focused search/answer/context checks, full Flutter tests, analysis, formatting and `git diff --check`. Verify the affected flow in the real Android emulator at normal and narrow/200% text sizes, retain screenshots and restore display overrides. Preserve existing source/citation validation and search timing.
- Pre-fix reproduction: the unchanged application failed 6 of 16 search widget checks (10 passed). An answer completed before debounce started one obsolete record write; the pending-query answer button stayed enabled; A → B → A revived the first answer; an old failure appeared on the new query; and both successful/failed earlier saves overwrote the saving state of a newer answer for the same text. Completion after debounce, clearing/disposal, current generation retries and current record retries passed.
- Status: `completed` on 2026-09-08. Added per-answer request identity, invalidated on each input edit and new generation; answer and record callbacks require that identity. The answer action waits until draft and committed queries match. Already-started saves still finish for their original record, and only mounted widgets refresh their providers. All 16 search widget checks and 21 focused service/context checks pass. Full `flutter test --no-pub --reporter expanded`: 417 passed, exit 0. `flutter analyze --no-pub --no-fatal-infos`: no issues. Format: two files unchanged; `git diff --check` and the ordinary debug APK build pass. Local commit subject: `fix(search): isolate answer completion across query edits`.
- Temporary materials: removed this leaf's completed full-test and emulator logs after retaining results. Keep `C:\Users\zhang\AppData\Local\Temp\anchor-dl004-20260908-01a07e0b-ui.dart` and `anchor-dl004-20260908-01a07e0b-ui.py` only for the immediately following header acceptance; these isolated fixtures use the actual screen/theme, controlled fake answers and in-memory records. Delete them when that verification finishes. Dependency/build caches and older materials remain retained. No test/build command or emulator is pending.
- Device progress: normal-size interaction confirmed that editing `checkpoint` to `recovery` and then completing the old answer within the 300ms debounce starts zero saves; the action is disabled during debounce and enabled afterward. The current `recovery` answer then saves exactly once. Normal-ready/answer screenshots and a 320px/200% screenshot are retained in the current task's visualization directory. The large-text screenshot exposes pre-existing metric-card overflow and clipped tab/context labels; no layout code was changed by DL-004. This is the next concrete UI candidate, not a passing global layout gate.
- Device interruption/recovery: two headless emulator runs exited with Windows Application Error 1000, `qemu-system-x86_64-headless.exe`, exception `0xc0000005`, at 10:42:53 and 10:56:41 Asia/Shanghai. A read-only diagnostic subagent was interrupted before returning evidence and is no longer active. The documented `-qt-hide-window -no-snapshot -gpu host` launch mode completed the remaining checks and exited 0 on explicit shutdown. At 320px/200%, the old answer again made zero saves and the current answer saved once; completion of an earlier same-query save left the new answer in its own pending-save state until its acknowledgement. Scrolling exposed the correct current answer and citation. The four layout classes were byte-for-byte equal to the baseline, confirming the header issue predates this fix.
- Device cleanup/evidence: restored 1080x2400, density 420, font scale 1.0; rebuilt and reinstalled the normal production entrypoint debug APK; stopped the fixture and emulator and confirmed ADB has no devices. The emulator database SHA-256 remained `7b5d1f282f695235d10c4a29d93c4022634830a96d9857d6679272c6d612235f`. The final app-PID log snapshot after display restoration had no zone/overflow matches, but it does not negate the captured earlier layout defect. Five screenshots plus `anchor-dl004-20260908-evidence.json` are retained under `D:\Agent\codex\visualizations\2026\09\07\01a07e0b-378b-78a2-9041-605bca5892b6`. No live model, persistent fixture write or physical-device acceptance is claimed.

### Root Decisions And Next Entry

- Round 2 chose and completed DL-002 after DL-001 because the initial analysis found verifiable documentation errors, not missing service wiring.
- Round 3 reproduced and completed DL-003. After its checks, the root returned to the adjacent asynchronous boundaries. Corpus invalidation already refreshes both search providers through their watched corpus; no additional invalidation change was justified by that inspection.
- Round 4 selected the bounded `DL-004` investigation above from the concrete debounce/request-ownership boundary. No unrelated refactor or new product feature is planned.
- Round 5 candidate `DL-005`: the 320px/200% screenshot shows four metric-card bottom overflows and clipped tab/context labels; even normal size shortens two metric labels. `_MetricTile` fixes height at 76 and shares a narrow row between icon, value and label; the five tabs always divide the full width, and the answer action shares one row with the context count. Reproduce these current-layout failures with production-theme widget checks, then make those labels readable without changing counts, tab routes or answer semantics.
- Next entry: record the DL-005 contract and reproduce its focused layout checks before editing. Reuse the retained synthetic emulator fixture, complete targeted/full/static and real-emulator checks, then return to root analysis. Do not repeat DL-001–004.
- Release-only work stays outside this local queue: the documented `HOLD` requires fresh external evidence and the existing release authorization boundary.

### Temporary Materials From This Assessment

- This handoff removed its two temporary `codex-heartbeat-compat-01a07e0b-smoke` output/error files from the system temporary directory and the relay's redundant single-probe `heartbeat-verification.json`, after retaining their validation results and cleanup hashes in `repair-evidence.json`. Retain the compatibility relay, its tests, final live evidence, both verified backups and its running logon task as the repair deliverables. The temporary tool-managed verification server was stopped before the supervised service started. Existing reports, old temporary files and historical worktrees remain untouched.
- Removed this task's `C:\Users\zhang\AppData\Local\Temp\anchor-dl003-20260908-01a07de8-flutter-test.log` after recording its 406-pass result. Retain the verified automation backup above as a recovery artifact. No new checkout, worktree, persistent test data or other temporary output was created explicitly by this task; pre-existing build/test caches, screenshots, reports and older temporary files remain untouched.
- Removed this task's `C:\Users\zhang\AppData\Local\Temp\anchor-trellis-20260908-01a07cfd-web-results\.last-run.json` and its empty parent directory after confirming it was the only entry.
- Web tests also write screenshots under `web/test-results/evidence`. Their existence was not inventoried before this run, so retain them; their names, modification times and ignored status do not establish ownership.
- Removed all five new DL-001 temporary files under `C:\Users\zhang\AppData\Local\Temp`: `anchor-loop-dl001-20260908-flutter-test.log`, `anchor-loop-dl001-20260908-helper.py`, `anchor-loop-dl001-20260908-exporter_test.dart`, `anchor-loop-dl001-20260908-fixture.json`, and `anchor-loop-dl001-20260908-inspect.png`. The temporary emulator UI XML was removed after each inspection. The three acceptance screenshots remain as evidence.

## Repository Boundaries

- `D:\Agent\codex\worktrees\anchor-claude-web-productization` is clean at the transition baseline and retained for reference only.
- `D:\Agent\codex\worktrees\anchor-claude-agent-recovery` is clean at `0133321c74d63c53db6afc681fd8422e50659566`. That commit is not an ancestor of the current branch; do not automatically merge or delete it.
- Keep both external task journals and worktrees. No cleanup of pre-existing files is authorized by their age or naming alone.
- Preserve the untracked user reports `docs/TECHNICAL_MODEL_ACCEPTANCE_2026-08-26.md` and `docs/TECHNICAL_MODEL_ACCEPTANCE_2026-08-26_2004.md`; do not stage them.
- Machine-wide Claude installation and settings are not part of this project migration.

## Completed Before The Transition

- `173a6c9`: Agent home header hierarchy.
- `6b08bc3`: Learning home visual hierarchy.
- `f0a637b`: Web gallery integration using actual Android screenshots.
- `eaa748e` and `38177c5`: narrow top bar and large-text layout fixes.

## Previous Codex Leaf

`970eec5`: Agent home learning plan visual hierarchy, implemented directly by Codex.

- Input: the existing workspace snapshot, plan, callbacks, strings, and shared AppColors.
- Output: a quiet white plan surface, readable ink hierarchy, restrained green route accent and primary action, and wrapping at 320 logical pixels / 200% text.
- Implementation scope: `_LearningAgentPlanCard`, `_PlanDetailsDisclosure`, `_PlanMetric`, `_PlanScopeChip`, `_PlanScoreChip`, and `_PlanLoadingCard` in `lib/features/agent/agent_home_screen.dart`; focused layout coverage in the existing Agent widget tests when needed.
- Preserve providers, routes, events, enabled/disabled rules, sessions, storage, and all user-facing strings.
- Acceptance: Agent home navigation and unified workspace tests, Flutter analysis, formatting, full Flutter tests, real emulator screenshots, and `git diff --check`.
- Status: implemented and verified by Codex on 2026-09-05.
- Result: white surface with a 1px neutral border; route title and scope wrap fully; statistics use unframed labels with stronger values; secondary copy has lower weight; the green CTA retains its callbacks and readable disabled colors.
- New regression coverage checks 390px / 100% and 320px / 200% labels and disclosure. The 200% title check failed on the original implementation and passed after the change.

## Previous Evidence Readability Leaf

Agent home expanded plan evidence readability, implemented directly by Codex.

- Input: existing plan evidence, session summary, focus points, strings, and callbacks.
- Output: full wrapping for the Agent Session title, objective, target, source constraint, memory reminder, focus title, and focus reason, including narrow screens and large text.
- Implementation scope: `_AgentSessionSummaryView`, `_AgentSessionRuleRow`, and `_FocusPointRow` in `lib/features/agent/agent_home_screen.dart`; regression coverage in `test/agent_home_navigation_widget_test.dart`.
- No changes to providers, routes, callbacks, strings, state, or storage. Only the one- or two-line truncation limits and title line height changed.
- Status: implemented and verified on 2026-09-05/06. The two new detailed-fixture tests failed before the fix and passed afterward at 390px / 100% and 320px / 200%.
- Coverage includes each expanded label, horizontal bounds, collapse/re-expand, and no checkpoint persistence writes from disclosure.

## Expanded Evidence Verification (2026-09-06)

- `flutter test --no-pub test/agent_home_navigation_widget_test.dart test/learning_agent_unified_workspace_test.dart`: 16 passed.
- `flutter test --no-pub`: 399 passed, zero failures, in the canonical checkout.
- `flutter analyze --no-pub --no-fatal-infos`: no issues found.
- Dart formatting and `git diff --check`: passed.
- Current debug build ran on the real Android 16 / API 36 emulator. Screenshots were inspected at 1080x2400 / 100% text and 840x2400 / 200% text (density 420, 320 logical pixels). Route/scope labels wrap, the primary action remains visible, and expanded evidence titles, constraints, reasons, and metadata wrap without ellipses. App-PID logs contain zero layout-overflow matches.
- Restored and verified emulator size 1080x2400 and font scale 1.0, then shut down the emulator. No matching Flutter run or emulator process remains.
- Screenshots are outside Git under `D:\Agent\codex\visualizations\2026\08\20\01a01e2e-d37b-7760-8934-ae0b4dd72be9`: `anchor-plan-evidence-codex-20260906-normal-details.png` and `anchor-plan-evidence-codex-20260906-large.png`. Previous plan-card screenshots retain their `anchor-plan-codex-20260905-` names.
- Temporary cleanup was blocked by the tool safety policy. These five files created during this leaf remain under `C:\Users\zhang\AppData\Local\Temp`: `anchor-plan-evidence-20260905-inspect.png`, `anchor-plan-evidence-20260905-add.png`, `anchor-plan-evidence-20260906-large-summary.png`, `anchor-plan-evidence-20260906-large-details.png`, and `anchor-plan-evidence-20260905-full-test.log`. They are not source changes or release evidence.

The previous worktree's 393-pass / 2-failure report is historical. Its frozen-hash and secure-storage transform failures did not reproduce in this canonical-checkout run. No frozen evidence or unrelated build files were changed to resolve them.

The debug startup `Zone mismatch` warning was the open reliability candidate for this leaf and is now resolved; the pre-fix reproduction and post-fix startup evidence are recorded below.

## Latest Reliability Leaf

Startup zone alignment, implemented directly by Codex.

- `lib/main.dart` now initializes Flutter bindings inside the same `runZonedGuarded` zone that calls `runApp`, while preserving the existing framework and async error handlers and system UI setup.
- No routes, providers, user-visible strings, storage, credentials, or release settings changed.
- The pre-fix warning was reproduced on the Android debug run. After the change, the real Android 16 / API 36 emulator reported `zoneMismatchLines=0`, `layoutOverflowLines=0`, and `startupErrorLines=0` for Anchor PID 3590.
- The targeted Agent tests, full Flutter test suite, analysis, formatting, and `git diff --check` passed. See Current Verification below for the latest counts. Emulator display settings were left at 1080x2400 / 100% and the emulator was shut down afterward.

## Previous Completed Leaf

`f389cbd`: Agent checkpoint goal and readiness-message readability. Code completed on 2026-09-06; the missing card-specific emulator verification was completed on 2026-09-08.

- The change removes fixed line limits from the goal/tool label and readiness message in `_AgentResumeCheckpointCard`. Existing regression tests cover ordinary text and 320 logical pixels / 200% text. No further application or test code changed during verification.
- The earlier emulator smoke covered startup only. It did not establish checkpoint-card visual acceptance; the results below close that specific gap.
- Reproduction used the existing `_unknownOutcomeCheckpoint(_plan())` fixture from `test/agent_home_navigation_widget_test.dart`, serialized through the production plan codec. A temporary exporter checked that the fixture requires a user decision and contains the long "最终结果尚未保存" message. One uniquely named synthetic checkpoint and one trace were inserted into the emulator's local database; both tables were empty beforehand. This is UI fixture evidence, not a real interrupted import or model-acceptance result.
- On the actual Android 16 / API 36 emulator, the goal, complete readiness message, metadata, and primary button remain visible at 1080x2400 / 100% text and 840x2400 / 200% text, both at density 420. The second configuration is 320 logical pixels wide.
- At 200% text, "确认工具结果" opens the decision dialog and "稍后处理" returns to the unchanged card. Deleting the synthetic session through the card removes it; SQLite `quick_check=ok`, checkpoint count 0, and trace count 0 match the initial state. No source import or AI request was performed.
- That run found `Session` wrapped as `Sessio` / `n` at 320px / 200%. The goal/message fix passed its own checks; the separate header finding was subsequently resolved and verified by DL-001 above.
- Screenshots are outside Git under `D:\Agent\codex\visualizations\2026\09\07\01a07cfd-0714-73c0-bc13-a10f2bdf8784`: `anchor-checkpoint-20260908-normal.png`, `anchor-checkpoint-20260908-large.png`, and `anchor-checkpoint-20260908-large-dialog.png`.

## Checkpoint Body Verification Baseline (2026-09-08)

These dated checks ran against application commit `f389cbd14f116a1be5f98930d4cb8b9a6b3943f8`. The later DL-001 results are recorded above; the original body-verification follow-up changed only two state documents.

- `flutter test --no-pub --reporter expanded test/agent_home_navigation_widget_test.dart test/learning_agent_unified_workspace_test.dart`: 18 passed, zero failures.
- `flutter test --no-pub --reporter expanded`: 401 passed, zero failures, exit code 0.
- `flutter analyze --no-pub --no-fatal-infos`: no issues found. Dart formatting: two files checked, zero changes. `git diff --check`: passed.
- `flutter build apk --debug --no-pub`: passed; the resulting APK was installed on the emulator for the card checks.
- Anchor PID 4455 logs reported `zoneMismatchLines=0`, `layoutOverflowLines=0`, and `frameworkErrorLines=0`. The final check after dialog, deletion, and display restoration also had zero matching framework errors.
- Restored and verified emulator size 1080x2400, density 420, and font scale 1.0. The emulator was shut down; ADB lists no devices and no matching Flutter run or emulator process remains.
- Removed all five temporary files created for this verification: the fixture helper, temporary Dart exporter, synthetic JSON, inspection screenshot, and full-test log. The three acceptance screenshots above are retained.
- The seven temporary files from the previous task remain untouched. Five are listed in the dated expanded-evidence section above; the other two are `C:\Users\zhang\AppData\Local\Temp\anchor-agent-resume-card-20260906-full-test.log` and `C:\Users\zhang\AppData\Local\Temp\anchor-agent-resume-card-20260906-startup.png`. They predate this task and are not current card-acceptance evidence.
- Both untracked user reports retain their initial SHA-256 hashes and are excluded from the documentation commit.

## Previous Header Finding

The `anchor-checkpoint-20260908-large.png` baseline exposed title/phase/delete contention in one row. DL-001 above completed this follow-up, preserving strings, actions, state, storage and goal/message wrapping. Use the continuous-development pointer for the next task; do not reopen this completed finding from its older screenshot.

## Release Boundary

Android identity remains `cc.eu.playlab.anchor`, database `anchor_learning.db`, candidate `1.0.0+2005`. Web remains a separate static demo with local data and no AI provider calls.

Private Alpha remains `HOLD`: `cohort_pending`, `release_day_acceptance_primary_stale`, and `physical_device_evidence_stale`. See `PRODUCTIZATION_RELEASE_PLAN.md` for dated artifact evidence. Emulator/UI checks do not establish real-device acceptance or a cohort decision. Push, deployment, release signing, and distribution remain outside the current task.
