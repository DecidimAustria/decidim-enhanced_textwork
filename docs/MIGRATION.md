# Migration to independent Textwork

## Current status

The target is now **Textwork 2.0.0.alpha2**, an independent `textwork` component on Decidim 0.32.1. The earlier proposal to migrate to core Proposals is superseded. Its [detailed analysis](history/PROPOSALS-MIGRATION.md) remains as historical evidence of the source-data complexity, not a current conversion recipe or estimate.

**No legacy converter is implemented. Do not install this alpha over a working Textwork 1.x installation.** The new code does not register the old `enhanced_textwork` manifest or old `Paragraph` class. Old data is not automatically deleted, but it is not automatically usable either. The new tables and models are deliberately distinct from the old ones.

Keeping the gem name does not transfer data. The independent architecture and these planning changes do not decide whether a general converter is worth building. Establish actual usage and obtain a representative backup first. Export/archive-only remains an explicit alternative.

## Target mapping

| Source | New target / required treatment |
| --- | --- |
| Legacy component and document metadata | `textwork` component and `Document`; translate settings and preserve component identity where safe. Never switch the manifest before source data and references are validated. |
| Paragraphs and headings | Stable `Section` plus an initial `Revision`; preserve translations, order and hierarchy. Old answers, costs and status values need an agreed mapping or an indexed archive, because the new model does not use Proposal states. |
| Historical paragraph versions | Reconstruct immutable `Revision` records where reliable, retain raw source payloads, and build document snapshots only where their composition can be established. Do not fabricate historical document versions. |
| Paragraph supports | `Support` pointing to the exact target revision where it can be established. Old supports usually refer to a paragraph, not a recorded revision; preserve that uncertainty explicitly. Attaching them to the imported current snapshot is a policy decision, not proof that participants supported that precise wording. Preserve temporary votes separately until their target semantics are agreed. |
| Amendments and replacement paragraphs | Own `Amendment`, linked to the mapped section and a justified base revision, with discussion, author, state and decisions preserved. Old Core amendment IDs and replacement-paragraph IDs need separate mappings. |
| Comments and replies | Keep IDs where possible and remap immediate/root commentable references to `Section` or the new `Amendment`. Preserve votes, authors, timestamps, moderation and deletion states. |
| Follows, moderation, attachments and resource links | Map resource type/ID pairs and both link endpoints; retain files and access controls. Features without a current administration flow need explicit archival or implementation before promising continued usability. |
| Internal notes, evaluation assignments, old answers and removed settings | Preserve in a restricted, indexed archive unless a dedicated corresponding feature is implemented. They must not silently become public comments or disappear. |
| Collaborative drafts and access requests | Preserve separately with authorship, discussions, files and provenance; the new module does not recreate that old collaboration workflow. |
| Logs, notifications, jobs, groups and taxonomy relations | Audit and transform or archive explicitly. Neither the core upgrade nor a string replacement is sufficient for old custom types and serialized references. |

The user's approved behavior for newly created data is that support applies to a specific text revision and only administrators decide amendments. A legacy conversion must document where old records lack the information needed to establish those semantics.

## Conversion sequence if a real installation needs it

1. Inventory exact source versions, schema variants, counts per component, used features, shared references, serialized history and file storage. Read the source before framework migrations remove group or historical information.
2. Restore-test a complete database/upload backup and retain an immutable source snapshot and source code/dependency versions.
3. Create a persisted mapping keyed by source installation, old type and ID, with target type/ID, checksums and progress. IDs can collide with existing target data.
4. Convert documents, sections, revisions and amendments, then remap participation and shared relationships. Refuse unsupported records and ambiguous historical relationships unless an explicit archival policy resolves them.
5. Preserve unsupported data in an accessible, permission-controlled archive. Provide old-link resolution from the mapping. Do not replay notifications or alter historical timestamps.
6. Reconcile counts, texts, identities, threaded comments, supports, amendment decisions, files and privacy. Test restart/idempotency, interrupted execution and restore recovery on a representative backup.
7. Switch components and reopen participation only after acceptance. Keep source tables and snapshots. A rollback needs the original shared rows as well, not just the old plugin tables.

The exact framework-upgrade order depends on the actual source release. Group-authorship transformations and destructive core tasks need a combined runbook. No universal runnable upgrade sequence is claimed here.

## Read-only inventory

The existing inventory is still usable from the old application's own Ruby/bundle:

```sh
RAILS_ENV=production bundle exec ruby /path/to/v2-checkout/bin/textwork-inventory /path/to/old-app/config/environment.rb > textwork-inventory.json
```

It reports old component IDs, legacy table counts and matching shared `_type` references. It does not export content and is **not** a completeness check for JSON/serialized history, GlobalIDs or URLs. Its `migration_supported` value remains false. Application initializers run when the old environment boots; prefer a restored backup.

## Alpha1 prototype and localtest

The Proposals-based alpha1 remains on `feature/proposals-textwork-2.0`, commit `dff08cb`. Alpha2 does not convert its core Proposal records. They remain in their original tables/components, with their comments and supports unchanged. The old added `/textwork` routes are no longer provided by the independent plugin; ordinary core Proposals routes remain available in an application that installs Proposals.

The local test application creates separate independent example/import components. Its new seed marker preserves both the old examples and later edits to the new examples. This is a local demonstration setup, not an alpha1 or 1.x migration.

## Archive-only option and effort

If no operator needs continued editing, document a breaking upgrade with a verified readable archive and a complete technical backup. Existing Word/CSV/JSON exports alone are not complete backups. Include all relevant languages, discussions and amendments, keep uploaded files, and separate public records from private notes, hidden content, voter identities and drafts. Test deactivation of old components and their references so they cannot break the new application's menus, search or notification rendering. Do not call inaccessible rows an archive.

The earlier 10–18 / 20–40 person-day ranges described conversion into Proposals and are **not confirmed estimates for this target**. Independent Textwork needs different mappings, particularly for support revisions and unsupported administrative data. Retain the initial inventory timebox of approximately 0.5–2 person-days for one available representative backup; estimate implementation after the data contract and archive boundary are known.

No legacy conversion or deletion is authorized by this plan. The current change implements the independent module and local test setup only.
