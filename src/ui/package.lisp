;;;; niori/src/ui/package.lisp
;;;
;;; Niori -- personal medical info management.
;;;
;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright (C) 2026  Igor Anikeev
;;;
;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

(defpackage #:niori-ui
  (:use #:cl #:clog #:clog-gui #:niori-platform)
  (:shadowing-import-from #:niori-platform #:open-window)
  (:documentation "Niori presentation layer.  Builds the docked shell on
top of clog-gui: menu bar, toolbar, navigator, tabbed editor area with
split views, output panel, properties panel and status bar.  It also
installs the platform UI hooks (open-view, open-window, properties,
status), the global keyboard shortcuts and the core commands.")
  (:export
   #:start-ui #:stop-ui
   #:build-shell #:build-menu-bar #:build-toolbar
   #:make-session #:session-of
   #:open-view-in-session #:open-dialog #:open-managed-window
   #:render-properties #:set-status-text #:toggle-panel
   #:activate-pane #:activate-tab #:close-tab #:close-active-tab
   #:split-editor #:refresh-toolbar
   #:install-ui-hooks #:install-session-subscriptions))
