# Decidim Enhanced Textwork

Independent participatory documents for **Decidim 0.32.1**, version **2.0.0.alpha2**.

Textwork is a separate component with its own documents, sections, text revisions, supports and amendments. It has **no runtime dependency on Proposals, Participatory Texts or Collaborative Texts**. It uses `decidim-core` and `decidim-comments` for the platform integration, comments, follows, moderation, authorization and decision notifications.

This is a development alpha for new components. **There is no automatic migration from Textwork 1.x or the Proposals-based alpha1.** Back up existing data and read [the migration plan](docs/MIGRATION.md) before changing an installation. No legacy tables are deleted by this release.

## Features

- Read a structured document with a contents list and a discussion panel for the selected paragraph.
- Comment on paragraphs and amendments using Decidim's threaded comments, including comment votes.
- Support a particular paragraph revision. After a change, old supports remain with the old revision and the new revision starts without supports.
- Propose a changed text, explain it, discuss it, support it, or withdraw your pending amendment.
- Organization administrators and administrators of the component's participatory process/space can accept or reject amendments. Being the author does not grant decision rights.
- Acceptance creates a new paragraph revision and a document snapshot. A stale amendment cannot overwrite a newer revision; rejection remains possible.
- View previous paragraph revisions and their support counts. Paragraph discussions span revisions; amendments retain their exact base revision.
- Import editor content, Markdown or ODT, review/edit/reorder unpublished sections, remove drafts and publish the document. Later administrative edits create new revisions too.
- Download a Word report containing published text, current-revision support counts, visible amendments and comment threads.
- Use German or English and the instance's Decidim styling.

The ODT importer preserves heading structure and paragraph text. It does not reproduce office styles, tables, embedded media or tracked changes. The Word export is a readable report, not a complete archival backup; it excludes moderated/deleted content and does not include uploaded files or every historical revision.

## Local installation

Add the gem to a Decidim 0.32.1 application using Ruby 3.4:

```ruby
gem "decidim-enhanced_textwork", path: "../decidim-enhanced_textwork"
```

Install dependencies and the plugin's own migrations, then rebuild assets and restart:

```sh
bundle install
bin/rails railties:install:migrations FROM=decidim_enhanced_textwork
bin/rails db:migrate
bin/rails assets:precompile
```

Decidim's `choose_target_plugins` task only selects bundled modules. It does not replace the explicit plugin migration installation above.

1. Add a **Textwork** component to a participatory space.
2. Configure comments, amendments and phase-specific support/comment blocks.
3. Open its administration, enter a document title and paste a text, or choose a Markdown/ODT file up to 2 MB. A selected file takes precedence over editor content.
4. Review, edit and reorder the sections, then publish the document and component.
5. Participants can read, support and discuss the text. Amendment decisions are available to authorized administrators on the amendment page.

The component manifest is `textwork`. New tables use `decidim_textwork_*`, keeping them separate from old `decidim_enhanced_textwork_*` data. Disabling this gem does not turn documents into Proposals.

## Development

Use `.ruby-version` and `.node-version`, PostgreSQL, ImageMagick and Chrome/Chromium:

```sh
bundle install
export DATABASE_HOST=127.0.0.1
export DATABASE_PORT=5432
# Set local DATABASE_USERNAME and DATABASE_PASSWORD if required.
bin/test-setup
bundle exec rspec spec
```

`bin/test-setup` creates/reuses an ignored test application and does not reset databases. Its database is `enhanced_textwork_test_test`. Never point tests at an installation database. The test application's full Decidim bundle includes other components, but the plugin itself only requires Core and Comments. `bin/check-independence` additionally loads the plugin in a separate Ruby process without requiring the full Decidim bundle and refuses a Proposals/Collaborative Texts load.

Set `DECIDIM_PATH=../decidim` consistently for Bundler and subsequent commands only when testing the sibling framework checkout instead of released gems.

See [implementation and validation](docs/IMPLEMENTATION.md) and [migration options](docs/MIGRATION.md). The Proposals-based prototype remains on `feature/proposals-textwork-2.0` at `dff08cb`; the independent implementation is on `feature/standalone-textwork`.

## History and license

Version 1 copied and adapted Proposals. Alpha1 replaced that copy with a Proposals extension. Alpha2 removes that component dependency because Decidim has announced the future replacement of Participatory Texts, and Collaborative Texts does not implement the paragraph participation workflow required here.

Software: AGPL-3.0. README: CC-BY-3.0 AT.
