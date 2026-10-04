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
