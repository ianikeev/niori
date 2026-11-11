;;;; niori/src/platform/package.lisp
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

(defpackage #:niori-platform
  (:use #:cl)
  (:documentation "Niori Platform: the module kernel every Niori module
talks to.  It hosts the module registry, the service registry, the command
system (with keyboard shortcuts), the navigation and view-type registries,
the persistence API (repository protocol + database migrations), the
background task registry and the event bus.  It is UI-agnostic: user
interface hooks are plain function slots installed by the UI layer.")
  (:export
   ;; util
   #:now-string #:today-string #:date-string #:keyword->title
   #:date-universal #:iso-date-universal #:string+ #:html-esc
   ;; ui hooks (installed by niori-ui)
   #:*open-view-hook* #:*open-window-hook*
   #:*set-properties-hook* #:*set-status-hook*
   #:open-window #:set-properties #:set-status
   ;; event bus
   #:subscribe #:unsubscribe-all #:publish #:notify #:log-line
   ;; services
   #:provide-service #:lookup-service #:remove-service
   #:all-service-names #:service-provider #:with-service
   ;; commands
   #:register-command #:find-command #:all-commands #:run-command
   #:command-for-key #:format-shortcut
   #:command-id #:command-title #:command-menu-path #:command-group
   #:command-shortcut #:command-tooltip #:command-toolbar-p
   #:command-enabled-fn #:command-handler #:command-module
   ;; modules
   #:define-module #:register-module #:find-module #:all-modules
   #:module-id #:module-name #:module-version #:module-description
   #:module-start-fn #:module-shutdown-fn
   #:start-module #:shutdown-module #:start-all-modules #:shutdown-all-modules
   ;; navigation
   #:register-navigation #:all-navigation-entries
   #:navigation-id #:navigation-label #:navigation-parent
   #:navigation-on-open #:navigation-module
   ;; view / editor types
   #:register-view-type #:find-view-type #:all-view-types
   #:view-type-id #:view-type-label #:view-type-builder #:view-type-module
   #:open-view
   ;; persistence api
   #:*store*
   #:repository #:repository-name #:repository-table #:repository-module
   #:register-repository #:find-repository #:all-repositories
   #:migration #:migration-module #:migration-version #:migration-fn
   #:register-migration #:define-migration #:all-migrations #:run-migrations
   #:store-execute #:store-migrate
   #:store-list #:store-get #:store-insert #:store-update
   #:store-delete #:store-count #:store-close
   #:repo-list #:repo-get #:repo-insert #:repo-update #:repo-delete #:repo-count
   ;; background tasks
   #:register-task #:find-task #:all-tasks #:run-task-now
   #:start-tasks #:stop-tasks #:tasks-running-p
   ;; lifecycle
   #:boot-platform #:shutdown-platform #:platform-booted-p))
