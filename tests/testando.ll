; ModuleID = 'tests/testando.bc'
source_filename = "aux/book.ll"

define void @main() {
entry:
  %x = alloca i32
  %y = alloca i32
  %four = add i32 0, 4
  br label %b1

b1:                                               ; preds = %entry
  %z = alloca i32
  store i32 1, i32* %z
  %zgta = icmp sgt i32 1, %four
  br i1 %zgta, label %b2, label %b3

b2:                                               ; preds = %b1
  store i32 1, i32* %x
  %zgt2 = icmp sgt i32 1, 2
  br i1 %zgt2, label %b4, label %b5

b3:                                               ; preds = %b1
  store i32 2, i32* %x
  br label %b5

b4:                                               ; preds = %b2
  %sum-x-1 = add i32 1, 1
  %sum-x-1-a = add i32 %sum-x-1, %four
  store i32 %sum-x-1-a, i32* %y
  br label %exit

b5:                                               ; preds = %b3, %b2
  %sub-x-3 = sub i32 1, 3
  store i32 %sub-x-3, i32* %z
  store i32 4, i32* %x
  br label %b6

b6:                                               ; preds = %b5
  %load-3-x = load i32, i32* %x
  %sum-x-7 = add i32 %load-3-x, 7
  store i32 %sum-x-7, i32* %z
  br label %exit

exit:                                             ; preds = %b6, %b4
  ret void
}
