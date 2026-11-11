# ADR-0001: Technology stack, toolchain pin and storage/encryption

- **Status**: accepted (encryption sub-decision: spike pending, M2)
- **Date**: 2026-11-12
- **Supersedes**: the NetBeans Platform 31 / Java 24 stack from the
  original outline

## Context

Niori is a single-user, cross-platform personal medical information
manager.  The original plan assumed the NetBeans Platform (Java 24,
Maven, FlatLaf, Java FFM for SQLite ciphers).  The existing codebase is
Common Lisp on SBCL with a CLOG browser UI, an ASDF-based module system
and a SQLite store behind a platform-defined protocol
(`store-*` generic functions).  The stack below records what is actually
pinned in this tree.

## Decision

1. **Language/runtime**: Common Lisp on SBCL 2.x.  The minimum SBCL
   version is whatever CI installs on ubuntu-latest and windows-latest;
   record it in `CHANGELOG.md` when the first CI run is green (M0).
2. **Dependency source**: Quicklisp, **dist pinned to `2026-01-01`**
   (`~/quicklisp/dists/quicklisp/distinfo.txt`).  CLOG and clog-gui come
   from this dist.  No library is adopted from outside the pin without
   an ADR.
3. **Build/assembly**: ASDF systems.  `niori` is the umbrella; modules
   are independent systems under `modules/` listed in
   `config/modules.lisp`.  (Replaces Maven + nbm-maven-plugin.)
4. **UI**: CLOG browser UI with clog-gui menus/windows; theme is
   `static-files/css/niori.css` over W3.CSS (replaces FlatLaf).
5. **Storage**: SQLite via the Quicklisp `sqlite` CFFI binding (a CLOG
   dependency) linked against the system libsqlite3.  All SQL uses bound
   parameters; schema changes only through platform migrations.
   (Replaces Java FFM bindings.)
6. **Encryption (open spike)**: SQLite3MultipleCiphers can be built as a
   drop-in replacement of the plain amalgamation; if `PRAGMA key` /
   `PRAGMA rekey` pass through the `sqlite` binding unchanged, no
   binding rewrite is needed — only a cipher-enabled libsqlite3 must be
   shipped per OS.  The M2 spike (`niori-reference-cffi`, committed but
   not shipped) verifies exactly this and decides **adopt vs. defer**.
   Deferral keeps unencrypted files and documents the risk; it does not
   change any API.  (Replaces SQLite3MultipleCiphers-via-FFM.)
7. **Testing**: Parachute suites behind `asdf:test-op`; dependency lint
   test as the ArchUnit equivalent; `pdftotext`/PDFBox only for
   golden-master PDF assertions.  No jqwik-grade property testing
   exists in CL — generated cases are hand-rolled (accepted gap).
8. **Reports (decided at M6 start, recommendation recorded now)**:
   HTML/CSS print templates rendered by headless Chromium
   `--print-to-pdf`; `cl-pdf` as fallback.  (Replaces JasperReports.)
9. **Packaging**: `sb-ext:save-lisp-and-die` executable plus bundled
   `static-files/`; AppImage (Linux), Inno Setup or zip (Windows).  The
   UI opens in the default browser.  (Replaces jpackage.)

## Consequences

- Cross-platform support is inherited from SBCL + a browser, not from a
  JVM; per-OS work concentrates on libsqlite3 features (FTS5, ciphers)
  and packaging.
- The `store-*` protocol is the compatibility firewall: storage,
  encryption and backup strategies can be exchanged without touching
  modules.
- Version pins live here and in `CHANGELOG.md`; bumping the Quicklisp
  dist is an ADR-worthy event because CLOG behavior can shift.
