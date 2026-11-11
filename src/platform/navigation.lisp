;;;; niori/src/platform/navigation.lisp
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

(in-package #:niori-platform)

;;; Navigation entries feed the Navigator panel.  A module registers a
;;; root entry plus optional children (PARENT is the root entry's id).
;;; ON-OPEN is a function of (SESSION) invoked when the user clicks the
;;; entry - typically it opens one of the module's views.

(defparameter *navigation-lock* (bt:make-lock "niori-navigation"))

(defparameter *navigation-entries* nil
  "Registration-ordered list of navigation-entry structs.")

(defstruct (navigation-entry (:constructor %make-navigation-entry)
                             (:conc-name navigation-))
  (id nil)
  (label "")
  (parent nil)     ; id of the root entry this belongs under, or nil
  (on-open nil)    ; (lambda (session))
  (module nil))

(defun register-navigation (id &key label parent on-open (module nil))
  "Register or replace the navigation entry ID."
  (bt:with-lock-held (*navigation-lock*)
    (setf *navigation-entries*
          (append (remove id *navigation-entries* :key #'navigation-id)
                  (list (%make-navigation-entry
                         :id id :label (or label (keyword->title id))
                         :parent parent :on-open on-open :module module)))))
  id)

(defun all-navigation-entries ()
  "All navigation entries in registration order."
  (copy-list *navigation-entries*))
