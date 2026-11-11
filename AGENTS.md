# AGENTS.md — Niori working conventions

Read this file at the start of every working session (human or LLM), plus
the ADRs listed for the active milestone in `docs/ROADMAP.md`.

## Source of truth

The tree this file lives in is the only baseline.  Earlier scaffold
iterations are history: do not consult, restore or reference them.  When
this file and the code disagree, the code wins — then fix this file.

## What Niori is

A modular, single-user personal medical information manager inspired by
the NetBeans Platform, built on CLOG (browser UI) + Common Lisp (SBCL).
Everything except view rendering is a classic CL application: registries,
commands, services, persistence, background tasks.  Roadmap:
`docs/ROADMAP.md`.

## Repository map

```
niori.asd                  umbrella system (test-op wiring)
start.lisp                 entry script for `sbcl --load start.lisp`
config/niori.conf          property-list configuration
config/modules.lisp        module ASDF systems loaded at boot
src/platform/              niori-platform: registries, commands, events,
                           persistence contract, tasks (NEVER uses CLOG)
src/infra/                 niori-infra: SQLite store, config, backup, sync
src/ui/                    niori-ui: CLOG shell (menus, toolbar, navigator,
                           editor tabs/splits, output, properties, status)
src/app/                   niori-app: boot order + shutdown
modules/niori-mod-*        one independent ASDF system per module
static-files/              W3.CSS, jQuery-UI (MIT, see NOTICE.txt), niori.css
docs/                      ROADMAP, ADRs, glossary, task cards
LICENSE                    GPL-3.0-or-later, full text
```

## Layering rules (enforced by a test since M1)

1. `niori-platform` never depends on `clog` or any UI package.  UI
   callbacks are installed as hooks (`*open-view-hook*`,
   `*open-window-hook*`, `*set-properties-hook*`, `*set-status-hook*`).
2. `niori-core` (from M1) never depends on `niori-ui`, `niori-infra` or
   CLOG.
3. Modules depend only on `niori-platform` (+ `clog` inside view
   builders).  A module never uses another module's package, never uses
   `niori-infra` or `niori-ui` directly, and never touches the store
   except through the platform persistence API (`repo-*`, `store-*`).
4. Cross-module communication goes through the event bus
   (`subscribe`/`publish`) or the service registry
   (`provide-service`/`lookup-service`).
5. New subsystems extend the platform contract first
   (`src/platform/*.lisp`), get an implementation second
   (`src/infra/` or `src/ui/`).

## Coding conventions

- Every `.lisp`, `.asd` and config file starts with the GPL header (copy
  the header from `niori.asd`; SPDX line: `GPL-3.0-or-later`).
- Packages: `niori-*` for layers, `niori-mod-<name>` for modules;
  module ids and command ids are keywords (`:medications.new`).
- Rows crossing the persistence API are property lists with keyword keys
  (`(:name "..." :active 1)`); `:id` is reserved.
- Dates/times are ISO-8601 strings (helpers `today-string`/`now-string`
  in the platform); IDs move to UUID strings per ADR-0002.
- SQL is always executed with bound parameters (`store-execute` /
  `execute-non-query` with `?` placeholders); table names come from
  repository registrations, never from user input.
- Schema changes only via `(define-migration :module N (store) ...)`;
  never edit an already-released migration.
- UI feedback: `notify` for toasts, `log-line` for the log, `set-status`
  for the status bar, `set-properties` for the properties panel.
- Long-running or periodic work is a `register-task`, never a bare
  thread; task errors must stay isolated.
- CSS lives in `static-files/css/niori.css`; no inline styles beyond
  small layout tweaks.

## Anti-hallucination rules (APIs)

- Before using any CLOG / clog-gui / `sqlite` binding function, read its
  definition in the local Quicklisp source:
  `(ql:where-is-system :clog)` → grep the sources.  Never write calls
  from memory.
- Before adopting any new library, confirm it exists in the pinned
  dist (`2026-01-01`) and note the decision in an ADR.
- When unsure whether a platform capability exists, search
  `src/platform/` first; extend the contract deliberately instead of
  guessing.

## Definition of Done for any change

- `(asdf:test-system :niori)` green (from M0; until then, the change
  compiles under `sbcl --load start.lisp` and the app boots).
- Layering rules hold (lint test from M1).
- New files carry the GPL header; `.asd` files declare
  `:license "GPL-3.0-or-later"`.
- Docs updated when behavior, config keys or the roadmap change:
  ADR for decisions, `CHANGELOG.md` entry, task card status.

## Task cards

One card per implementable unit of work; keep them small (a card fits in
one session).  Template: `docs/task-cards/TEMPLATE.md`.  Cards live in
`docs/task-cards/` named `M<milestone>-<nn>-<slug>.md`.
