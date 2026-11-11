;;;; niori/src/platform/persistence.lisp
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

;;; Persistence API.  The platform defines the *contract only*:
;;;   - repositories: named logical tables owned by a module,
;;;   - migrations:   versioned, per-module schema steps,
;;;   - store protocol: generic functions implemented by the
;;;     infrastructure layer (niori-infra ships an SQLite store).
;;; Rows are property lists with keyword keys (:ID :NAME ...), which
;;; keeps module code free of SQL where practical.

(defparameter *store* nil
  "The active store instance, installed by the infrastructure layer.")

;;; ------------------------------------------------------------------
;;; Repositories
;;; ------------------------------------------------------------------

(defparameter *repositories-lock* (bt:make-lock "niori-repositories"))

(defparameter *repositories* (make-hash-table :test 'eq)
  "REPOSITORY-NAME -> repository struct.")

(defstruct (repository (:constructor %make-repository))
  (name nil)     ; keyword, e.g. :medications
  (table "")     ; SQL table name
  (module nil))  ; owning module keyword

(defun register-repository (name &key table (module nil))
  "Register or replace the logical repository NAME backed by TABLE."
  (bt:with-lock-held (*repositories-lock*)
    (setf (gethash name *repositories*)
          (%make-repository :name name :table (or table (string-downcase name))
                            :module module)))
  name)

(defun find-repository (name)
  (gethash name *repositories*))

(defun all-repositories ()
  (bt:with-lock-held (*repositories-lock*)
    (sort (loop for repository being the hash-values of *repositories*
                collect repository)
          #'string< :key (lambda (repository) (symbol-name (repository-name repository))))))

;;; ------------------------------------------------------------------
;;; Migrations
;;; ------------------------------------------------------------------

(defparameter *migrations-lock* (bt:make-lock "niori-migrations"))

(defparameter *migrations* (make-hash-table :test 'equal)
  "(MODULE . VERSION) -> migration struct.")

(defstruct (migration (:constructor %make-migration))
  (module nil)
  (version 0)
  (fn nil))       ; (lambda (store))

(defmacro define-migration (module version (store) &body body)
  "Declare migration VERSION for MODULE.  BODY runs with STORE bound to
the store instance and should create/alter the module's tables."
  `(register-migration ,module ,version (lambda (,store)
                                          (declare (ignorable ,store))
                                          ,@body)))

(defun register-migration (module version fn)
  "Register or replace migration VERSION of MODULE."
  (bt:with-lock-held (*migrations-lock*)
    (setf (gethash (cons module version) *migrations*)
          (%make-migration :module module :version version :fn fn)))
  version)

(defun all-migrations ()
  "All migrations ordered by module name, then version."
  (bt:with-lock-held (*migrations-lock*)
    (sort (loop for migration being the hash-values of *migrations*
                collect migration)
          (lambda (a b)
            (or (string< (symbol-name (migration-module a))
                         (symbol-name (migration-module b)))
                (and (eq (migration-module a) (migration-module b))
                     (< (migration-version a) (migration-version b))))))))

;;; ------------------------------------------------------------------
;;; Store protocol (implemented in niori-infra)
;;; ------------------------------------------------------------------

(defgeneric store-execute (store sql &rest params)
  (:documentation "Run DDL/DML with bound PARAMS; no result rows."))

(defgeneric store-migrate (store module version fn)
  (:documentation "Apply FN (a migration) inside a transaction, recording
(MODULE VERSION) in the store's migration bookkeeping.  Skip if recorded."))

(defgeneric store-list (store repository)
  (:documentation "All rows of REPOSITORY as plists, ordered by id."))

(defgeneric store-get (store repository id)
  (:documentation "Row with ID as a plist, or NIL."))

(defgeneric store-insert (store repository data)
  (:documentation "Insert DATA plist; returns the stored row including :ID."))

(defgeneric store-update (store repository id data)
  (:documentation "Update row ID with DATA plist (ignoring :ID)."))

(defgeneric store-delete (store repository id)
  (:documentation "Delete row ID."))

(defgeneric store-count (store repository)
  (:documentation "Number of rows in REPOSITORY."))

(defgeneric store-close (store)
  (:documentation "Close the store."))

;;; ------------------------------------------------------------------
;;; Repository conveniences (operate on *STORE*)
;;; ------------------------------------------------------------------

(defun resolve-repository (repo-or-name)
  (if (repository-p repo-or-name)
      repo-or-name
      (find-repository repo-or-name)))

(defmacro with-repository ((repository repo-or-name) &body body)
  `(let ((,repository (resolve-repository ,repo-or-name)))
     (unless (and ,repository *store*)
       (error "Repository ~S unavailable (is the infrastructure started?)"
              ,repo-or-name))
     ,@body))

(defun repo-list (repo-or-name)
  (with-repository (repository repo-or-name)
    (store-list *store* repository)))

(defun repo-get (repo-or-name id)
  (with-repository (repository repo-or-name)
    (store-get *store* repository id)))

(defun repo-insert (repo-or-name data)
  (with-repository (repository repo-or-name)
    (store-insert *store* repository data)))

(defun repo-update (repo-or-name id data)
  (with-repository (repository repo-or-name)
    (store-update *store* repository id data)))

(defun repo-delete (repo-or-name id)
  (with-repository (repository repo-or-name)
    (store-delete *store* repository id)))

(defun repo-count (repo-or-name)
  (with-repository (repository repo-or-name)
    (store-count *store* repository)))

(defun run-migrations ()
  "Apply every registered migration that the store has not recorded yet."
  (unless *store*
    (error "Cannot run migrations: no store is open"))
  (dolist (migration (all-migrations))
    (store-migrate *store*
                   (migration-module migration)
                   (migration-version migration)
                   (migration-fn migration))))
