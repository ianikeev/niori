;;;; niori/src/platform/platform.lisp
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

(in-package #:niori-platform)

;;; Platform lifecycle.  BOOT-PLATFORM gives every registry a clean
;;; slate so the application can be restarted inside one Lisp image.

(defparameter *platform-booted-p* nil)

(defun boot-platform ()
  "Reset transient state and mark the platform booted.  Registries are
only cleared on the very first boot in an image, so calling START twice
keeps already-registered modules (their registrations are idempotent)."
  (setf *open-view-hook* nil *open-window-hook* nil
        *set-properties-hook* nil *set-status-hook* nil)
  (bt:with-lock-held (*event-lock*) (clrhash *subscribers*))
  (unless *platform-booted-p*
    (bt:with-lock-held (*services-lock*) (clrhash *services*))
    (bt:with-lock-held (*commands-lock*) (clrhash *commands*))
    (bt:with-lock-held (*modules-lock*)  (clrhash *module-registry*))
    (bt:with-lock-held (*view-types-lock*) (clrhash *view-types*))
    (bt:with-lock-held (*repositories-lock*) (clrhash *repositories*))
    (bt:with-lock-held (*migrations-lock*) (clrhash *migrations*))
    (bt:with-lock-held (*tasks-lock*) (clrhash *tasks*))
    (bt:with-lock-held (*navigation-lock*)
      (setf *navigation-entries* nil)))
  (setf *store* nil *platform-booted-p* t)
  (log-line :info "Niori platform booted"))

(defun shutdown-platform ()
  "Tear the platform down (registries keep their contents for inspection)."
  (setf *platform-booted-p* nil
        *open-view-hook* nil *open-window-hook* nil
        *set-properties-hook* nil *set-status-hook* nil)
  (bt:with-lock-held (*event-lock*) (clrhash *subscribers*))
  (log-line :info "Niori platform shut down"))

(defun platform-booted-p ()
  *platform-booted-p*)
