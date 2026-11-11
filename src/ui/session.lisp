;;;; niori/src/ui/session.lisp
;;;
;;; Niori - a modular desktop application built on CLOG.
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

(in-package #:niori-ui)

;;; Every browser page (CLOG connection) gets its own session object
;;; holding the shell elements and the open editor panes/tabs.  The
;;; session is stored per connection so handlers can reach it from
;;; anywhere: (session-of body).

(defstruct (editor-tab (:conc-name tab-))
  (title "")
  (button nil)          ; tab strip entry
  (content nil)         ; the scrollable content element
  (view-type-id nil))

(defstruct (editor-pane (:conc-name pane-))
  (container nil)
  (tabbar nil)
  (content-area nil)
  (tabs nil)
  (active-tab nil))

(defstruct (niori-session (:conc-name session-))
  (body nil)
  ;; shell rows
  (menu-row nil) (toolbar-row nil) (main-row nil)
  (output-row nil) (status-row nil)
  ;; navigator
  (navigator-col nil) (navigator-body nil)
  ;; editor
  (editor-col nil) (panes-row nil)
  (panes nil) (active-pane nil)
  ;; output
  (output-tabs (make-hash-table :test 'eq))
  (output-bodies (make-hash-table :test 'eq))
  ;; properties
  (props-col nil) (props-body nil)
  ;; status bar
  (status-state nil) (status-sync nil)
  ;; floating toasts
  (toast-area nil)
  ;; toolbar
  (toolbar-buttons (make-hash-table :test 'eq))
  ;; managed windows
  (window-cascade 0))

(defun make-session (body)
  (make-niori-session :body body))

(defun session-of (body)
  "Return the niori-session stored on a connection body."
  (connection-data-item body "niori-session"))
