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
| Document | Original locale, translated metadata, publication/trash, Core search, Core document follows; publication/participation lock. |
| Block | Stable heading/paragraph identity, position and heading_depth, current text, paragraph comments/likes, or persistent Core editor image plus alternative text. |
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

Text and structure changes lock the document first. Published originals, their
metadata and structure are immutable during collection. Unpublishing for
corrections is allowed only without stored participation. Suggestions in every
status, removed blocks, hidden/deleted comments and retained likes count; removing
a like removes that stored contribution. Trash and restore retain all feedback.
Manual translations can still be reviewed independently of the original.

Decision, version and structure-history models/code remain, but evaluation is off
by default. Its switch does not override collection immutability. The isolated
legacy algorithm tests do not represent an available evaluation workflow.

Editing an own pending suggestion rebases it to the current paragraph version.
Its first like or comment sets a permanent feedback timestamp, preventing later
edits even if feedback is removed. Withdrawal remains possible while pending.

Reads/writes scope IDs through the current component. Public writes check the
organization, resource visibility, space participation, Core ActionAuthorizer and
phase switches and the active step’s end date in the organization’s time zone.
The final end date remains open through its whole local day. Extending it reopens
writes. These checks also cover the Core controllers and commands; following,
reporting and deleting one’s own comment are exempt from the deadline.
Core verification dialogs are used when required. Hidden suggestions are excluded
from counts, lists and direct-link content; original blocks cannot be reported.

## Browser integration

One Stimulus controller owns the selected paragraph, request cancellation, browser
history, drafts, focus and mobile sheet. Panel GETs are cancellable; submitted
comment writes finish before switching resources. The document stays fixed on the left. Lists, details and all form fields remain in
the right panel on desktop, and in the same mobile sheet. The sticky holder has
zero height; its own scroll area fits the viewport and the visible Core footer.

The existing lossless token diff preserves whitespace, line breaks and punctuation.
Presentation groups deletions before insertions and uses a before/after layout for
large changes. Cards, details and live previews share this renderer; server-rendered
comparison markup provides the before/after text without the browser renderer. A bounded LCS
calculation falls back to a full replacement for very large differences. It writes
text nodes, not participant-provided HTML. Markdown rendering accepts a small safe
subset and escapes raw HTML.

The controls use Core Like/Unlike/CreateFollow commands with resource-specific
responses. This avoids Core's single-resource DOM IDs without introducing another
likes table. The comments adapter is a local subclass for cancellable reads and
scoped sorting; it does not modify Core prototypes, forms, views or write endpoints.
Scoped permission/command/cell extensions protect Core writes and closed comment
controls. No Core file or JavaScript prototype is changed. These integration
boundaries need regression tests when upgrading Decidim.

## Languages, events and files

Manual translations take precedence. Original changes retain them in
`outdated_translations` and clear active translations. Admins can review and restore
them. Machine responses are accepted only for the exact current source and locale;
they do not create content/history versions. Completed translations can be reused
if the same original returns. Failed jobs have bounded retries; later page requests
can retry after a cooldown. Use a persistent queue in deployed applications; the
local app deliberately uses memory-only jobs.

Core events deliver to the suggestion author, document followers and/or people who
agreed, according to the event. Recipients are deduplicated, the actor is excluded,
and delivery waits until the enclosing transaction commits. Comment events remain
Core events with the resource recipient hook. Rejection includes its reason.

Editor, Markdown, ODT and DOCX inputs create headings and complete list/paragraph
blocks. XML and ZIP sizes are bounded; external entities are rejected. Office page
layout, tables, images, tracked changes and complex styles/numbering are outside
the converter. Editor-uploaded images become separate blocks linked to Core EditorImage records,
with their own stored alt text. External image URLs are never fetched. Display
variants limit the longest edge to 1600 px without upscaling; enlargement uses the
original. Empty or filename-derived descriptions trigger an editable reminder
before publishing, with an explicit publish-anyway option. No caption is stored.
Imported content must be reviewed before publication.

Word export includes current text, pending visible suggestions, visible comments
and paragraph/suggestion agreement counts, proposal dates, authors and reasons.
Pending suggestions sort by agreement descending and oldest first at equal counts.
Images appear as textual placeholders with alternative text. It uses one requested language and refuses missing
translations instead of silently mixing languages. It is not a complete archive.

## Verification and limits

The reproducible checks and acceptance matrix are in
[REDESIGN-IMPLEMENTATION.md](REDESIGN-IMPLEMENTATION.md). Functional tests use a
separate test database; no customer data or external translation service is used.
Automatic accessibility checks and keyboard/reflow tests cover the reading view
and panel. They are not a complete WCAG 2.2 AA certification. Instance colors,
assistive technologies, large real documents and the chosen production translation
provider still require acceptance testing before a production release.

## Frontend accessibility report follow-up, 2026-10-09

The reported Textwork findings led to these plugin changes:

- Comment and reply fields have visible, associated labels and a description
  referencing their character counters. The adaptations apply only to Textwork
  resources, including forms loaded through Core's asynchronous comment endpoints.
- Document headings start at H2 below the document H1. Missing imported levels
  are normalized for display without changing stored depths, numbering or data.
  Suggestions and comments in the paragraph panel both use H3.
- The browser title includes the localized document title through Decidim's
  current page-title helper.
- Contents counters include a hidden description identifying comments and
  suggestions. Refreshing counters preserves that description.
- A mobile paragraph panel makes all surrounding page branches inert, including
  the header, breadcrumbs and footer. Closing, resizing and disconnecting restore
  their previous inert states. Core reporting dialogs moved to the document body
  remain operable above the panel; closing them restores the panel's modal state.

Regression coverage includes imported heading levels, document titles, root and
reply labels, keyboard focus, nested reporting, restoring the page background,
320/390 px viewports and enlarged text. These technical tests do not replace a
manual screenreader check or establish accessibility of an individual deployment.

The report's process hero, user menu, process navigation and unused Core dialog
placeholders belong to the host application or Decidim. No global Core override
was added for them. Hidden placeholders must be checked in their visible state
before treating their empty names as user-facing barriers. A 32 × 24 px rectangular
target meets the 24 × 24 px minimum; smaller targets require checking the spacing
exceptions before concluding that they fail.

Reference guidance: [W3C modal dialogs](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/),
[form labels](https://www.w3.org/WAI/WCAG22/Understanding/labels-or-instructions.html),
[heading hierarchy](https://www.w3.org/WAI/tutorials/page-structure/headings/) and
[minimum target size](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html).

The authenticated frontend of `klima.participation.works` was subsequently checked
on the same date. Its deployed document still shows the earlier unlabelled comment
field, H3/H4 chapter headings, organization-only page title and incomplete modal
background isolation; the fixes above are local and have not been deployed.

The contents list also remained open after clicking the document title. The plugin
now closes it on outside clicks anywhere in the page, focus leaving the list, or
Escape. Escape restores focus to the summary when focus was inside the list and
does not also close an open paragraph panel. Choosing a chapter closes the list
and focuses that chapter. Native details/summary behavior is retained.

Additional live findings belong to the host application/Core: the mobile user menu
has only an initial as its accessible name, and the process hero has white text
without a background-color or gradient fallback when its image cannot load.
The 20 px process navigation trigger has ample separation from adjacent visible
targets in the inspected 603 px viewport, so its height alone does not establish
a target-size failure. The authorization dialog is hidden; its open state was not
tested. The reported other unnamed buttons and SVGs were not reproduced on the
current process/document pages. No administration or participation submission was
performed during this live check.
