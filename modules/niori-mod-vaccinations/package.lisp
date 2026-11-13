;;;; niori/modules/niori-mod-vaccinations/package.lisp
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

(defpackage #:niori-mod-vaccinations
  (:use #:cl #:clog #:niori-platform)
  (:shadowing-import-from #:niori-platform #:open-window)
  (:documentation "Niori module: vaccinations.  Demonstrates a background
task (booster reminders) that publishes events instead of touching the
UI directly, plus a filtered child navigation entry (Due soon)."))
