# Decidim Enhanced Textwork

Paragraph discussions and document tools for Decidim's participatory texts.

Version **2.0.0.alpha1** extends `decidim-proposals` on **Decidim 0.32.1**. It uses core proposals, comments, amendments, supports and administration instead of maintaining a separate copy of Proposals.

**This branch is for development and testing with new components. It is not yet an upgrade for installations with Enhanced Textwork 1.x data.** The old `enhanced_textwork` component and `Paragraph` model are no longer registered. Installing this alpha over 1.x would make those components unavailable. No legacy data migration or automatic deletion is included. See [the migration plan](docs/MIGRATION.md).

## Features

- Read a document with an adjacent discussion panel for the selected paragraph; on small screens the panel follows the document.
- Use Decidim's comments, amendment cards, support controls, follows and proposal detail pages. Permissions and component/step settings remain managed by Decidim.
- Optionally hide automatically numbered paragraph titles.
- Paste text into the current Decidim editor. Headings and paragraphs become unpublished core proposals; review, reorder and publish them through Decidim's participatory-text preview.
- Delete individual unpublished paragraphs from the Textwork tools page.
- Download a Word report with published paragraphs, support counts, visible amendments and comment threads. Moderated and deleted content is excluded.
- Use the interface in English or German.

The Word report contains text and basic headings, rather than a reproduction of editor formatting. Images, tables, attachments and Word tracked changes are not exported. Amendment visibility follows the current user's core visibility rules. Export is restricted to authorized administrators.

## Installation for testing

Use a Decidim 0.32.1 application with Ruby 3.4 and its normal Node/Shakapacker toolchain. From a local checkout, add:

```ruby
gem "decidim-enhanced_textwork", path: "../decidim-enhanced_textwork"
```

Then run `bundle install`, rebuild application assets and restart the application. This version introduces no database tables or migrations. The application still needs the normal Decidim migrations.

1. Create a **Proposals** component.
2. Enable **Participatory texts** and **Enhanced Textwork view for participatory texts** in its settings.
3. Configure comments, amendments and supports using the usual component and phase settings.
4. Open the component's participatory-text preview, then **Textwork tools**.
5. Enter a title and paste a document into the editor. Import into an empty component, review the resulting paragraphs and publish them.

The core Markdown/ODT import remains available. The editor import deliberately refuses components that already contain proposals, including drafts and amendments. Use the normal preview to edit existing drafts. Textwork tools can remove individual drafts.

Turning off the Textwork setting restores the standard Proposals view; the data remains ordinary core proposals. No separate Textwork component is created in version 2.

## Development

Use the versions in `.ruby-version` and `.node-version`, PostgreSQL, ImageMagick and Chrome/Chromium for browser tests. Run these commands from this repository, against a local test database server:

```sh
bundle install
export DATABASE_HOST=127.0.0.1
export DATABASE_PORT=5432
# Set DATABASE_USERNAME and DATABASE_PASSWORD if required by your local server.
bin/test-setup
bundle exec rspec spec
```

`bin/test-setup` generates an ignored application in `spec/decidim_dummy_app`, migrates its test database and builds assets. It reuses an existing generated application and does not drop databases. The test database is named `enhanced_textwork_test_test`. Never point these commands at an installation database or set `DATABASE_URL` to one.

To resolve gems from the neighbouring framework checkout, set `DECIDIM_PATH=../decidim` before `bundle install` and keep it set for subsequent commands. Without it, development uses the released 0.32 gems.

Browser tests cover the discussion panel, mobile layout, posting comments, support/unvote, and editor import/publication. Request and service tests cover component boundaries, permissions, drafts, moderation, amendments, export and legacy inventory. Screenshots are saved under the ignored `tmp/` directory.

## Implementation and remaining work

The integration adds two global settings and a small set of routes to Proposals. It redirects the enabled component's public index to the document view and adds one tools link to the core admin preview. These integration points need checking for each Decidim minor release.

There are no custom proposal, comment, vote or amendment models. The editor import delegates parsing to `Decidim::Proposals::MarkdownToProposals`. The DOCX writer creates a small OOXML text report without fetching external resources or depending on the old Caracal fork.

See [architecture and validation](docs/IMPLEMENTATION.md), [the 1.x migration plan](docs/MIGRATION.md) and [the changelog](CHANGELOG.md). Legacy migration, redirects from old paragraph URLs and a real-data upgrade rehearsal remain release requirements. This alpha has not been deployed to a customer installation.

## History and license

Version 1 was based on a copy of Decidim Proposals, with `Paragraph` replacing `Proposal`, additional document tools and a custom discussion view. Its README required Decidim 0.26; the previous checkout declared compatibility from 0.26 release candidates to below 0.29. The v1 code remains in Git history and on `update-to-decidim-0.28`.

Software: AGPL-3.0. README: CC-BY-3.0 AT.
