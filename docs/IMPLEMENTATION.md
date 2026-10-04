# Version 2 implementation

## Scope

Initial development branch: `feature/proposals-textwork-2.0`, based on legacy commit `7715beb8310b`. Framework reference: local `release/0.32-stable`, commit `d514de311b`, version 0.32.1. The executable tests use the released Decidim 0.32.1 gems.

The old copied module is replaced by an opt-in Proposals extension in the same gem. New documents use core tables exclusively. There is no automatic legacy conversion in this alpha.

## Integration points

| Area | Implementation |
| --- | --- |
| Component settings | Add `enhanced_textwork_enabled` (default false) and `textwork_hide_numbered_titles` (default true) to Proposals. Both participatory texts and Textwork must be enabled. |
| Public routing | Prepend a small `index` override to the core controller. Enabled components redirect to the added `/textwork` route; otherwise call `super`. |
| Document view | Query published, unmoderated, non-amendment proposals belonging to the current component in position/ID order. Resolve the selected paragraph through the same scope. |
| Discussion | Render core comments, follow controls, amendment cards and vote controls. Filter moderated amendments before rendering the cards. Use mounted Proposals paths for voting and details. |
| Admin entry point | One small override of `_bulk-actions.html.erb` adds the tools link alongside the original import/discard actions. |
| Editor import | Core editor HTML → sanitized HTML → Kramdown → core Markdown parser. Lock the component, require it to be empty, create drafts and metadata in a transaction. |
| Draft deletion | Component-scoped unpublished core proposal lookup, core permission check and traceability. Published proposals and other components' drafts cannot be deleted through this route. |
| Word report | Authorized admin download. Published and visible data, ordered comment threads, basic OOXML text/heading output. No HTTP/file fetches from document content. |
| Assets | Register a Shakapacker entrypoint through `config/assets.rb`; load the plugin stylesheet and core proposal interactions on the document page. |
| Legacy inspection | SQL-only reporting class, a rake task and an entry script usable with an old application's bundle. |

All added admin actions require the core `manage participatory_texts` permission; export also requires `export proposals`. Ordinary Decidim routing controls access to the organization, space and component. The plugin does not add public export access.

## Boundaries

- Selecting another paragraph currently navigates to a new page with a discussion anchor. It does not reproduce the old custom AJAX navigation.
- The discussion panel contains one paragraph's discussion at a time and moves below the text on small screens.
- Core import parsing determines the handling of headings, lists and paragraphs. Arbitrary office-document layouts are not preserved.
- The Word report is synchronous and intended for normal-sized documents. Large-document performance and background exports remain to be assessed.
- Core details, amendment creation/editing and moderation screens remain core screens. The plugin does not copy them or reimplement their business rules.
- The old similarity configuration and separate Paragraph GraphQL types are not retained. Integrations must use core Proposals interfaces after migration.

## Validation

The suite runs against an isolated generated test application and PostgreSQL. It covers opt-in routing, normal-view fallback, component isolation, drafts, moderation, admin access, core voting, amendment display, editor import, draft deletion, DOCX structure/content, threaded comments and non-mutating legacy inventory.

Chrome system tests exercise desktop/mobile discussion, comment submission, support/unvote and the editor-to-core-publication flow. The plugin assets are built through the application's normal Shakapacker pipeline. No customer database, deployment or framework source is modified.

Local validation on 2026-10-04: Ruby 3.4.7, Decidim 0.32.1, Rails 8.1.4, PostgreSQL 14 and Node 22.14.0. The suite contains 30 examples, including four Chrome system tests. Asset compilation, Rails eager loading (`zeitwerk:check`), repeatable setup on the generated application, Ruby syntax and gem packaging were checked. GitHub Actions is configured but has not run remotely.

Before a stable release, add legacy conversion with representative fixtures, rehearse it on a restored installation, check large documents and verify exported reports in the Word/LibreOffice versions used by administrators. XML/ZIP tests establish the report structure; they do not substitute for office-application acceptance.
