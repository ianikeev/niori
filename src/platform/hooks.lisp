;;;; niori/src/platform/hooks.lisp
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

(in-package #:niori-platform)

;;; The platform is UI-agnostic.  The presentation layer (niori-ui)
;;; installs these function slots at boot; modules never touch CLOG
;;; through the platform - they call the small facades below.

(defparameter *open-view-hook* nil
  "Function of (SESSION VIEW-TYPE DATA TITLE) that opens DATA in the editor area.")

(defparameter *open-window-hook* nil
  "Function of (SESSION ID TITLE BUILDER WIDTH HEIGHT) that opens a managed window.")

(defparameter *set-properties-hook* nil
  "Function of (SESSION PLIST) that shows context-sensitive properties.")

(defparameter *set-status-hook* nil
  "Function of (SESSION TEXT) that updates the status bar application state.")

(defun open-window (session id &key title builder (width 460) (height 340))
  "Open (or focus, if already open) the window registered under ID.
BUILDER is a function of (CONTENT-ELEMENT SESSION) that fills the window."
  (if (and *open-window-hook* session)
      (funcall *open-window-hook* session id title builder width height)
      (log-line :warn "open-window: no active UI window manager - ignored")))

(defun set-properties (session plist)
  "Show context-sensitive information in the properties panel.
PLIST is a list alternating string keys and values."
  (when (and *set-properties-hook* session)
    (funcall *set-properties-hook* session plist)))

(defun set-status (session text)
  "Update the application-state part of the status bar."
  (when (and *set-status-hook* session)
    (funcall *set-status-hook* session text)))
