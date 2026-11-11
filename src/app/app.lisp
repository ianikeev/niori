;;;; niori/src/app/app.lisp
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

(in-package #:niori-app)

(defun app-base-dir ()
  "Niori source root: two levels above this system's source directory."
  (uiop:pathname-parent-directory-pathname
   (uiop:pathname-parent-directory-pathname
    (asdf:system-source-directory :niori-app))))

(defun default-module-systems ()
  "Used when config/modules.lisp is missing."
  '(:niori-mod-medications
    :niori-mod-visits
    :niori-mod-tests
    :niori-mod-vaccinations))

(defun configured-module-systems (base-dir)
  (let ((path (merge-pathnames "config/modules.lisp" base-dir)))
    (or (when (probe-file path)
          (with-open-file (stream path :direction :input
                                        :if-does-not-exist nil)
            (let ((form (read stream nil nil)))
              (when (listp form) form))))
        (default-module-systems))))

(defun load-configured-modules (base-dir)
  "Load every module system listed in config/modules.lisp.  Modules are
independent ASDF systems: adding one is a matter of adding its directory,
listing it here and restarting."
  (let ((systems (configured-module-systems base-dir)))
    (dolist (system systems)
      (handler-case (asdf:load-system system)
        (error (condition)
          (niori-platform:notify "Module failed to load"
                                 (format nil "~S: ~A" system condition)
                                 :kind :error))))
    (niori-platform:log-line
     :info (format nil "Module systems loaded: ~{~S~^ ~}" systems))))

(defun start (&key port host (auto-open nil supplied-p))
  "Boot Niori: platform, infrastructure, migrations, modules, tasks, UI.
Parameter values override config/niori.conf when supplied."
  (let ((base-dir (app-base-dir)))
    ;; make all module systems findable relative to the source root
    (asdf:initialize-source-registry
     `(:source-registry (:tree ,(namestring base-dir))
                        :inherit-configuration))
    (niori-platform:boot-platform)
    (niori-infra:start-infrastructure base-dir)
    (load-configured-modules base-dir)
    ;; migrations run after the modules are loaded: modules declare
    ;; their schema steps at load time
    (niori-platform:run-migrations)
    (niori-platform:start-all-modules)
    (niori-platform:start-tasks)
    (niori-ui:start-ui
     :host (or host (niori-infra:config-get :host) "127.0.0.1")
     :port (or port (niori-infra:config-get :port) 8080)
     :auto-open (if supplied-p auto-open
                    (niori-infra:config-get :auto-open)))
    (niori-platform:notify "Niori is ready"
                           (format nil "Open http://~A:~A"
                                   (or host (niori-infra:config-get :host) "127.0.0.1")
                                   (or port (niori-infra:config-get :port) 8080)))
    t))

(defun stop ()
  "Shut everything down in reverse order."
  (niori-ui:stop-ui)
  (niori-platform:stop-tasks)
  (niori-platform:shutdown-all-modules)
  (niori-infra:close-infrastructure)
  (niori-platform:shutdown-platform)
  (niori-platform:log-line :info "Niori stopped"))
