using PartedArrays
using Test

function myfun(a,b)
    c = [1,3,5,6]
    d = a*b
    e = c .* d
    return e
end

@testset "Vector" begin
# Vector
x,y = collect(1:3),[5,10,1,8]
V = [x;y]
parts = (x=1:3,y=4:7)
Z = PartedArray(V,parts)
@test Z.x == x
@test Z.y == y
@test Z[:x] == x
@test Z[:y] == y
@test Z == V
@test Z.A == V
@test Z[1] == 1
@test Z[end] == 8
@test Z + Z == 2V
@test length(Z) == 7
@test size(Z) == (7,)
Z = PartedVector(V,(3,4),(:x,:y))

@test Z.x == x
@test Z.y == y
@test Z[:x] == x
@test Z[:y] == y
@test Z == V
@test Z.A == V
@test Z[1] == 1
@test Z[end] == 8
@test Z + Z == 2V
@test length(Z) == 7
@test size(Z) == (7,)
Z = PartedVector(V,[3,4],[:x,:y])
@test Z.x == x
@test Z.y == y
@test Z[:x] == x
@test Z[:y] == y
@test Z == V
@test Z.A == V
@test Z[1] == 1
@test Z[end] == 8
@test Z + Z == 2V
@test length(Z) == 7
@test size(Z) == (7,)
@inferred getindex(Z,:x)
@test Z.parts isa Dict
Z = PartedVector(V,(3,4),Val((:x,:y)))
@test Z.x == x
@test Z.parts isa NamedTuple


# Test multiplication
function testfun(V::PartedArray,a)
    V.A'a
end
a = ones(7)
@inferred testfun(Z,a)

# Copying
Z2 = copy(Z)
@test Z2 isa PartedVector
@test Z2.A == Z.A
@test !(Z2.A === Z.A)
Z2 .= rand(1:7,7)
@test Z2.x != Z.x
Zs = [Z,Z2]
Zs2 = copy(Zs)
@test Zs2[1].A == Zs[1].A
@test Zs2[1].A === Zs[1].A
@test Zs2[2].A === Zs[2].A
Zs2 = deepcopy(Zs)
@test Zs2[1].A == Zs[1].A
@test !(Zs2[1].A === Zs[1].A)
@test !(Zs2[2].A === Zs[2].A)
typeof(Zs2)
@test Zs2 isa Vector{PartedVector{Int,Vector{Int},P}} where P <: NamedTuple

PartedVecTraj{T} = Vector{PartedVector{Int,Vector{Int},P}} where P <: NamedTuple

struct vars{T}
    X::PartedVecTraj{T}
end
v = vars(Zs2)
@inferred rand(3,3)*v.X[1].x

end

@testset "Matrix" begin
# Matrix
xx = ones(2,2)
xy = ones(2,3)*2
yx = ones(3,2)*3
yy = ones(3,3)*10
A = [xx xy;
     yx yy]
parts = (xx=(1:2,1:2),xy=(1:2,3:5),yx=(3:5,1:2),yy=(3:5,3:5))
B = PartedArray(A,parts)
@inferred rand(2,2)*B.xx
@test B.xx == xx
@test B.yy == yy
@test B[:xx] == xx
@test B[:yy] == yy
@test B.xy == xy
@test B == A
@test B.A == A
@test B[1] == 1
@test B[end] == 10
@test B[2,3] == 2
@test B + B == 2A
@test length(B) == 25
@test size(B) == (5,5)
B = PartedArrays.PartedMatrix(A,(2,3),(:x,:y))
@test B.xx == xx
@test B.yy == yy
@test B[:xx] == xx
@test B[:yy] == yy
@test B.xy == xy
@test B == A
@test B.A == A
@test B[1] == 1
@test B[end] == 10
@test B[2,3] == 2
@test B + B == 2A
@test length(B) == 25
@test size(B) == (5,5)
inds = LinearIndices(A)[1:2,1:2]
@test B[inds] == A[inds]
@test B[inds] == B.xx

B + A
@test B + A == 2A
@test IndexStyle(B) == IndexCartesian()
A[2,2] = 10
@test B.xx[2,2] == 10
B[3,3] = 100
@test B.yy[1,1] == 100
B[1:3] .= 1
@test B.xx[:,1] == [1;1]
B[3] = 55
@test B.yx[1] == 55
end

@testset "Partitioning" begin
names = (:x,:y,:z)
lengths = (5,10,15)
lengths2 = (5,10,15,2)
@test_throws MethodError create_partition(lengths2,names)
names2 = (:a,:b)
lengths2 = (2,3)
part = @inferred create_partition2(lengths,lengths2)
@test length(part) == 6

names_combined = PartedArrays.combine_names(names, names2)
part = @inferred create_partition2(lengths,lengths2,Val(names_combined))
@test length(part) == 6
@test part.xa == (1:5,1:2)
@test length.(part.zb) == (15,3)
end
