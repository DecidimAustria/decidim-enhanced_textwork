# Changelog

## 2.0.0.alpha1 — unreleased

- Replace the copied 0.26-era Proposals implementation with an opt-in extension for Decidim 0.32.1.
- Store new document paragraphs as core proposals and reuse core comments, amendments, votes, follows and publication tools.
- Add a responsive document/discussion view, current-editor import, individual draft deletion and a basic Word report.
- Make the contents navigable by paragraph with text previews and a current-selection marker. Separate the selected text, amendments and comments in a wider discussion panel, with controls adapted for narrow screens.
- Add English/German interface strings, integration/browser tests and a read-only legacy inventory.
- Remove the separate legacy component, models, copied APIs/assets and old installation migrations from the v2 gem. Existing v1 data is **not yet supported**; follow `docs/MIGRATION.md` before considering an upgrade.
