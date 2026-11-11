;;;; niori/src/platform/view-types.lisp
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

;;; Editor/view types.  A module registers a view type id with a
;;; BUILDER function of (CONTENT-ELEMENT SESSION DATA).  The UI layer
;;; installs *OPEN-VIEW-HOOK*; OPEN-VIEW routes through it so modules
;;; never build window chrome themselves - they only fill content.

(defparameter *view-types-lock* (bt:make-lock "niori-view-types"))

(defparameter *view-types* (make-hash-table :test 'eq)
  "VIEW-TYPE-ID -> view-type struct.")

(defstruct (view-type (:constructor %make-view-type))
  (id nil)
  (label "")
  (builder nil)    ; (lambda (content session data))
  (module nil))

(defun register-view-type (id &key label builder (module nil))
  "Register or replace the view type ID."
  (unless builder
    (error "View type ~S registered without a builder" id))
  (bt:with-lock-held (*view-types-lock*)
    (setf (gethash id *view-types*)
          (%make-view-type :id id :label (or label (keyword->title id))
                           :builder builder :module module)))
  id)

(defun find-view-type (id)
  (gethash id *view-types*))

(defun all-view-types ()
  (bt:with-lock-held (*view-types-lock*)
    (sort (loop for view-type being the hash-values of *view-types*
                collect view-type)
          #'string< :key (lambda (view-type) (symbol-name (view-type-id view-type))))))

(defun open-view (view-type &key data title (session nil))
  "Open VIEW-TYPE in the editor area of SESSION, optionally passing DATA
(a filter keyword, record, ...) and overriding the tab TITLE."
  (let ((definition (if (view-type-p view-type) view-type (find-view-type view-type))))
    (cond
      ((null definition)
       (notify "Unknown view" (format nil "No view type registered as ~S" view-type)
               :kind :error))
      ((and *open-view-hook* session)
       (funcall *open-view-hook* session definition data title))
      (t
       (log-line :warn "open-view: no active session or UI hook - ignored")))
    definition))
