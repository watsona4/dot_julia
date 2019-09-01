using ExtensibleUnions
using Test

abstract type A1 end
@test_throws ArgumentError extensibleunion!(A1)

@test_throws ArgumentError extensibleunion!(Int)

struct S1
    x
end
@test_throws ArgumentError extensibleunion!(S1)

mutable struct S2 end
@test_throws ArgumentError extensibleunion!(S2)

abstract type A2 end
struct S3 <: A2
end
@test_throws ArgumentError extensibleunion!(S3)

struct S4 end
@test !isextensibleunion(S4)
extensibleunion!(S4)
@test isextensibleunion(S4)
extensibleunion!(S4)
@test isextensibleunion(S4)
extensibleunion!(S4)
@test isextensibleunion(S4)

struct S6 end
extensibleunion!(S6)
@test !ExtensibleUnions.unioncurrentlycontains(S6, String)
addtounion!(S6, String)
@test ExtensibleUnions.unioncurrentlycontains(S6, String)

struct S7 end
extensibleunion!(S7)
@test !ExtensibleUnions.unioncurrentlycontains(S7, String)
addtounion!(S7, String)
@test ExtensibleUnions.unioncurrentlycontains(S7, String)

struct S8 end
@test_throws ArgumentError addtounion!(S8)
@test_throws ArgumentError ExtensibleUnions.unioncurrentlycontains(S8, String)
