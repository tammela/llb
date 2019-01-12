declare i32 @printf(i8*, ...)
@.pint = private unnamed_addr constant [3 x i8] c"%d\00"

define i32 @main() {
b1:
   %x = alloca i32
   store i32 0, i32* %x
   %cond = icmp eq i32 1, 0
   br i1 %cond, label %b2, label %b3
b2:
   store i32 20, i32* %x
   br label %b4
b3:
   store i32 10, i32* %x
   br label %b4
b4:
   %lx = load i32, i32* %x
   call i32 (i8*, ...) @printf(i8* getelementptr ([3 x i8], [3 x i8]* @.pint, i32 0, i32 0), i32 %lx)
   ret i32 0
}
