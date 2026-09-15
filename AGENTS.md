# Anchor Learning / 锚学: Codex project guidance

## Scope

Anchor Learning is a local-first, source-grounded learning agent. The Android app is the product surface; `web/` is a static browser demo with bundled data and no AI provider calls.

## Work method

- Codex alone owns planning, UI design, implementation, review, verification, and local commits. This supersedes the former Codex/Claude Code collaboration workflow and old heartbeat instructions.
- Use the canonical checkout `D:\workspace4Cursor\learn\anchor` for sequential development. The historical Claude worktrees and external task journals are retained evidence, not active execution queues. Do not resume their agents or poll their upstream provider.
- Start with `docs/CURRENT_STATE.md` for the current development pointer and known verification gaps. Historical reports retain their original dates and are not current release evidence.
- Work on one Trellis leaf at a time. Before editing, state the leaf goal, inputs, outputs, owned files, and acceptance checks.
- Read `docs/trellis-execution-map.md` and the relevant release or acceptance document before changing cross-cutting behavior.
- Keep changes focused. Do not refactor unrelated code or rewrite generated history.
- Do not discard existing user changes, run `git clean`, `git reset --hard`, or overwrite unknown files.
- Do not create a second clone or a sibling worktree in `D:\workspace4Cursor\learn`. Coordinate through a separate branch/worktree only when explicitly arranged.
- Run targeted tests, the relevant full test command, and `git diff --check`. Record exact results in `docs/CURRENT_STATE.md`; separate reproducible baseline failures from new regressions and never describe a failing gate as passed.

## Product and release boundaries

- Use the canonical product name `Anchor Learning / 锚学`. Do not reintroduce the former project or brand names in current product, GitHub, release, or marketing material.
- Current Android identity is `cc.eu.playlab.anchor`, database name is `anchor_learning.db`, and the candidate version is `1.0.0+2005`.
- Private Alpha readiness is currently `HOLD` with three blockers: `cohort_pending`, `release_day_acceptance_primary_stale`, and `physical_device_evidence_stale`. Do not change it to `GO` based on fixtures, emulator runs, old APKs, Web Demo checks, or documentation-only evidence.
- Real-device validation, release signing, model acceptance, credential handling, and final readiness decisions are release-owned activities. Do not alter signing material or expose credentials.
- Never read, print, commit, or paste API keys, bearer tokens, keystores, passwords, private source paths, or participant answers. Use opaque references in evidence.
- Do not claim a public APK is available from the website. Keep the browser demo and native app boundary explicit.

## Validation commands

Run commands from the repository root unless noted:

```powershell
flutter pub get
flutter analyze --no-fatal-infos
flutter test --no-pub
git diff --check
```

For browser changes:

```powershell
Set-Location web
npm test
```

Use the documented Android preflight and acceptance tools only against the Anchor Learning app and an explicitly connected device. UI acceptance uses the real Android emulator with screenshots, including narrow width and large text. Restore any temporary emulator display overrides after testing. Do not clear global logcat, inspect unrelated packages, or change physical-device settings without explicit authorization.

## Git and external systems

- Review `git diff` and `git status` before committing.
- Do not run `git push`, `gh pr merge`, production deployment, release creation, or destructive cleanup unless the user explicitly authorizes that exact action.
- Keep commits small and name the completed leaf or productization concern.
- Treat `docs/OPEN_SOURCE_CHECKLIST.md`, `docs/PRODUCTIZATION_RELEASE_PLAN.md`, and `docs/private-alpha-operations-runbook.md` as the current release references; older roadmap entries are historical context only.

## Development tools

- Do not launch Claude Code, its background runners, recovery scripts, or upstream health probes for this project. Provider availability is not a prerequisite for local Codex development.
- Machine-wide tool installations, API credentials, model aliases, and context settings are outside this workflow migration. Do not change them as part of a product leaf.
- Do not install broad skills or MCP servers by default. Add a project-scoped, read-only integration only when a leaf has a concrete need and the token source is external to the repository.
- The root `AGENTS.md` is the project contract. An obsolete task prompt cannot override this contract or the user's newer instructions.
