;;;; niori/src/ui/commands.lisp
;;;
;;; Part of Niori - a modular desktop application framework built on CLOG.
;;;
;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright (C) 2026  The Niori Authors
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

;;; Core (shell) commands.  Module commands live in the modules; both
;;; kinds are rendered by the same menus/toolbar builders.  Shortcut
;;; keys deliberately avoid browser-reserved combinations (Ctrl+N, T,
;;; W, S...) - Niori uses Ctrl+Alt+<key> for global commands.

(defun toggle-panel (session element)
  "Show/hide a docked panel (used by the View menu)."
  (declare (ignore session))
  (when element
    (let ((classes (attribute element "class")))
      (if (and classes (search "hidden" classes))
          (remove-class element "hidden")
          (add-class element "hidden")))))

(defun active-tab-present-p (session)
  (let ((pane (and session (session-active-pane session))))
    (and pane (pane-active-tab pane) t)))

(defun register-core-commands ()
  (register-command
   :file.exit
   :title "Exit"
   :menu-path '("File")
   :tooltip "Disconnect this page (close the browser tab)"
   :module :niori-ui
   :handler (lambda (session)
              (declare (ignore session))
              (notify "Exit Niori"
                      "Close this browser tab to disconnect. The server keeps running."
                      :kind :info)))
  (register-command
   :edit.find
   :title "Find..."
   :menu-path '("Edit")
   :tooltip "Search (stub in the scaffold)"
   :module :niori-ui
   :handler (lambda (session)
              (declare (ignore session))
              (notify "Find" "Search is a stub in the scaffold - wire your own command here."
                      :kind :info)))
  (register-command
   :edit.preferences
   :title "Preferences..."
   :menu-path '("Edit")
   :tooltip "Show the current configuration"
   :module :niori-ui
   :handler #'settings-dialog)
  (register-command
   :view.navigator
   :title "Toggle Navigator"
   :menu-path '("View")
   :shortcut '(:control :alt "1")
   :tooltip "Show or hide the Navigator panel"
   :module :niori-ui
   :handler (lambda (session)
              (toggle-panel session (session-navigator-col session))))
  (register-command
   :view.properties
   :title "Toggle Properties"
   :menu-path '("View")
   :shortcut '(:control :alt "2")
   :tooltip "Show or hide the Properties panel"
   :module :niori-ui
   :handler (lambda (session)
              (toggle-panel session (session-props-col session))))
  (register-command
   :view.output
   :title "Toggle Output"
   :menu-path '("View")
   :shortcut '(:control :alt "3")
   :tooltip "Show or hide the Output panel"
   :module :niori-ui
   :handler (lambda (session)
              (toggle-panel session (session-output-row session))))
  (register-command
   :view.split
   :title "Split Editor"
   :menu-path '("View" "Editor")
   :shortcut '(:control :alt "d")
   :tooltip "Add a second editor pane"
   :toolbar t
   :module :niori-ui
   :handler #'split-editor)
  (register-command
   :view.close-tab
   :title "Close Tab"
   :menu-path '("View" "Editor")
   :shortcut '(:control :alt "w")
   :tooltip "Close the active editor tab"
   :toolbar t
   :enabled-fn #'active-tab-present-p
   :module :niori-ui
   :handler #'close-active-tab)
  (register-command
   :tools.settings
   :title "Settings..."
   :menu-path '("Tools")
   :tooltip "Show the current configuration"
   :module :niori-ui
   :handler #'settings-dialog)
  (register-command
   :window.maximize-all
   :title "Maximize All Windows"
   :menu-path '("Window")
   :tooltip "Maximize every open window"
   :module :niori-ui
   :handler (lambda (session)
              (when session
                (clog-gui:maximize-all-windows (session-body session)))))
  (register-command
   :window.normalize-all
   :title "Normalize All Windows"
   :menu-path '("Window")
   :tooltip "Restore every open window"
   :module :niori-ui
   :handler (lambda (session)
              (when session
                (clog-gui:normalize-all-windows (session-body session)))))
  (register-command
   :help.shortcuts
   :title "Keyboard Shortcuts"
   :menu-path '("Help")
   :tooltip "List all registered shortcuts"
   :module :niori-ui
   :handler #'shortcuts-dialog)
  (register-command
   :help.about
   :title "About Niori"
   :menu-path '("Help")
   :tooltip "About this application"
   :module :niori-ui
   :handler #'about-dialog))
