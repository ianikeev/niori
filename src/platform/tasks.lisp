;;;; niori/src/platform/tasks.lisp
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

(in-package #:niori-platform)

;;; Background tasks.  Modules register periodic jobs (reminders,
;;; synchronization, cleanup...).  Each task gets its own thread that
;;; sleeps in one-second slices so STOP-TASKS stays responsive.
;;; Tasks must not touch UI elements - they publish events or use the
;;; repository API; the UI reacts through the event bus.

(defparameter *tasks-lock* (bt:make-lock "niori-tasks"))

(defparameter *tasks* (make-hash-table :test 'eq)
  "TASK-ID -> task struct.")

(defparameter *tasks-running-p* nil)

(defstruct (task (:constructor %make-task))
  (id nil)
  (label "")
  (interval-seconds 60)
  (fn nil)        ; (lambda ())
  (thread nil)
  (stop-p nil))

(defun register-task (id &key label (interval-seconds 60) fn)
  "Register or replace the background task ID.  FN takes no arguments."
  (unless fn
    (error "Task ~S registered without a function" id))
  (bt:with-lock-held (*tasks-lock*)
    (setf (gethash id *tasks*)
          (%make-task :id id :label (or label (keyword->title id))
                      :interval-seconds (max 5 interval-seconds) :fn fn)))
  id)

(defun find-task (id)
  (gethash id *tasks*))

(defun all-tasks ()
  (bt:with-lock-held (*tasks-lock*)
    (sort (loop for task being the hash-values of *tasks*
                collect task)
          #'string< :key (lambda (task) (symbol-name (task-id task))))))

(defun run-task-now (id)
  "Run the task's function once, immediately (used by the Tasks panel)."
  (let ((task (find-task id)))
    (when task
      (handler-case (funcall (task-fn task))
        (error (condition)
          (notify "Task failed" (format nil "~A: ~A" (task-label task) condition)
                  :kind :error)))
      t)))

(defun task-loop (task)
  (loop until (task-stop-p task)
        do (loop repeat (max 1 (task-interval-seconds task))
                 until (task-stop-p task)
                 do (sleep 1))
           (unless (task-stop-p task)
             (handler-case (funcall (task-fn task))
               (error (condition)
                 (format *error-output*
                         "~&[niori] task ~S error: ~A~%" (task-id task) condition))))))

(defun start-tasks ()
  "Start a thread for every registered task (once per platform boot)."
  (bt:with-lock-held (*tasks-lock*)
    (when *tasks-running-p*
      (return-from start-tasks nil))
    (loop for task being the hash-values of *tasks*
          do (let ((task task))   ; fresh binding: the thread closure must
                                  ; not see the reassigned loop variable
               (setf (task-stop-p task) nil
                     (task-thread task)
                     (bt:make-thread
                      (lambda () (task-loop task))
                      :name (format nil "niori-task-~A" (task-id task))))))
    (setf *tasks-running-p* t))
  (log-line :info (format nil "Background tasks started (~A)"
                          (hash-table-count *tasks*))))

(defun stop-tasks ()
  "Signal all task threads to stop and wait for them."
  (bt:with-lock-held (*tasks-lock*)
    (loop for task being the hash-values of *tasks*
          do (setf (task-stop-p task) t))
    (loop for task being the hash-values of *tasks*
          for thread = (task-thread task)
          when (and thread (bt:thread-alive-p thread))
            do (ignore-errors (bt:join-thread thread))
               (setf (task-thread task) nil))
    (setf *tasks-running-p* nil)))

(defun tasks-running-p ()
  *tasks-running-p*)
