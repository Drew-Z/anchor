# Current Development State

Updated: 2026-09-08. This is the current execution pointer, not a release approval.

## Development Mode

- Codex owns the complete development loop, including UI implementation and emulator verification, under `../AGENTS.md`.
- Canonical checkout: `D:\workspace4Cursor\learn\anchor`, branch `codex/anchor-web-demo`.
- Transition baseline: `173a6c9a039fba27f8ad439a870f6306f66bc0f2`.
- Workflow migration commit: `54ab396` (`docs: switch Anchor development to Codex only`). Current code is the canonical branch HEAD; the transition baseline is not a reset target.
- Continued from task `01a01e2e-d37b-7760-8934-ae0b4dd72be9` on 2026-09-08. Its remaining checkpoint-card emulator verification is complete; the separate header layout finding below is the next candidate.
- The old `anchor-web-productization-loop` automation is absent in the app, confirmed by the automation API on 2026-09-05. No replacement schedule was created; work continues in the current task. Other projects' automations are unrelated.
- Claude task `20260905-135936-e5d2eef4` failed before editing. Its initial agent and both recovery sessions have been stopped. Its provider failures and exhausted retries are historical evidence, not a current development blocker or a task to resume.

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

## Latest Completed Leaf

`f389cbd`: Agent checkpoint goal and readiness-message readability. Code completed on 2026-09-06; the missing card-specific emulator verification was completed on 2026-09-08.

- The change removes fixed line limits from the goal/tool label and readiness message in `_AgentResumeCheckpointCard`. Existing regression tests cover ordinary text and 320 logical pixels / 200% text. No further application or test code changed during verification.
- The earlier emulator smoke covered startup only. It did not establish checkpoint-card visual acceptance; the results below close that specific gap.
- Reproduction used the existing `_unknownOutcomeCheckpoint(_plan())` fixture from `test/agent_home_navigation_widget_test.dart`, serialized through the production plan codec. A temporary exporter checked that the fixture requires a user decision and contains the long "最终结果尚未保存" message. One uniquely named synthetic checkpoint and one trace were inserted into the emulator's local database; both tables were empty beforehand. This is UI fixture evidence, not a real interrupted import or model-acceptance result.
- On the actual Android 16 / API 36 emulator, the goal, complete readiness message, metadata, and primary button remain visible at 1080x2400 / 100% text and 840x2400 / 200% text, both at density 420. The second configuration is 320 logical pixels wide.
- At 200% text, "确认工具结果" opens the decision dialog and "稍后处理" returns to the unchanged card. Deleting the synthetic session through the card removes it; SQLite `quick_check=ok`, checkpoint count 0, and trace count 0 match the initial state. No source import or AI request was performed.
- The card header still wraps `Session` as `Sessio` / `n` at 320px / 200%. The goal/message fix is verified; the header is a separate open layout concern, not a claim that the whole card is visually finished.
- Screenshots are outside Git under `D:\Agent\codex\visualizations\2026\09\07\01a07cfd-0714-73c0-bc13-a10f2bdf8784`: `anchor-checkpoint-20260908-normal.png`, `anchor-checkpoint-20260908-large.png`, and `anchor-checkpoint-20260908-large-dialog.png`.

## Current Verification (2026-09-08)

Checks ran against application commit `f389cbd14f116a1be5f98930d4cb8b9a6b3943f8`; this follow-up changes only the two state documents.

- `flutter test --no-pub --reporter expanded test/agent_home_navigation_widget_test.dart test/learning_agent_unified_workspace_test.dart`: 18 passed, zero failures.
- `flutter test --no-pub --reporter expanded`: 401 passed, zero failures, exit code 0.
- `flutter analyze --no-pub --no-fatal-infos`: no issues found. Dart formatting: two files checked, zero changes. `git diff --check`: passed.
- `flutter build apk --debug --no-pub`: passed; the resulting APK was installed on the emulator for the card checks.
- Anchor PID 4455 logs reported `zoneMismatchLines=0`, `layoutOverflowLines=0`, and `frameworkErrorLines=0`. The final check after dialog, deletion, and display restoration also had zero matching framework errors.
- Restored and verified emulator size 1080x2400, density 420, and font scale 1.0. The emulator was shut down; ADB lists no devices and no matching Flutter run or emulator process remains.
- Removed all five temporary files created for this verification: the fixture helper, temporary Dart exporter, synthetic JSON, inspection screenshot, and full-test log. The three acceptance screenshots above are retained.
- The seven temporary files from the previous task remain untouched. Five are listed in the dated expanded-evidence section above; the other two are `C:\Users\zhang\AppData\Local\Temp\anchor-agent-resume-card-20260906-full-test.log` and `C:\Users\zhang\AppData\Local\Temp\anchor-agent-resume-card-20260906-startup.png`. They predate this task and are not current card-acceptance evidence.
- Both untracked user reports retain their initial SHA-256 hashes and are excluded from the documentation commit.

## Next Bounded Candidate

Review the header row of `_AgentResumeCheckpointCard` at 320 logical pixels / 200% text. The title, phase label, and delete action share one row; the phase and action consume enough width to split `Session` inside the word. Use `anchor-checkpoint-20260908-large.png` as the baseline. Limit the next leaf to this header layout and meaningful regression coverage, preserving the verified goal/message wrapping, all strings, actions, state, and storage. This follow-up has not been implemented.

## Release Boundary

Android identity remains `cc.eu.playlab.anchor`, database `anchor_learning.db`, candidate `1.0.0+2005`. Web remains a separate static demo with local data and no AI provider calls.

Private Alpha remains `HOLD`: `cohort_pending`, `release_day_acceptance_primary_stale`, and `physical_device_evidence_stale`. See `PRODUCTIZATION_RELEASE_PLAN.md` for dated artifact evidence. Emulator/UI checks do not establish real-device acceptance or a cohort decision. Push, deployment, release signing, and distribution remain outside the current task.
