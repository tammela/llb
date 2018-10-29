declare i32 @putchar(i32)
declare i32 @printf(i8*, ...)
declare i8* @malloc(i64)
@.pchar = private unnamed_addr constant [3 x i8] c"%c\00"
@.pint = private unnamed_addr constant [3 x i8] c"%d\00"
@.pfloat = private unnamed_addr constant [3 x i8] c"%f\00"
@.pstr = private unnamed_addr constant [3 x i8] c"%s\00"
@.paddress = private unnamed_addr constant [3 x i8] c"%p\00"

define void @main() {
entry:
  %t2 = add i32 1, 0

  %t1 = alloca i32
  store i32 %t2, i32* %t1

  %t3 = load i32, i32* %t1

  %t5 = icmp eq i32 %t3, 1
  br i1 %t5, label %l1, label %l2
l1:
  %t9 = load i32, i32* %t1
  call i32 (i8*, ...) @printf(i8* getelementptr ([3 x i8], [3 x i8]* @.pint, i32 0, i32 0), i32 %t9)
  br label %l3
l2:
  %t7 = add i32 20, 0
  call i32 (i8*, ...) @printf(i8* getelementptr ([3 x i8], [3 x i8]* @.pint, i32 0, i32 0), i32 %t7)
  br label %l3
l3:
  %t8 = getelementptr [2 x i8], [2 x i8]* @.str0 , i32 0, i32 0
  call i32 (i8*, ...) @printf(i8* getelementptr ([3 x i8], [3 x i8]* @.pstr, i32 0, i32 0), i8* %t8)
  ret void
}
@.str0 = private unnamed_addr constant [2 x i8] c"
\00"
