;;;; niori/src/app/niori-app.asd
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

(asdf:defsystem #:niori-app
  :description "Niori Application - entry point and lifecycle: boots the platform, opens the store, loads the configured module systems and starts the UI"
  :author "Igor Anikeev"
  :license "GPL-3.0-or-later"
  :version "0.1.0"
  :depends-on (#:niori-platform
               #:niori-infra
               #:niori-ui
               #:uiop)
  :serial t
  :components ((:file "package")
               (:file "app")))
