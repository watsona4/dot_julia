using ExtensibleUnions
using Test

struct S5 end
function f1 end
@test !isextensibleunion(S5)
@test !isextensiblefunction(f1)
extensiblefunction!(f1)
@test isextensiblefunction(f1)
@test_throws ArgumentError extensiblefunction!(f1, S5)
@test !isextensibleunion(S5)
extensibleunion!(S5)
@test isextensibleunion(S5)
extensiblefunction!(f1, S5)
@test isextensiblefunction(f1)
extensiblefunction!(f1, S5)
@test isextensiblefunction(f1)
extensiblefunction!(f1, S5)
@test isextensiblefunction(f1)
