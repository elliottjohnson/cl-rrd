;;;; cl-rrd - Common Lisp bindings to librrd2
;;;; Copyright (C) 2008 Harry Bock <harry@oshean.org>

;;;; This file is part of cl-rrd.

;;;; cl-rrd is free software; you can redistribute it and/or modify
;;;; it under the terms of the GNU General Public License as published by
;;;; the Free Software Foundation; either version 2 of the License, or
;;;; (at your option) any later version.

;;;; cl-rrd is distributed in the hope that it will be useful,
;;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;; GNU General Public License for more details.

;;;; You should have received a copy of the GNU General Public License
;;;; along with cl-rrd; if not, write to the Free Software
;;;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
(in-package :cl-rrd)

;;; Boolean operators
(def-rpn-operators '(lt le gt ge eq ne) 2)
(def-rpn-operators '(un isinf) 1)
(def-rpn-operators '(if) 3)

;;; Comparison operators
(def-rpn-operators '(min max) 2)
(def-rpn-operators '(limit) 3)

;;; Arithmetic operators
(def-rpn-operators '(* + - / % addnan atan2) 2)
(def-rpn-operators '(sin cos log exp sqrt atan floor ceil abs) 1)
(def-rpn-operators '(deg2rad rad2deg) 1)

;;; Set operations
(def-rpn-operators '(sort rev avg) 1)
(def-rpn-operators '(trend trendnan) 2)

;;; Direct stack operations
(def-rpn-operators '(dup pop exc) 0)

;;; RPN special values
(def-rpn-special-values '(:unkn :inf :neginf :prev :count))
(def-rpn-special-values '(:now :time :ltime))

(defun valid-rpn-special (special)
  (declare (type keyword special))
  (member special *rpn-special-value-list*))

(defun valid-rpn-operator (operator arity)
  "Returns true if operator is a defined RPN operator with the specified arity."
  (declare (type symbol operator))
  (multiple-value-bind (value exists-p) (gethash operator *rpn-operator-map*)
    (and exists-p (eql value arity))))

(defun valid-variable-name (name)
  (declare (type (or string symbol) name))
  (let ((str (string name)))
    (every (lambda (char)
	     (or (alphanumericp char)
		 (char= #\- char)
		 (char= #\_ char))) str)))

(defun to-variable-name (name)
  (unless (valid-variable-name name)
    (error "~a cannot be converted to a valid DS name." name))
  (let ((ds-name (string-downcase name)))
    (substitute #\_ #\- ds-name)))

(defun parse-rpn (expression)
  (etypecase expression
    (keyword
     (unless (valid-rpn-special expression)
       (error "~a is not a defined RPN special value." expression))
     (string-upcase expression))
    (real (to-string expression))
    (symbol (to-variable-name expression))
    (list
     (reverse
      (let (rpn-list
	    (operator (first expression)))
	(unless (valid-rpn-operator operator (length (rest expression)))
	  (error "~a/~d is not a defined RPN operator." operator (length (rest expression))))
	(dolist (operand (rest expression))
	  (push (parse-rpn operand) rpn-list))
	(push (format nil "~a" operator) rpn-list))))))

(defun compile-rpn (expression)
  "Create an RPN string from the given Lisp-like RPN expression."
  (format nil "~{~a~^,~}" (flatten (parse-rpn expression))))
