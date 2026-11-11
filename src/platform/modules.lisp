;;;; niori/src/platform/modules.lisp
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

;;; The module registry.  Every Niori module is an independent ASDF
;;; system whose package calls DEFINE-MODULE at load time.  The entry
;;; point (niori-app) decides which module systems to load - typically
;;; from config/modules.lisp - so modules can be added or removed
;;; without touching the rest of the application.

(defparameter *modules-lock* (bt:make-lock "niori-modules"))

(defparameter *module-registry* (make-hash-table :test 'eq)
  "MODULE-ID -> module struct.")

(defstruct (module (:constructor %make-module))
  (id nil)
  (name "")
  (version "0.0.0")
  (description "")
  (start-fn nil)     ; (lambda ()) called by START-MODULE, may be nil
  (shutdown-fn nil)  ; (lambda ()) called by SHUTDOWN-MODULE, may be nil
  (started-p nil))

(defmacro define-module (id &key name version description start-fn shutdown-fn)
  "Declare a Niori module.  Place at the top level of a module package so
that loading the module's ASDF system registers it."
  `(register-module ,id
                    :name ,(or name (string (keyword->title id)))
                    :version ,version :description ,description
                    :start-fn ,start-fn :shutdown-fn ,shutdown-fn))

(defun register-module (id &key name version description start-fn shutdown-fn)
  "Register or update the module ID (idempotent across reloads)."
  (bt:with-lock-held (*modules-lock*)
    (let ((existing (gethash id *module-registry*)))
      (if existing
          (setf (module-name existing) (or name (module-name existing))
                (module-version existing) (or version (module-version existing))
                (module-description existing) (or description (module-description existing))
                (module-start-fn existing) (or start-fn (module-start-fn existing))
                (module-shutdown-fn existing) (or shutdown-fn (module-shutdown-fn existing)))
          (setf (gethash id *module-registry*)
                (%make-module :id id :name (or name (keyword->title id))
                              :version (or version "0.1.0")
                              :description (or description "")
                              :start-fn start-fn :shutdown-fn shutdown-fn)))))
  id)

(defun find-module (id)
  (gethash id *module-registry*))

(defun all-modules ()
  "All registered modules sorted by id."
  (bt:with-lock-held (*modules-lock*)
    (sort (loop for module being the hash-values of *module-registry*
                collect module)
          #'string< :key (lambda (module) (symbol-name (module-id module))))))

(defun start-module (id)
  "Run the module's start function (if any) and mark it started."
  (let ((module (find-module id)))
    (when (and module (not (module-started-p module)))
      (when (module-start-fn module)
        (funcall (module-start-fn module)))
      (setf (module-started-p module) t)
      (log-line :info (format nil "Module ~A started" (module-name module))))
    (and module t)))

(defun shutdown-module (id)
  (let ((module (find-module id)))
    (when (and module (module-started-p module))
      (when (module-shutdown-fn module)
        (funcall (module-shutdown-fn module)))
      (setf (module-started-p module) nil))
    (and module t)))

(defun start-all-modules ()
  (dolist (module (all-modules))
    (handler-case (start-module (module-id module))
      (error (condition)
        (notify "Module failed to start"
                (format nil "~A: ~A" (module-name module) condition)
                :kind :error)))))

(defun shutdown-all-modules ()
  (dolist (module (all-modules))
    (handler-case (shutdown-module (module-id module))
      (error () nil))))
