;;;; niori/src/platform/services.lisp
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

;;; The service registry is Niori's equivalent of the NetBeans Lookup:
;;; providers publish objects under a keyword; consumers look them up
;;; without any compile-time dependency on the provider module.

(defparameter *services-lock* (bt:make-lock "niori-services"))

(defparameter *services* (make-hash-table :test 'eq)
  "SERVICE-NAME -> (list VALUE PROVIDER-MODULE).")

(defun provide-service (name value &key provider)
  "Publish VALUE under the service NAME.  PROVIDER, when given, is the
module keyword that provides the service (shown in the module info dialog)."
  (bt:with-lock-held (*services-lock*)
    (setf (gethash name *services*) (list value provider)))
  name)

(defun lookup-service (name)
  "Return the object published under NAME, or NIL."
  (first (gethash name *services*)))

(defun service-provider (name)
  "Return the module keyword that provides NAME, or NIL."
  (second (gethash name *services*)))

(defun remove-service (name)
  (bt:with-lock-held (*services-lock*)
    (remhash name *services*))
  name)

(defun all-service-names ()
  "All registered service names, sorted."
  (bt:with-lock-held (*services-lock*)
    (sort (loop for name being the hash-keys of *services*
                collect name)
          #'string< :key #'symbol-name)))

(defmacro with-service ((var name) &body body)
  "Evaluate BODY with VAR bound to the service NAME; skip if absent."
  `(let ((,var (lookup-service ,name)))
     (when ,var
       ,@body)))
