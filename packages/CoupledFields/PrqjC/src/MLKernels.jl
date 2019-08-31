
#==========================================================================
 Some functions from Julia package MLKernels.jl (v0.1), that I've borrowed and modified.
 See https://github.com/trthatcher/MLKernels.jl/blob/master/LICENSE.md:
"The MIT License (MIT)
Copyright (c) 2015 Tim Thatcher
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
==========================================================================#

export Kernel
export kernelmatrix, SquaredDistanceKernel, PolynomialKernel, LinearKernel
export GaussianKernel

abstract type Kernel{T} end
abstract type StandardKernel{T<:AbstractFloat} <: Kernel{T} end
abstract type BaseKernel{T<:AbstractFloat} <: StandardKernel{T} end
abstract type CompositeKernel{T<:AbstractFloat} <: StandardKernel{T} end


#==========================================================================
  Additive Kernel: k(x,y) = sum(k(x_i,y_i))    x ∈ ℝⁿ, y ∈ ℝⁿ
  Separable Kernel: k(x,y) = k(x)k(y)    x ∈ ℝ, y ∈ ℝ
==========================================================================#

abstract type AdditiveKernel{T<:AbstractFloat} <: BaseKernel{T} end
abstract type SeparableKernel{T<:AbstractFloat} <: AdditiveKernel{T} end

phi(κ::SeparableKernel{T}, x::T, y::T) where {T<:AbstractFloat} = phi(κ,x) * phi(κ,y)
isnonnegative(κ::Kernel) = kernelrange(κ) == :Rp


#==========================================================================
  Squared Distance Kernel
  k(x,y) = (x-y)²ᵗ    x ∈ ℝ, y ∈ ℝ, t ∈ (0,1]
==========================================================================#

struct SquaredDistanceKernel{T<:AbstractFloat,CASE} <: AdditiveKernel{T} 
    t::T
    function (::Type{SquaredDistanceKernel{T,CASE}})(t::T) where {T,CASE}
        0 < t <= 1 || error("Parameter t = $(t) must be in range (0,1]")
        new{T,CASE}(t)
    end
end

function SquaredDistanceKernel(t::T = 1.0) where {T<:AbstractFloat}
    CASE =  if t == 1
                :t1
            elseif t == 0.5
                :t0p5
            else
                :∅
            end
    SquaredDistanceKernel{T,CASE}(t)
end

isnegdef(::SquaredDistanceKernel) = true
kernelrange(::SquaredDistanceKernel) = :Rp

phi(κ::SquaredDistanceKernel{T,:t1}, x::Vector{T}, y::Vector{T}) where {T<:AbstractFloat} = sum(abs2, x-y)
phi(κ::SquaredDistanceKernel{T,:t0p5}, x::Vector{T}, y::Vector{T}) where {T<:AbstractFloat} = sum(abs, x-y)
phi(κ::SquaredDistanceKernel{T}, x::Vector{T}, y::Vector{T}) where {T<:AbstractFloat} = sum(abs2, x-y)^κ.t


#==========================================================================
  Scalar Product Kernel
  (Code preserved for future reasons)
==========================================================================#

struct ScalarProductKernel{T<:AbstractFloat} <: SeparableKernel{T} end
ScalarProductKernel() = ScalarProductKernel{Float64}()

ismercer(::ScalarProductKernel) = true

convert(::Type{ScalarProductKernel{T}}, κ::ScalarProductKernel) where {T<:AbstractFloat} = ScalarProductKernel{T}()

phi(κ::ScalarProductKernel{T}, x::T) where {T<:AbstractFloat} = x

convert(::Type{Kernel{T}}, κ::ScalarProductKernel) where {T<:AbstractFloat} = convert(ScalarProductKernel{T}, κ)


#==========================================================================
  Polynomial Kernel
==========================================================================#

struct PolynomialKernel{T<:AbstractFloat,CASE} <: CompositeKernel{T}
    k::BaseKernel{T}
    alpha::T
    c::T
    d::T
    function (::Type{PolynomialKernel{T,CASE}})(κ::BaseKernel{T}, α::T, c::T, d::T) where {T,CASE}
        ismercer(κ) == true || error("Composed kernel must be a Mercer kernel.")
        α > 0 || error("α = $(α) must be greater than zero.")
        c >= 0 || error("c = $(c) must be non-negative.")
        (d > 0 && trunc(d) == d) || error("d = $(d) must be an integer greater than zero.")
        if CASE == :d1 && d != 1
            error("Special case d = 1 flagged but d = $(convert(Int64,d))")
        end
        new{T,CASE}(κ, α, c, d)
    end
end

PolynomialKernel(κ::BaseKernel{T}, α::T = one(T), c::T = one(T), d::T = convert(T, 2)) where {T<:AbstractFloat} = PolynomialKernel{T, d == 1 ? :d1 : :Ø}(κ, α, c, d)
PolynomialKernel(α::T = 1.0, c::T = one(T), d::T = convert(T, 2)) where {T<:AbstractFloat} = PolynomialKernel(convert(Kernel{T},ScalarProductKernel()), α, c, d)
LinearKernel(α::T = 1.0, c::T = one(T)) where {T<:AbstractFloat} = PolynomialKernel(ScalarProductKernel(), α, c, one(T))

phi(κ::PolynomialKernel{T}, x::Vector{T}, y::Vector{T}) where {T<:AbstractFloat} = (κ.alpha*dot(x,y) + κ.c)^κ.d
phi(κ::PolynomialKernel{T,:d1}, x::Vector{T}, y::Vector{T}) where {T<:AbstractFloat} = κ.alpha*dot(x,y) + κ.c


#==========================================================================
  Exponential Kernel
==========================================================================#

struct ExponentialKernel{T<:AbstractFloat,CASE} <: CompositeKernel{T}
    k::BaseKernel{T}
    alpha::T
    gamma::T
    function (::Type{ExponentialKernel{T,CASE}})(κ::BaseKernel{T}, α::T, γ::T) where {T,CASE}
        isnegdef(κ) == true || error("Composed kernel must be negative definite.")
        isnonnegative(κ) || error("Composed kernel must attain only non-negative values.")
        α > 0 || error("α = $(α) must be greater than zero.")
        0 < γ <= 1 || error("γ = $(γ) must be in the interval (0,1].")
        if CASE == :γ1 &&  γ != 1
            error("Special case γ = 1 flagged but γ = $(γ)")
        end
        new{T,CASE}(κ, α, γ)
    end
end
ExponentialKernel(κ::BaseKernel{T}, α::T = one(T), γ::T = one(T)) where {T<:AbstractFloat} = ExponentialKernel{T, γ == 1 ? :γ1 : :Ø}(κ, α, γ)
ExponentialKernel(α::T = 1.0, γ::T = one(T)) where {T<:AbstractFloat} = ExponentialKernel(convert(Kernel{T}, SquaredDistanceKernel()), α, γ)

GaussianKernel(α::T = 1.0) where {T<:AbstractFloat} = ExponentialKernel(SquaredDistanceKernel(one(T)), α)
RadialBasisKernel(α::T = 1.0) where {T<:AbstractFloat} = ExponentialKernel(SquaredDistanceKernel(one(T)),α)
LaplacianKernel(α::T = 1.0) where {T<:AbstractFloat} = ExponentialKernel(SquaredDistanceKernel(one(T)),α, convert(T, 0.5))


function convert(::Type{ExponentialKernel{T}}, κ::ExponentialKernel) where {T<:AbstractFloat}
    ExponentialKernel(convert(Kernel{T}, κ.k), convert(T, κ.alpha), convert(T, κ.gamma))
end

phi(κ::ExponentialKernel{T}, x::Vector{T}, y::Vector{T}) where {T<:AbstractFloat} = exp.(-κ.alpha * sum(abs2, x-y)^κ.gamma)
phi(κ::ExponentialKernel{T,:γ1}, x::Vector{T}, y::Vector{T}) where {T<:AbstractFloat} = exp.(-κ.alpha * sum(abs2, x-y))


#==========================================================================
  Generic Kernel Matrix Functions
==========================================================================#

function init_pairwise(X::Matrix{T}, Y::Matrix{T}, is_trans::Bool) where {T<:AbstractFloat}
    n_dim = is_trans ? 2 : 1
    n = size(X, n_dim)
    m = size(Y, n_dim)
    return Array{T}(undef, n, m)
end


function kernelmatrix(κ::Kernel{T}, X::Matrix{T}, Y::Matrix{T}, is_trans::Bool = false) where {T<:AbstractFloat}
    kernelmatrix!(init_pairwise(X, Y, is_trans), κ, X, Y, is_trans)
end


#==========================================================================
  Base and Composite Kernel Matrix Functions
==========================================================================#

function kernelmatrix!(K::Matrix{T}, κ::BaseKernel{T}, X::Matrix{T}, Y::Matrix{T}, is_trans::Bool) where {T<:AbstractFloat}
    pairwise!(K, κ, X, Y, is_trans)
end

function kernelmatrix!(K::Matrix{T}, κ::CompositeKernel{T}, X::Matrix{T}, Y::Matrix{T}, is_trans::Bool) where {T<:AbstractFloat}
    pairwise!(K, κ, X, Y, is_trans)
end


#===================================================================================================
  Default Pairwise Computation
===================================================================================================#

# Initiate pairwise matrices

function init_pairwise(X::Matrix{T}, is_trans::Bool) where {T<:AbstractFloat}
    n = size(X, is_trans ? 2 : 1)
    Array(T, n, n)
end

# Pairwise definition

function pairwise!(K::Matrix{T}, κ::Kernel{T}, X::Matrix{T}, Y::Matrix{T}, is_trans::Bool) where {T<:AbstractFloat}
    if is_trans
        pairwise_XtYt!(K, κ, X, Y)
    else
        pairwise_XY!(K, κ, X, Y)
    end
end



function pairwise_XY!(K::Matrix{T}, κ::Kernel{T}, X::Matrix{T}, Y::Matrix{T}) where {T<:AbstractFloat}
    (n = size(X,1)) == size(K,1) || throw(DimensionMismatch("Dimension 1 of X must match dimension 1 of K."))
    (m = size(Y,1)) == size(K,2) || throw(DimensionMismatch("Dimension 1 of Y must match dimension 2 of K."))
    size(X,2) == size(Y,2) || throw(DimensionMismatch("Dimension 2 of Y must match dimension 2 of X."))
    for j = 1:m
        y = Y[j,:]
        for i = 1:n
            K[i,j] = phi(κ, X[i,:], y)
        end
    end
    K
end


function pairwise_XtYt!(K::Matrix{T}, κ::Kernel{T}, X::Matrix{T}, Y::Matrix{T}) where {T<:AbstractFloat}
    (n = size(X,2)) == size(K,1) || throw(DimensionMismatch("Dimension 2 of X must match dimension 1 of K."))
    (m = size(Y,2)) == size(K,2) || throw(DimensionMismatch("Dimension 2 of Y must match dimension 2 of K."))
    size(X,1) == size(Y,1) || throw(DimensionMismatch("Dimension 1 of Y must match dimension 1 of X."))
    for j = 1:m
        y = Y[:,j]
        for i = 1:n
            K[i,j] = phi(κ, X[:,i], y)
        end
    end
    K
end




