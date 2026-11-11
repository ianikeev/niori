# Niori documentation

All project documentation lives in the repository and is loaded at the
start of every working session (see `AGENTS.md`).  These files are part
of Niori and share its license, GPL-3.0-or-later.

| Document | Purpose |
|---|---|
| [ROADMAP.md](ROADMAP.md) | Implementation plan adapted from the NetBeans Platform outline to this CLOG/Common Lisp codebase: conventions, concept mapping, milestones M0–M10, exit criteria, risks |
| [adr/ADR-0001-technology-stack-and-storage.md](adr/ADR-0001-technology-stack-and-storage.md) | Toolchain pin, SQLite binding, encryption decision |
| [adr/ADR-0002-domain-model-and-identifiers.md](adr/ADR-0002-domain-model-and-identifiers.md) | Domain records, UUID identifiers, date precision |
| [adr/ADR-0003-medical-standards-interoperability.md](adr/ADR-0003-medical-standards-interoperability.md) | HL7 v2 / C-CDA / FHIR R4 exchange strategy |
| [glossary.md](glossary.md) | Platform and medical terminology |
| [task-cards/TEMPLATE.md](task-cards/TEMPLATE.md) | Task card template (one small unit of work per card) |

Decision records follow a lightweight format: context → decision →
consequences → status.  Superseded ADRs stay in place with their status
changed.
