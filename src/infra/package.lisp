;;;; niori/src/infra/package.lisp
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

(defpackage #:niori-infra
  (:use #:cl #:niori-platform)
  (:documentation "Niori infrastructure layer: the SQLite-backed store
implementing the platform persistence protocol, file-based configuration,
database backups and the synchronization heartbeat service.")
  (:import-from #:sqlite
                #:connect
                #:disconnect
                #:execute-non-query
                #:execute-to-list
                #:execute-single
                #:last-insert-rowid)
  (:export
   #:open-store #:sqlite-store #:store-path
   #:load-config #:save-config #:config-get #:config-set #:config-keys
   #:database-path #:backup-directory-path #:backup-now
   #:sync-now
   #:start-infrastructure #:close-infrastructure))
