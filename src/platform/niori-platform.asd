;;;; niori/src/platform/niori-platform.asd
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

(asdf:defsystem #:niori-platform
  :description "Niori Platform - module/service/command registries, event bus, persistence API, background tasks. Deliberately UI-agnostic: it never references CLOG."
  :author "Igor Anikeev"
  :license "GPL-3.0-or-later"
  :version "0.1.0"
  :depends-on (#:bordeaux-threads)
  :serial t
  :components ((:file "package")
               (:file "util")
               (:file "hooks")
               (:file "events")
               (:file "services")
               (:file "commands")
               (:file "modules")
               (:file "navigation")
               (:file "view-types")
               (:file "persistence")
               (:file "tasks")
               (:file "platform")))
