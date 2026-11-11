;;;; niori/src/platform/events.lisp
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

(in-package #:niori-platform)

;;; Simple synchronous event bus.  Modules stay decoupled by publishing
;;; and subscribing instead of calling each other directly.  Event types
;;; used by Niori itself:
;;;   :notification  (&key title message kind time)   - output panel + toasts
;;;   :log           (&key level message time)        - output panel, Logs tab
;;;   :sync-status   (text)                           - status bar

(defparameter *event-lock* (bt:make-lock "niori-events"))

(defparameter *subscribers* (make-hash-table :test 'eq)
  "EVENT-TYPE -> list of handler functions.")

(defun subscribe (event-type handler)
  "Register HANDLER for EVENT-TYPE.  Returns EVENT-TYPE."
  (bt:with-lock-held (*event-lock*)
    (pushnew handler (gethash event-type *subscribers* nil)))
  event-type)

(defun unsubscribe-all (event-type)
  "Drop all handlers for EVENT-TYPE."
  (bt:with-lock-held (*event-lock*)
    (remhash event-type *subscribers*))
  event-type)

(defun publish (event-type &rest arguments)
  "Dispatch ARGUMENTS to every handler registered for EVENT-TYPE.
A failing handler is reported on *ERROR-OUTPUT* and skipped so that one
bad subscriber cannot take the whole application down."
  (let ((handlers (bt:with-lock-held (*event-lock*)
                    (copy-list (gethash event-type *subscribers*)))))
    (dolist (handler handlers)
      (handler-case (apply handler arguments)
        (error (condition)
          (format *error-output*
                  "~&[niori] handler error on event ~S: ~A~%"
                  event-type condition)))))
  arguments)

(defun notify (title message &key (kind :info))
  "Publish a user-facing notification.  KIND is one of :INFO :WARN :ERROR."
  (publish :notification :title title :message message :kind kind
                         :time (now-string)))

(defun log-line (level message)
  "Publish a log line for the output panel.  LEVEL is :INFO :WARN or :ERROR."
  (publish :log :level level :message message :time (now-string)))
