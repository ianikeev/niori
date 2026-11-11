;;;; niori/modules/niori-mod-tests/niori-mod-tests.asd
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

(asdf:defsystem #:niori-mod-tests
  :description "Niori module: laboratory and clinical test results"
  :author "The Niori Authors"
  :license "GPL-3.0-or-later"
  :version "0.1.0"
  :depends-on (#:niori-platform
               #:clog)
  :serial t
  :components ((:file "package")
               (:file "tests")))
