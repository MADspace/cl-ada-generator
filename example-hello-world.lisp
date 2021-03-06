(eval-when (:compile-toplevel :execute :load-toplevel)
  (ql:quickload :cl-ada-generator))
#+nil
(ql:register-local-projects)

(in-package :cl-ada-generator)

;; https://github.com/AdaCore/Compile_And_Prove_Demo/tree/master/examples/hello_world

(let ((code `(with-compilation-unit
		 (with Ada.Command_Line Ada.Text_IO)
	       (procedure ((Hello_World nil
					:decl ((decl ((You "constant String"
							   (assign-if (< 0 Ada.Command_Line.Argument_Count)
							
								      (call Ada.Command_Line.Argument 1)
								      (string "world")))
						      )))))
			  (call Ada.Text_IO.Put (string "Hello, "))
			  (call Ada.Text_IO.Put_Line You)
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
  (ensure-directories-exist #P"/dev/shm/hello_world/")
  (write-source #P"/dev/shm/hello_world/" "hello_world" "adb" code)
  (write-source #P"/dev/shm/hello_world/" "main" "gpr" gpr)
  (write-source #P"/dev/shm/hello_world/" "main" "adc" adc))

;; run  cd /dev/shm/hello_world; gprbuild main.gpr
