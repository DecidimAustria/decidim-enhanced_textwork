# Changelog

## 2.0.0.alpha3 — development

- Replace the alpha2 participation model with stable blocks, original-text versions and suggestions, in the same gem.
- Add the document reading view, asynchronous discussion panel, mobile sheet, keyboard focus and draft protection.
- Use Core likes and follows for chapters and Core comments/votes for paragraphs and suggestions.
- Add administrative editing, reviewed stale acceptance, structural history and soft removal with automatic reasoned rejection.
- Translate on demand through a version-bound provider adapter; preserve outdated manual translations.
- Add DOCX import, single-language reports, moderation integration and chapter notifications.
- Keep legacy tables; no conversion from 1.x or alpha1/2. The separate 3033 test app preserves alpha2 on 3032.

## 2.0.0.alpha2

- Replace the Proposals extension with an independent Textwork component and additive tables.
- Add immutable paragraph revisions, revision-bound supports and document snapshots.
- Add own amendments with administrator decisions, stale-change protection, comments and decision notifications.
- Retain editor/Markdown/ODT import, review/publication, responsive discussion and Word reports without Proposals integration.
- Preserve the previous prototype in Git and revise the legacy migration plan for the independent target. No legacy conversion is included.

## 2.0.0.alpha1 — unreleased

- Replace the copied 0.26-era Proposals implementation with an opt-in extension for Decidim 0.32.1.
- Store new document paragraphs as core proposals and reuse core comments, amendments, votes, follows and publication tools.
- Add a responsive document/discussion view, current-editor import, individual draft deletion and a basic Word report.
- Make the contents navigable by paragraph with text previews and a current-selection marker. Separate the selected text, amendments and comments in a wider discussion panel, with controls adapted for narrow screens.
- Add English/German interface strings, integration/browser tests and a read-only legacy inventory.
- Remove the separate legacy component, models, copied APIs/assets and old installation migrations from the v2 gem. Existing v1 data is **not yet supported**; follow `docs/MIGRATION.md` before considering an upgrade.
