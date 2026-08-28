# Anchor Learning / 锚学: Claude Code project guidance

## Scope

Anchor Learning is a local-first, source-grounded learning agent. The Android app is the product surface; `web/` is a static browser demo with bundled data and no AI provider calls.

## Work method

- Work on one Trellis leaf at a time. Before editing, state the leaf goal, inputs, outputs, owned files, and acceptance checks.
- Read `docs/trellis-execution-map.md` and the relevant release or acceptance document before changing cross-cutting behavior.
- Keep changes focused. Do not refactor unrelated code or rewrite generated history.
- Do not discard existing user changes, run `git clean`, `git reset --hard`, or overwrite unknown files.
- Do not create a second clone or a sibling worktree in `D:\workspace4Cursor\learn`. Coordinate through a separate branch/worktree only when explicitly arranged.
- A leaf is complete only after targeted tests, the relevant full test command, and `git diff --check` pass. Record the result in the leaf handoff or task summary.

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

Use the documented Android preflight and acceptance tools only against the Anchor Learning app and an explicitly connected device. Do not clear global logcat, inspect unrelated packages, or mutate device settings.

## Git and external systems

- Review `git diff` and `git status` before committing.
- Do not run `git push`, `gh pr merge`, production deployment, release creation, or destructive cleanup unless the user explicitly authorizes that exact action.
- Keep commits small and name the completed leaf or productization concern.
- Treat `docs/OPEN_SOURCE_CHECKLIST.md`, `docs/PRODUCTIZATION_RELEASE_PLAN.md`, and `docs/private-alpha-operations-runbook.md` as the current release references; older roadmap entries are historical context only.

## Claude Code configuration

- Permission mode is operator-controlled. Preserve the operator's configured Claude Code mode, including an explicit `--dangerously-skip-permissions` wrapper, and do not treat that choice as an Anchor Learning project issue. Use plan mode for investigation and restricted edit mode for bounded implementation when the operator's mode permits it.
- Do not install broad skills or MCP servers by default. Add a project-scoped, read-only integration only when a leaf has a concrete need and the token source is external to the repository.
- The root `CLAUDE.md` is the project contract. A Trellis skill is unnecessary unless repeated leaf workflows prove that this file is insufficient.
