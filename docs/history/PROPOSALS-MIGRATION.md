# Historical analysis: discarded Proposals target

This plan was written before the decision to implement independent Textwork. Its target tables and estimates are not the current implementation plan. See [the current plan](../MIGRATION.md).

# Migration from Enhanced Textwork 1.x

## Status

The same gem will carry the new implementation as version 2. Keeping the gem name makes dependency management and release history simpler; it does **not** migrate records automatically.

The current alpha supports new core Proposals components. It does not load the old `enhanced_textwork` manifest or its models. **Do not deploy it over a working 1.x installation.** No conversion task is included yet. The alpha removes the old implementation and installation migrations from the gem, but does not execute SQL to delete old tables. Historical migrations already copied into an application's `db/migrate` must be assessed separately, especially when recreating a database.

Legacy migration is a separate release requirement. First obtain a database/upload backup and a representative inventory. Neither a change of gem name nor a class alias from `Paragraph` to `Proposal` is sufficient: IDs can overlap, schemas differ and shared tables refer to the old class names.

## Read-only inventory

Run the following from the **old application's directory, using its Ruby and bundle**, without installing version 2 in that application:

```sh
RAILS_ENV=production bundle exec ruby /path/to/v2-checkout/bin/textwork-inventory /path/to/old-app/config/environment.rb > textwork-inventory.json
```

Use the application's normal environment and database configuration. Prefer a restored backup for the initial investigation. The script boots the application and performs read-only SQL queries. It reports:

- component IDs and their participatory-space IDs/types where `manifest_name = enhanced_textwork`;
- row counts for all `decidim_enhanced_textwork_*` tables;
- counts of references in shared string/text columns ending in `_type` that start with `Decidim::EnhancedTextwork::`.

It does not export document text, user names or credentials. It does include internal IDs. It is an inventory, **not a completeness check**: serialized/JSON references, GlobalIDs, event-class names, URLs and version payloads need a separate audit. Counts for tables are global, not per component. Application initializers still run when booting the old environment.

In a disposable v2 test application, the equivalent task is:

```sh
bin/rails decidim_enhanced_textwork:legacy:inspect
```

The report explicitly states `migration_supported: false` until a tested converter exists.

## Proposed conversion

Implement a resumable, explicit conversion with a persisted mapping from old model/ID to new model/ID. Never assume old paragraph IDs are available in the Proposals table. Copy and verify records before switching each component's manifest; keep source tables until acceptance and a separate cleanup decision.

| Existing data | Proposed target / work needed |
| --- | --- |
| Textwork component | Preserve component ID and participatory space; switch to `proposals` after conversion, enable participatory texts and Textwork view. Translate global and phase settings explicitly. |
| Paragraphs and document metadata | Core `Proposal` and `ParticipatoryText`; preserve translations, positions, section/article levels, publication dates, answers and authorship. Map old status values to the component's 0.32 proposal states. |
| Votes and temporary votes | Core proposal vote structures; remap paragraph IDs and validate uniqueness, ownership and counts. |
| Comments and replies | Keep comment IDs where possible; update both immediate and root commentable types/IDs, including amendment discussions. |
| Amendments | Core amendment relations using the mapped proposals, preserving amendment status and authors. |
| Shared relations | Audit coauthorships, follows, likes/old endorsements, moderations/reports, resource links, attachments, permissions, valuations and notes. Both endpoints of links may need conversion. |
| Versions, logs, notifications and jobs | Audit type columns, serialized payloads, GlobalIDs and event-class names. Preserve readable history and prevent old queued jobs from loading removed classes. |
| Categories/scopes and user groups | Reconcile with the application's Decidim taxonomy and user-group conversions; do not treat core upgrade tasks as converters for custom Paragraph records. |
| Collaborative drafts | No equivalent core feature in 0.32. Preserve them separately and decide explicitly between conversion to unpublished proposals, archival or a separate replacement. Never discard automatically. |
| Existing paragraph URLs | Redirect through the persisted ID mapping. Component IDs alone do not preserve old `/paragraphs/...` routes. |

The 0.32 checkout contains core migrations for proposal states, the endorsement-to-like rename, user-group conversion and removal of collaborative drafts. They target core data and do not establish compatibility for the old plugin's tables. The order of application upgrades and conversion must be rehearsed on a backup before running any potentially destructive core post-upgrade tasks.

## Acceptance before a migration release

1. Record the source plugin revision, Decidim version, schema and inventory. Cover the actual schemas in use; refuse unknown variants.
2. Take and restore database and upload backups. Keep the old application available for comparison.
3. Provide a dry run with mapping counts, unsupported records and conflicts. Abort on unresolved relationships or ID collisions.
4. Convert in transactions/checkpoints, without replaying participant notifications or changing original timestamps. Re-running must not duplicate data.
5. Compare counts and content per component and locale, threaded discussions, supports, amendments, attachments, moderation, permissions and readable history. Check links and both public/admin flows.
6. Rebuild derived counts/search only after source and target relationships have been verified.
7. Switch components only after validation. Keep a mapping report and rollback procedure. Do not remove source tables in the same release.

Until this exists, version 1 and version 2 serve different installation states. A new gem would still need the same conversion work, so this plan keeps the existing gem and uses a major version boundary.

## Complexity assessment, 2026-10-04

This is a source-based plan, not an implemented or rehearsed migration. No legacy installation database has been inspected. Actual usage, record counts, installed plugin revisions and local customizations are unknown. The decision between a supported converter and an archive-only upgrade is still open; the release requirements above describe the converter option, not a commitment to build it.

Reference points:

- Legacy plugin commit `7715beb8310b`, immediately before the v2 rewrite. Its migration files match tag `v1.0.3`; model code differs. This does not establish that any installation ran all those migrations.
- Current plugin commit `047abc7`, version `2.0.0.alpha1`.
- Decidim `release/0.32-stable` at `d514de311b1d3783f63b4fcb614c907180049845`, and the generated 0.32.1 schema in the local test application.

### What preservation means

Distinguish three outcomes before promising an upgrade:

1. **Continue participation:** existing documents, paragraphs, comments, supports and amendments remain usable, with their authors, permissions, publication states and timestamps.
2. **Preserve all existing records:** retain source values, associations and historical payloads, including information with no supported target feature. Some records may only be accessible through a restricted archive.
3. **Retain every old feature:** also recreate collaborative-draft workflows and historical interfaces. This requires product development beyond database migration and is not part of the narrow Proposals extension.

The full-preservation option below combines the first two. It cannot recover records already deleted before the source backup. Keeping inaccessible rows in abandoned tables is not sufficient evidence of a usable archive.

### Concrete source-to-target mapping

After the known legacy migrations, seven plugin tables are expected. Older reports and endorsements were moved into shared tables by previous plugin migrations. Unexpected remaining tables or columns require investigation rather than automatic deletion.

| Source table suffix after `decidim_enhanced_textwork_` | Target | Conversion and difficulty |
| --- | --- | --- |
| `paragraphs` | `decidim_proposals_proposals` | Copy every record, including unpublished and withdrawn paragraphs and amendment proposals. Preserve localized title/body/answer, position, section level, reference, publication/answer dates, costs, execution period and geographic data. Allocate new IDs. Medium. |
| `participatory_texts` | `decidim_proposals_participatory_texts` | Copy localized title/description and timestamps; retain component association. Check missing or multiple metadata records and conflicts in the target. Low. |
| `paragraph_votes` | `decidim_proposals_proposal_votes` | Map `decidim_paragraph_id` to `decidim_proposal_id`, retain voter, timestamps and `temporary`. The latter is a column, not a separate temporary-votes table. Check uniqueness per proposal/voter. Low to medium. |
| `paragraph_notes` | `decidim_proposals_proposal_notes` | Remap paragraph and author references, preserve private note text and timestamps. The target's additional `parent_id` remains empty for legacy notes without threading. Low to medium. |
| `valuation_assignments` | `decidim_proposals_evaluation_assignments` | Remap paragraph IDs and `valuator_role_*` to `evaluator_role_*`; verify that each space role still exists and has the intended permissions. Medium. |
| `collaborative_drafts` | Restricted legacy archive; optional separate conversion | No equivalent Proposals table in 0.32. Retain text, states, authors, requests, comments, attachments and history. Converting an open draft into an unpublished proposal changes its collaboration workflow and requires an explicit decision. High if used. |
| `collaborative_draft_collaborator_requests` | Same archive, linked to its draft | Preserve requests and users. An unpublished proposal has no equivalent request-access workflow. Medium if archived, high if recreated. |

Published collaborative drafts may already have produced paragraphs linked by `created_from_collaborative_draft`. Preserve that provenance; do not import the same published work a second time.

Paragraph states need an explicit conversion:

| Legacy value | Target treatment |
| --- | --- |
| `nil` / `not_answered` | No proposal-state association; preserve any answer/publication metadata for consistency checking. |
| `evaluating`, `accepted`, `rejected` | Create or find the matching **component-specific** proposal state and assign its ID. Preserve `state_published_at`, including an unpublished answer. |
| `withdrawn` | Set `withdrawn_at`. The old schema has no dedicated withdrawal timestamp; derive it from a trustworthy historical event where available. Otherwise use a documented fallback, such as the core migration's `updated_at` approach, while retaining the original state in the archive. Do not claim the fallback is an exact historical date. |
| Anything else | Stop and report the custom value. Do not silently map it to unanswered. |

The original HTML and translations must be retained before any rich-text conversion. Verify headings, lists, embedded media, internal links and mentions in the target editor; a text-only export/import is not lossless.

### Shared records are the main migration work

In an in-place installation upgrade, retain shared record IDs where possible and change their resource references through the mapping. This avoids rebuilding comment threads and comment-vote relationships unnecessarily.

| Data | Required handling |
| --- | --- |
| Comments and replies | For comments directly on a paragraph, update `decidim_commentable_type/id`. For the entire thread, update `decidim_root_commentable_type/id`. Replies whose immediate parent is another comment keep that parent. Preserve comment IDs, votes, authors, alignment, timestamps, moderation and deletion state. |
| Amendments | Keep the amendment record and its state; remap **both** `decidim_amendable_type/id` and `decidim_emendation_type/id`. An amendment's replacement text is another paragraph record. Preserve its own discussions and supports too. |
| Coauthorships and groups | Remap the coauthorable resource and reconcile old user-group authorship with the core upgrade. Preserve the original acting user and group relationship in the protected snapshot even where the new model no longer exposes both. |
| Follows, likes, moderation, reports | Remap resource references without recreating participants' actions. Legacy endorsements map to likes, while paragraph supports map to proposal votes; do not merge these concepts. Reports normally retain their moderation association. Hidden content must remain hidden. |
| Attachments | Remap resource ownership, preserve attachment IDs where possible and verify the corresponding blobs/files and collections. Include direct Active Storage references if present in the source installation. A database dump alone does not contain uploaded files. |
| Resource links | Map both endpoints and inspect relation names. For example, `paragraphs_from_meeting` and `included_paragraphs` are not understood merely by changing IDs; their core equivalents and behavior require explicit mapping. Check links from other components, such as accountability results. |
| Permissions and settings | Transform action names such as `endorse` to the target equivalent where required. Keep verification restrictions and phase-specific blocks. Never let missing keys silently grant broader access. |
| Categories, scopes and taxonomies | Preserve source associations, reconcile them with the installation's taxonomy conversion, and configure target filters. A renamed resource type alone does not create the new taxonomy associations. |
| Versions and action logs | Audit `versions.item_type/item_id`, `object`, `object_changes`, any older serialized payloads, and action-log resource references/`extra`. Retain original snapshots. A blind class-name replacement does not make historical state fields compatible with current proposal history views. Use explicit historical transformations or a read-only legacy history viewer. |
| Notifications and background jobs | Inspect resource types, event classes, event names, embedded GlobalIDs and job arguments. Map supported records; preserve unsupported historical notifications in an archive or provide compatibility rendering. Drain or quarantine old jobs before switching. Do not replay notification delivery during conversion. |
| Other persisted references | Audit search entries, rich-text links, custom integrations, gamification and metric names. The legacy engine registered paragraph-specific badges and metrics. Preserve historical data, then decide which derived values can be recalculated as core proposal values. |

The existing inventory only counts plugin tables and matching `_type` columns. Extend it to report per-component relationships and inspect the named payloads before treating it as a migration preflight. Do not run unrestricted search-and-replace over all database strings.

### Settings must be translated, not copied wholesale

Retain component IDs, names, participatory spaces, publication state, ordering and original settings snapshots. Switch `manifest_name` from `enhanced_textwork` to `proposals` only after conversion and validation.

Known examples from the two manifests:

- `paragraph_limit`, `paragraph_length`, `paragraph_edit_time`, `threshold_per_paragraph`, `paragraph_answering_enabled` and `official_paragraphs_enabled` need their corresponding proposal keys.
- `paragraph_edit_before_minutes` becomes the target `edit_time` value with minutes as its unit.
- `can_accumulate_supports_beyond_threshold` becomes `can_accumulate_votes_beyond_threshold`.
- `endorsements_enabled/blocked` become `likes_enabled/blocked` in phase settings.
- `hide_participatory_text_titles_enabled` maps to `textwork_hide_numbered_titles`; enable `enhanced_textwork_enabled` for documents using the new view.
- Preserve comment/support/amendment settings, including visibility and blocked phases. The old and current manifests have different defaults, including amendment enablement; relying on defaults would change behavior.
- Validate old sort values, wizard texts, scope settings and settings without a target counterpart. Retain obsolete values in the archive and report their loss of active behavior.
- Check whether every source component actually uses participatory texts. The old manifest allowed that feature to be disabled; do not reinterpret an ordinary paragraph collection as a structured document without a decision.

### Proposed implementation units

Prefer a versioned, explicitly invoked conversion task over an automatic bulk conversion during normal application startup or deployment. Schema migrations only create the supporting tables; data transformations belong in a separately orchestrated migration service or data tasks.

1. **Migration bookkeeping schema.** Add a runs table and a mapping table, with source installation identity, component, old model/ID, target model/ID, source revision/schema fingerprint, converter version, checkpoint, counts and checksums. Enforce uniqueness on the source identity/model/ID and check conflicting target assignments. Persist mappings for old-URL resolution. Include `db` files in gem packaging if this gem ships the schema migrations; the current gem file list excludes them.
2. **Preservation snapshot.** Before transformations or destructive core upgrades, retain complete source rows and affected shared rows, including settings and serialized history. Use a restricted, versioned archive with a manifest and checksums, or dedicated archive storage with a defined reader. Keep this data out of Git. Back up the complete database and uploads independently.
3. **Document conversion.** Allocate target IDs, create component states and copy document metadata and every paragraph variant. Do not trigger application create/publish commands, timestamp updates, mail, traceability events or automatic position changes.
4. **Participation conversion.** Copy votes, private notes and evaluation assignments. Remap comments, amendments, authorship and remaining shared relations through explicit adapters. Include references from other components. Stop on unresolved references, duplicate votes or unknown state/permission mappings.
5. **History and compatibility.** Transform supported historical records, expose retained legacy-only data under appropriate access controls, and add redirects for old paragraph, comparison, version and document links. Do not redirect an old write action in a way that repeats it. Include API consumers and embeds in the compatibility review.
6. **Validation and activation.** Recompute derived counters/search, compare source and target, and switch the component manifest/settings in a controlled transaction. Mark the run accepted only after browser checks of public and administrative behavior.

For each unit, define restart behavior and failure recovery. A restart must use persisted mappings rather than infer completion from the presence of some target rows. Check that source records have not changed since the snapshot. Never silently skip records that failed a model validation.

The exact number of Rails migration files is not the effort driver. The likely schema work is one or two small migrations for bookkeeping/archive storage; most work is data conversion, compatibility and verification. No table drop belongs in the initial migration release.

### Order relative to the Decidim upgrade

Do not run the current alpha over a live legacy installation and hope that core migrations will convert it. The old plugin also cannot simply be loaded unchanged under 0.32.

The preferred investigation path is an offline conversion on a restored installation, targeting the final 0.32 schema, with a preservation snapshot taken **before** upgrading. A temporary compatibility layer may be necessary while framework tasks inspect old component manifests or constantize legacy resources. This layer must be tested; it does not currently exist.

The framework upgrade and the Textwork conversion need one combined runbook. Choose the intermediate releases from the actual source version. For each checkpoint, record schema migrations, data migrations, explicit upgrade tasks and what information must have been preserved or transformed before them. An alternative is to convert to that source release's core Proposals first and let subsequent core migrations handle its records; this introduces an additional target adapter and still does not preserve collaborative drafts automatically.

Specific ordering constraints found in the inspected source:

- The user-group authorship task lists `Decidim::Proposals::Proposal` as its coauthorable model. It does not list Textwork paragraphs or drafts. Later migrations remove old group columns and membership tables. Capture those values early and either convert before the relevant task or perform an explicit equivalent conversion from the snapshot. Do not blindly rerun the entire task sequence.
- Default proposal-state creation selects components whose manifest is already `proposals`. Components converted later require their own state initialization.
- The WYSIWYG task registers core Proposals, not Textwork paragraphs. Determine whether migrated content still needs conversion and apply the matching converter once to the affected records.
- Core 0.32 removes **core Proposals** collaborative-draft tables and later deletes references with the core collaborative-draft type. This does not itself prove that custom Textwork tables are deleted. However, mapping Textwork drafts temporarily to that removed type would expose them to that cleanup. Preserve them separately.

For the real cutover, stop writes and affected workers, take the final consistent backup, execute the rehearsed sequence, validate, and only then reopen participation. Initial rehearsals must not send mail or connect to production storage for writes.

Retaining source tables alone is not a rollback: shared comments and other relations have already been changed. Before reopening writes, restore the full database/files and matching old application release on failure, or use a fully tested reverse mapping with shared-row snapshots. After new participation has been accepted, a restore would lose those new actions; recovery then needs a separate reconciliation plan.

### Acceptance evidence

Test a fixture with existing core proposals whose IDs overlap legacy paragraph IDs, multiple components/organizations, multiple locales, headings, unpublished and withdrawn records, final/temporary supports, moderated/deleted comments, nested replies and comment votes, every amendment state, group authors, private notes, attachments, taxonomy assignments, history and draft provenance.

For each component, compare:

- Record counts by kind and state, not only visible paragraphs.
- Exact source text/translation checksums in the preservation archive; for deliberate editor transformations, compare structured content and manually inspect rendering as well.
- Voter identities and temporary flags, original/amendment relationships, thread roots/parents, authors and original timestamps.
- Attachment file checksums, permission restrictions, publication/moderation states, and private/public boundaries.
- Every old resource reference: it must resolve to the mapped target or an explicitly indexed archive item. Unsupported references are a blocking report, not accepted omissions.
- Functional reading, commenting, supporting/unvoting, proposing/discussing amendments and administrative answering after migration; old links and retained history must also work as agreed.
- A second execution makes no duplicate records or new participant notifications. Injected interruptions resume safely, and a backup restore has been exercised.

Synthetic tests do not replace at least one rehearsal on a representative restored legacy database. The existing 32 plugin tests cover the new implementation, not a 1.x upgrade.

### Effort and decision options

These are engineering estimates, not measured runtimes or fixed offers. A person-day means a day of implementation/review/testing effort. They exclude upgrading the rest of an installation, unrelated plugins, deployment coordination, and developing a replacement collaborative-draft feature. Data volume mainly changes rehearsal/runtime planning; schema variants and historical features change development effort.

| Option | Expected result | Rough effort |
| --- | --- | --- |
| Inventory and decision | Inspect one accessible representative backup; confirm features in use, schema and preservation requirements. | 0.5–2 person-days, assuming backup and environment are available. |
| Scoped converter | One known source schema; continue documents, comments, supports and amendments plus actually used relations. Preserve unsupported history separately under an agreed archive contract. Includes tests and one rehearsal. | 10–18 person-days, subject to inventory. |
| Reusable comprehensive migration | Cover supported legacy variants, extensive historical/shared references, group conversion, restricted archive access and compatibility/redirects, with recovery tests. | 20–40 person-days; unusual integrations can exceed this. |
| Archive one installation, then start fresh | Verified database/files backup plus readable text/comment/amendment exports and documented deactivation. No continuation of those documents in v2. | 1–3 person-days if existing exports suffice; a new reusable archive exporter may add 3–7 days. |

The converter estimates are alternative total scopes, not amounts to add together. A promise to retain every old interactive workflow needs a separate specification and estimate.

Recommendation: do not build the comprehensive converter speculatively. First ask maintainers/operators whether any installation still uses Textwork and obtain an inventory where possible. Local source code or download numbers cannot establish that nobody uses it. If one real installation needs continuation, scope the converter to its observed schema and data, then decide whether to generalize it.

### Archive-only release option

This is a legitimate product choice, but it must be documented as a breaking change rather than called a data migration. Suggested release wording:

> Version 2 does not migrate Textwork 1.x components. Existing textworks will no longer be accessible or editable through the new plugin. Before upgrading, export the documents, discussions and amendments and verify a complete database and uploaded-file backup. Version 2 does not itself delete the old Textwork tables, but their presence does not make those records usable in the new application.

The minimum archive procedure would be:

1. Produce and restore-test a complete database backup with uploads and the source code/dependency versions needed to interpret it. Keep operational secrets outside the published archive.
2. While the old application still works, export documents in every relevant language, structure/order, discussions and amendment decisions, with authorship/timestamps and relevant support totals. Save attachments as files, not just counts or remote URLs. Confirm coverage against the database.
3. Separate the readable public record from restricted material such as drafts, hidden content, private evaluation notes and voter-level records. Full technical preservation does not mean publishing all stored information.
4. Keep a machine-readable preservation package for information absent from the readable export, including original IDs and relationships. Existing CSV/JSON/Word exports are not database-complete backups: the old paragraph serializer contains counts for comments/attachments/followers, and the component export filters to published paragraphs. A separate comments export still does not cover all legacy records.
5. Make the archive locatable and define old-link handling. Prevent legacy components from breaking component lists, navigation, exports, search or notifications after the gem change. Merely unpublishing a component does not remove all shared references; test a small compatibility/archive handler or explicit decommissioning process.
6. Start new work in v2 Proposals components. Do not automatically delete old components with cascading callbacks or remove their tables as part of this release. Any later cleanup is a separate decision after archive acceptance.

A small upgrade guard should detect legacy components, tables with records and shared legacy references and fail with a clear message unless a supported conversion or explicit archival path has been completed. The existing inventory can inform this guard but is not itself a guard. It is useful even if no converter is built.

Keeping the same gem with a major version change remains reasonable for either option. A new gem would not remove the data-conversion or decommissioning work; it would mainly change packaging and installation instructions.

### Source pointers for review

- Legacy models, migrations, component settings and exports: [plugin tree at 7715beb](https://github.com/DecidimAustria/decidim-enhanced_textwork/tree/7715beb8310b).
- [Current legacy inventory](../../lib/decidim/enhanced_textwork/legacy_inventory.rb) and [current integration](../../lib/decidim/enhanced_textwork/engine.rb).
- [Core proposal-state initialization](https://github.com/decidim/decidim/blob/d514de311b1d3783f63b4fcb614c907180049845/decidim-proposals/db/migrate/20240110203504_create_default_proposal_states.rb).
- [Core withdrawal conversion](https://github.com/decidim/decidim/blob/d514de311b1d3783f63b4fcb614c907180049845/decidim-proposals/db/migrate/20240110203500_add_withdrawn_at_field_to_proposals.rb).
- [User-group authorship upgrade](https://github.com/decidim/decidim/blob/d514de311b1d3783f63b4fcb614c907180049845/decidim-core/lib/tasks/upgrade/user_groups_migration.rake) and [subsequent removal of group columns](https://github.com/decidim/decidim/blob/d514de311b1d3783f63b4fcb614c907180049845/decidim-core/db/migrate/20260208201405_remove_user_group_core.rb).
- [Rich-text upgrade registrations](https://github.com/decidim/decidim/blob/d514de311b1d3783f63b4fcb614c907180049845/decidim-core/lib/tasks/upgrade/decidim_migrate_wysiwyg_content.rake).
- [Core collaborative-draft table removal](https://github.com/decidim/decidim/blob/d514de311b1d3783f63b4fcb614c907180049845/decidim-proposals/db/migrate/20250515132352_drop_collaborative_drafts_tables.rb) and [reference cleanup](https://github.com/decidim/decidim/blob/d514de311b1d3783f63b4fcb614c907180049845/decidim-proposals/db/data/20260224210316_remove_collaborative_drafts_references.rb).
