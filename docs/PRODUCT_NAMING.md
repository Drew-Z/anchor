# Product Naming

## Canonical Names

- Product: `Anchor Learning`
- Chinese product name: `锚学`
- Repository: `anchor`
- Dart package: `anchor_learning`
- macOS application product: `Anchor Learning.app`

## Formal Application Identifiers

The following identifiers are the productization candidates for new installs:

- Android `applicationId` and namespace: `cc.eu.playlab.anchor`
- SQLite database file: `anchor_learning.db`
- Android platform channel: `cc.eu.playlab.anchor/project_directory`
- macOS bundle identifier: `cc.eu.playlab.anchor`

The Android application ID migration is intentionally performed before external
users are invited. Existing local data must be transferred through the app's
SQLite backup/restore flow; it cannot be assumed to survive an Android package
change by overwrite installation.

## Naming Rules

- New user-facing text, documentation, fixtures, export names, and support
  artifacts must use `Anchor Learning`, `锚学`, or the `anchor-learning` prefix.
- Do not introduce the former working name in new code or documentation.
- Historical implementation references that have already been migrated should
  be described using the current product name; technical compatibility markers
  should be explained explicitly when they appear.
