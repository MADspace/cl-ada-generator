(eval-when (:compile-toplevel :execute :load-toplevel)
  (ql:quickload :cl-ada-generator))
#+nil
(ql:register-local-projects)

(in-package :cl-ada-generator)



(let ((def `(package Bounded_Queue_V2
		     (subtype Element_Type Integer)
		     (type Queue_Array private)
		     (type (discriminant Queue_Type ((Max_Size Positive))) private)
		     (function (Full ((Queue Queue_Type :i)) Boolean))
		     (function (Empty ((Queue Queue_Type :i)) Boolean))
		     (function (Size ((Queue Queue_Type :i)) Natural))
		     (function (First_Element ((Queue Queue_Type :i)) Element_Type ((with (pre (not (call Empty Queue)))))))
		     (function (Last_Element ((Queue Queue_Type :i)) Element_Type
					     ((with (pre (not (call Empty Queue)))))))
		     (procedure (Clear ((Queue Queue_Type :io))
				      ((with (post (and-then (call Empty Queue) (= (call Size Queue) 0)))))))

		     (procedure (Enqueue ((Queue Queue_Type :io)
					  (Item Element_Type :i))
					 ((with (pre (not (call Full Queue)))
						(post  (and-then (not (call Empty Queue))
								 (= (call Size Queue)
								    (+ (call Size (attrib Queue Old)) 1))
								 (= (call Last_Element Queue) Item)))))))
		     (procedure (Dequeue ((Queue Queue_Type :io)
					  (Item Element_Type :o))
					 ((with (pre (not (call Empty Queue)))
						(post  (and-then (= Item (call First_Element (attrib Queue Old)))
								 (= (call Size Queue)
								    (- (call Size (attrib Queue Old)) 1))))))))
		     (raw "private")
		     (type Queue_Array (array ((range nil nil :type Positive)) Element_Type))
		     (type (discriminant Queue_Type ((Max_Size Positive)))
			   (record ((Count Natural)
				    (Front Positive)
				    (Rear Positive)
				    (Items (aref Queue_Array (dots 1 Max_Size))))))))
      (code `(package-body Bounded_Queue_V2
			   (function (Full ((Queue Queue_Type :i)) Boolean)
				     (return (= Queue.Count Queue.Max_Size)))
			   (function (Empty ((Queue Queue_Type :i)) Boolean)
				     (return (= Queue.Count 0)))
			   (function (Size ((Queue Queue_Type :i)) Natural)
				     (return Queue.Count))
			   (function (First_Element ((Queue Queue_Type :i)) Element_Type)
				     (return (aref Queue.Items Queue.Front)))
			   (function (Last_Element ((Queue Queue_Type :i)) Element_Type)
				     (return (aref Queue.Items Queue.Rear)))
			   (procedure (Clear ((Queue Queue_Type :io)))
				      (setf Queue.Count 0
					    Queue.Front 1
					    Queue.Rear Queue.Max_Size))
			   (procedure (Enqueue ((Queue Queue_Type :io)
						(Item Element_Type :i)))
				      (setf Queue.Rear (rem Queue.Rear (+ Queue.Max_Size 1))
					    (aref Queue.Items Queue.Rear) Item)
				      (incf Queue.Count))
			   (procedure (Dequeue ((Queue Queue_Type :io)
						(Item Element_Type :o)))
				      (setf Item (aref Queue.Items Queue.Front)
					    Queue.Front (rem Queue.Front (+ Queue.Max_Size 1)))
				      (decf Queue.Count))))
      (call `(with-compilation-unit
		 (with-use Bounded_Queue_V2)
	       (with-use Ada.Text_IO)
	       (procedure (Bounded_Queue_Example_V2 nil ((decl ((My_Queue (call Bounded_Queue_V1.Queue_Type :Max_Size 100))
								(Value Integer)))))
			  (call Clear My_Queue)
			  (for (Count (range 17 52 :type Integer))
			       (call Enqueue :Queue My_Queue :Item Count))
			  (for (Count (range 1 5 :type Integer))
			       (call Dequeue :Queue My_Queue :Item Value)
			       (call Put_Line (attrib Integer (call Image Value))))
			  (call Clear My_Queue)
			  (setf Value (call Size My_Queue))
			  (call Put_Line (& (string "Size of cleared queue is ")
					    (attrib Integer (call Image Value))))))))
  (ensure-directories-exist #P"/dev/shm/q2/")
  (write-source #P"/dev/shm/q2/" "bounded_queue_v2" "ads" def)
  (write-source #P"/dev/shm/q2/" "bounded_queue_v2" "adb" code)
  (write-source #P"/dev/shm/q2/" "bounded_queue_example_v2" "adb" call)
  ;(emit-ada :code code)
  )
