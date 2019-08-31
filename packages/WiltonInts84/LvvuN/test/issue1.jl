using WiltonInts84
using StaticArrays
using Test

#include("num_quad.jl")

if !@isdefined record
    record = false
end

v1p = SVector(4.12, 1.74, 1.8);
v2p = SVector(2.04, 3.47, -3.5);
v3p = SVector(-4.21, 3.2, 0.08);
lvp = v2p-v1p; # an edge vector
observationPointp = v1p + 2.84*lvp;
I, J = wiltonints(v1p,v2p,v3p,observationPointp,Val{0})

using JLD2
fn = joinpath(dirname(@__FILE__),"issue1.jld2")

if record == true
    K, L = dblquadints1(v1p, v2p, v3p, observationPointp, Val{0})
    K = [k for k in K]
    L = [L[d][i] for i in 1:3, d in eachindex(L)]
    jldopen(fn, "w") do file
        write(file, "K", K)
        write(file, "L", L)
    end
else
    K, L = jldopen(fn,"r") do file
        read(file, "K"),
        read(file, "L")
    end
end

for d in eachindex(K)
    @eval @test nearlyequal(I[$d], K[$d], 10e-8)
    for i in 1:3
        @eval @test nearlyequal(J[$d][$i], L[$i,$d], 10e-8)
    end
end
