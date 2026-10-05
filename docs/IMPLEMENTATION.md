# Textwork alpha3 implementation

Target: official Decidim 0.32.1, Ruby 3.4.7. Branch: `feature/textwork-redesign`.
The [alpha2 implementation](history/ALPHA2-IMPLEMENTATION.md) is historical.

## Architecture and data

The existing gem and namespace are retained. The `textwork` component owns its
public/admin engines and depends explicitly on Core, Admin and Comments. There
are no Proposals or Collaborative Texts models, routes or patches. Loading the
plugin without either component is checked by `bin/check-independence`.

| Model | Responsibility |
| --- | --- |
| Document | Original locale, translated metadata, publication/trash, Core search, agreement/follows for unstructured documents. |
| Block | Stable heading/paragraph identity, position and heading_depth, current text, comments or chapter likes/follows. |
| BlockVersion | Immutable original text, consecutive version, author, origin and accepted suggestion/adjustment. |
| Suggestion | Exact base version and changeset, author, reason, decision, moderation, comments and Core likes. |
| DocumentRevision | Immutable import/add/remove/move record with positions, numbers and text where applicable. |
| TranslationRequest | Unique resource/field/target/source-digest request and proxy for the configured Core translation provider. |

Schema changes are additive. Alpha2 tables remain, but their removed model classes
and old public flows are not compatibility adapters. A new component is required;
see [migration boundaries](MIGRATION.md). The obsolete pending suggestion counter
was deliberately not added: public counts derive from visible pending suggestions,
grouped once for the whole reading page.

## Rules and concurrency

Text and structure changes lock the document first. Accepting a suggestion checks
the version displayed in the admin form; stale suggestions remain acceptable after
review, but a concurrent edit returns a conflict. New original text creates one
BlockVersion and one PaperTrail text version. Position and counter updates do not
create text versions. A reviewed identical final text still records its acceptance.

Removal sets `removed_at`, rejects every pending suggestion with a localized reason
and retains contributions. Removed content and visible discussions are readable
from the version history. Document trash similarly preserves blocks and contributions.
Chapter likes remain across edits and moves. They are not revision supports.

Editing an own pending suggestion rebases it to the current paragraph version.
Its first like or comment sets a permanent feedback timestamp, preventing later
edits even if feedback is removed. Withdrawal remains possible while pending.

Reads/writes scope IDs through the current component. Public writes check the
organization, resource visibility, space participation, Core ActionAuthorizer and
phase switches. Decisions require organization or participatory-space admin rights.
Core verification dialogs are used when required. Hidden suggestions are excluded
from counts, lists and direct-link content; original blocks cannot be reported.

## Browser integration

One Stimulus controller owns the selected paragraph, request cancellation, browser
history, drafts, focus and mobile sheet. Panel GETs are cancellable; submitted
comment writes finish before switching resources. The actual textarea moves into
the document on desktop and stays in the sheet on mobile.

The browser diff preserves whitespace, line breaks and punctuation. A bounded LCS
calculation falls back to a full replacement for very large differences. It writes
text nodes, not participant-provided HTML. Markdown rendering accepts a small safe
subset and escapes raw HTML.

The controls use Core Like/Unlike/CreateFollow commands with resource-specific
responses. This avoids Core's single-resource DOM IDs without introducing another
likes table. The comments adapter is a local subclass for cancellable reads and
scoped sorting; it does not modify Core prototypes, forms, views or write endpoints.
These two adapter boundaries need regression tests when upgrading Decidim.

## Languages, events and files

Manual translations take precedence. Original changes retain them in
`outdated_translations` and clear active translations. Admins can review and restore
them. Machine responses are accepted only for the exact current source and locale;
they do not create content/history versions. Completed translations can be reused
if the same original returns. Failed jobs have bounded retries; later page requests
can retry after a cooldown. Use a persistent queue in deployed applications; the
local app deliberately uses memory-only jobs.

Core events deliver to the suggestion author, chapter followers and/or people who
agreed, according to the event. Recipients are deduplicated, the actor is excluded,
and delivery waits until the enclosing transaction commits. Comment events remain
Core events with the resource recipient hook. Rejection includes its reason.

Editor, Markdown, ODT and DOCX inputs create headings and complete list/paragraph
blocks. XML and ZIP sizes are bounded; external entities are rejected. Office page
layout, tables, images, tracked changes and complex styles/numbering are outside
the converter. Imported content must be reviewed before publication.

Word export includes current text, pending visible suggestions, visible comments
and agreement counts. It uses one requested language and refuses missing
translations instead of silently mixing languages. It is not a complete archive.

## Verification and limits

The reproducible checks and acceptance matrix are in
[REDESIGN-IMPLEMENTATION.md](REDESIGN-IMPLEMENTATION.md). Functional tests use a
separate test database; no customer data or external translation service is used.
Automatic accessibility checks and keyboard/reflow tests cover the reading view
and panel. They are not a complete WCAG 2.2 AA certification. Instance colors,
assistive technologies, large real documents and the chosen production translation
provider still require acceptance testing before a production release.
