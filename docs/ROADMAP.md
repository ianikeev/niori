# Niori Implementation Roadmap

Adapted from the original NetBeans Platform 31 / Java 24 / Maven plan for
Niori to the **current codebase**: a modular desktop application built on
**CLOG + Common Lisp (SBCL)** with ASDF systems instead of Maven modules.

Source of truth is the tree this file lives in.  Earlier iterations of the
scaffold are history and are deliberately not referenced anywhere in these
documents; where this roadmap says "exists", it means "exists in this tree
today".

Status markers per milestone: `[done]`, `[partial]`, `[todo]`.

---

## 1. Global conventions (adapted)

| NetBeans plan | Niori (this repository) |
|---|---|
| NetBeans Platform 31, pinned in `pom.xml` | CLOG + clog-gui from a **pinned Quicklisp dist** — current pin: `2026-01-01` (see ADR-0001) |
| JDK 24 (Temurin) | SBCL 2.x (minimum version and CI install method in ADR-0001) |
| Maven multi-module + `nbm-maven-plugin` | ASDF systems: `niori` (umbrella) → `niori-app` → `niori-ui`, `niori-infra`, `niori-platform`, plus one independent system per module under `modules/` |
| Base package `org.niori` | CL packages `niori-platform`, `niori-infra`, `niori-ui`, `niori-app`, `niori-mod-*` (already in place) |
| FlatLaf look and feel | `static-files/css/niori.css` on a W3.CSS base |
| SQLite + SQLite3MultipleCiphers via Java FFM | Quicklisp `sqlite` CFFI binding (CLOG dependency) against system libsqlite3; encryption via a cipher-enabled libsqlite3 build — spike + ADR-0001 decision |
| JUnit 5, AssertJ, jqwik, ArchUnit, JaCoCo, Failsafe, PDFBox | Parachute suites wired to `asdf:test-op`; an **ASDF/package dependency lint test** as the ArchUnit equivalent; golden-master PDF checks with `pdftotext`/PDFBox in CI. Honest note: there is no jqwik-grade property-testing framework in CL; generated examples are hand-rolled |
| Groovy via JSR-223 | **Not needed** — the application *is* Common Lisp.  M7 shrinks to an in-app script console and script library |
| JasperReports | HTML/CSS print templates rendered to PDF by headless Chromium (`--print-to-pdf`); `cl-pdf` kept as fallback.  Decision + rationale in ADR when M6 starts |
| `jpackage` installers | `sb-ext:save-lisp-and-die` executable + bundled `static-files/`; AppImage on Linux, Inno Setup or zip on Windows |
| GitHub Actions `ubuntu-latest` + `windows-latest` | Same matrix.  SBCL + Quicklisp installed by the workflow; tests run headless; a smoke job boots the server with `:auto-open nil` and HTTP-fetches the shell markup |

Storage backend note: the tree already depends on the `sqlite` system (the
CFFI binding that CLOG itself depends on), *not* `cl-sqlite` — every SQL
statement goes through bound parameters in `src/infra/store.lisp`.

## 2. NetBeans Platform concept → Niori mapping

This is the dictionary to use when reading the original plan or any
NetBeans documentation.

| NetBeans Platform concept | Niori implementation | Where in this tree |
|---|---|---|
| Module system (NBM) | `define-module` / `start-all-modules`; each module is an independent ASDF system listed in `config/modules.lisp` | `src/platform/modules.lisp`, `modules/*/` |
| Lookup / `@ServiceProvider` | `provide-service` / `lookup-service` | `src/platform/services.lisp` |
| Actions, `@ActionReference`, shortcuts | `register-command` with `:menu-path`, `:shortcut`, `:toolbar`, `:enabled-fn` | `src/platform/commands.lisp` |
| `@TopComponent.Registration` (editor mode) | `register-view-type` + `open-view` — tabs and split views in the editor area | `src/platform/view-types.lisp`, `src/ui/editor.lisp` |
| `@TopComponent.Registration` (floating) | `open-window` — draggable, closable clog-gui windows, cascaded | `src/platform/hooks.lisp`, `src/ui/windows.lisp` |
| Nodes / ExplorerManager / BeanTreeView | `register-navigation` tree with children | `src/platform/navigation.lisp`, `src/ui/navigator.lisp` |
| PropertySheet | `set-properties` | `src/ui/properties.lisp` |
| StatusLineElementProvider | `set-status` + sync status from the event bus | `src/ui/statusbar.lisp` |
| Output Window / IOProvider | `notify` (toasts/notifications) and `log-line` (log tab) | `src/ui/output.lisp`, `src/platform/events.lisp` |
| Options dialog | `config/niori.conf` + `niori-infra:config-get`; dialog planned in M3 | `src/infra/config.lisp` |
| `layer.xml` registrations | Direct registration calls executed when the module system loads | `modules/*/` |
| `ModuleInstall` / `@OnStop` | `define-module :start-fn / :stop-fn`, `register-task`, `niori-app:start` / `niori-app:stop` | `src/platform/modules.lisp`, `src/platform/tasks.lisp`, `src/app/app.lisp` |
| EventBus / MessageManager | `subscribe` / `publish` on the platform event bus | `src/platform/events.lisp` |
| Window System persistence | Editor tab/split layout persistence — planned in M3 | `src/ui/editor.lisp` |

## 3. Current state (what the tree already contains)

- **Seven-region shell**: menu bar (File, Edit, View, Modules, Tools, Window,
  Help), toolbar, navigator, tabbed + split editor, output area
  (notifications / logs / tasks), properties panel, status bar with app and
  sync state.
- **Platform** (`niori-platform`, UI-agnostic — never references CLOG):
  module registry, service registry, command system with shortcuts, event
  bus, navigation registry, view-type registry, persistence contract
  (repositories, per-module versioned migrations, `store-*` protocol),
  background tasks.  UI facades installed as hooks at boot.
- **Infrastructure** (`niori-infra`): SQLite store implementing the
  `store-*` protocol (transactional migrations recorded in
  `niori_schema_migrations`), property-list config, backup (file copy),
  sync heartbeat stub.
- **Application** (`niori-app`): boot order — platform → infrastructure →
  modules → migrations → module starts → tasks → UI; orderly `stop`.
- **Medical modules** (independent ASDF systems): `:medications`,
  `:visits` (doctor visits), `:tests` (test results), `:vaccinations` —
  each demonstrates repositories, migrations, a view type, navigation,
  a command with menu path + shortcut, and a provided service.
- **GPL-3.0-or-later** licensing: `LICENSE` (full text), GPL header in
  every source file, `:license "GPL-3.0-or-later"` in all `.asd` files.
- **Not yet present**: tests, CI, document/file storage, encryption,
  FTS, observations with precision, reports, scripting console, OCR,
  packaging, i18n, HL7/standards support.

## 4. Milestones

### M0 — Project skeleton, toolchain, CI `[partial]`

The skeleton itself is done (the app runs wherever SBCL and a browser run,
which covers Windows/Linux/macOS).  Remaining: pinned toolchain, test
harness, CI, committed docs (this change).

1. Record the toolchain pin in ADR-0001: Quicklisp dist `2026-01-01`,
   minimum SBCL version verified locally, `sqlite` binding + libsqlite3
   version/feature check (FTS5 presence).
2. Create a `niori-tests` ASDF system (Parachute) with
   `(asdf:test-op ...)` wired through the umbrella system; add
   `run-tests.lisp` (`sbcl --script run-tests.lisp` exits non-zero on
   failure).
3. First suites: platform registries (commands, services, navigation,
   view types), config parsing, migration bookkeeping against a temp
   database.
4. `.github/workflows/ci.yml`: matrix `ubuntu-latest` + `windows-latest`;
   install SBCL + Quicklisp; `run-tests.lisp`; smoke job that calls
   `(niori-app:start :auto-open nil)` on a random port, fetches `/` with
   dexador and asserts the navigator/status-bar markup, then `(stop)`.
5. Commit `AGENTS.md`, `docs/` (this documentation set), `CHANGELOG.md`.

**Exit criteria**: `sbcl --script run-tests.lisp` green locally; CI green
on both OSes; smoke test fetches the shell and finds the seven regions'
markup; docs committed.

### M1 — Domain model, contracts, dependency lint `[partial]`

The persistence *contract* exists (repositories, migrations, `store-*`).
What is missing are typed domain records, parsing utilities, service
contracts beyond CRUD, and the ArchUnit-equivalent.

1. New ASDF system `niori-core` (depends only on platform-side utilities,
   never on CLOG or niori-ui): structs/classes for `patient`, `document`,
   `observation`, `tag`, and the `date-precision` enum
   (`:year :month :day :time :datetime`).  Modules map plist rows to these
   records at their boundary (ADR-0002).
2. Parsers in `niori-core`: ISO-8601 dates with precision, dot/comma
   decimals ("last separator wins": `7.2 %`, `7,2 %`), SHA-256 via
   ironclad, file hashing helpers.
3. SPI contracts as generic functions in `niori-platform`
   (implementations arrive in M2/M3): `import-service`
   (inbox → documents, SHA-256 dedupe), `backup-service`
   (`VACUUM INTO` snapshots), `observation-service`
   (precision-aware ordering).
4. Dependency lint test (the ArchUnit equivalent): a Parachute test that
   fails if `niori-platform` depends on `clog`, if `niori-core` depends on
   `niori-ui`/`niori-infra`, or if a module depends on another module,
   `niori-infra` or `niori-ui` (modules may use `niori-platform` + `clog`
   only).  Implemented over `asdf:system-depends-on` plus a
   `defpackage` scan.
5. **HL7-forward items (cheap now, expensive later — do them here):**
   add `uuid TEXT UNIQUE` columns (new migrations, ADR-0002);
   add terminology columns `code_system` / `code` / `code_display` to
   observations, medications and vaccinations (LOINC, RxNorm, CVX,
   ICD-10); add provenance columns `source_document_id`, `imported_from`,
   `payload_sha256` where a record can originate from an import
   (ADR-0003).

**Exit criteria**: entity round-trip tests (plist ↔ record) green; parser
suites green; lint test green and documented in AGENTS.md; ADR-0002
committed.

### M2 — SQLite storage: integrity, import, backup, encryption spike `[partial]`

The store exists with transactional, recorded migrations.  Build on it:

1. Centralize PRAGMAs in `src/infra/store.lisp`: `foreign_keys = ON`,
   `journal_mode = WAL`, `synchronous = FULL` while migrating.
2. **Encryption spike** (`niori-reference-cffi`, committed, not shipped):
   build the SQLite3MultipleCiphers amalgamation as a drop-in libsqlite3
   and verify that `PRAGMA key` / `PRAGMA rekey` pass through the existing
   `sqlite` binding; record what packaging needs (DLL/SO shipping).
   Outcome updates ADR-0001 (adopt vs. defer).  The `store-*` protocol
   makes either outcome cheap.
3. Migration crash-safety test with an injectable failpoint (signal after
   the data copy, before the commit) proving rollback + re-run works.
4. Blob integrity: `documents` table stores `sha256`; verification on
   read; corrupt blob raises a typed error.
5. Import service implementation in `niori-infra`: inbox polling via a
   platform background task (there is no `WatchService` in CL; a polling
   `register-task` is the honest equivalent), imports PDF/PNG/JPEG,
   dedupes by SHA-256, guesses dates from `yyyy-MM-dd_` filename
   prefixes.  Thumbnails: render in the browser (CSS), optional
   ImageMagick `convert` if present on the host.
6. Backup service via `VACUUM INTO` (consistent snapshot while running);
   keep the existing file-copy as fallback.
7. Sample-data generator `niori-devtools-sampledata` (deterministic
   seed): 1 patient, 200 documents, 2 000 observations for demos and
   screenshots.

**Exit criteria**: integration suites green on both OSes (temp-dir
databases); import a real PDF and find it via metadata search;
`VACUUM INTO` snapshot passes `integrity_check`; encryption spike has a
written ADR outcome and, if adopted, an open-with-key / wrong-key test.

### M3 — Document management UI `[partial]`

The seven-region shell is done.  Add the document workflow:

1. `niori-mod-documents` module: repository + migrations (path, title,
   mime type, sha256, date-added, date-of-record, tags), list + viewer
   view types; PDF/image display via an object URL served by a new
   `/doc/:id` route (verify the CLOG file-serving API against the local
   Quicklisp source before writing code).
2. Navigator: Documents branch; properties panel shows editable metadata;
   search filters by title, tag, date range.
3. Drag-and-drop import: browser drop events on the editor area upload
   files to the import endpoint → import service (verify CLOG's custom
   event support against its Quicklisp source).
4. Tools → Options dialog (CLOG dialog) editing the `config/niori.conf`
   keys via `niori-infra`.
5. Backup-on-close: hook `niori-app:stop` and the browser `beforeunload`
   event.
6. Layout persistence: editor tab/split state persisted server-side per
   session id and restored on reconnect (the NetBeans "window layout
   persists across restarts" behavior, browser edition).

**Exit criteria**: import, view, search and tag documents on both OSes;
layout survives a restart; backup-on-close restorable.

### M4 — Encryption flow `[todo]`

1. Passphrase dialog (CLOG modal, `src/ui/dialogs.lisp`): never log key
   material; wipe strings where practical.
2. `EncryptedDatabaseOpener` in `niori-infra`: detect encryption state on
   open; wrong passphrase → clean typed error surfaced as a notification.
3. Plaintext → encrypted migration (`ATTACH ... KEY` copy or `PRAGMA
   rekey` path, per the ADR-0001 outcome), keeping a plaintext `.bak`.
4. Change passphrase via `PRAGMA rekey`.
5. First-run wizard step for choosing encryption (arrives with the M9
   wizard; M4 ships the dialog first).

**Exit criteria**: daily use on an encrypted DB; wrong passphrase gives a
clean error, no crash; rekey round-trip test green; plaintext `.bak`
still opens (documented).

### M5 — Observations, timeline, charts, SQL console `[todo]`

1. `observation-service` implementation + forms: fast keyboard entry
   (`7.2 %`, `7,2 %` — last separator wins), precision-aware date entry
   (year/month/day/time/datetime).
2. `niori-mod-observations` module: sortable/filterable table view type.
3. Timeline view: documents + observations merged by date, precision
   aware.
4. Charts: vendored Chart.js (MIT — add to `static-files/NOTICE.txt`),
   rendered in the browser; the chart model built in Lisp stays pure and
   unit-tested.
5. Read-only SQL console view type: dedicated connection with
   `PRAGMA query_only = 1`; results grid; CSV export; test that any write
   attempt raises the SQLite readonly error.
6. Performance smoke: 1 000 documents / 2 000 observations render the
   timeline in under a second.

**Exit criteria**: enter, browse and chart observations from real data;
SQL console cannot modify data; dogfooding begins.

### M6 — Reports & handoff export `[todo]`

1. ADR decision (at M6 start): HTML/CSS print templates + headless
   Chromium `--print-to-pdf` (a browser is already required at runtime)
   vs. `cl-pdf`.  Recommended: Chromium, with golden-master text checks
   via `pdftotext`.
2. `niori-reports` module: `report-service` provided through the service
   registry; flagship patient summary template.
3. Report preview view type; PDF export stored as a `Document` tagged
   `generated` (exempt from dedupe).
4. Handoff export: ZIP (Quicklisp `archive`/`zip` libraries) containing
   the summary PDF + documents renamed from metadata
   (`2021-03-14_LabName_HbA1c.pdf`) + observations CSV/JSON; SHA-256 per
   entry (ironclad).
5. Golden-master tests: `pdftotext` asserts patient name, "HbA1c",
   "7.2 %" appear; export test verifies ZIP entry hashes against source
   documents.

**Exit criteria**: produce a handoff ZIP from real data and open it on
another machine.

### M7 — Scripting (Common Lisp is the scripting language) `[todo]`

This milestone shrinks dramatically compared to the Groovy plan:

1. In-app Lisp console view type evaluating against a `ctx` facade
   (service lookups only, no raw store handle).  Security note: this is
   arbitrary code execution by design — acceptable for a single-user
   local application; document it.
2. Script library persisted under the data directory; example scripts
   shipped.
3. Run from Tools menu; output and error reports land in the output
   panel (`handler-case` + condition report formatting).
4. CI runs the example scripts against sample data — this catches facade
   drift.
5. Writes go through services which enforce the rules; read-only facade
   by default.

**Exit criteria**: a script lists observations above a threshold and
exports them to CSV.

### M8 — OCR & full-text search `[todo]`

1. Tesseract wrapper: `uiop:run-program` with version probe, timeout and
   kill; job queue on platform background tasks; progress via the event
   bus.
2. FTS5: `document_fts` virtual table (external content) maintained by
   triggers on `documents`; consistency tests for insert/update/delete;
   CJK/unicode smoke.  Prerequisite: verify the libsqlite3 in use has
   FTS5 compiled in (Debian/Ubuntu: yes; Windows: ship the right DLL).
3. Search UI: full-text field in the navigator; re-OCR action per
   document; language pack download behind explicit consent — the only
   network call in the app.

**Exit criteria**: FTS finds words inside the oldest scanned PDFs.

### M9 — 1.0 polish & packaging `[todo]`

1. i18n: a `niori-i18n` dictionary package (per-locale plists) +
   parity test that all locales define the same key set; module strings
   registered by id.
2. First-run wizard (CLOG dialog flow): create database, choose
   encryption, set inbox.
3. Sample-data generator polish for screenshots/demos.
4. README, user guide, CHANGELOG complete; GPL headers verified by a
   test that scans every source file for the SPDX line.
5. Packaging: `sb-ext:save-lisp-and-die` executable + `static-files/`
   bundle (spike early: foreign-library paths and static file resolution
   inside a saved core); AppImage for Linux; Inno Setup or signed zip for
   Windows; the UI opens in the default browser (document minimum
   browser versions).
6. Full manual checklist on both OSes, including clean VM installs.

**Exit criteria**: installers/launchers work on clean Windows and Linux
VMs; all suites green (migration, blob integrity, i18n parity, headers);
tagged release with attached artifacts.

### M10 — Medical standards interoperability: HL7 v2, CDA, FHIR `[todo]`

The user-facing goal: exchange medical documentation using HL7 and
related standards.  Architecture decisions live in ADR-0003; the
cheap-now items (UUIDs, terminology codes, provenance, raw payload
archive) are pulled forward into M1/M2 so this milestone is additive,
not a rewrite.

1. **HL7 v2.x import** — `niori-mod-import-hl7v2`: pipe-delimited parser
   (no mature CL HL7 library exists; the v2 encoding is simple enough to
   own).  Start with `ORU^R01` lab results: `PID` → patient demographics,
   `OBR`/`OBX` → observations with LOINC codes; store the raw message
   (hash + archive) and set the provenance columns.  Registered as an
   `import-service` provider; a background task scans the inbox for
   `.hl7` files.  Golden sample messages as test fixtures.
2. **C-CDA import** — `niori-mod-import-cda` (later phase): parse
   clinical documents with `cxml`/`plump`; extract observations,
   medications and immunization sections; keep the original XML as a
   `Document`.
3. **FHIR R4 export** — `niori-mod-fhir-export`: JSON bundles via a JSON
   library + hand-rolled resource structs for the resources that matter:
   `Patient`, `Observation`, `DiagnosticReport`, `MedicationRequest` /
   `MedicationStatement`, `Immunization`, `Encounter`,
   `DocumentReference`.  Validate exports offline against FHIR JSON
   schema fixtures; write to a user-chosen file.  Server sync (via
   `dexador`) is a later, explicitly opt-in step.
4. **FHIR import** — same resource map reversed, for bundles/NDJSON the
   user received elsewhere.
5. Privacy invariant: no network by default; every transfer is
   user-initiated file output or consent-gated.

**Exit criteria**: round-trip demo — import an `ORU^R01` message and see
the observation in the timeline with LOINC code and provenance; export a
FHIR bundle that validates; original raw payloads archived with hashes.

## 5. Definition of Done (every milestone)

- All suites green via `(asdf:test-system :niori)` on the full CI matrix
  (ubuntu + windows).
- Manual checklist items executed on both Windows and Linux.
- ADRs and `CHANGELOG.md` updated.
- Dogfooding gate passed where the milestone defines one (M5, M6).
- No new dependencies outside the pinned Quicklisp dist; every library
  choice verified against the local Quicklisp source before use
  (`(ql:where-is-system :name)`), never from memory.

## 6. Risk register

| Risk | Mitigation |
|---|---|
| Cipher-enabled libsqlite3 must be built/shipped per OS | M2 spike decides adopt vs. defer; `store-*` protocol keeps the swap cheap |
| FTS5 availability varies by libsqlite3 build | Feature check in the M0 toolchain record; ship a known DLL on Windows |
| No jqwik-grade property testing in CL | Hand-rolled generated cases; golden fixtures; documented gap |
| CLOG binary/file serving + custom JS events must match the pinned dist | Anti-hallucination rule: read the local Quicklisp source before M3 code |
| Saved-core packaging pitfalls (foreign libs, static paths) | Spike early in M9, before the polish work |
| Browser dependency at runtime | Document minimum browser versions; the server renders plain HTML/CSS/JS |
| Encryption of a live medical DB is a trust boundary | M4 exit criteria are strict; wrong-passphrase UX tested; no key material in logs |

## 7. Session protocol for LLM-assisted work

Documented in `AGENTS.md`: read `AGENTS.md` + the milestone's ADRs at
session start; verify every CLOG/`sqlite` API against the local Quicklisp
source before use; keep the layering rules (enforced by the M1 lint
test); run the test suite before claiming any milestone step done.
