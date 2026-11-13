;;;; niori/src/ui/editor.lisp
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

;;; The editor area: one or more panes (split views), each with a tab
;;; strip.  Tabs are opened through the platform's OPEN-VIEW facade;
;;; view builders only fill the content element they receive.

(defun make-pane (session)
  "Create a new editor pane in the split container."
  (let* ((container (create-div (session-panes-row session) :class "niori-pane"))
         (tabbar (create-div container :class "niori-tabbar"))
         (content-area (create-div container :class "niori-pane-body"))
         (pane (make-editor-pane :container container
                                 :tabbar tabbar
                                 :content-area content-area)))
    (setf (session-panes session)
          (append (session-panes session) (list pane)))
    (set-on-click container
                  (lambda (obj)
                    (declare (ignore obj))
                    (activate-pane session pane)))
    pane))

(defun activate-pane (session pane)
  "Make PANE the focused pane and refresh context-sensitive widgets."
  (setf (session-active-pane session) pane)
  (dolist (other (session-panes session))
    (remove-class (pane-container other) "focused"))
  (add-class (pane-container pane) "focused")
  (refresh-toolbar session)
  (set-default-properties session)
  pane)

(defun active-pane-or-create (session)
  (let ((pane (session-active-pane session)))
    (unless pane
      (setf pane (first (session-panes session)))
      (when pane
        (activate-pane session pane)))
    pane))

(defun set-default-properties (session)
  "Context-sensitive properties for the current focus."
  (let ((pane (session-active-pane session))
        (tab (and (session-active-pane session)
                  (pane-active-tab (session-active-pane session)))))
    (set-properties session
                    (if (and tab (validp (tab-content tab)))
                        (list "Tab" (tab-title tab)
                              "View type" (princ-to-string (tab-view-type-id tab)))
                        (list "Editor" "No tab open"
                              "Hint" "Use the Navigator or the File menu")))))

(defun open-view-in-session (session view-type data title)
  "Platform open-view hook: open VIEW-TYPE as a new tab in the active pane."
  (let* ((pane (or (active-pane-or-create session)
                   (make-pane session)))
         (label (or title (view-type-label view-type)))
         (button (create-div (pane-tabbar pane) :class "niori-tab"))
         (content (create-div (pane-content-area pane) :class "niori-tab-content"))
         (tab (make-editor-tab :title label :button button
                               :content content
                               :view-type-id (view-type-id view-type))))
    ;; tab strip entry: label + close box, each with its own click target
    (let ((label-element (create-span button :content label)))
      (set-on-click label-element
                    (lambda (obj)
                      (declare (ignore obj))
                      (activate-pane session pane)
                      (activate-tab session pane tab))))
    (let ((close-element (create-span button :class "niori-tab-close"
                                      :content "&times;")))
      (set-on-click close-element
                    (lambda (obj)
                      (declare (ignore obj))
                      (close-tab session pane tab))))
    ;; clicking anywhere else on the tab also activates it
    (set-on-click button
                  (lambda (obj)
                    (declare (ignore obj))
                    (when (validp content)
                      (activate-pane session pane)
                      (activate-tab session pane tab))))
    (setf (pane-tabs pane) (append (pane-tabs pane) (list tab)))
    ;; let the module's builder fill the content
    (handler-case (funcall (view-type-builder view-type) content session data)
      (error (condition)
        (setf (inner-html content)
                  (format nil "<div class='niori-note niori-note-error'>The view ~S failed to build: ~A</div>"
                          (view-type-id view-type) (html-esc condition)))
        (log-line :error (format nil "View ~S failed: ~A"
                                 (view-type-id view-type) condition))))
    (activate-tab session pane tab)
    tab))

(defun activate-tab (session pane tab)
  (when (validp (tab-content tab))
    (setf (pane-active-tab pane) tab)
    (dolist (other (pane-tabs pane))
      (remove-class (tab-button other) "active")
      (remove-class (tab-content other) "active"))
    (add-class (tab-button tab) "active")
    (add-class (tab-content tab) "active")
    (activate-pane session pane)))

(defun close-tab (session pane tab)
  "Close a tab and activate a sensible neighbour."
  (let* ((tabs (pane-tabs pane))
         (position (position tab tabs))
         (neighbour (when (> (length tabs) 1)
                      (if (> position 0)
                          (nth (1- position) tabs)
                          (nth (1+ position) tabs)))))
    (setf (pane-tabs pane) (remove tab tabs))
    (when (validp (tab-button tab)) (destroy (tab-button tab)))
    (when (validp (tab-content tab)) (destroy (tab-content tab)))
    (when (eq (pane-active-tab pane) tab)
      (setf (pane-active-tab pane) nil))
    (when neighbour
      (activate-tab session pane neighbour))
    (when (eq pane (session-active-pane session))
      (refresh-toolbar session)
      (set-default-properties session))
    (log-line :info (format nil "Tab closed: ~A" (tab-title tab)))))

(defun close-active-tab (session)
  (let ((pane (active-pane-or-create session)))
    (when (and pane (pane-active-tab pane))
      (close-tab session pane (pane-active-tab pane)))))

(defun split-editor (session)
  "Add a second editor pane (split view)."
  (let ((pane (make-pane session)))
    (activate-pane session pane)
    (log-line :info "Editor split")
    pane))

(defun close-pane (session pane)
  "Remove a pane unless it is the last one."
  (if (<= (length (session-panes session)) 1)
      (notify "Editor" "The last editor pane cannot be closed." :kind :warn)
      (progn
        (setf (session-panes session) (remove pane (session-panes session)))
        (destroy (pane-container pane))
        (when (eq (session-active-pane session) pane)
          (setf (session-active-pane session) nil)
          (let ((remaining (first (session-panes session))))
            (when remaining
              (activate-pane session remaining)))))))
