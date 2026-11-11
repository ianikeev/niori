;;;; niori/src/infra/backup.lisp
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

(in-package #:niori-infra)

(defun database-path ()
  "Absolute path of the SQLite database file."
  (merge-pathnames (config-get :database-file)
                   (merge-pathnames (config-get :data-directory)
                                    *config-base-dir*)))

(defun backup-directory-path ()
  "Absolute path of the backup folder."
  (merge-pathnames (config-get :backup-directory) *config-base-dir*))

(defun backup-timestamp ()
  (multiple-value-bind (sec min hour day month year)
      (decode-universal-time (get-universal-time))
    (format nil "~4,'0d~2,'0d~2,'0dT~2,'0d~2,'0d~2,'0d"
            year month day hour min sec)))

(defun backup-now ()
  "Copy the database file into the backup folder and notify the user."
  (let* ((source (database-path))
         (target (merge-pathnames
                  (format nil "niori-backup-~A.db" (backup-timestamp))
                  (ensure-directories-exist (backup-directory-path)))))
    (unless (probe-file source)
      (error "Database file ~A does not exist" source))
    (uiop:copy-file source target)
    (notify "Backup created" (enough-namestring target *config-base-dir*))
    (log-line :info (format nil "Database backed up to ~A" target))
    target))
