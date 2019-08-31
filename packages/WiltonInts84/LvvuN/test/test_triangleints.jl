using WiltonInts84

using Test
using StaticArrays

#include("num_quad.jl")

if !@isdefined record
    record = false
end

N = 2
T = Float64

J = Vector{SVector{N+3,T}}()
I = similar(J)
L = Vector{SVector{N+3,SVector{3,T}}}()
K = similar(L)

v1 = SVector(1.0, 0.0, 0.0)
v2 = SVector(0.0, 1.0, 0.0)
v3 = SVector(0.0, 0.0, 0.0)
n = normalize(cross(v1-v3,v2-v3))

X = [
    (v1 + v2 + v3)/3               + 20n, # h > 0, inside
    (1-1.5)v1 + 1.5v3              + 20n, # h > 0, on extension [v1,v3]
    0.5v1 + 0.5v3                  + 20n, # h > 0, on the interior of [v1,v3]
    -0.5v1 + 0.5v2 + (1-0.5-0.5)v3 + 20n, # h > 0, outside
    v2                             + 20n, # h > 0, on top of v2

    (v1 + v2 + v3)/3               - 20n, # h < 0, inside
    (1-1.5)v1 + 1.5v3              - 20n, # h < 0, on extension [v1,v3]
    0.5v1 + 0.5v3                  - 20n, # h < 0, on the interior of [v1,v3]
    -0.5v1 + 0.5v2 + (1-0.5-0.5)v3 - 20n, # h < 0, outside
    v2                             - 20n, # h < 0, on top of v2

    (1-1.5)v1 + 1.5v3              - 0n,  # h = 0, on extension [v1,v3]
    -0.5v1 + 0.5v2 + (1-0.5-0.5)v3 - 0n,  # h = 0, outside

    (v1 + v2 + v3)/3               - 0n,  # h = 0, inside
]


for (i,x) in enumerate(X)
    A, B = wiltonints(v1,v2,v3,x,Val{N})
    push!(I,SVector(A));
    push!(K,SVector(B));
    if record
        P, Q = dblquadints1(v1,v2,v3,x,Val{N})
        push!(J,SVector(P));
        push!(L,SVector(Q));
    end
end

using JLD2
fn = joinpath(dirname(@__FILE__),"triangleints.jld2")

# convert data to arrays to avoid JLD bug
I = T[I[m][n] for m in eachindex(I), n in 1:length(eltype(I))]
K = T[K[m][n][p] for m in eachindex(K), n in 1:length(eltype(K)), p in 1:3]

if record == true
    J = T[J[m][n] for m in eachindex(J), n in 1:length(eltype(J))]
    L = T[L[m][n][p] for m in eachindex(L), n in 1:length(eltype(L)), p in 1:3]
    jldopen(fn,"w") do file
        write(file, "J", J)
        write(file, "L", L)
    end
else
    J,L = jldopen(fn,"r") do file
        read(file, "J"), read(file, "L")
    end
end

# The actual tests
ϵ = 1.0e-4
for i = 1 : size(I,1)-1
    for j = 1 : size(I,2)
        @test !isnan(I[i,j])
        @test !isnan(K[i,j,1])
        @test !isnan(K[i,j,2])
        @test !isnan(K[i,j,3])
        @test !isinf(I[i,j])
        @test !isinf(K[i,j,1])
        @test !isinf(K[i,j,2])
        @test !isinf(K[i,j,3])
        @test nearlyequal(I[i,j], J[i,j], ϵ)
        @test nearlyequal(vec(K[i,j,:]), vec(L[i,j,:]), ϵ)
    end
end

ϵ = 2.0e-4
for i = size(I,1)
    for j = 1 : size(I,2)
        @test !isnan(I[i,j])
        @test !isnan(K[i,j,1])
        @test !isnan(K[i,j,2])
        @test !isnan(K[i,j,3])
        @test !isinf(I[i,j])
        @test !isinf(K[i,j,1])
        @test !isinf(K[i,j,2])
        @test !isinf(K[i,j,3])
        @test nearlyequal(I[i,j], J[i,j], ϵ)
        j == 1 && continue # dblquad cannot approx Cauchy principal values...
        @test nearlyequal(vec(K[i,j,:]), vec(L[i,j,:]), ϵ)
    end
end
