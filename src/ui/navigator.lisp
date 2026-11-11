;;;; niori/src/ui/navigator.lisp
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

(defun build-navigator (session)
  "Render the navigation entries contributed by the modules."
  (let ((container (session-navigator-body session))
        (entries (all-navigation-entries)))
    (destroy-children container)
    (let ((roots (remove-if #'navigation-parent entries)))
      (if roots
          (dolist (root roots)
            (let ((root-element
                    (create-div container :class "niori-nav-root"
                                :content (navigation-label root))))
              (when (navigation-on-open root)
                (let ((on-open (navigation-on-open root)))
                  (set-on-click root-element
                                (lambda (obj)
                                  (declare (ignore obj))
                                  (funcall on-open session)))))
              (dolist (child (remove-if-not
                              (lambda (entry)
                                (eq (navigation-parent entry)
                                    (navigation-id root)))
                              entries))
                (when (navigation-on-open child)
                  (let ((on-open (navigation-on-open child)))
                    (let ((child-element
                            (create-div container :class "niori-nav-child"
                                        :content (navigation-label child))))
                      (set-on-click child-element
                                    (lambda (obj)
                                      (declare (ignore obj))
                                      (funcall on-open session)))))))))
          (create-div container
                      :content "No navigation entries registered."
                      :class "niori-muted")))))
