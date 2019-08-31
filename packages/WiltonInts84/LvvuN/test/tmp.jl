using WiltonInts84

using Test
using StaticArrays

include("num_quad.jl")

if !@isdefined record
    record = false
end

p1 = SVector(0.4,0.7000000000000001,0.0)
p2 = SVector(0.5,0.7000000000000001,0.0)
p3 = SVector(0.5,0.6000000000000001,0.0)
z  = SVector(0.0,0.0,1.0)


N = 2
T = eltype(Float64)
P = SVector{3,T}
J = Vector{SVector{N+3,T}}()
L = Vector{SVector{N+3,P}}()
I = similar(J)
K = similar(L)

h = 1.2


# circle through triangle vertex
c = SVector(0.020000000000000004,0.06,0.0)
r, R = 0.0, 0.8
q = contour(p1,p2,p3,c,r,R)
@test length(q.segments) == 0
@test length(q.arcs) == 0
@test length(q.circles) == 0
A,B = wiltonints(q,c, Val{N})
push!(I,SVector(A)); push!(K,SVector(B))
if record
    P,Q = dblquadints1(p1,p2,p3,c,Val{N},r,R)
    push!(J,P); push!(L,Q)
end
