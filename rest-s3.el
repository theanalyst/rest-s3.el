;;; rest-s3.el --- Emacs client for authorizing for S3 like places

;; Copyright (C) 2013  Abhishek L

;; Author: Abhishek L <abhishek.lekshmanan@gmail.com>
;; URL: http://www.github.com/theanalyst/rest-s3.el
;; Version: 0.1.0
;; Package-Requires:
;; Keywords: convenience

;; This file is not a part of GNU Emacs
;;; Commentary:
;; This was primarily developed to test S3 like APIs for eg. in ceph's radosgw
;; though it is expected to work with other API's that expect an S3 like
;; authentication (including Amazon S3)
;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'hmac-sha1)
(require 's)

(defcustom s3-access-key-id nil
  "Access Key for AWS/ S3 like system account"
  :type 'string)

(defcustom s3-secret-access-key nil
  "Secret Key for AWS/S3 like account
   You probably should NEVER store this"
  :type 'string)

(defun s3--parse-s3-url (uri)
  (let* ((uri-struct (url-generic-parse-url uri))
	 (filename (url-filename uri-struct)))
    (if (string= "" filename) "/" filename)))

(defun s3--normalize-path (filepath)
  (if (s-equals? "/" (s-left 1 filepath))
      filepath
      (concat "/" filepath)
    ))

(defun s3--format-date ()
  (format-time-string "%a, %d %b %Y %H:%M:%S %Z" nil t))

(defun s3--canonicalize (filepath method &optional content-type content-md5 date)
  "No, I didn't mean you Ubuntu!
  Headers "
  (string-make-unibyte (concat method "\n"
                               (or content-type "") "\n"
                               (or content-md5 "") "\n"
                               (or date "") "\n"
                               filepath)))

(defun s3auth (filepath method access secret &rest args)
  "Create S3 Authentication Headers

The following parameters are expected:

filepath -  the request path, the path after / in hostname, for eg. s3.amazonaws.com/bucket -> bucket
            if you are planning to pass an uri instead, you can use the s3-parse-url helper on the url
method   -  the request method, GET, PUT etc
access   -  the aws access key
secret   -  the aws secret key
args     -  takes following arguments for now : content-type, content-md5 and date (in amz format)
"
  (format "AWS %s:%s" access
	  (base64-encode-string
	   (hmac-sha1 secret
                (apply #'s3--canonicalize (s3--normalize-path filepath) method args)))))
