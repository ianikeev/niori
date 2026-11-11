;;;; niori/src/infra/config.lisp
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

;;; Plain-file configuration.  config/niori.conf contains a single
;;; property list, e.g.
;;;   (:port 8080 :host "127.0.0.1" :sync-interval-seconds 60)
;;; Only the keys present in the file override the defaults.

(defparameter *default-config*
  '(:port 8080
    :host "127.0.0.1"
    :auto-open t
    :data-directory "data/"
    :database-file "niori.db"
    :backup-directory "backups/"
    :backup-on-start nil
    :sync-enabled t
    :sync-interval-seconds 60)
  "Fallback values used for every key the conf file does not set.
Directory values must end with a path separator (/).")

(defparameter *config* (copy-list *default-config*))

(defparameter *config-base-dir* nil
  "Directory the application runs from; config/ and data/ live under it.")

(defun config-file-path (&optional (base-dir *config-base-dir*))
  (merge-pathnames "config/niori.conf" base-dir))

(defun load-config (&optional (base-dir (uiop:getcwd)))
  "Read config/niori.conf under BASE-DIR, merged over the defaults."
  (setf *config-base-dir* (uiop:pathname-directory-pathname base-dir))
  (let ((path (config-file-path)))
    (setf *config* (copy-list *default-config*))
    (when (probe-file path)
      (with-open-file (stream path :direction :input
                                   :if-does-not-exist nil)
        (let ((form (read stream nil nil)))
          (when (and (listp form) (evenp (length form)))
            (loop for (key value) on form by #'cddr
                  do (setf (getf *config* key) value))))))
    *config*))

(defun save-config ()
  "Write the current configuration back to config/niori.conf."
  (let ((path (config-file-path)))
    (ensure-directories-exist path)
    (with-open-file (stream path :direction :output
                                 :if-exists :supersede
                                 :if-does-not-exist :create)
      (prin1 *config* stream)
      (terpri stream)))
  *config*)

(defun config-get (key)
  "Current value for configuration KEY."
  (getf *config* key))

(defun config-set (key value)
  "Set configuration KEY to VALUE and persist it."
  (setf (getf *config* key) value)
  (ignore-errors (save-config))
  value)

(defun config-keys ()
  "All configuration keys currently in effect."
  (loop for key in *config* by #'cddr
        collect key))
