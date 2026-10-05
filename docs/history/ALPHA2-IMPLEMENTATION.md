# Independent Textwork implementation

## Architecture

Target: official Decidim 0.32.1, Ruby 3.4.7. Plugin: 2.0.0.alpha2. Branch: `feature/standalone-textwork`.

The component manifest `textwork` mounts independent public and administrative Rails engines. It does not add routes, settings, controller prepends or view overrides to Proposals or Collaborative Texts. Gem dependencies are Core, Comments, Kramdown and Rubyzip. The old component manifest is deliberately not reused.

| Model | Purpose |
| --- | --- |
| `Document` | One document per component, localized title/description and publication state. |
| `Section` | Stable identity, heading/paragraph level, ordering, comments, follows, moderation and current revision pointer. |
| `Revision` | Immutable localized text/title, sequence number, editor and creation date. |
| `Support` | Unique participant support for a revision or amendment. Repeated requests do not add duplicate supports. |
| `Amendment` | Exact base revision, author, proposed text and reason, pending/accepted/rejected/withdrawn state, decision actor/date/reason and accepted result revision. |
| `DocumentVersion` | Immutable ordered references to paragraph revisions, plus document metadata, at publication and subsequent published edits/reordering/acceptance. |

Models live under `Decidim::EnhancedTextwork`; tables use the new `decidim_textwork_*` prefix. In particular, the new section model does not reuse the legacy `Paragraph` type, so old polymorphic references cannot accidentally resolve to unrelated new IDs.

## Participation and authorization

Public writes require the same organization, a visible resource, participation permission in the space, action authorization and applicable component/phase settings. Reads and writes scope resource IDs through the current component/document. Moderated sections and their amendments are excluded from public views. Core Comments is attached through `CommentableWithComponent`, with an additional visibility/block guard.

An organization administrator or a user with an administrator role in the current participatory space may decide amendments. An author, evaluator or administrator of another space does not gain that right. The component administration also uses Decidim's normal administrative access checks.

All mutations that affect paragraph versions or supports lock the document. Amendment acceptance checks the base revision against the current revision before replacing it. A stale acceptance returns a conflict, and a second decision cannot create another revision. Pending amendments may still be rejected if stale. Supports submitted from an outdated page are refused for the old revision, while existing supports can be withdrawn from its history page if participation is enabled.

Revision rows are read-only after creation. Published sections cannot be deleted through the draft-delete endpoint. Administrative text edits create a revision; reordering preserves paragraph IDs. Only unpublished draft sections can be removed. Comments stay in a paragraph-wide discussion, explicitly labelled as spanning revisions. Amendment discussions remain attached to the amendment and its base revision.

Amendment decisions are recorded through Decidim traceability and notify the submitting participant using the normal event infrastructure. The local test application captures outgoing mail locally.

## Import and export

Editor HTML is sanitized by Decidim and parsed into top-level headings and paragraph blocks without the former Proposals parser. Markdown uses Kramdown followed by the same sanitizer. ODT reads heading/paragraph text from a bounded `content.xml`, rejects entity declarations and external document types, and does not fetch resources. Imports require an empty component and are transactional. Original office formatting, tables, images and tracked changes are outside the import contract.

The DOCX writer emits a text report. It excludes moderated/deleted content and replies whose parent is excluded. It is not a database-complete preservation format.

## Validation and local test data

Tests cover import/publication, component boundaries, hidden/draft content, phase blocks, login, revision-bound supports, immutable history, stale/duplicate decisions, process-administrator boundaries and exports. Browser scenarios exercise the editor, core comment submission, supports/unvote, amendment submission/commenting/acceptance and responsive document presentation.

Verified on 2026-10-04: **46 examples, 0 failures**, including the browser scenarios above, against official Decidim 0.32.1. Localtest passed Rails autoloading and the asset build; rerunning seeds preserved existing data.

`bin/check-independence` verifies that loading the component does not load Proposals or Collaborative Texts. Schema changes are additive and the installation task explicitly installs the external gem's migration.

`decidim-localtest` retains its original Proposals components. Independent examples are separate components with a separate seed marker, so rerunning setup preserves manual test changes. The local database was dumped before creating the independent examples; backups and credentials remain ignored. This is not a migration of the prototype data and is not a rehearsal on a legacy customer installation.

## Release boundaries

This remains a development alpha, not an approved production upgrade. Legacy conversion, full historical archival, external integration compatibility and a representative legacy rehearsal are separate work. The document design remains the existing prototype; the requested larger redesign has not been implemented here. A complete WCAG 2.2 AA audit also remains separate from the functional and responsive checks.
