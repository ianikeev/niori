;;;; niori/src/infra/infrastructure.lisp
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

(defun start-infrastructure (&optional (base-dir (uiop:getcwd)))
  "Open the store, publish the infrastructure services, register the
Tools commands and the synchronization background task.  Database
migrations are applied later by (niori-platform:run-migrations), after
all modules have been loaded."
  (load-config base-dir)
  (let ((path (database-path)))
    (ensure-directories-exist path)
    (setf *store* (open-store path))
    (provide-service :persistence *store* :provider :niori-infra)
    (provide-service :database-path (namestring path) :provider :niori-infra))
  (provide-service :config #'config-get :provider :niori-infra)
  (provide-service :config-keys #'config-keys :provider :niori-infra)
  (provide-service :sync #'sync-now :provider :niori-infra)

  (register-command :tools.backup
                    :title "Backup Now"
                    :menu-path '("Tools")
                    :tooltip "Copy the SQLite database into the backup folder"
                    :module :niori-infra
                    :handler (lambda (session)
                               (declare (ignore session))
                               (backup-now)))

  (register-task :infrastructure.sync
                 :label "Synchronization heartbeat"
                 :interval-seconds (or (config-get :sync-interval-seconds) 60)
                 :fn (lambda ()
                       (if (config-get :sync-enabled)
                           (sync-now)
                           (publish :sync-status "Synchronization disabled"))))

  (when (config-get :backup-on-start)
    (backup-now))
  (log-line :info (format nil "Infrastructure started (store: ~A)"
                          (store-path *store*))))

(defun close-infrastructure ()
  "Close the store and unpublish infrastructure services."
  (when *store*
    (store-close *store*)
    (setf *store* nil))
  (remove-service :persistence)
  (remove-service :database-path)
  (remove-service :config)
  (remove-service :config-keys)
  (remove-service :sync)
  (log-line :info "Infrastructure stopped"))
