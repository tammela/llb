declare i32 @printf(i8*, ...)
@.pint = private unnamed_addr constant [3 x i8] c"%d\00"

define void @main() {
entry:
  %t1 = add i32 1, 0 ; %t1 = 1
  %t2 = add i32 2, 0 ; %t2 = 2
  %t3 = icmp eq i32 %t1, %t2 ; %t1 == t2 ?
  br i1 %t3, label %l1, label %l2
l1:
  call i32 (i8*, ...) @printf(i8* getelementptr ([3 x i8], [3 x i8]* @.pint, i32 0, i32 0), i32 %t1)
  br label %l3
l2:
  call i32 (i8*, ...) @printf(i8* getelementptr ([3 x i8], [3 x i8]* @.pint, i32 0, i32 0), i32 %t2)
  br label %l3
l3:
  ret void
}
