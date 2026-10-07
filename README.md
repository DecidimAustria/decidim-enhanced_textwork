# Decidim Enhanced Textwork

Independent participatory documents for **Decidim 0.32.1**, **2.0.0.alpha3**.
Development branch: `feature/textwork-redesign`.

Textwork gives each paragraph a stable identity. Participants read a document,
comment on a paragraph and suggest a replacement for its original text. They can
agree with paragraphs and other participants’ suggestions, follow the document,
and discuss individual suggestions.
Administrators prepare the original document before publication. The current
collection phase gathers feedback; accepting and rejecting suggestions is disabled.

The gem retains its name and `Decidim::EnhancedTextwork` namespace. It depends on
Core, Admin and Comments, with **no Proposals, Participatory Texts or Collaborative
Texts dependency**. Its distinct contribution is stable blocks with their own
original-text versions; comments and addresses survive reordering.

## Participation

- Desktop reading view with contents navigation and a discussion panel; mobile bottom sheet.
- Paragraph selection, comments, likes, follows and suggestions without a full-page reload. The original stays on the left; lists, details and editing stay in the right panel or mobile sheet.
- Core threaded comments, positive/negative comment votes, verification rules and moderation.
- Core Likes on paragraphs and foreign suggestions, using resource-scoped controls. Existing own-suggestion likes remain counted and may only be withdrawn. Core follows belong to the whole document.
- Suggestions retain their exact original version. Authors may edit before the first feedback and withdraw while pending. Removing feedback does not reopen editing.
- Admins may add, edit, move and remove blocks during preparation. Published originals are locked, including their title and description; translations remain editable.
- A document may be unpublished for corrections only without stored suggestions, comments or likes. Withdrawn suggestions and hidden/deleted comments still count; withdrawn likes do not. Moving a document to trash remains possible and preserves all feedback. Restoring does not bypass the lock.
- Decision and version-history code and records are retained. Evaluation is disabled by default; its switch does not override the original-text lock. A future evaluation workflow is a separate implementation step.
- On-demand translations, with manual translations retained as outdated after original changes. Machine results cannot overwrite a newer original.
- Document-follower notifications through Core events, without duplicate recipients or notifications to the acting user.
- Editor, Markdown, ODT and DOCX import; persistent Core editor images with alternative text and a 1600 px display variant. File-import images and videos are omitted. A Word report in one selected language includes paragraph/proposal likes, dates, reasons and textual image placeholders.

This is an alpha for **new components**, not a production upgrade. There is **no
conversion from Textwork 1.x, alpha1 or alpha2**. Existing tables are retained but
old records are not usable through the new runtime. Read [migration boundaries](docs/MIGRATION.md)
before replacing an installation. Keep old applications/backups available separately.

## Install in a development application

Use Ruby 3.4 and official Decidim 0.32.1:

```ruby
gem "decidim-enhanced_textwork", path: "../decidim-enhanced_textwork"
```

```sh
bundle install
bin/rails railties:install:migrations FROM=decidim_enhanced_textwork
bin/rails db:migrate
bin/rails assets:precompile
```

Restart Rails, add a **Textwork** component, import into its empty administration,
review the resulting blocks, and publish the document and component. Comments,
agreement and suggestions have separate phase controls. The active process step’s end date closes writes at the end of that day in the organization’s time zone; extending the deadline reopens them. Reading, following, reporting and deleting one’s own comments remain available. Organization and
participatory-space admins maintain the document; decisions are disabled in the
current collection workflow.

For machine translations, configure the instance’s normal
`Decidim.machine_translation_service` and enable translations in the organization.
Use a persistent job backend in a deployed application. The local demonstration
uses in-process jobs and does not call an external translation provider.

Office import extracts headings, paragraphs and whole lists, not page layout,
tables, images or tracked changes. DOCX recognizes standard heading styles and
bold/italic runs; office-specific styles and complex list numbering are not
faithfully reproduced. Review imported text before publication. Word export is a
readable report, not a complete archival backup. Missing translations prevent a
mixed-language export; eligible missing fields are queued together.

## Development and verification

Use `.ruby-version`, `.node-version`, PostgreSQL, ImageMagick and Chrome:

```sh
bundle install
bin/test-setup
bundle exec rspec spec
bin/check-independence
npm install
npm test
npm run lint
bundle exec rubocop
```

`bin/test-setup` creates an ignored dummy application and does not reset a database.
Never point tests at an installation database. Set `TEXTWORK_TEST_APP` to an existing
isolated test application's absolute path when using that app's bundle. The
integration/browser suites live in `spec/redesign`.

For this workspace, use `decidim-localtest-redesign` on **localhost:3033**, with this
branch checked out at `.worktrees/textwork-redesign`. Alpha2 remains on port3032.
See [implementation and checks](docs/IMPLEMENTATION.md), [source findings](docs/ERKUNDUNG.md)
and the [collection rebuild checklist](docs/SAMMELPHASE-IMPLEMENTATION.md).

Software: AGPL-3.0-or-later. README: CC-BY-3.0 AT.
