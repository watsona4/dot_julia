using FlexLinearAlgebra
using LinearAlgebra
using Test

v = FlexConvert([4,5,6])
@test v+v == 2v
@test v-v == FlexVector(1:3)
@test dot(v,v) == 77
v[2] = 4
v[3] = 4
@test v == 4*FlexOnes(1:3)
@test v[-1] == 0

x = collect(1:5)
v = FlexConvert(x)
@test Vector(v) == x
@test Set(keys(v)) == Set(1:5)
@test sum(values(v)) == sum(v)
@test keytype(v) == Int
@test valtype(0. * v) == Float64
@test length(v) == 5
@test haskey(v,1)
@test (-v) + v == 0v

v = FlexOnes(Int,1:6)
delete_entry!(v,5)
delete_entry!(v,5)
@test sum(v) == 5

M = FlexConvert(Matrix{Int}(I,3,3))
@test M[1,1]==1
S = Set(1:3)
@test Set(row_keys(M)) == S
@test Set(col_keys(M)) == S

A = [1 3; 4 5]
B = [-1.0 3; 5 -1.5]
v = [2; 3]
AA = FlexConvert(A)
BB = FlexConvert(B)
vv = FlexConvert(v)

@test valtype(BB) == Float64
S = Set(1:2)
@test Set(row_keys(BB)) == S
@test Set(col_keys(BB)) == S


@test Vector(AA*vv) == A*v
@test Matrix(AA*BB) == Matrix(A)*Matrix(B)
@test (AA*BB)*vv == AA*(BB*vv)
@test Set(row_keys(AA)) == Set(row_keys(BB))
AA[1,3] = 2
@test size(AA) == (2,3)


A = FlexMatrix{Int}(1:2,3:4)
A[1,4] = 5
@test sum(values(A)) == 5


A = FlexOnes(Int,1:5,1:5)
delete_row!(A,5)
delete_col!(A,5)
@test A == FlexOnes(Int,1:4,1:4)

A = FlexOnes(1:3,6:12) + im * FlexOnes(1:3,6:12)
@test Matrix(A') == Matrix(A)'

v = FlexOnes(Complex,1:4)
v[4] = 2im
@test dot(v,v) == (v'*v)[1]
