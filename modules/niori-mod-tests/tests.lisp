;;;; niori/modules/niori-mod-tests/tests.lisp
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

(in-package #:niori-mod-tests)

;;; ------------------------------------------------------------------
;;; Module declaration
;;; ------------------------------------------------------------------

(define-module :tests
  :name "Test Results"
  :version "0.1.0"
  :description "Laboratory and clinical test results with reference ranges."
  :start-fn (lambda ()
              (log-line :info "Test Results module ready")))

;;; ------------------------------------------------------------------
;;; Database
;;; ------------------------------------------------------------------

(register-repository :test-results :table "test_results" :module :tests)

(define-migration :tests 1 (store)
  (store-execute store
                 "CREATE TABLE IF NOT EXISTS test_results (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    date TEXT NOT NULL,
                    name TEXT NOT NULL,
                    category TEXT,
                    result TEXT,
                    reference TEXT,
                    status TEXT,
                    lab TEXT,
                    notes TEXT)")
  (store-execute store
                 "INSERT INTO test_results (date, name, category, result, reference, status, lab, notes)
                  VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
                 "2026-10-30" "HbA1c" "Blood" "5.4 %" "< 5.7 %"
                 "Normal" "Central Lab" "")
  (store-execute store
                 "INSERT INTO test_results (date, name, category, result, reference, status, lab, notes)
                  VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
                 "2026-10-30" "LDL cholesterol" "Blood" "148 mg/dL" "< 130 mg/dL"
                 "Attention" "Central Lab" "Discuss at next visit")
  (store-execute store
                 "INSERT INTO test_results (date, name, category, result, reference, status, lab, notes)
                  VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
                 "2026-08-11" "Vitamin D" "Blood" "18 ng/mL" "30 - 100 ng/mL"
                 "Attention" "City Hospital" "Supplement started"))

;;; ------------------------------------------------------------------
;;; View (editor type)
;;; ------------------------------------------------------------------

(defun status-badge (status)
  (cond ((string-equal status "Normal")
         "<span class='niori-badge niori-badge-ok'>Normal</span>")
        ((string-equal status "Attention")
         "<span class='niori-badge niori-badge-warn'>Attention</span>")
        (t
         (format nil "<span class='niori-badge niori-badge-off'>~A</span>"
                 (html-esc status)))))

(defun render-test-row (body container session flagged-only record)
  (let* ((id (getf record :id))
         (row (create-table-row body))
         (cells (list
                 (create-table-column row :content (html-esc (getf record :date)))
                 (create-table-column row :content (html-esc (getf record :name)))
                 (create-table-column row :content (html-esc (getf record :category)))
                 (create-table-column row :content (html-esc (getf record :result)))
                 (create-table-column row :content (html-esc (getf record :reference)))
                 (create-table-column row :content (status-badge (getf record :status)))
                 (create-table-column row :content (html-esc (getf record :lab))))))
    (dolist (cell cells)
      (set-on-click cell
                    (lambda (obj)
                      (declare (ignore obj))
                      (add-class row "sel")
                      (set-properties session
                                      (list "Test" (getf record :name)
                                            "Date" (getf record :date)
                                            "Category" (getf record :category)
                                            "Result" (getf record :result)
                                            "Reference" (getf record :reference)
                                            "Status" (getf record :status)
                                            "Lab" (getf record :lab)
                                            "Notes" (getf record :notes))))))
    (let ((actions (create-table-column row)))
      (let ((delete-button (create-button actions :content "Delete"
                                          :class "niori-btn")))
        (set-on-click delete-button
                      (lambda (obj)
                        (declare (ignore obj))
                        (repo-delete :test-results id)
                        (log-line :info
                                  (format nil "Test result removed (#~A)" id))
                        (render-test-rows container session flagged-only)))))))

(defun render-test-rows (container session flagged-only)
  "Rebuild the test results table (optionally flagged records only)."
  (destroy-children container)
  (let ((table (create-table container :class "niori-table")))
    (let ((head (create-table-head table))
          (body (create-table-body table)))
      (let ((header (create-table-row head)))
        (dolist (column '("Date" "Test" "Category" "Result" "Reference"
                          "Status" "Lab" ""))
          (create-table-heading header :content column)))
      (dolist (record (if flagged-only
                          (remove-if-not
                           (lambda (record)
                             (string-equal (getf record :status "") "Attention"))
                           (repo-list :test-results))
                          (repo-list :test-results)))
        (render-test-row body container session flagged-only record)))))

(defun tests-view (content session data)
  (let ((flagged-only (eq data :flagged)))
    (create-div content :class "niori-view-title" :content "Test Results")
    (create-div content :class "niori-view-sub"
                :content (if flagged-only
                             "Results flagged for follow-up."
                             "Laboratory and clinical results with reference ranges."))
    (let* ((form (create-div content :class "niori-form-row"))
           (date-input (create-form-element form "date" :class "niori-input"))
           (name-input (create-form-element form "text" :placeholder "Test name"
                                            :class "niori-input"))
           (category-input (create-form-element form "text"
                                                :placeholder "Category"
                                                :class "niori-input"))
           (result-input (create-form-element form "text" :placeholder "Result"
                                              :class "niori-input"))
           (reference-input (create-form-element form "text"
                                                 :placeholder "Reference range"
                                                 :class "niori-input"))
           (status-input (create-form-element form "text" :placeholder "Status"
                                              :class "niori-input"))
           (lab-input (create-form-element form "text" :placeholder "Lab"
                                           :class "niori-input"))
           (add-button (create-button form :content "Add Result" :class "niori-btn"))
           (rows (create-div content)))
      (set-on-click add-button
                    (lambda (obj)
                      (declare (ignore obj))
                      (let ((name (value name-input)))
                        (if (and name (plusp (length (string-trim " " name))))
                            (progn
                              (repo-insert :test-results
                                           (list :date (or (value date-input)
                                                           (today-string))
                                                 :name (string-trim " " name)
                                                 :category (value category-input)
                                                 :result (value result-input)
                                                 :reference (value reference-input)
                                                 :status (value status-input)
                                                 :lab (value lab-input)
                                                 :notes ""))
                              (notify "Test result added" (string-trim " " name))
                              (setf (value date-input) ""
                                    (value name-input) ""
                                    (value category-input) ""
                                    (value result-input) ""
                                    (value reference-input) ""
                                    (value status-input) ""
                                    (value lab-input) "")
                              (render-test-rows rows session flagged-only))
                            (notify "Name required"
                                    "Enter the test name first."
                                    :kind :warn)))))
      (render-test-rows rows session flagged-only))))

(register-view-type :tests.list
                    :label "Test Results"
                    :builder #'tests-view
                    :module :tests)

;;; ------------------------------------------------------------------
;;; Navigation
;;; ------------------------------------------------------------------

(register-navigation :nav-tests
                     :label "Test Results"
                     :module :tests
                     :on-open (lambda (session)
                                (open-view :tests.list :session session)))

(register-navigation :nav-tests-flagged
                     :label "Needs follow-up"
                     :parent :nav-tests
                     :module :tests
                     :on-open (lambda (session)
                                (open-view :tests.list :session session
                                           :data :flagged
                                           :title "Needs follow-up")))

;;; ------------------------------------------------------------------
;;; Command (menu contribution + shortcut)
;;; ------------------------------------------------------------------

(register-command :tests.new
                  :title "New Test Result"
                  :menu-path '("File" "New")
                  :shortcut '(:control :alt "t")
                  :tooltip "Open the test results list"
                  :module :tests
                  :handler (lambda (session)
                             (open-view :tests.list :session session)))
