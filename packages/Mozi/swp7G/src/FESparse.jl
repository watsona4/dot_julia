module FESparse
using SparseArrays

export SparseMatrixCOO,SparseMatrixDOK
export spzeros_coo,spzeros_dok
export to_csc, to_array

mutable struct SparseMatrixDOK{Tv,Ti<:Integer} <: AbstractSparseMatrix{Tv,Ti}
    m::Int
    n::Int
    dict::Dict{Tuple{Ti,Ti},Tv}
end

mutable struct SparseMatrixCOO{Tv,Ti<:Integer} <: AbstractSparseMatrix{Tv,Ti}
    m::Int
    n::Int
    rowptr::Vector{Ti}
    colptr::Vector{Ti}
    nzval::Vector{Tv}
end

import Base.size

size(spmatrix::SparseMatrixCOO)=(spmatrix.m,spmatrix.n)

function spzeros_dok(m::Int,n::Int)
    SparseMatrixDOK{Float64,Int}(m,n,Dict{Tuple{Int,Int},Float64}())
end

function spzeros_coo(m::Int,n::Int)
    SparseMatrixCOO{Float64,Int}(m,n,Int[],Int[],Float64[])
end

function SparseMatrixCOO(A :: AbstractArray)
    m,n=size(A)
    I=Vector{Int}()
    J=Vector{Int}()
    V=Vector{Float64}()
    for j in 1:n, i in 1:m
        if A[i,j]!=0
            push!(I,i)
            push!(J,j)
            push!(V,A[i,j])
        end
    end
    SparseMatrixCOO{Float64,Int}(m,n,I,J,V)
end

function add(a::SparseMatrixCOO,b::SparseMatrixCOO)
    if a.m!=b.m || a.n!=b.n
        throw("Dimension not match!")
    end
    I=[a.rowptr;b.rowptr]
    J=[a.colptr;b.colptr]
    V=[a.nzval;b.nzval]
    SparseMatrixCOO(a.m,a.n,I,J,V)
end

import Base.+
import Base.getindex

+(a::SparseMatrixCOO,b::SparseMatrixCOO)=add(a::SparseMatrixCOO,b::SparseMatrixCOO)

function getindex(spmatrix::SparseMatrixCOO,i::Int,j::Int)
    idx=(spmatrix.rowptr.==i) .& (spmatrix.colptr.==j)
    return reduce(+, spmatrix.nzval[idx])
end

function getindex(spmatrix::SparseMatrixCOO,i::Int,j::Int)
    idx=(spmatrix.rowptr.==i) .& (spmatrix.colptr.==j)
    return reduce(+, spmatrix.nzval[idx])
end

function to_csc(spmatrix::SparseMatrixCOO)
    m=spmatrix.m
    n=spmatrix.n
    I=spmatrix.rowptr
    J=spmatrix.colptr
    V=spmatrix.nzval
    sparse(I,J,V,m,n)
end

function to_array(spmatrix::SparseMatrixCOO)
    Array(to_csc(spmatrix))
end

end
