using DimArrays
using Test

a = DimVector([1,2,3,4], :aa, 100)

@test DimArrays.dname(a,1) == :aa
@test DimArrays.ifunc(a,1)(1) == 100
@test DimArrays.haslabel(a) == false

@test typeof(a') <: DimMatrix
@test ndims( (a')' )==1
@test DimArrays.dname( (a')' ,1) == :aa

@test typeof( map(sqrt, a) ) <: DimVector
@test typeof( [sqrt(i) for i in a] ) <: DimVector

b = DimArray([1.0 2; 3 4]; label=:c)

@test string(b) == "DimArray([1.0 2.0; 3.0 4.0]; label = :c)"

@test string(name!(selectdim(b, :col, 2), "one", "cont")) == "DimArray([2.0, 4.0], :one; label = :cont)"

@test permutedims(b, (:col, :row))[1,2] ≈ 3

using Statistics

@test sum(b; dims=[:row,:col])[1] ≈ 10
@test std(b; dims=:col)[1] ≈ 0.7071067811865476
@test typeof( mean(b; dims=2) ) <: DimMatrix

@test selectdim(b, :col, 1)[2] ≈ 3
@test typeof( selectdim(b, 2, 1) ) <: DimVector

@test (b .+ 99)[1,1] ≈ 100
# @test typeof(b .+ 99) <: DimMatrix

@test sum( hcat(DimArray([1,3]), [2,4]) ./ b ) ≈ 4

@test maximum( nest([DimArray([1,3]), [2,4]]) .- b ) ≈ 0

# aabb = vcat(hcat(a,a),b,b)

# @test size(aabb) == (8,2)
# @test DimArrays.dnames(aabb) == [:aa, :col]

push!(a, 55,66)
@test DimArrays.ifuncs(a)[1](length(a)) == 600

c = dictvector(ones(2), [:α, "β"], :ω, :N)

push!(c, 77, 88)
append!(c, [0,0])
push!(c, 99, :γ)

@test c isa DimVector
# @test sum(c, :ω)[1] ≈ 266 # todo: dims=: etc
