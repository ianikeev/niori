# Niori

Niori is a modular, desktop-style application framework built with
[CLOG](https://clog.common-lisp.dev/) (the Common Lisp Omnificent GUI) and
inspired by the architecture of the **NetBeans Platform**.  The UI runs in the
browser, but everything else - registries, commands, services, persistence,
background tasks - is a classic Common Lisp application.

The bundled example modules turn Niori into a small **personal medical
information manager**: medications, doctor visits, test results and
vaccinations.

```
+--------------------------------------------------------------------------+
| File  Edit  View  Modules  Tools  Window  Help          (clog-gui menus) |
+--------------------------------------------------------------------------+
| [Close Tab] [Split Editor]                                    Niori      |  <- toolbar
+----------------+---------------------------------------+-----------------+
| NAVIGATOR      |  Editor area: tabs, split views       | PROPERTIES      |
| Medications    |  (context-sensitive, per view type)   | (context-       |
| Doctor Visits  |                                       |  sensitive)     |
|  Upcoming...   |                                       |                 |
| Test Results   |                                       |                 |
| Vaccinations   |                                       |                 |
+----------------+---------------------------------------+-----------------+
| Notifications | Logs | Tasks                           (output area)     |
+--------------------------------------------------------------------------+
| Ready - 4 modules loaded          DB: ...   Synchronized at ...  (status)  |
+--------------------------------------------------------------------------+
```

## Architecture

Niori Application (entry point and lifecycle)
`niori-app` boots the platform, opens the store, loads the configured module
systems, applies migrations, starts background tasks and launches the UI.

Niori Platform (`niori-platform`, deliberately UI-agnostic)
- **Module registry** - `define-module` / `start-all-modules`
- **Service registry** - `provide-service` / `lookup-service` (a small Lookup)
- **Command system** - `register-command` with menu path, toolbar flag and
  keyboard shortcut; the UI renders every command into menus/toolbar/keys
- **Event bus** - `subscribe` / `publish`; notifications, logs and sync
  status travel through it, keeping modules decoupled
- **Window manager** - `open-window` facade; the UI implements it with
  draggable, closable `clog-gui` windows (cascaded, never overlapping)
- **Persistence API** - repositories (logical tables), versioned per-module
  **database migrations** and the `store-*` protocol

Presentation layer (`niori-ui`)
CLOG UI - docked shell, clog-gui menus, toolbar, navigator, tabbed editor
with split views, output panel, properties panel, status bar, dialogs.

Infrastructure (`niori-infra`)
SQLite store (via `cl-sqlite`) implementing the platform persistence
protocol, file configuration, backups, synchronization heartbeat.

Modules (`modules/`, each an **independent ASDF system**)
A module can register its own:
- **Navigation entries** (`register-navigation`, with children)
- **Commands and keyboard shortcuts** (`register-command`, shown in the
  fixed menus File/Edit/View/Modules/Tools/Window/Help and the toolbar)
- **Editor/view types** (`register-view-type` + `open-view`)
- **Services** (`provide-service ... :provider :module-id`)
- **Database migrations** (`define-migration`) and repositories
  (`register-repository`)
- **Menu contributions** (via command `:menu-path`)
- **Background tasks** (`register-task`, own thread, error isolated)

## Quick start

Requirements: SBCL 2.x, [Quicklisp](https://quicklisp.org) (installs CLOG and
cl-sqlite automatically), and libsqlite3 (`libsqlite3-dev` on Debian/Ubuntu).

```bash
sbcl --load start.lisp
```

Then open <http://127.0.0.1:8080>.  `start.lisp` registers the source tree
with ASDF, loads the `niori` system, loads the modules listed in
`config/modules.lisp` and calls `(niori-app:start)`.

From an existing REPL with Quicklisp:

```lisp
(asdf:initialize-source-registry
 '(:source-registry (:tree "/path/to/niori/") :inherit-configuration))
(ql:quickload :niori)
(niori-app:start)                 ; :port, :host, :auto-open override the conf
(niori-app:stop)                  ; orderly shutdown
```

Headless (e.g. on a server): `(niori-app:start :auto-open nil)`.

## Configuration

`config/niori.conf` is a single property list; only listed keys override the
defaults (see `src/infra/config.lisp`):

| Key                      | Default  | Meaning                                |
|--------------------------|----------|----------------------------------------|
| `:port`                  | 8080     | HTTP port of the UI                    |
| `:host`                  | 127.0.0.1| Bind address                           |
| `:auto-open`             | t        | Open the browser on start              |
| `:data-directory`        | `data/`  | Where the SQLite file lives            |
| `:database-file`         | niori.db | Database file name                     |
| `:backup-directory`      | `backups/`| Where `Backup Now` copies the DB      |
| `:backup-on-start`       | nil      | Backup at every boot                   |
| `:sync-enabled`          | t        | Sync heartbeat status in the status bar|
| `:sync-interval-seconds` | 60       | Heartbeat interval                     |

`config/modules.lisp` lists the module ASDF systems loaded at boot; comment
out a line to disable a module, add a line to enable your own.

## Writing a module

A module is one directory under `modules/` with a `.asd` and a package that
`:use`s `niori-platform` (and `clog` for view content).  Skeleton:

```lisp
;; mymodule.lisp
(in-package #:niori-mod-mymodule)

(define-module :mymodule
  :name "My Module"
  :version "0.1.0"
  :description "What it does."
  :start-fn (lambda () (log-line :info "My Module ready")))

(register-repository :mymodule-items :table "mymodule_items" :module :mymodule)

(define-migration :mymodule 1 (store)
  (store-execute store "CREATE TABLE IF NOT EXISTS mymodule_items (
                          id INTEGER PRIMARY KEY AUTOINCREMENT,
                          title TEXT NOT NULL)"))

(register-view-type :mymodule.list :label "My Module"
                    :builder #'my-module-view :module :mymodule)

(register-navigation :nav-mymodule :label "My Module" :module :mymodule
                     :on-open (lambda (session)
                                (open-view :mymodule.list :session session)))

(register-command :mymodule.new
                  :title "New Item"
                  :menu-path '("File" "New")     ; menu contribution
                  :shortcut '(:control :alt "i") ; global keyboard shortcut
                  :module :mymodule
                  :handler (lambda (session)
                             (open-view :mymodule.list :session session))))

(provide-service :mymodule (lambda () (repo-count :mymodule-items))
                 :provider :mymodule)

(register-task :mymodule.tick :label "My Module tick" :interval-seconds 300
               :fn (lambda () (log-line :info "tick")))
```

Then add `:niori-mod-mymodule` to `config/modules.lisp` and restart.
A view builder is a function of `(content session data)` that fills the
CLOG element `content`; call `(set-properties session '("Key" value ...))`
to drive the properties panel, `(notify ...)` for toasts/notifications and
`(log-line ...)` for the log.  Data access uses `repo-list`, `repo-get`,
`repo-insert`, `repo-update`, `repo-delete`, `repo-count` on the repository
name; rows are plists with keyword keys (`:id`, `:title`, ...).

## Keyboard shortcuts

Ctrl+Alt+M / V / T / N - open Medications / Visits / Test Results /
Vaccinations.  Ctrl+Alt+D - split editor, Ctrl+Alt+W - close tab,
Ctrl+Alt+1/2/3 - toggle Navigator / Properties / Output.  Shortcuts avoid
combinations the browser reserves; see Help > Keyboard Shortcuts inside the
app for the live list.

## Data, backup, synchronization

All data lives in one SQLite database (`data/niori.db` by default).  Schema
changes are versioned per module: bump the version, add a
`(define-migration :module N (store) ...)`, and it is applied inside a
transaction on the next boot; applied versions are recorded in
`niori_schema_migrations`.  Tools > Backup Now copies the database file into
`backups/`.  Synchronization is a stub: the heartbeat task publishes
`:sync-status` events that the status bar displays - replace
`niori-infra:sync-now` with real synchronization logic.

## Notes on bundled static files

`static-files/` contains a copy of [W3.CSS](https://www.w3schools.com/w3css/)
and jQuery-UI (both MIT-licensed), which clog-gui expects under `/css` and
`/js`, plus `css/niori.css` - the shell stylesheet of Niori itself.

## License

Niori is free software; it is licensed under the **GNU General Public
License, version 3 or any later version** (SPDX: `GPL-3.0-or-later`).
Every source file carries the standard GPL header, and the complete license
text ships as [`LICENSE`](LICENSE).
