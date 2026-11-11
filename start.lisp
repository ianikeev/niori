;;;; niori/start.lisp - load and start Niori.
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
;;;
;;;   sbcl --load start.lisp
;;;
;;; or evaluate the same forms in any Lisp image with Quicklisp.  The
;;; folder does not need to be in ~/common-lisp: it registers itself
;;; with ASDF relative to this file's location.

(require :asdf)

(let ((here (uiop:pathname-directory-pathname
             (truename (or *load-pathname* *default-pathname-defaults*)))))
  (asdf:initialize-source-registry
   `(:source-registry (:tree ,(namestring here))
                      :inherit-configuration)))

;;; Load the app; CLOG and friends come from Quicklisp:
#+quicklisp
(ql:quickload :niori)
#-quicklisp
(asdf:load-system :niori)

;;; Boot platform + infrastructure + modules and open the browser
;;; (auto-open can be turned off in config/niori.conf):
(niori-app:start)
