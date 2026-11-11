;;;; niori/src/infra/sync.lisp
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

;;; Synchronization is a stub in the scaffold: the heartbeat task simply
;;; publishes :SYNC-STATUS events that the status bar displays.  Replace
;;; SYNC-NOW with real multi-device synchronization code; everything
;;; else (status bar, tasks panel, configuration key) already reacts.

(defparameter *last-sync* nil)

(defun sync-now ()
  "Mark this moment as synchronized and tell the UI."
  (setf *last-sync* (now-string))
  (publish :sync-status (format nil "Synchronized at ~A" *last-sync*))
  *last-sync*)
