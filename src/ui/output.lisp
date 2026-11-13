;;;; niori/src/ui/output.lisp
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

(in-package #:niori-ui)

(defparameter *output-tabs* '((:notifications "Notifications")
                              (:logs "Logs")
                              (:tasks "Tasks")))

(defun build-output (session)
  "Notifications / Logs / Tasks tabs at the bottom of the shell."
  (let* ((row (session-output-row session))
         (tabs (create-div row :class "niori-outtabs"))
         (bodies (session-output-bodies session))
         (buttons (session-output-tabs session)))
    (dolist (spec *output-tabs*)
      (destructuring-bind (id title) spec
        (let ((button (create-div tabs :class "niori-outtab" :content title))
              (body (create-div row :class "niori-outbody wrapped")))
          (setf (gethash id buttons) button
                (gethash id bodies) body)
          (let ((tab-id id))
            (set-on-click button
                          (lambda (obj)
                            (declare (ignore obj))
                            (show-output-tab session tab-id)))))))
    (show-output-tab session :notifications)))

(defun show-output-tab (session which)
  (let ((buttons (session-output-tabs session))
        (bodies (session-output-bodies session)))
    (dolist (spec *output-tabs*)
      (let* ((id (first spec))
             (button (gethash id buttons))
             (body (gethash id bodies)))
        (when (validp button)
          (if (eq id which)
              (progn (add-class button "active")
                     (remove-class body "hidden"))
              (progn (remove-class button "active")
                     (add-class body "hidden"))))))
    (when (eq which :tasks)
      (rebuild-tasks-list session))))

(defun rebuild-tasks-list (session)
  "Fresh list of registered background tasks with Run now buttons."
  (let ((body (gethash :tasks (session-output-bodies session))))
    (when (validp body)
      (destroy-children body)
      (let ((tasks (all-tasks)))
        (if tasks
            (dolist (task tasks)
              (let ((row (create-div body :class "niori-task-row")))
                (create-span row
                             :content (format nil "~A (every ~As)"
                                              (task-label task)
                                              (task-interval-seconds task)))
                (let ((button (create-button row :content "Run now"
                                              :class "niori-btn")))
                  (let ((task-id (task-id task)))
                    (set-on-click button
                                  (lambda (obj)
                                    (declare (ignore obj))
                                    (run-task-now task-id)))))))
            (create-div body
                        :content "No background tasks registered."
                        :class "niori-muted"))))))

(defun add-notification (session title message kind time)
  "Show a notification in the output panel and as a toast."
  (let ((body (gethash :notifications (session-output-bodies session))))
    (when (validp body)
      (let ((entry (create-div body
                               :class (format nil "niori-note niori-note-~A"
                                              (string-downcase kind)))))
        (setf (inner-html entry)
                  (format nil "<span class='niori-note-time'>~A</span><b>~A</b> ~A"
                          (html-esc time) (html-esc title) (html-esc message)))
        (place-inside-top-of entry body))))
  (let ((toasts (session-toast-area session)))
    (when (validp toasts)
      (let ((toast (create-div toasts
                               :class (format nil "niori-toast niori-toast-~A"
                                              (string-downcase kind)))))
        (setf (inner-html toast)
                  (format nil "<b>~A</b>~A" (html-esc title) (html-esc message)))
        (set-on-click toast (lambda (obj) (destroy obj)))))))

(defun add-log-line (session level message time)
  (let ((logs (gethash :logs (session-output-bodies session))))
    (when (validp logs)
      (create-div logs
                  :class "niori-log-line"
                  :content (format nil "[~A] ~A: ~A" time level message)))))

(defun install-session-subscriptions (session)
  "Wire the event bus to this page's output panel and status bar."
  (subscribe :notification
             (lambda (&key title message kind time)
               (add-notification session title message kind time)))
  (subscribe :log
             (lambda (&key level message time)
               (add-log-line session level message time)))
  (subscribe :sync-status
             (lambda (text)
               (update-sync-status session text))))
