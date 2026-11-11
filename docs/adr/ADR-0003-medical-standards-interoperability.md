# ADR-0003: Medical standards interoperability (HL7 v2, CDA, FHIR)

- **Status**: accepted (implementation in M10; forward-compatible fields
  land in M1/M2)
- **Date**: 2026-11-12

## Context

Niori must, in the future, exchange medical documentation using HL7 and
other respective standards.  The realistic landscape for a personal,
single-user records manager:

- **HL7 v2.x** — pipe-delimited messages, still how most labs and
  practices emit results (`ORU^R01`), demographics (`ADT^A01/A08`).
- **C-CDA** — XML clinical documents patients receive after visits or
  for continuity of care.
- **FHIR R4** — JSON resources; the modern exchange and API standard.
- **Terminologies** — LOINC (labs), RxNorm (medications), CVX
  (vaccines), ICD-10 (diagnoses).

There is no mature Common Lisp library for any of these standards, and
none is needed for the subset Niori requires: v2 is a simple delimited
format, CDA is XML, FHIR is JSON with published schemas.

## Decision

1. **Exchange is module work, not platform work.**  Importers/exporters
   are ordinary Niori modules (`niori-mod-import-hl7v2`,
   `niori-mod-import-cda`, `niori-mod-fhir-export`,
   `niori-mod-fhir-import`) registered like any other module and
   disabled by simply removing a line from `config/modules.lisp`.  They
   provide `import-service` / export commands; nothing in
   `niori-platform` knows the standards exist.
2. **Domain mapping (FHIR R4 as the canonical external model):**

   | Niori domain | FHIR R4 resource(s) | HL7 v2 | C-CDA section |
   |---|---|---|---|
   | Patient | `Patient` | `PID` | header |
   | Observation (test result value) | `Observation` / `DiagnosticReport` | `OBR`/`OBX` | Results |
   | Medication | `MedicationRequest`, `MedicationStatement` | `RDE`/`RXA` segments | Medications |
   | Doctor visit | `Encounter` (+ `Procedure`) | `ADT`/`PR1` | Encounters |
   | Vaccination | `Immunization` | `RXA` | Immunizations |
   | Document (file) | `DocumentReference` + `Binary` | N/A (attach) | document body |

3. **Import protocol** (all importers follow it):
   1. parse → 2. map to `niori-core` records with terminology codes when
   present → 3. persist via repositories with provenance
   (`imported_from`, `source_document_id`, `payload_sha256`) → 4. archive
   the original raw payload as a `Document` (or a dedicated archive
   store) → 5. publish an event bus announcement so open views refresh.
   Dedupe by payload SHA-256 plus a semantic key (e.g. observation type
   + timestamp + value).
4. **Export protocol**: build a FHIR R4 JSON `Bundle` from the selected
   scope (patient summary, date range), write to a user-chosen file;
   validation happens offline against FHIR JSON schema fixtures in the
   test suite.  HL7 v2 export and CDA generation are out of scope for
   1.0 — consumers of v2/CDA are institutions, and FHIR is the
   direction they accept.
5. **Privacy invariant**: Niori makes no network calls by default.  All
   exchange is file-based and user-initiated; any future FHIR *server*
   sync (via `dexador`) must be an explicit, consent-gated action with
   the endpoint shown in the UI.
6. **Forward compatibility done now** (pulled into M1/M2, per ADR-0002):
   UUID identifiers, ISO-8601 dates with precision, terminology code
   columns, provenance columns, raw payload archiving.  With these in
   place M10 is additive: parsers + mappers + UI, no schema rework.

## Consequences

- Small, owned parsers beat nonexistent dependencies: golden fixture
  files (real-world-shaped `ORU^R01` samples, a C-CDA extract, FHIR
  bundles) become the test spec.
- The mapping table above is the single reference for implementers; it
  belongs in code review for every M10 card.
- If a standards profile demands things Niori's model lacks (e.g.
  practitioners as first-class records), the domain model gains them
  via ADR before the mapper is written — the mapper never invents
  silent transformations.
