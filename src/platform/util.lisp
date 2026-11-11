;;;; niori/src/platform/util.lisp
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

(defun now-string (&optional (universal (get-universal-time)))
  "Return the current local time formatted as YYYY-MM-DD HH:MM:SS."
  (multiple-value-bind (sec min hour day month year)
      (decode-universal-time universal)
    (declare (ignore sec))
    (format nil "~4,'0d-~2,'0d-~2,'0d ~2,'0d:~2,'0d:~2,'0d"
            year month day hour min sec)))

(defun today-string (&optional (universal (get-universal-time)))
  "Return the current local date formatted as YYYY-MM-DD."
  (subseq (now-string universal) 0 10))

(defun date-string (universal)
  "Format UNIVERSAL-TIME as YYYY-MM-DD."
  (multiple-value-bind (sec min hour day month year)
      (decode-universal-time universal)
    (declare (ignore sec min hour))
    (format nil "~4,'0d-~2,'0d-~2,'0d" year month day)))

(defun date-universal (year month day)
  "Encode YEAR MONTH DAY (ISO numbers) into a UNIVERSAL-TIME."
  (encode-universal-time 0 0 0 day month year))

(defun iso-date-universal (string)
  "Parse a YYYY-MM-DD string into a UNIVERSAL-TIME, or NIL."
  (ignore-errors
   (date-universal (parse-integer string :start 0 :end 4)
                   (parse-integer string :start 5 :end 7)
                   (parse-integer string :start 8 :end 10))))

(defun keyword->title (keyword)
  "Turn :MEDICATIONS into \"Medications\" (a best-effort prettifier)."
  (format nil "~@(~A~)" (substitute #\Space #\- (string keyword))))

(defun string+ (&rest parts)
  "Convenience concatenation treating NIL and symbols sensibly."
  (apply #'concatenate 'string
         (mapcar (lambda (p) (if (stringp p) p (princ-to-string p))) parts)))

(defun html-esc (value)
  "HTML-escape VALUE (an arbitrary Lisp value) so it can be embedded in
:content strings of CLOG element constructors.  CLOG does not escape
:content, so anything that came from the database or user input must
go through this first."
  (let ((string (if (stringp value) value (princ-to-string (or value "")))))
    (with-output-to-string (out)
      (loop for char across string
            do (case char
                 (#\& (write-string "&amp;" out))
                 (#\< (write-string "&lt;" out))
                 (#\> (write-string "&gt;" out))
                 (#\" (write-string "&#x22;" out))
                 (t (write-char char out)))))))
