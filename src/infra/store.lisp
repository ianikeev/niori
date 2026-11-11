;;;; niori/src/infra/store.lisp
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

(in-package #:niori-infra)

;;; SQLite store implementing the platform's persistence protocol.
;;; Rows cross the API boundary as property lists (:ID :NAME ...);
;;; values are always passed to SQLite as bound parameters, never
;;; spliced into SQL strings.  Table names come from trusted repository
;;; registrations, not from user input.

(defclass sqlite-store ()
  ((db :initarg :db :reader store-db)
   (path :initarg :path :reader store-path)
   (lock :initform (bt:make-lock "niori-db") :reader store-lock)))

(defparameter *inside-migrate* nil
  "Bound by STORE-MIGRATE while a migration body runs on the locked
connection.")

(defun open-store (path)
  "Open (creating if necessary) the SQLite database at PATH."
  (ensure-directories-exist path)
  (make-instance 'sqlite-store :db (connect (namestring path))
                               :path path))

(defmacro with-db ((db store) &body body)
  "Serialize all database access through one connection-wide lock."
  `(bt:with-lock-held ((store-lock ,store))
     (let ((,db (store-db ,store)))
       ,@body)))

(defun to-keyword (name)
  (intern (string-upcase (string name)) :keyword))

(defun to-column (keyword)
  (string-downcase (symbol-name keyword)))

(defun table-columns (db table)
  "Column names of TABLE via PRAGMA table_info."
  (mapcar #'second
          (execute-to-list db (format nil "PRAGMA table_info(~A)" table))))

(defun row->plist (columns row)
  (loop for column in columns
        for value in row
        append (list (to-keyword column) value)))

(defun data-columns (data)
  "Column keywords of a DATA plist, excluding :ID."
  (loop for key in data by #'cddr
        unless (eq key :id)
          collect key))

(defmethod store-execute ((store sqlite-store) sql &rest params)
  (if *inside-migrate*
      ;; Migration bodies run with the lock already held by
      ;; STORE-MIGRATE (so the whole migration is one transaction);
      ;; the dynamic binding keeps nested STORE-EXECUTE calls from
      ;; re-trying the non-recursive lock.
      (apply #'execute-non-query (store-db store) sql params)
      (with-db (db store)
        (apply #'execute-non-query db sql params))))

(defmethod store-migrate ((store sqlite-store) module version fn)
  (let (applied)
    (with-db (db store)
      (execute-non-query
       db "CREATE TABLE IF NOT EXISTS niori_schema_migrations
             (module TEXT NOT NULL, version INTEGER NOT NULL,
              applied_at TEXT, PRIMARY KEY (module, version))")
      (unless (execute-to-list
               db "SELECT version FROM niori_schema_migrations
                   WHERE module = ? AND version = ?"
               (symbol-name module) version)
        (execute-non-query db "BEGIN")
        (handler-case
            (let ((*inside-migrate* t))
              (funcall fn store)
              (execute-non-query db "COMMIT")
              (execute-non-query
               db "INSERT INTO niori_schema_migrations
                     (module, version, applied_at) VALUES (?, ?, ?)"
               (symbol-name module) version (now-string))
              (setf applied t))
          (error (condition)
            (ignore-errors (execute-non-query db "ROLLBACK"))
            (error condition)))))
    (when applied
      (log-line :info (format nil "Migration ~A v~A applied" module version)))
    applied))

(defmethod store-list ((store sqlite-store) repository)
  (with-db (db store)
    (let* ((table (repository-table repository))
           (columns (table-columns db table))
           (rows (execute-to-list db (format nil "SELECT * FROM ~A ORDER BY id" table))))
      (mapcar (lambda (row) (row->plist columns row)) rows))))

(defmethod store-get ((store sqlite-store) repository id)
  (with-db (db store)
    (let* ((table (repository-table repository))
           (columns (table-columns db table))
           (rows (execute-to-list db (format nil "SELECT * FROM ~A WHERE id = ?" table) id)))
      (when rows
        (row->plist columns (first rows))))))

(defmethod store-insert ((store sqlite-store) repository data)
  (with-db (db store)
    (let* ((table (repository-table repository))
           (keys (data-columns data))
           (columns (mapcar #'to-column keys))
           (values (loop for key in keys collect (getf data key)))
           (placeholders (format nil "~{~A~^, ~}"
                                 (loop for key in keys collect "?"))))
      (apply #'execute-non-query db
             (format nil "INSERT INTO ~A (~{~A~^, ~}) VALUES (~A)"
                     table columns placeholders)
             values)
      (let* ((id (last-insert-rowid db))
             (all-columns (table-columns db table))
             (rows (execute-to-list db (format nil "SELECT * FROM ~A WHERE id = ?" table) id)))
        (when rows
          (row->plist all-columns (first rows)))))))

(defmethod store-update ((store sqlite-store) repository id data)
  (with-db (db store)
    (let* ((table (repository-table repository))
           (keys (data-columns data))
           (assignments (mapcar #'to-column keys))
           (values (loop for key in keys collect (getf data key))))
      (when assignments
        (apply #'execute-non-query db
               (format nil "UPDATE ~A SET ~{~A = ?~^, ~} WHERE id = ?" table assignments)
               (append values (list id))))
      (let* ((columns (table-columns db table))
             (rows (execute-to-list db (format nil "SELECT * FROM ~A WHERE id = ?" table) id)))
        (when rows
          (row->plist columns (first rows)))))))

(defmethod store-delete ((store sqlite-store) repository id)
  (with-db (db store)
    (execute-non-query db (format nil "DELETE FROM ~A WHERE id = ?"
                                  (repository-table repository))
                       id)
    t))

(defmethod store-count ((store sqlite-store) repository)
  (with-db (db store)
    (let ((count (execute-single db (format nil "SELECT COUNT(*) FROM ~A"
                                            (repository-table repository)))))
      (or count 0))))

(defmethod store-close ((store sqlite-store))
  (ignore-errors (disconnect (store-db store))))
