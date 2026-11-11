# ADR-0002: Domain model, identifiers and date precision

- **Status**: accepted (UUID migration lands in M1/M2)
- **Date**: 2026-11-12

## Context

The scaffold stores rows as property lists crossing the persistence API
(`(:name "..." :active 1)`), with `INTEGER PRIMARY KEY AUTOINCREMENT`
ids and free-text timestamps.  That is fine for CRUD demos but
insufficient for a medical records manager that must (a) stay stable
across import/export, (b) exchange data via HL7/FHIR later (M10), and
(c) order events when only part of a date is known ("in 2021", "March
2021", "2021-03-14 09:30").

## Decision

1. **Canonical records in `niori-core`** (new system, M1): `patient`,
   `document`, `observation`, `tag`, plus the `date-precision` enum
   `(:year :month :day :time :datetime)`.  Records are plain structs;
   modules convert plist rows ↔ records at their boundary so the
   repository/plist convention stays unchanged underneath.
2. **Identifiers become UUID strings.**  New migrations add a
   `uuid TEXT UNIQUE` column to every domain table and backfill existing
   rows; new records always get a UUID (generated with the CL UUID
   library from the pinned dist).  Integer ids remain internal primary
   keys; UUIDs are the external identity used by export/import and
   references between records.  Rationale: FHIR resource ids, HL7
   instance identifiers and handoff archives all need stable,
   globally-unique ids that survive re-numbering.
3. **Dates are ISO-8601 strings plus a precision field.**  `2021`,
   `2021-03`, `2021-03-14`, `2021-03-14T09:30` each carry an explicit
   precision; ordering compares within equal precision first, then
   falls back to the precision floor.  This matches FHIR `date` /
   `dateTime` semantics and avoids fake 01-01 timestamps.
4. **Terminology fields on coded records** (observations, medications,
   vaccinations): `code_system` / `code` / `code_display` (LOINC,
   RxNorm, CVX, ICD-10).  Free-text names stay as the human display;
   codes are optional but always present for imported data that has
   them.
5. **Provenance fields** where a record can be imported:
   `imported_from` (e.g. `hl7v2:ORU^R01`, `cda`, `fhir`),
   `source_document_id` (link to the stored `Document`), and
   `payload_sha256` pointing at the archived raw payload.  Original raw
   payloads are never discarded (medical-legal traceability).
6. **Search criteria** as a plain plist/record: title substring, tag,
   date range (with precision), mime type — implemented in M2/M3 on top
   of repositories, FTS later (M8).

## Consequences

- The plist convention at the persistence boundary is preserved, so no
  module breaks; the record layer is additive.
- Every domain table gains a migration (uuid, terminology, provenance
  columns) — done once, in M1/M2, before data accumulates.
- `niori-core` must not depend on CLOG/UI (see the layering rules in
  `AGENTS.md`); it is testable headlessly and reused by reports,
  exports and scripts.
