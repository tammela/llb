
define void @main() {
entry:
    ; declaring x and y
    %x = alloca i32
    %y = alloca i32

    ; a = 4
    %a = alloca i32
    %four = add i32 0, 4
    store i32 %four, i32* %a

    br label %b1
b1:
    ; z = 1
    %z = alloca i32
    store i32 1, i32* %z

    ; z > a
    %load-1-z = load i32, i32* %z
    %load-1-a = load i32, i32* %a
    %zgta = icmp sgt i32 %load-1-z, %load-1-a

    br i1 %zgta, label %b2, label %b3
b2:
    ; x = 1
    store i32 1, i32* %x

    ; z > 2
    %load-2-z = load i32, i32* %z
    %zgt2 = icmp sgt i32 %load-2-z, 2

    br i1 %zgt2, label %b4, label %b5
b3:
    ; x = 2
    store i32 2, i32* %x

    br label %b5
b4:
    ; y = 3
    store i32 3, i32* %y

    ; y = x + 1 + a
    %load-1-x = load i32, i32* %x
    %load-2-a = load i32, i32* %a
    %sum-x-1 = add i32 %load-1-x, 1
    %sum-x-1-a = add i32 %sum-x-1, %load-2-a
    store i32 %sum-x-1-a, i32* %y

    ; y = y + 1
    %load-1-y = load i32, i32* %y
    %sum-y-1 = add i32 %load-1-y, 1
    store i32 %sum-y-1, i32* %y

    br label %exit
b5:
    ; z = x - 3
    %load-2-x = load i32, i32* %x
    %sub-x-3 = sub i32 %load-2-x, 3
    store i32 %sub-x-3, i32* %z

    br label %b6
b6:
    ; z = x + 7
    %load-3-x = load i32, i32* %x
    %sum-x-7 = add i32 %load-3-x, 7
    store i32 %sum-x-7, i32* %z

    br label %exit
exit:
    ; TODO: print a, x, y, z
    ret void
}
