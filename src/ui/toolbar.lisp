;;;; niori/src/ui/toolbar.lisp
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

(defun build-toolbar (session)
  "One button per command registered with :toolbar t, plus the app brand."
  (let ((bar (create-div (session-toolbar-row session) :class "niori-toolbar")))
    (dolist (command (all-commands))
      (when (command-toolbar-p command)
        (let* ((command-id (command-id command))
               (button (create-button bar
                                      :content (command-title command)
                                      :class "niori-btn")))
          (setf (attribute button "title")
                         (if (command-shortcut command)
                             (format nil "~A (~A)"
                                     (command-tooltip command)
                                     (format-shortcut (command-shortcut command)))
                             (command-tooltip command)))
          (set-on-click button
                        (lambda (obj)
                          (declare (ignore obj))
                          (run-command command-id session)))
          (setf (gethash command-id (session-toolbar-buttons session)) button))))
    (create-span bar :class "niori-brand" :content "Niori")
    (refresh-toolbar session)))

(defun refresh-toolbar (session)
  "Context-sensitive enable/disable of the toolbar buttons."
  (let ((buttons (session-toolbar-buttons session)))
    (loop for id being the hash-keys of buttons
          using (hash-value button)
          for command = (find-command id)
          when command
            do (let ((enabled-p (handler-case
                                    (funcall (command-enabled-fn command) session)
                                  (error () t))))
                 (if enabled-p
                     (remove-class button "disabled")
                     (add-class button "disabled"))))))
