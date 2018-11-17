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
  %t1 = alloca i32
  %t2 = alloca i32
  %t3 = alloca i32**
  %t4 = add i32 0, 0
  store i32 %t4, i32* %t1
  %t5 = add i32 0, 0
  store i32 %t5, i32* %t2
  %t6 = add i32 10, 0
  %t7 = sext i32 %t6 to i64
  %t8 = mul i64 %t7, 8
  %t9 = call i8* @malloc(i64 %t8)
  %t10 = bitcast i8* %t9 to i32**
  store i32** %t10, i32*** %t3
  br label %l1
l1:
  %t11 = load i32, i32* %t1
  %t12 = add i32 10, 0
  %t13 = icmp slt i32 %t11, %t12
  br i1 %t13, label %l2, label %l3
l2:
  %t14 = load i32**, i32*** %t3
  %t15 = load i32, i32* %t1
  %t16 = getelementptr i32*, i32** %t14, i32 %t15
  %t17 = add i32 10, 0
  %t18 = sext i32 %t17 to i64
  %t19 = mul i64 %t18, 4
  %t20 = call i8* @malloc(i64 %t19)
  %t21 = bitcast i8* %t20 to i32*
  store i32* %t21, i32** %t16
  br label %l1
l3:
  %t22 = add i32 0, 0
  store i32 %t22, i32* %t1
  br label %l4
l4:
  %t23 = load i32, i32* %t1
  %t24 = add i32 10, 0
  %t25 = icmp slt i32 %t23, %t24
  br i1 %t25, label %l5, label %l6
l5:
  br label %l7
l7:
  %t26 = load i32, i32* %t2
  %t27 = add i32 10, 0
  %t28 = icmp slt i32 %t26, %t27
  br i1 %t28, label %l8, label %l9
l8:
  %t29 = load i32**, i32*** %t3
  %t30 = load i32, i32* %t1
  %t31 = getelementptr i32*, i32** %t29, i32 %t30
  %t32 = load i32*, i32** %t31
  %t33 = load i32, i32* %t2
  %t34 = getelementptr i32, i32* %t32, i32 %t33
  %t35 = add i32 0, 0
  store i32 %t35, i32* %t34
  br label %l7
l9:
  br label %l4
l6:
  %t36 = add i32 0, 0
  store i32 %t36, i32* %t1
  br label %l10
l10:
  %t37 = load i32, i32* %t1
  %t38 = add i32 10, 0
  %t39 = icmp slt i32 %t37, %t38
  br i1 %t39, label %l11, label %l12
l11:
  %t40 = load i32**, i32*** %t3
  %t41 = load i32, i32* %t1
  %t42 = getelementptr i32*, i32** %t40, i32 %t41
  %t43 = load i32*, i32** %t42
  %t44 = load i32, i32* %t1
  %t45 = getelementptr i32, i32* %t43, i32 %t44
  %t46 = add i32 1, 0
  store i32 %t46, i32* %t45
  br label %l10
l12:
  ret void
}
