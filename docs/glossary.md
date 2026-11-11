# Niori glossary

## Platform terms

- **Module** — an independent ASDF system that registers extensions at
  load time and is listed in `config/modules.lisp`.
- **Command** — a registered unit of user action (`register-command`)
  with menu path, optional toolbar button, optional global shortcut and
  a handler of one argument (the session).
- **View type / view** — an editor-area content type
  (`register-view-type`); views open as tabs or split panes via
  `open-view`.
- **Navigation entry** — a node in the navigator tree
  (`register-navigation`), optionally with children.
- **Service** — a named function registered in the service registry
  (`provide-service`), the equivalent of a Lookup entry.
- **Repository** — a named logical table owned by a module
  (`register-repository`); rows cross the API as property lists.
- **Migration** — a versioned, per-module schema step
  (`define-migration`), applied inside a transaction and recorded in
  `niori_schema_migrations`.
- **Store** — the persistence backend instance implementing the
  `store-*` protocol; the platform holds the contract, `niori-infra`
  ships the SQLite implementation.
- **Session** — one connected browser client; handlers receive it as
  their single argument.
- **Event bus** — `subscribe`/`publish` decoupled messaging; powers
  notifications, logs and sync status.
- **Background task** — a periodic function on its own thread
  (`register-task`) with isolated error handling.

## Medical / domain terms

- **Patient** — the person the records belong to (single-user app; a
  minimal demographic record kept for interoperability).
- **Document** — a stored file (PDF, image, …) with metadata: title,
  mime type, SHA-256, date added, date of record, tags.
- **Observation** — a clinical measurement or finding with a value,
  unit, timestamp and **date precision** (year / month / day / time /
  datetime) — e.g. HbA1c 7.2 %.
- **Medication** — a drug with strength, schedule, prescriber, active
  flag.
- **Doctor visit** — an encounter: date, reason, findings, plan.
- **Test result** — a laboratory or diagnostic result, possibly linked
  to a document.
- **Vaccination** — an immunization event: vaccine, date, dose, lot.

## Interoperability terms (M10)

- **HL7 v2.x** — pipe-delimited messaging standard (e.g. `ORU^R01` for
  lab results); segments `MSH`, `PID`, `OBR`, `OBX`.
- **C-CDA** — Consolidated Clinical Document Architecture: XML clinical
  documents (continuity-of-care documents, discharge summaries).
- **FHIR R4** — HL7's JSON/REST resource standard; resources used by
  Niori: `Patient`, `Observation`, `DiagnosticReport`,
  `MedicationRequest`, `MedicationStatement`, `Immunization`,
  `Encounter`, `DocumentReference`.
- **LOINC** — code system for laboratory observations.
- **RxNorm** — code system for medications (US).
- **CVX** — code system for vaccines.
- **ICD-10** — diagnosis code system.
- **Provenance** — where a record came from: `imported_from`,
  `source_document_id`, `payload_sha256`.
