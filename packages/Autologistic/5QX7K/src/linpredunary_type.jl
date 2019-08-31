"""
    LinPredUnary

The unary part of an autologistic model, parametrized as a regression linear predictor.
Its fields are `X`, an n-by-p-by-m matrix (n obs, p predictors, m observations), and `β`,
a p-vector of parameters (the same for all observations).

# Constructors
    LinPredUnary(X::Matrix{Float64}, β::Vector{Float64})
    LinPredUnary(X::Matrix{Float64})
    LinPredUnary(X::Array{Float64, 3})
    LinPredUnary(n::Int,p::Int)
    LinPredUnary(n::Int,p::Int,m::Int)

Any quantities not provided in the constructors are initialized to zeros.

# Examples
```jldoctest
julia> u = LinPredUnary(ones(5,3,2), [1.0, 2.0, 3.0]);
julia> u[:,:]
5×2 Array{Float64,2}:
 6.0  6.0
 6.0  6.0
 6.0  6.0
 6.0  6.0
 6.0  6.0
```
"""
struct LinPredUnary <: AbstractUnaryParameter
    X::Array{Float64, 3}
    β::Vector{Float64}

    function LinPredUnary(x, beta) 
        if size(x)[2] != length(beta)
            error("LinPredUnary: X and β dimensions are inconsistent")
        end
        new(x, beta)
    end
end

# Constructors
function LinPredUnary(X::Matrix{Float64}, β::Vector{Float64})
    (n,p) = size(X)
    return LinPredUnary(reshape(X,(n,p,1)), β)
end
function LinPredUnary(X::Matrix{Float64})
    (n,p) = size(X)
    return LinPredUnary(reshape(X,(n,p,1)), zeros(Float64,p))
end
function LinPredUnary(X::Array{Float64, 3})
    (n,p,m) = size(X)
    return LinPredUnary(X, zeros(Float64,p))
end
function LinPredUnary(n::Int,p::Int)
    X = zeros(Float64,n,p,1)
    return LinPredUnary(X, zeros(Float64,p))
end
function LinPredUnary(n::Int,p::Int,m::Int)
    X = zeros(Float64,n,p,m)
    return LinPredUnary(X, zeros(Float64,p))
end

#---- AbstractArray methods ----

size(u::LinPredUnary) = (size(u.X,1), size(u.X,3))

# getindex - implementations

function getindex(u::LinPredUnary, ::Colon, ::Colon)
    n, p, m = size(u.X)
    out = zeros(n,m)
    for r = 1:m
        for i = 1:n
            for j = 1:p
                out[i,r] = out[i,r] + u.X[i,j,r] * u.β[j]
            end
        end
    end
    return out
end

function getindex(u::LinPredUnary, I::AbstractArray)
    out = u[:,:]
    return out[I]
end

getindex(u::LinPredUnary, i::Int, r::Int) = sum(u.X[i,:,r] .* u.β)   

function getindex(u::LinPredUnary, ::Colon, r::Int) 
    n, p, m = size(u.X)
    out = zeros(n)
    for i = 1:n
        for j = 1:p
            out[i] = out[i] + u.X[i,j,r] * u.β[j]
        end
    end
    return out
end

function getindex(u::LinPredUnary, I::AbstractVector, R::AbstractVector)
    out = zeros(length(I),length(R))
    for r in 1:length(R)
        for i in 1:length(I)
            for j = 1:size(u.X,2)
                out[i,r] = out[i,r] + u.X[I[i],j,R[r]] * u.β[j]
            end
        end
    end
    return out
end

# getindex- translations
getindex(u::LinPredUnary, I::Tuple{Integer, Integer}) = u[I[1], I[2]]
getindex(u::LinPredUnary, i::Int, ::Colon) = u[i, 1:size(u.X,3)]
getindex(u::LinPredUnary, I::AbstractRange{<:Integer}, J::AbstractVector{Bool}) = u[I,findall(J)]
getindex(u::LinPredUnary, I::AbstractVector{Bool}, J::AbstractRange{<:Integer}) = u[findall(I),J]
getindex(u::LinPredUnary, I::Integer, J::AbstractVector{Bool}) = u[I,findall(J)]
getindex(u::LinPredUnary, I::AbstractVector{Bool}, J::Integer) = u[findall(I),J]
getindex(u::LinPredUnary, I::AbstractVector{Bool}, J::AbstractVector{Bool}) = u[findall(I),findall(J)]
getindex(u::LinPredUnary, I::AbstractVector{<:Integer}, J::AbstractVector{Bool}) = u[I,findall(J)]
getindex(u::LinPredUnary, I::AbstractVector{Bool}, J::AbstractVector{<:Integer}) = u[findall(I),J]

# setindex!
setindex!(u::LinPredUnary, v::Real, i::Int, j::Int) =
    error("Values of $(typeof(u)) must be set using setparameters!().")


#---- AbstractUnaryParameter interface ----
getparameters(u::LinPredUnary) = u.β
function setparameters!(u::LinPredUnary, newpars::Vector{Float64})
    u.β[:] = newpars
end


#---- to be used in show methods ----
function showfields(u::LinPredUnary, leadspaces=0)
    spc = repeat(" ", leadspaces)
    return spc * "X  $(size2string(u.X)) array (covariates)\n" *
           spc * "β  $(size2string(u.β)) vector (regression coefficients)\n"
end