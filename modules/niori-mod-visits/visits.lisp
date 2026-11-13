;;;; niori/modules/niori-mod-visits/visits.lisp
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

(in-package #:niori-mod-visits)

;;; ------------------------------------------------------------------
;;; Module declaration
;;; ------------------------------------------------------------------

(define-module :visits
  :name "Doctor Visits"
  :version "0.1.0"
  :description "Appointments and visit history with doctors and specialists."
  :start-fn (lambda ()
              (log-line :info "Doctor Visits module ready")))

;;; ------------------------------------------------------------------
;;; Database
;;; ------------------------------------------------------------------

(register-repository :visits :table "visits" :module :visits)

(define-migration :visits 1 (store)
  (store-execute store
                 "CREATE TABLE IF NOT EXISTS visits (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    date TEXT NOT NULL,
                    doctor TEXT,
                    specialty TEXT,
                    reason TEXT,
                    location TEXT,
                    notes TEXT)")
  (store-execute store
                 "INSERT INTO visits (date, doctor, specialty, reason, location, notes)
                  VALUES (?, ?, ?, ?, ?, ?)"
                 "2026-11-25" "Dr. Chen" "Cardiology"
                 "Follow-up: blood pressure" "Heart & Vascular Clinic" "Bring BP log")
  (store-execute store
                 "INSERT INTO visits (date, doctor, specialty, reason, location, notes)
                  VALUES (?, ?, ?, ?, ?, ?)"
                 "2026-12-10" "Dr. Rossi" "Dermatology"
                 "Annual skin check" "Riverside Medical Center" "")
  (store-execute store
                 "INSERT INTO visits (date, doctor, specialty, reason, location, notes)
                  VALUES (?, ?, ?, ?, ?, ?)"
                 "2026-09-14" "Dr. Chen" "Cardiology"
                 "Annual physical" "Heart & Vascular Clinic" "ECG normal")
  (store-execute store
                 "INSERT INTO visits (date, doctor, specialty, reason, location, notes)
                  VALUES (?, ?, ?, ?, ?, ?)"
                 "2026-05-02" "Dr. Okafor" "General practice"
                 "Persistent cough" "Community Health Center" "Resolved"))

;;; ------------------------------------------------------------------
;;; View (editor type) with filter data
;;; ------------------------------------------------------------------

(defun visit-matches-p (record filter)
  (let ((date (or (getf record :date) "")))
    (ecase filter
      (:all t)
      (:upcoming (string>= date (today-string)))
      (:history (string< date (today-string))))))

(defun render-visit-row (body container session filter record)
  (let* ((id (getf record :id))
         (row (create-table-row body))
         (cells (list
                 (create-table-column row :content (html-esc (getf record :date)))
                 (create-table-column row :content (html-esc (getf record :doctor)))
                 (create-table-column row :content (html-esc (getf record :specialty)))
                 (create-table-column row :content (html-esc (getf record :reason)))
                 (create-table-column row :content (html-esc (getf record :location))))))
    (dolist (cell cells)
      (set-on-click cell
                    (lambda (obj)
                      (declare (ignore obj))
                      (add-class row "sel")
                      (set-properties session
                                      (list "Date" (getf record :date)
                                            "Doctor" (getf record :doctor)
                                            "Specialty" (getf record :specialty)
                                            "Reason" (getf record :reason)
                                            "Location" (getf record :location)
                                            "Notes" (getf record :notes))))))
    (let ((actions (create-table-column row)))
      (let ((delete-button (create-button actions :content "Delete"
                                          :class "niori-btn")))
        (set-on-click delete-button
                      (lambda (obj)
                        (declare (ignore obj))
                        (repo-delete :visits id)
                        (log-line :info
                                  (format nil "Visit removed (#~A)" id))
                        (render-visit-rows container session filter)))))))

(defun render-visit-rows (container session filter)
  "Rebuild the visits table for the given FILTER."
  (destroy-children container)
  (let ((table (create-table container :class "niori-table")))
    (let ((head (create-table-head table))
          (body (create-table-body table)))
      (let ((header (create-table-row head)))
        (dolist (column '("Date" "Doctor" "Specialty" "Reason" "Location" ""))
          (create-table-heading header :content column)))
      (dolist (record (remove-if-not
                       (lambda (record)
                         (visit-matches-p record filter))
                       (repo-list :visits)))
        (render-visit-row body container session filter record)))))

(defun visits-view (content session data)
  (let ((filter (or data :all)))
    (create-div content :class "niori-view-title" :content "Doctor Visits")
    (create-div content :class "niori-view-sub"
                :content (ecase filter
                           (:all "All recorded visits and appointments.")
                           (:upcoming "Upcoming appointments.")
                           (:history "Past visits.")))
    (let* ((form (create-div content :class "niori-form-row"))
           (date-input (create-form-element form "date" :class "niori-input"))
           (doctor-input (create-form-element form "text" :placeholder "Doctor"
                                              :class "niori-input"))
           (specialty-input (create-form-element form "text"
                                                 :placeholder "Specialty"
                                                 :class "niori-input"))
           (reason-input (create-form-element form "text" :placeholder "Reason"
                                              :class "niori-input"))
           (location-input (create-form-element form "text"
                                                :placeholder "Location"
                                                :class "niori-input"))
           (add-button (create-button form :content "Add Visit" :class "niori-btn"))
           (rows (create-div content)))
      (set-on-click add-button
                    (lambda (obj)
                      (declare (ignore obj))
                      (let ((date (value date-input)))
                        (if (and date (plusp (length date)))
                            (progn
                              (repo-insert :visits
                                           (list :date date
                                                 :doctor (value doctor-input)
                                                 :specialty (value specialty-input)
                                                 :reason (value reason-input)
                                                 :location (value location-input)
                                                 :notes ""))
                              (notify "Visit added" date)
                              (setf (value date-input) ""
                                    (value doctor-input) ""
                                    (value specialty-input) ""
                                    (value reason-input) ""
                                    (value location-input) "")
                              (render-visit-rows rows session filter))
                            (notify "Date required"
                                    "Pick a date for the visit first."
                                    :kind :warn)))))
      (render-visit-rows rows session filter))))

(register-view-type :visits.list
                    :label "Doctor Visits"
                    :builder #'visits-view
                    :module :visits)

;;; ------------------------------------------------------------------
;;; Navigation (root + children passing filter data)
;;; ------------------------------------------------------------------

(register-navigation :nav-visits
                     :label "Doctor Visits"
                     :module :visits
                     :on-open (lambda (session)
                                (open-view :visits.list :session session)))

(register-navigation :nav-visits-upcoming
                     :label "Upcoming appointments"
                     :parent :nav-visits
                     :module :visits
                     :on-open (lambda (session)
                                (open-view :visits.list :session session
                                           :data :upcoming
                                           :title "Upcoming appointments")))

(register-navigation :nav-visits-history
                     :label "Visit history"
                     :parent :nav-visits
                     :module :visits
                     :on-open (lambda (session)
                                (open-view :visits.list :session session
                                           :data :history
                                           :title "Visit history")))

;;; ------------------------------------------------------------------
;;; Command (menu contribution + shortcut)
;;; ------------------------------------------------------------------

(register-command :visits.new
                  :title "New Visit"
                  :menu-path '("File" "New")
                  :shortcut '(:control :alt "v")
                  :tooltip "Open the doctor visits list"
                  :module :visits
                  :handler (lambda (session)
                             (open-view :visits.list :session session)))
