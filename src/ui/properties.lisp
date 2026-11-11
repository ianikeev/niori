;;;; niori/src/ui/properties.lisp
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

(in-package #:niori-ui)

(defun build-properties (session)
  "Create the properties panel (header + body)."
  (let ((col (session-props-col session)))
    (create-div col :class "niori-panel-header" :content "Properties")
    (setf (session-props-body session)
          (create-div col :class "niori-body"))))

(defun render-properties (session plist)
  "Show PLIST (alternating string keys and values) in the panel.
Installed as niori-platform:*set-properties-hook*."
  (let ((body (session-props-body session)))
    (when (validp body)
      (destroy-children body)
      (let ((table (create-table body :class "niori-props-table")))
        (loop for (key value) on plist by #'cddr
              do (let ((row (create-table-row table)))
                   (let ((key-cell (create-table-column row :content (princ-to-string key))))
                     (add-class key-cell "niori-props-key"))
                   (create-table-column row
                                        :content (html-esc value))))))))
