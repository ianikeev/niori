;;;; niori/src/ui/statusbar.lisp
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

(in-package #:niori-ui)

(defun build-statusbar (session)
  "Application state on the left, database and sync status on the right."
  (let ((bar (create-div (session-status-row session) :class "niori-status")))
    (setf (session-status-state session)
          (create-span bar :content "Starting..."))
    (create-span bar :class "niori-spacer" :content "")
    (with-service (path :database-path)
      (create-span bar :content (format nil "DB: ~A" path)))
    (setf (session-status-sync session)
          (create-span bar :content "Sync: waiting..."))))

(defun set-status-text (session text)
  "Update the application state area.  Installed as
niori-platform:*set-status-hook*."
  (let ((state (session-status-state session)))
    (when (validp state)
      (setf (text state) text))))

(defun update-sync-status (session text)
  "React to :SYNC-STATUS events."
  (let ((sync (session-status-sync session)))
    (when (validp sync)
      (setf (text sync) text))))
