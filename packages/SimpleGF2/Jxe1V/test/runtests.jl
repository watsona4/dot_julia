using SimpleGF2
using LinearAlgebra
using Test

A = ones(GF2,3,3)
@test det(A) == GF2(4)
@test rank(A) == 1
@test nullity(A) == 2
@test A*A==A
@test A+A == 0A
B = [ 1 1 1; 0 0 0; 0 0 0]
@test rref(A) == GF2.(B)
@test size(nullspace(A)) == (3,2)
v = ones(GF2,3)
x = solve(A,v)
@test A*x == v

@test GF2(3) == 5
