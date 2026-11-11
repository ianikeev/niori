;;;; niori/src/ui/dialogs.lisp
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

;;; Dialogs are clog-gui windows: draggable, closable, keep-on-top.
;;; They are created hidden, filled by a builder, centered and shown -
;;; the same recipe the CLOG GUI demo uses.

(defun open-dialog (session title width height builder)
  "Open a centered keep-on-top dialog window; BUILDER fills the content."
  (let* ((body (session-body session))
         (window (clog-gui:create-gui-window body :title title
                                                  :width width :height height
                                                  :hidden t
                                                  :keep-on-top t)))
    (funcall builder (clog-gui:window-content window) session)
    (clog-gui:window-center window)
    (setf (visiblep window) t)
    window))

(defun app-version ()
  (or (ignore-errors (asdf/component:component-version (asdf:find-system :niori)))
      "0.1.0"))

(defun about-dialog (session)
  (open-dialog session "About Niori" 400 270
               (lambda (content session)
                 (declare (ignore session))
                 (setf (inner-html content)
                           (format nil
                                   "<div class='niori-dialog'>
<p style='font-size:16px;font-weight:600;color:#2563eb'>Niori ~A</p>
<p>A modular desktop-style application framework built with CLOG, the
Common Lisp Omnificent GUI, and inspired by the architecture of the
NetBeans Platform.</p>
<p>The bundled modules demonstrate a personal medical information
manager: medications, doctor visits, test results and vaccinations.</p>
<p class='niori-muted'>Licensed under the GNU General Public License,
version 3 or later.  See the LICENSE file for details.</p>
</div>"
                                   (html-esc (app-version)))))))

(defun shortcuts-dialog (session)
  (open-dialog session "Keyboard Shortcuts" 380 320
               (lambda (content session)
                 (declare (ignore session))
                 (setf (inner-html content)
                           "<div class='niori-dialog'><p>Global shortcuts installed on this page:</p></div>")
                 (let ((table (create-table content :class "niori-table")))
                   (let ((head (create-table-head table))
                         (body (create-table-body table)))
                     (let ((header-row (create-table-row head)))
                       (create-table-heading header-row :content "Command")
                       (create-table-heading header-row :content "Menu")
                       (create-table-heading header-row :content "Shortcut"))
                     (dolist (command (all-commands))
                       (when (command-shortcut command)
                         (let ((row (create-table-row body)))
                           (create-table-column row :content (html-esc (command-title command)))
                           (create-table-column row :content (html-esc (first (command-menu-path command))))
                           (create-table-column row :content (html-esc (format-shortcut (command-shortcut command))))))))))))

(defun module-info-dialog (session module)
  (open-dialog session (format nil "Module: ~A" (module-name module)) 430 300
               (lambda (content session)
                 (declare (ignore session))
                 (setf (inner-html content)
                           "<div class='niori-dialog'><p>Module details and provided services:</p></div>")
                 (let ((table (create-table content :class "niori-table")))
                   (let ((body (create-table-body table)))
                     (dolist (pair (list (list "Id" (module-id module))
                                         (list "Version" (module-version module))
                                         (list "Description" (module-description module))))
                       (let ((row (create-table-row body)))
                         (create-table-column row :content (html-esc (first pair)))
                         (create-table-column row :content (html-esc (second pair)))))
                     (let ((services (remove-if-not
                                      (lambda (name)
                                        (eq (service-provider name) (module-id module)))
                                      (all-service-names))))
                       (let ((row (create-table-row body)))
                         (create-table-column row :content "Services")
                         (create-table-column row
                                              :content (if services
                                                           (html-esc (format nil "~{~A~^, ~}" services))
                                                           "-")))))))))

(defun settings-dialog (session)
  (open-dialog session "Settings" 430 300
               (lambda (content session)
                 (declare (ignore session))
                 (with-service (keys :config-keys)
                   (with-service (get-value :config)
                     (setf (inner-html content)
                               "<div class='niori-dialog'><p>Current configuration
(edit <b>config/niori.conf</b> and restart, or use the tools below).</p></div>")
                     (let ((table (create-table content :class "niori-table")))
                       (let ((body (create-table-body table)))
                         (dolist (key (funcall keys))
                           (let ((row (create-table-row body)))
                             (create-table-column row :content (html-esc key))
                             (create-table-column row :content (html-esc (funcall get-value key))))))))))))

