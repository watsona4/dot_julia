module StandardizedMatrices

export StandardizedMatrix

using Statistics, LinearAlgebra
import LinearAlgebra: mul!

#-----------------------------------------------------------------------------# types
const AVec{T} 	= AbstractVector{T}
const AMat{T} 	= AbstractMatrix{T}
const VecF 		= Vector{Float64}

#----------------------------------------------------------------# StandardizedMatrix
"""
Treat a matrix as standardized, similar to `z = StatsBase.zscore(x, 1)`, without
altering the original data.

`z = StandardizedMatrix(x::AbstractMatrix)`
`z = StandardizedMatrix(x::AbstractMatrix, μ::AbstractVector, σ::AbstractVector)`
"""
struct StandardizedMatrix{T <: AbstractFloat, S <: AMat} <: AMat{T}
	data::S
	μ::VecF			# column means
	σinv::VecF		# inverse of column stdevs
end
function StandardizedMatrix(x::AMat, μ::AVec, σ::AVec)
	T = eltype((x[1] - μ[1]) / σ[1])
	n, p = size(x)
	μp = length(μ)
	σp = length(σ)
	@assert p == μp "size(x, 2) == $p doesn't match length(μ) == $μp"
	@assert p == σp "size(x, 2) == $p doesn't match length(σ) == $σp"
	StandardizedMatrix{T, typeof(x)}(x, μ, one(eltype(σ)) ./ σ)
end
StandardizedMatrix(x::AMat) = StandardizedMatrix(x, vec(mean(x, dims=1)), vec(std(x, dims=1)))

Base.size(o::StandardizedMatrix) 				= size(o.data)
Base.IndexStyle(o::StandardizedMatrix)		= IndexStyle(o.data)
function Base.getindex(o::StandardizedMatrix, i::Int, j::Int)
	v = getindex(o.data, i, j)
	return (v - o.μ[j]) * o.σinv[j]
end
function Base.getindex(o::StandardizedMatrix, i::Int)
	v = getindex(o.data, i)
	j = ceil(Int, i / size(o, 1))
	return (v - o.μ[j]) * o.σinv[j]
end
function Base.:*(A::StandardizedMatrix, B::AVec{T}) where T <: Real
	y = zeros(typeof(A[1] * B[1]), size(A, 1))
	mul!(y, A, B)
	y
end
function Base.:*(A::StandardizedMatrix, B::AMat{T}) where T <: Real
	y = zeros(typeof(A[1] * B[1]), size(A, 1), size(B, 2))
	mul!(y, A, B)
	y
end

#------------------------------------------------------# Matrix-Vector multiplication
function mul!(y::AVec, A::StandardizedMatrix, b::AVec)
	mul!(y, A.data, Diagonal(A.σinv) * b)
	center!(y)
end
function mul!(y::AVec, A::Adjoint{T}, b::AVec) where {T<:StandardizedMatrix}
	mul!(y, A.data', b - mean(b))
	_scale!(y, A.σinv)
end

#------------------------------------------------------# Matrix-Matrix multiplication
function mul!(y::AMat, A::StandardizedMatrix, b::AMat)
	mul!(y, A.data, Diagonal(A.σinv) * b)
	center!(y)
end
function mul!(y::AMat, A::Adjoint{T}, b::AMat) where {T<:StandardizedMatrix}
	mul!(y, A.data', b .- mean(b, 1))
	_scale!(y, A.σinv)
end

#---------------------------------------------------------------------------# helpers
function center!(v::Vector)
	μ = mean(v)
	for i in eachindex(v)
		@inbounds v[i] -= μ
	end
	v
end
function center!(m::Matrix)
	μ = mean(m, dims=1)
	@inbounds for j in 1:size(m, 2)
		μj = μ[j]
		for i in 1:size(m, 1)
			m[i, j] -= μj
		end
	end
	m
end
function _scale!(a::Vector, b::Vector)
	for i in eachindex(a)
		@inbounds a[i] *= b[i]
	end
	a
end
function _scale!(a::Matrix, b::Vector)
	for j in 1:size(a, 2)
		for i in 1:size(a, 1)
			a[i, j] *= b[i]
		end
	end
	a
end

end #module
