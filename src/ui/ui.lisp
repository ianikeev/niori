;;;; niori/src/ui/ui.lisp
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

(in-package #:niori-ui)

;;; Server startup and the per-connection page assembly.

(defun app-static-root ()
  "Niori's static file directory (two levels above this system's
source directory).  Served by CLOG so /css/niori.css, /css/w3.css and
jQuery-UI resolve; see static-files/."
  (uiop:pathname-parent-directory-pathname
   (uiop:pathname-parent-directory-pathname
    (asdf:system-source-directory :niori-ui))))

(defun build-shell (session)
  "Create the docked layout:
menu bar / toolbar / [navigator | editor | properties] / output / status."
  (let ((body (session-body session)))
    ;; The stylesheet is a real file served from static-files/css/
    ;; (inline <style> injection would get HTML-escaped on the wire
    ;; and entities are not decoded inside <style> elements).
    (load-css (html-document body) "/css/niori.css")
    (setf (session-toast-area session)
          (create-div body :class "niori-toasts"))
    (let ((shell (create-div body :class "niori-shell")))
      (setf (session-menu-row session)
            (create-div shell :class "niori-menu-row"))
      (setf (session-toolbar-row session)
            (create-div shell :class "niori-toolbar-row"))
      (let ((main (create-div shell :class "niori-main")))
        (setf (session-main-row session) main)
        (let ((navigator (create-div main :class "niori-side")))
          (setf (session-navigator-col session) navigator)
          (create-div navigator :class "niori-panel-header"
                      :content "Navigator")
          (setf (session-navigator-body session)
                (create-div navigator :class "niori-body")))
        (let ((editor (create-div main :class "niori-editor")))
          (setf (session-editor-col session) editor)
          (setf (session-panes-row session)
                (create-div editor :class "niori-panes")))
        (let ((properties (create-div main :class "niori-props")))
          (setf (session-props-col session) properties)))
      (setf (session-output-row session)
            (create-div shell :class "niori-output"))
      (setf (session-status-row session)
            (create-div shell :class "niori-status-row")))
    (build-navigator session)
    (build-properties session)
    (build-output session)
    (build-statusbar session)
    (activate-pane session (make-pane session))))

(defun install-shortcuts (session)
  "Global keyboard shortcuts, dispatched through the command registry."
  (let ((body (session-body session)))
    (set-on-key-down
     body
     (lambda (obj keys)
       (declare (ignore obj))
       (let ((command (command-for-key (getf keys :key)
                                       (getf keys :ctrl-key)
                                       (getf keys :alt-key)
                                       (getf keys :shift-key)
                                       (getf keys :meta-key))))
         (when command
           (run-command (command-id command) session)))))))

(defun on-new-window (body)
  "Called by CLOG for every new browser page."
  (set-html-on-close body "Connection lost - reload the page to reconnect.")
  (clog-gui:clog-gui-initialize body)
  (let ((session (make-session body)))
    (setf (connection-data-item body "niori-session") session)
    (build-shell session)
    (build-menu-bar session)
    (build-toolbar session)
    (install-shortcuts session)
    (install-session-subscriptions session)
    (set-status session
                (format nil "Ready - ~A modules loaded" (length (all-modules))))
    (publish :sync-status "Sync: waiting for first heartbeat")
    (clog:run body)))

(defun start-ui (&key (host "127.0.0.1") (port 8080) (auto-open t))
  "Install the platform UI hooks, (re-)register the core commands and
start the CLOG web server."
  (install-ui-hooks)
  (register-core-commands)
  (clog:initialize 'on-new-window
                   :host host :port port
                   :static-root (merge-pathnames "static-files/"
                                                 (app-static-root)))
  (when auto-open
    (ignore-errors
     (clog:open-browser :url (format nil "http://~A:~A" host port))))
  (log-line :info (format nil "Niori UI listening on http://~A:~A" host port)))

(defun stop-ui ()
  (ignore-errors (clog:shutdown)))
