;;;; niori/src/platform/commands.lisp
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

(in-package #:niori-platform)

;;; The command system.  Modules register commands once; the UI layer
;;; renders them as menu items (menu-path), toolbar buttons (toolbar-p)
;;; and global keyboard shortcuts (shortcut).  This is the fix for the
;;; old "menus do nothing" bug: the only way a menu item exists is via a
;;; registered command with a wired handler.

(defparameter *commands-lock* (bt:make-lock "niori-commands"))

(defparameter *commands* (make-hash-table :test 'eq)
  "COMMAND-ID -> command struct.")

(defstruct (command (:constructor %make-command))
  (id nil)                       ; keyword, e.g. :medications.new
  (title "")                     ; menu / toolbar label
  (menu-path nil)                ; e.g. '("File") or '("File" "New") - 2nd part is a group
  (group nil)                    ; optional group inside the menu (renders a separator)
  (shortcut nil)                 ; e.g. '(:control :alt "m") or nil
  (tooltip "")                   ; tooltip text (toolbar buttons)
  (toolbar-p nil)                ; show as toolbar button?
  (enabled-fn nil)               ; (lambda (session)) -> boolean, context sensitivity
  (handler nil :read-only t)     ; (lambda (session))
  (module nil))                  ; providing module keyword

(defun register-command (id &key title (menu-path nil) (group nil) (shortcut nil)
                             (tooltip "") (toolbar nil) (enabled-fn nil) handler
                             (module nil))
  "Register or replace the command ID."
  (unless handler
    (error "Command ~S registered without a handler" id))
  (bt:with-lock-held (*commands-lock*)
    (setf (gethash id *commands*)
          (%make-command :id id :title (or title (keyword->title id))
                         :menu-path menu-path :group group :shortcut shortcut
                         :tooltip tooltip :toolbar-p toolbar
                         :enabled-fn (or enabled-fn (constantly t))
                         :handler handler :module module)))
  id)

(defun find-command (id)
  (gethash id *commands*))

(defun all-commands ()
  "All registered commands sorted by menu path then id (stable menus)."
  (bt:with-lock-held (*commands-lock*)
    (sort (loop for command being the hash-values of *commands*
                collect command)
          #'string<
          :key (lambda (command)
                 (format nil "~A~A" (command-menu-path command)
                         (symbol-name (command-id command)))))))

(defun run-command (id &optional (session nil))
  "Execute the command ID, passing SESSION to its handler."
  (let ((command (find-command id)))
    (cond
      ((null command)
       (notify "Unknown command" (format nil "No command registered as ~S" id)
               :kind :error))
      (t
       (log-line :info (format nil "Command ~S executed" id))
       (handler-case (funcall (command-handler command) session)
         (error (condition)
           (notify "Command failed"
                   (format nil "~A: ~A" (command-title command) condition)
                   :kind :error)))))))

(defun normalize-shortcut (spec)
  "Normalize a shortcut spec like (:control :alt \"m\") into a plist
(:control t :alt t :shift nil :meta nil :key \"m\")."
  (let ((mods (butlast spec))
        (key (first (last spec))))
    (list :control (and (member :control mods) t)
          :meta    (and (member :meta mods) t)
          :alt     (and (member :alt mods) t)
          :shift   (and (member :shift mods) t)
          :key     (string-downcase (string key)))))

(defun format-shortcut (spec)
  "Human readable form: (:control :alt \"m\") -> \"Ctrl+Alt+M\"."
  (let ((n (normalize-shortcut spec)))
    (format nil "~:[~;Ctrl+~]~:[~;Meta+~]~:[~;Alt+~]~:[~;Shift+~]~A"
            (getf n :control) (getf n :meta) (getf n :alt) (getf n :shift)
            (string-upcase (getf n :key)))))

(defun command-for-key (key-string ctrl alt shift meta)
  "Return the command bound to the given key + modifiers, or NIL.
KEY-STRING is the DOM KeyboardEvent.key name (case insensitive)."
  (let ((want (string-downcase (string key-string))))
    (loop for command being the hash-values of *commands*
          for spec = (command-shortcut command)
          when spec
            do (let ((n (normalize-shortcut spec)))
                 (when (and (equal (getf n :key) want)
                            (eq (and (getf n :control) t) (and ctrl t))
                            (eq (and (getf n :meta) t) (and meta t))
                            (eq (and (getf n :alt) t) (and alt t))
                            (eq (and (getf n :shift) t) (and shift t)))
                   (return command))))))
