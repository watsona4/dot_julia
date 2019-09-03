using Test
using RingLists

a = RingList(1,2,3)
b = RingList(2,3,1)
@test a==b
@test reverse(a)==reverse(b)
@test hash(a) == hash(b)
@test length(a) == 3
@test sort(collect(keys(a))) == [1,2,3]
@test Set(a) == Set([1,2,3])
@test first(a,true) == 1
@test a[1] == 2
@test Vector(b) == [1,2,3]
@test eltype(b) == Int
a = RingList{Int}()
insert!(a,1)
insert!(a,2)
@test Vector(a) == [1,2]

a = RingList(1,2,3,4)
b = RingList(1,2,4)
delete!(a,3)
@test a==b
