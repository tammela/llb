; ModuleID = 'tests/testando.bc'
source_filename = "aux/book.ll"

define void @main() {
entry:
  %x = alloca i32
  %y = alloca i32
  %a = alloca i32
  %four = add i32 0, 4
  br label %b1

b1:                                               ; preds = %entry
  %z = alloca i32
  %zgta = icmp sgt i32 1, %four
  br i1 %zgta, label %b2, label %b3

b2:                                               ; preds = %b1
  %zgt2 = icmp sgt i32 1, 2
  br i1 %zgt2, label %b4, label %b5

b3:                                               ; preds = %b1
  br label %b5

b4:                                               ; preds = %b2
  %load-1-x = load i32, i32* %x
  %load-2-a = load i32, i32* %a
  %sum-x-1 = add i32 %load-1-x, 1
  %sum-x-1-a = add i32 %sum-x-1, %load-2-a
  %sum-x-1-a-y = add i32 %sum-x-1-a, 3
  %sum-y-1 = add i32 %sum-x-1-a, 1
  br label %exit

b5:                                               ; preds = %b3, %b2
  %phi2 = phi i32 [ 1, %b2 ], [ 2, %b3 ]
  %sub-x-3 = sub i32 %phi2, 3
  br label %b6

b6:                                               ; preds = %b5
  %load-3-x = load i32, i32* %x
  %sum-x-7 = add i32 %load-3-x, 7
  br label %exit

exit:                                             ; preds = %b6, %b4
  %phi3 = phi i32 [ 1, %b4 ], [ undef, %b6 ]
  %phi1 = phi i32 [ 1, %b4 ], [ %sum-x-7, %b6 ]
  %phi = phi i32 [ %sum-y-1, %b4 ], [ undef, %b6 ]
  ret void
}
