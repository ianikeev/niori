;;;; niori/src/ui/menus.lisp
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

(defparameter *menu-titles*
  '("File" "Edit" "View" "Modules" "Tools" "Window" "Help")
  "The fixed main menu layout.  Commands from any module are merged into
these menus through their menu-path; unknown top-level paths are appended
after the fixed menus.")

(defun build-menu-bar (session)
  "Build the main menu bar from the fixed layout plus every registered
command.  Every menu item is wired to run-command - the fix for the old
'menus do nothing' bug."
  (let* ((bar (clog-gui:create-gui-menu-bar (session-menu-row session)
                                            :main-menu t))
         (menus (make-hash-table :test 'equal))
         (groups-seen nil))
    (dolist (title *menu-titles*)
      (setf (gethash title menus)
            (clog-gui:create-gui-menu-drop-down bar :content title)))
    ;; one menu item per command, grouped under its menu-path
    (dolist (command (all-commands))
      (let ((path (command-menu-path command)))
        (when path
          (let* ((menu-title (first path))
                 (group (second path))
                 (dropdown (or (gethash menu-title menus)
                               (setf (gethash menu-title menus)
                                     (clog-gui:create-gui-menu-drop-down
                                      bar :content menu-title)))))
            (when group
              (let ((key (list menu-title group)))
                (unless (member key groups-seen :test #'equal)
                  (push key groups-seen)
                  (create-div dropdown :class "niori-menu-sep"))))
            (let ((command-id (command-id command))
                  (shortcut (command-shortcut command))
                  (title-text (command-title command)))
              (clog-gui:create-gui-menu-item
               dropdown
               :content (if shortcut
                            (format nil "~A<span class='niori-shortcut'>~A</span>"
                                    (html-esc title-text)
                                    (format-shortcut shortcut))
                            (html-esc title-text))
               :on-click (lambda (obj)
                           (declare (ignore obj))
                           (run-command command-id session)))))))
    ;; Modules menu: one info entry per registered module
    (let ((modules (all-modules)))
      (if modules
          (dolist (module modules)
            (let ((registered module))
              (clog-gui:create-gui-menu-item
               (gethash "Modules" menus)
               :content (html-esc (module-name module))
               :on-click (lambda (obj)
                           (declare (ignore obj))
                           (module-info-dialog session registered))))))
          (clog-gui:create-gui-menu-item
           (gethash "Modules" menus)
           :content "(no modules loaded)")))
    ;; Window menu: the auto-updating list of open clog-gui windows
    (let ((window-menu (gethash "Window" menus)))
      (create-div window-menu :class "niori-menu-sep")
      (clog-gui:create-gui-menu-window-select window-menu
                                              :content "Open windows"))
    bar))
