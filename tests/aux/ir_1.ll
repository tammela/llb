
define void @main() {
entry:
  br i1 true, label %l1, label %l2
l1:
  br label %l3
l2:
  br label %l3
final:
  ret void
}
