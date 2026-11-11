;;;; niori/src/ui/windows.lisp
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

;;; CLOG window manager implementation of the platform's window facade.
;;; This is the fix for the old "windows overlap and cannot be moved"
;;; bug: all windows are clog-gui windows (draggable through their title
;;; bar) and are cascaded so new windows never sit exactly on top of
;;; existing ones.

(defun open-managed-window (session id title builder width height)
  "Open the window registered under ID, or focus it if it already exists."
  (let* ((body (session-body session))
         (existing (ignore-errors (clog-gui:window-by-param body id))))
    (if (and existing (validp existing))
        (progn (clog-gui:window-focus existing) existing)
        (let* ((offset (* 32 (mod (incf (session-window-cascade session)) 6)))
               (window (clog-gui:create-gui-window
                        body :title title
                        :top (+ 60 offset) :left (+ 140 offset)
                        :width (or width 460) :height (or height 340)
                        :window-param id)))
          (funcall builder (clog-gui:window-content window) session)
          (clog-gui:window-focus window)
          window))))

(defun install-ui-hooks ()
  "Install the platform UI hooks.  Called once from START-UI."
  (setf *open-view-hook*
        (lambda (session view-type data title)
          (open-view-in-session session view-type data title)))
  (setf *open-window-hook*
        (lambda (session id title builder width height)
          (open-managed-window session id title builder width height)))
  (setf *set-properties-hook*
        (lambda (session plist)
          (render-properties session plist)))
  (setf *set-status-hook*
        (lambda (session text)
          (set-status-text session text)))
  (log-line :info "UI hooks installed"))
