using Mozi.FESparse
using LinearAlgebra
A=Diagonal([1,1,1])
B=Diagonal([2,2,2])
spA=SparseMatrixCOO(A)
spB=SparseMatrixCOO(B)
res=spA+spB
@test res[1,2]==0
@test res[1,1]==3

@show to_csc(res)

function disperse(A::Matrix,i::Vector{Int},N::Int)
    m,n=size(A)
    I = repeat(i,outer=n)
    J = repeat(i,inner=m)
    V = reshape(A,m*n)
    SparseMatrixCOO(N,N,I,J,V)
end

function disperse(A::Vector,i::Vector{Int},N::Int)
    m=length(A)
    I = i
    J = [1 for i in 1:m]
    V = A
    to_array(SparseMatrixCOO(N,1,I,J,V))[:,1]
end

@show disperse([1,2,3],[4,5,10],10)
