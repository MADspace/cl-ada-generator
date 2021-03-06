(eval-when (:compile-toplevel :execute :load-toplevel)
  (ql:quickload :cl-ada-generator))

(in-package :cl-ada-generator)

;; https://github.com/AdaCore/Compile_And_Prove_Demo/

(let* ((name "Absolute_Value")
      (dir-name (format nil "/dev/shm/~a/" (string-downcase name)))
      (code `(with-compilation-unit

	       (function ((,name ((X Integer))
				 :ret Integer
				 :cond ((pre (/= X (attrib Integer First)))
					(post (= (attrib ,name Result) (call abs X))))))
			 (if (< 0 X)
			     (return X)
			     (return (- X)))
			  )))
      (gpr `(project Main
		     (package Compiler
			      (for-use (call Default_Switches (string "Ada")) (comma-list (string "-gnatwa"))))
		     (package Prove
			      (for-use Switches (comma-list (string "--level=2")
							    (string "-j0"))))
		     (package Builder
			      (for-use Global_Configuration_Pragmas (string "main.adc")))))
      (adc `(with-compilation-unit
		(pragma (call Profile GNAT_Extended_Ravenscar))
	      (pragma (call Partition_Elaboration_Policy Sequential))
	      (pragma (call SPARK_Mode On))
	      (pragma (call Warnings Off (string "no Global contract available")))
	      (pragma (call Warnings Off (string "subprogram * has no effect"))))))
  (ensure-directories-exist dir-name)
  (write-source dir-name (string-downcase name) "adb" code)
  (write-source dir-name "main" "gpr" gpr)
  (write-source dir-name "main" "adc" adc))

