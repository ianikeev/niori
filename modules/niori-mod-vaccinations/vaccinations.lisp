;;;; niori/modules/niori-mod-vaccinations/vaccinations.lisp
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

(in-package #:niori-mod-vaccinations)

;;; ------------------------------------------------------------------
;;; Module declaration
;;; ------------------------------------------------------------------

(define-module :vaccinations
  :name "Vaccinations"
  :version "0.1.0"
  :description "Vaccination record with booster due dates and reminders."
  :start-fn (lambda ()
              (log-line :info "Vaccinations module ready")))

;;; ------------------------------------------------------------------
;;; Database
;;; ------------------------------------------------------------------

(register-repository :vaccinations :table "vaccinations" :module :vaccinations)

(define-migration :vaccinations 1 (store)
  (store-execute store
                 "CREATE TABLE IF NOT EXISTS vaccinations (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    vaccine TEXT NOT NULL,
                    date TEXT,
                    dose TEXT,
                    administered_by TEXT,
                    next_due TEXT,
                    location TEXT,
                    notes TEXT)")
  (store-execute store
                 "INSERT INTO vaccinations (vaccine, date, dose, administered_by, next_due, location, notes)
                  VALUES (?, ?, ?, ?, ?, ?, ?)"
                 "Influenza" "2025-10-04" "Annual" "Dr. Okafor" "2026-11-20"
                 "Community Health Center" "Flu shot")
  (store-execute store
                 "INSERT INTO vaccinations (vaccine, date, dose, administered_by, next_due, location, notes)
                  VALUES (?, ?, ?, ?, ?, ?, ?)"
                 "COVID-19" "2026-06-15" "Booster" "Dr. Okafor" ""
                 "Community Health Center" "")
  (store-execute store
                 "INSERT INTO vaccinations (vaccine, date, dose, administered_by, next_due, location, notes)
                  VALUES (?, ?, ?, ?, ?, ?, ?)"
                 "Tetanus" "2022-03-10" "Booster" "Dr. Chen" "2032-03-10"
                 "City Hospital" "Valid for 10 years"))

;;; ------------------------------------------------------------------
;;; View (editor type)
;;; ------------------------------------------------------------------

(defun due-soon-p (record)
  "True when the record's next_due date falls within the next 30 days
(or is already overdue).  ISO dates compare correctly as universal times."
  (let ((next-due (getf record :next_due)))
    (when (and next-due (>= (length next-due) 10))
      (let* ((today (iso-date-universal (today-string)))
             (limit (+ today (* 30 86400)))
             (due (iso-date-universal (subseq next-due 0 10))))
        (and due (<= due limit))))))

(defun render-vaccination-row (body container session due-soon-only record)
  (let* ((id (getf record :id))
         (row (create-table-row body))
         (cells (list
                 (create-table-column row :content (html-esc (getf record :vaccine)))
                 (create-table-column row :content (html-esc (getf record :date)))
                 (create-table-column row :content (html-esc (getf record :dose)))
                 (create-table-column row :content (html-esc (getf record :administered_by)))
                 (create-table-column row :content (html-esc (getf record :next_due)))
                 (create-table-column row :content (html-esc (getf record :location))))))
    (dolist (cell cells)
      (set-on-click cell
                    (lambda (obj)
                      (declare (ignore obj))
                      (add-class row "sel")
                      (set-properties session
                                      (list "Vaccine" (getf record :vaccine)
                                            "Date" (getf record :date)
                                            "Dose" (getf record :dose)
                                            "Administered by" (getf record :administered_by)
                                            "Next due" (getf record :next_due)
                                            "Location" (getf record :location)
                                            "Notes" (getf record :notes))))))
    (let ((actions (create-table-column row)))
      (let ((delete-button (create-button actions :content "Delete"
                                          :class "niori-btn")))
        (set-on-click delete-button
                      (lambda (obj)
                        (declare (ignore obj))
                        (repo-delete :vaccinations id)
                        (log-line :info
                                  (format nil "Vaccination removed (#~A)" id))
                        (render-vaccination-rows container session
                                                 due-soon-only)))))))

(defun render-vaccination-rows (container session due-soon-only)
  "Rebuild the vaccinations table (optionally due-soon records only)."
  (destroy-children container)
  (let ((table (create-table container :class "niori-table")))
    (let ((head (create-table-head table))
          (body (create-table-body table)))
      (let ((header (create-table-row head)))
        (dolist (column '("Vaccine" "Date" "Dose" "Administered by" "Next due"
                          "Location" ""))
          (create-table-heading header :content column)))
      (dolist (record (if due-soon-only
                          (remove-if-not #'due-soon-p (repo-list :vaccinations))
                          (repo-list :vaccinations)))
        (render-vaccination-row body container session due-soon-only record)))))

(defun vaccinations-view (content session data)
  (let ((due-soon-only (eq data :due-soon)))
    (create-div content :class "niori-view-title" :content "Vaccinations")
    (create-div content :class "niori-view-sub"
                :content (if due-soon-only
                             "Booster doses due within the next 30 days."
                             "Vaccination record with booster due dates."))
    (let* ((form (create-div content :class "niori-form-row"))
           (vaccine-input (create-form-element form "text" :placeholder "Vaccine"
                                               :class "niori-input"))
           (date-input (create-form-element form "date" :class "niori-input"))
           (dose-input (create-form-element form "text" :placeholder "Dose"
                                            :class "niori-input"))
           (admin-input (create-form-element form "text"
                                             :placeholder "Administered by"
                                             :class "niori-input"))
           (next-due-input (create-form-element form "date" :class "niori-input"))
           (location-input (create-form-element form "text"
                                                :placeholder "Location"
                                                :class "niori-input"))
           (add-button (create-button form :content "Add Vaccination"
                                       :class "niori-btn"))
           (rows (create-div content)))
      (set-on-click add-button
                    (lambda (obj)
                      (declare (ignore obj))
                      (let ((vaccine (value vaccine-input)))
                        (if (and vaccine (plusp (length (string-trim " " vaccine))))
                            (progn
                              (repo-insert :vaccinations
                                           (list :vaccine (string-trim " " vaccine)
                                                 :date (value date-input)
                                                 :dose (value dose-input)
                                                 :administered_by (value admin-input)
                                                 :next_due (value next-due-input)
                                                 :location (value location-input)
                                                 :notes ""))
                              (notify "Vaccination added" (string-trim " " vaccine))
                              (setf (value vaccine-input) ""
                                    (value date-input) ""
                                    (value dose-input) ""
                                    (value admin-input) ""
                                    (value next-due-input) ""
                                    (value location-input) "")
                              (render-vaccination-rows rows session
                                                       due-soon-only))
                            (notify "Vaccine required"
                                    "Enter the vaccine name first."
                                    :kind :warn)))))
      (render-vaccination-rows rows session due-soon-only))))

(register-view-type :vaccinations.list
                    :label "Vaccinations"
                    :builder #'vaccinations-view
                    :module :vaccinations)

;;; ------------------------------------------------------------------
;;; Navigation
;;; ------------------------------------------------------------------

(register-navigation :nav-vaccinations
                     :label "Vaccinations"
                     :module :vaccinations
                     :on-open (lambda (session)
                                (open-view :vaccinations.list :session session)))

(register-navigation :nav-vaccinations-due
                     :label "Due soon"
                     :parent :nav-vaccinations
                     :module :vaccinations
                     :on-open (lambda (session)
                                (open-view :vaccinations.list :session session
                                           :data :due-soon
                                           :title "Due soon")))

;;; ------------------------------------------------------------------
;;; Command (menu contribution + shortcut)
;;; ------------------------------------------------------------------

(register-command :vaccinations.new
                  :title "New Vaccination"
                  :menu-path '("File" "New")
                  :shortcut '(:control :alt "n")
                  :tooltip "Open the vaccinations list"
                  :module :vaccinations
                  :handler (lambda (session)
                             (open-view :vaccinations.list :session session)))

;;; ------------------------------------------------------------------
;;; Background task: booster reminders (publishes events, no UI access)
;;; ------------------------------------------------------------------

(defparameter *reminder-sent-p* nil)

(defun check-reminders ()
  (unless *reminder-sent-p*
    (let ((due (remove-if-not #'due-soon-p (repo-list :vaccinations))))
      (when due
        (notify "Vaccination reminder"
                (format nil "Booster due: ~{~A~^, ~}"
                        (mapcar (lambda (record)
                                  (format nil "~A (~A)"
                                          (getf record :vaccine)
                                          (getf record :next_due)))
                                due))
                :kind :warn)
        (log-line :info "Vaccination reminders checked - boosters due")
        (setf *reminder-sent-p* t)))))

(register-task :vaccinations.reminders
               :label "Vaccination reminders"
               :interval-seconds 60
               :fn #'check-reminders)
