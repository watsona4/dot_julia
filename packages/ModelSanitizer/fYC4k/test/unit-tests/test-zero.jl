import ModelSanitizer
import Test

a = [1, 2, 3]
b = [4 5 6; 7 8 9; 10 11 12]
c = Array{Int, 3}(undef, 3, 3, 3)
c[:] .= 100

d = ["foo", "bar", "baz"]
e = ["foo" "bar" "baz"; "foo" "bar" "baz"]
f = Array{String, 3}(undef, 3, 3, 3)
f[:] .= "foo"

g = Any["foo", "bar", "baz"]
h = Any["foo" "bar" "baz"; "foo" "bar" "baz"]
i = Array{Any, 3}(undef, 3, 3, 3)
i[:] .= "foo"

j = Union{String, Missing}["foo", missing, "baz"]
k = Union{Missing, Nothing}[missing, nothing, missing]
l = Nothing[nothing, nothing, nothing]

Test.@test !any(a .== 0)
Test.@test !any(b .== 0)
Test.@test !any(c .== 0)
Test.@test !any(d .== "")
Test.@test !any(e .== "")
Test.@test !any(f .== "")
Test.@test !any(g .== 0)
Test.@test !any(h .== 0)
Test.@test !any(i .== 0)
Test.@test !any(skipmissing(j .== ""))
Test.@test !(skipmissing(k) == skipmissing([missing, nothing, missing]))
Test.@test all(l .== nothing)

ModelSanitizer.zero!(a)
ModelSanitizer.zero!(b)
ModelSanitizer.zero!(c)
ModelSanitizer.zero!(d)
ModelSanitizer.zero!(e)
ModelSanitizer.zero!(f)
ModelSanitizer.zero!(g)
ModelSanitizer.zero!(h)
ModelSanitizer.zero!(i)
ModelSanitizer.zero!(j)
ModelSanitizer.zero!(k)
ModelSanitizer.zero!(l)

Test.@test all(a .== 0)
Test.@test all(b .== 0)
Test.@test all(c .== 0)
Test.@test all(d .== "")
Test.@test all(e .== "")
Test.@test all(f .== "")
Test.@test all(g .== 0)
Test.@test all(h .== 0)
Test.@test all(i .== 0)
Test.@test all(j .== "")
Test.@test all(k .== nothing)
Test.@test all(l .== nothing)

struct Z end

Test.@test zero(Any) == 0
Test.@test zero(Z) == 0
Test.@test zero(String) == ""
Test.@test zero(Nothing) == nothing
Test.@test zero(Missing) === missing
Test.@test ismissing(zero(Missing))
