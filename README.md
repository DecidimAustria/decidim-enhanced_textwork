# Decidim Enhanced Textwork

Participatory documents for Decidim 0.32.1. The current release branch is
`release/2.0.0`; the gem version is still `2.0.0.alpha3`.
This README describes that branch. Earlier development checkouts have different
features and data models.

Textwork lets participants read a document paragraph by paragraph, agree with
paragraphs, comment on them and suggest replacement text. Administrators prepare
and publish the document. The current workflow collects feedback; evaluation is
disabled by default.

## Version 2 and breaking changes

Version 1 copied and adapted Decidim Proposals. Version 2 is an independent
`textwork` component with its own documents, stable blocks, original-text versions
and suggestions. It uses Decidim Core, Admin and Comments for platform integration,
likes, follows, threaded comments, permissions, moderation and notifications.
It has no runtime dependency on Proposals, Participatory Texts or Collaborative
Texts. The gem name and `Decidim::EnhancedTextwork` namespace remain unchanged.

The update is breaking:

- The component manifest changes from `enhanced_textwork` to `textwork`. Models,
  routes, settings and participation records have changed. Existing components
  cannot be upgraded by changing their manifest name.
- There is no automatic conversion from version 1, the Proposals-based alpha1,
  or the standalone alpha2. Alpha3 uses blocks and Core Likes instead of alpha2's
  sections and revision-bound supports. Alpha2 documents are not automatically
  converted to blocks.
- The new migrations retain legacy tables, but retaining rows does not make old
  textworks usable in the new interface. Historical comments, links, notifications
  and other references also need migration or an accessible archive.
- Publication locks the original text and structure. Suggestions are collected
  separately. The current collection workflow does not provide the full version 1
  evaluation or collaborative-draft workflow.
- The target is official Decidim 0.32.1 with Ruby 3.4. The gem is still an alpha for
  new components, not a supported upgrade over a working version 1 installation.

Before replacing an old installation, preserve and restore-test its database and
uploads, retain its application and dependency versions, and export readable
records from the old application. A Word report alone is not a backup. Read
[migration boundaries and archival options](docs/MIGRATION.md) before deciding
whether to convert historical participation or keep the old installation as an
archive.

## Participation and administration

- Contents navigation and paragraph selection, with a discussion panel on desktop
  and a bottom sheet on mobile. Comments, likes and suggestions load without a
  full-page reload.
- Stable block identities preserve paragraph addresses and discussions when
  administrators reorder a draft.
- Core threaded comments, positive and negative comment votes, verification rules
  and moderation.
- Core Likes on paragraphs and other participants' suggestions. Participants
  cannot add likes to their own suggestions; existing own-suggestion likes remain
  counted and can be withdrawn. Follows apply to the whole document.
- Suggestions retain their exact original version. Authors can edit pending
  suggestions before the first feedback and withdraw them while participation is
  open. Removing feedback does not reopen editing.
- Organization and participatory-space administrators can import, edit, reorder
  and remove blocks before publication. Published originals, including the title
  and description, are locked; translations remain editable.
- Unpublishing is allowed only without stored suggestions, comments or likes.
  Withdrawn suggestions and hidden or deleted comments still count; withdrawn
  likes do not. Moving a document to trash preserves its feedback. Restoring it
  does not bypass the original-text lock.
- Decision and version-history code and records are retained. Evaluation is
  disabled by default. Enabling its setting does not unlock published originals;
  a complete evaluation workflow remains a separate implementation step.
- On-demand translations, with manual translations retained as outdated after
  original changes. Machine results cannot overwrite a newer original.
- Core notifications for document followers, without duplicate recipients or
  notifications to the acting user.
- An admin layout with grouped document controls, block cards and edit forms,
  using a separate registered stylesheet pack and Decidim theme styles.

## Import formats

Administrators can paste content into the editor or upload one of these files,
up to 2 MB. A selected file takes precedence over editor content.

| Input | Supported content and limitations |
| --- | --- |
| Editor content | Headings, paragraphs and whole lists. Uploaded Core editor images persist, with alternative text and a display variant up to 1600 px. Videos are omitted. |
| Markdown, `.md` or `.markdown` | UTF-8 text converted to document blocks. File-import images are omitted. |
| OpenDocument Text, `.odt` | Headings, paragraphs and lists. Office layout, tables, embedded images and tracked changes are not reproduced. |
| Word, `.docx` | Standard heading styles, paragraphs, lists, and bold or italic text. Office-specific styles, complex list numbering, tables, embedded images and tracked changes are not faithfully reproduced. |

Review the imported blocks before publication. Importing a report does not restore
its comments, likes, suggestions or historical records.

## Export formats

The module currently provides one document report format: **Word `.docx`**.
Authorized administrators select a language and click **Export textwork** in the
component administration. The download is named `textwork-<document-id>-<language>.docx`.

The report contains:

- The document title and introduction, followed by active headings and paragraphs
  in document order.
- Paragraph like counts and visible comment threads, including author names,
  dates and reply indentation.
- Visible pending suggestions, ordered by likes and then creation time. Each
  includes its author, date, like count, proposed text, justification and visible
  comment thread.
- Textual placeholders for image blocks, using their alternative descriptions.
  Image files are not embedded.

The report uses one selected language. Missing translations stop the download
rather than silently mixing languages. Eligible missing document and suggestion
fields are queued for translation; comment translations follow Core's translation
policy. Retry when the required translations are available.

There is no built-in PDF, CSV, JSON, Markdown or ODT report export. The read-only
legacy inventory tool described in [the migration guide](docs/MIGRATION.md) can
produce JSON metadata, but it does not export document content.

The Word report is a readable record of current participation. It excludes
removed blocks, withdrawn or moderated suggestions, accepted and rejected
suggestions, hidden or deleted comments, uploaded files and historical text
versions. Keep a complete database and upload backup for archival or migration.

## Installation

Use official Decidim 0.32.1 and Ruby 3.4. To install the current development release:

```ruby
gem "decidim-enhanced_textwork",
    git: "https://github.com/DecidimAustria/decidim-enhanced_textwork.git",
    branch: "release/2.0.0"
```

For local module development, use a path to the checkout containing that release:

```ruby
gem "decidim-enhanced_textwork", path: "../decidim-enhanced_textwork"
```

Install the plugin migrations, migrate, rebuild assets and restart Rails:

```sh
bundle install
bin/rails railties:install:migrations FROM=decidim_enhanced_textwork
bin/rails db:migrate
bin/rails assets:precompile
```

Commit the copied migration files and updated schema in the application before
deploying. Installing the gem alone does not create its tables. Decidim's
`choose_target_plugins` task selects bundled modules and does not replace the
explicit migration installation above. Both public and admin stylesheet packs
must be built from the updated gem.

1. Add a **Textwork** component to a participatory space.
2. Configure comments, likes and the phase controls for comments, likes and
   suggestions.
3. Import a document into the empty component administration.
4. Review the title, introduction, language, blocks and image descriptions.
5. Publish the document and the component.

The active process step's end date closes participation at the end of that day in
the organization's time zone. Extending the deadline reopens participation.
Reading, following, reporting and deleting one's own comments remain available.

For machine translations, configure the instance's normal
`Decidim.machine_translation_service` and enable translations in the organization.
Use a persistent job backend in deployed applications. The local demonstration
uses in-process jobs and does not call an external translation provider.

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
Never point tests at an installation database. Set `TEXTWORK_TEST_APP` to an
isolated test application's absolute path when using that application's bundle.
The integration and browser suites are in `spec/redesign`.

In this workspace, `decidim-localtest-redesign` on localhost:3033 loads the module
checkout at `.worktrees/textwork-redesign`. Use that application's `bin/localtest`
commands for server and asset tasks. The separate alpha2 application remains on
port 3032 with its own database.

See [implementation and checks](docs/IMPLEMENTATION.md),
[source findings](docs/ERKUNDUNG.md),
[the collection rebuild checklist](docs/SAMMELPHASE-IMPLEMENTATION.md) and
[migration boundaries](docs/MIGRATION.md). The Proposals-based alpha1 prototype
remains on `feature/proposals-textwork-2.0`; the current development branch is
`feature/textwork-redesign`.

## License

Software: AGPL-3.0-or-later. README: CC-BY-3.0 AT.
