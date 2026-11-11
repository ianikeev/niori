;;;; niori/modules/niori-mod-medications/medications.lisp
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

(in-package #:niori-mod-medications)

;;; ------------------------------------------------------------------
;;; Module declaration
;;; ------------------------------------------------------------------

(define-module :medications
  :name "Medications"
  :version "0.1.0"
  :description "Track medications, dosages, schedules and prescribers."
  :start-fn (lambda ()
              (log-line :info "Medications module ready")))

;;; ------------------------------------------------------------------
;;; Database: repository + migration (schema and seed data)
;;; ------------------------------------------------------------------

(register-repository :medications :table "medications" :module :medications)

(define-migration :medications 1 (store)
  (store-execute store
                 "CREATE TABLE IF NOT EXISTS medications (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    strength TEXT,
                    schedule TEXT,
                    prescriber TEXT,
                    active INTEGER DEFAULT 1,
                    notes TEXT,
                    created TEXT)")
  (store-execute store
                 "INSERT INTO medications
                    (name, strength, schedule, prescriber, active, notes, created)
                  VALUES (?, ?, ?, ?, ?, ?, ?)"
                 "Ibuprofen" "200 mg" "As needed, max 3x per day" "Dr. Chen" 1
                 "For pain and inflammation" (today-string))
  (store-execute store
                 "INSERT INTO medications
                    (name, strength, schedule, prescriber, active, notes, created)
                  VALUES (?, ?, ?, ?, ?, ?, ?)"
                 "Lisinopril" "10 mg" "Once daily, morning" "Dr. Chen" 1
                 "Blood pressure" (today-string))
  (store-execute store
                 "INSERT INTO medications
                    (name, strength, schedule, prescriber, active, notes, created)
                  VALUES (?, ?, ?, ?, ?, ?, ?)"
                 "Vitamin D3" "1000 IU" "Once daily" "Dr. Okafor" 1
                 "Supplement" (today-string)))

;;; ------------------------------------------------------------------
;;; View (editor type)
;;; ------------------------------------------------------------------

(defun render-medication-row (body container session record)
  "One table row: data cells, delete button, properties on click."
  (let* ((id (getf record :id))
         (row (create-table-row body))
         (cells (list
                 (create-table-column row :content (html-esc (getf record :name)))
                 (create-table-column row :content (html-esc (getf record :strength)))
                 (create-table-column row :content (html-esc (getf record :schedule)))
                 (create-table-column row :content (html-esc (getf record :prescriber)))
                 (create-table-column
                  row
                  :content (if (= (getf record :active 0) 1)
                               "<span class='niori-badge niori-badge-ok'>Active</span>"
                               "<span class='niori-badge niori-badge-off'>Stopped</span>")))))
    (dolist (cell cells)
      (set-on-click cell
                    (lambda (obj)
                      (declare (ignore obj))
                      (add-class row "sel")
                      (set-properties session
                                      (list "Medication" (getf record :name)
                                            "Strength" (getf record :strength)
                                            "Schedule" (getf record :schedule)
                                            "Prescriber" (getf record :prescriber)
                                            "Notes" (getf record :notes))))))
    (let ((actions (create-table-column row)))
      (let ((delete-button (create-button actions :content "Delete"
                                          :class "niori-btn")))
        (set-on-click delete-button
                      (lambda (obj)
                        (declare (ignore obj))
                        (repo-delete :medications id)
                        (log-line :info
                                  (format nil "Medication removed (#~A)" id))
                        (render-medication-rows container session)))))))

(defun render-medication-rows (container session)
  "Rebuild the medications table inside CONTAINER."
  (destroy-children container)
  (let ((table (create-table container :class "niori-table")))
    (let ((head (create-table-head table))
          (body (create-table-body table)))
      (let ((header (create-table-row head)))
        (dolist (column '("Medication" "Strength" "Schedule" "Prescriber"
                          "Status" ""))
          (create-table-heading header :content column)))
      (dolist (record (repo-list :medications))
        (render-medication-row body container session record)))))

(defun medications-view (content session data)
  "List view: add form, records table, delete buttons, properties on click."
  (declare (ignore data))
  (create-div content :class "niori-view-title" :content "Medications")
  (create-div content :class "niori-view-sub"
              :content "Active and past medications, dosages and schedules.")
  (let* ((form (create-div content :class "niori-form-row"))
         (name-input (create-form-element form "text" :placeholder "Name"
                                          :class "niori-input"))
         (strength-input (create-form-element form "text"
                                              :placeholder "Strength"
                                              :class "niori-input"))
         (schedule-input (create-form-element form "text"
                                              :placeholder "Schedule"
                                              :class "niori-input"))
         (prescriber-input (create-form-element form "text"
                                                :placeholder "Prescriber"
                                                :class "niori-input"))
         (add-button (create-button form :content "Add Medication"
                                     :class "niori-btn"))
         (rows (create-div content)))
    (set-on-click add-button
                  (lambda (obj)
                    (declare (ignore obj))
                    (let ((name (value name-input)))
                      (if (and name (plusp (length (string-trim " " name))))
                          (progn
                            (repo-insert :medications
                                         (list :name (string-trim " " name)
                                               :strength (value strength-input)
                                               :schedule (value schedule-input)
                                               :prescriber (value prescriber-input)
                                               :active 1
                                               :notes ""
                                               :created (today-string)))
                            (notify "Medication added" (string-trim " " name))
                            (setf (value name-input) ""
                                  (value strength-input) ""
                                  (value schedule-input) ""
                                  (value prescriber-input) "")
                            (render-medication-rows rows session))
                          (notify "Name required"
                                  "Enter the medication name first."
                                  :kind :warn)))))
    (render-medication-rows rows session)))

(register-view-type :medications.list
                    :label "Medications"
                    :builder #'medications-view
                    :module :medications)

;;; ------------------------------------------------------------------
;;; Navigation, command (menu contribution + shortcut), service
;;; ------------------------------------------------------------------

(register-navigation :nav-medications
                     :label "Medications"
                     :module :medications
                     :on-open (lambda (session)
                                (open-view :medications.list :session session)))

(register-command :medications.new
                  :title "New Medication"
                  :menu-path '("File" "New")
                  :shortcut '(:control :alt "m")
                  :tooltip "Open the medications list"
                  :module :medications
                  :handler (lambda (session)
                             (open-view :medications.list :session session)))

(provide-service :medications
                 (lambda () (repo-count :medications))
                 :provider :medications)
