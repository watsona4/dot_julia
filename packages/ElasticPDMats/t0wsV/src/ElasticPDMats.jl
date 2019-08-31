module ElasticPDMats
import Base: size, getindex, setindex!, append!, show, view, deleteat!
import LinearAlgebra: mul!, ldiv!
using LinearAlgebra, MacroTools
using PDMats
import PDMats: dim, Matrix, diag, pdadd!, *, \, inv, logdet, eigmax, eigmin, whiten!, unwhiten!, quad, quad!, invquad, invquad!, X_A_Xt, Xt_A_X, X_invA_Xt, Xt_invA_X
export ElasticPDMat, AllElasticArray, ElasticSymmetricMatrix, ElasticCholesky, setcapacity!, setstepsize!, setdimension!

mutable struct AllElasticArray{T, N} <: AbstractArray{T, N}
    dims::Tuple{Vararg{Int, N}}
    capacity::Tuple{Vararg{Int, N}}
    stepsize::Tuple{Vararg{Int, N}}
    data::Array{T, N}
end
function AllElasticArray(m::AbstractArray{T, N}; dims = size(m), 
                         capacity = fill(10^2, N), 
                         stepsize = fill(10^2, N)) where {T, N}
    AllElasticArray(dims, Tuple(max.(dims, capacity)), Tuple(max.(dims, stepsize)), m)
end
AllElasticArray(N; capacity = tuple(fill(10^2, N)...), stepsize = tuple(fill(10^2, N)...)) = 
AllElasticArray(zeros(capacity...), dims = tuple(fill(0, N)...), capacity = capacity,
                    stepsize = stepsize)

size(m::AllElasticArray) = m.dims
for i in 2:3
    vars = [Symbol(:i, j) for j in 1:i]
    @eval begin
        getindex(m::AllElasticArray{T, $i}, $(vars...)) where {T} = getindex(m.data, $(vars...))
        setindex!(m::AllElasticArray{T, $i}, v::T, $(vars...)) where {T} = setindex!(m.data,v, $(vars...))
        view(m::AllElasticArray{T, $i}, $(vars...)) where {T} = view(m.data, $(vars...))
        view(m::AllElasticArray{T, $i}) where {T} = view(m, $([:(UnitRange(1, m.dims[$j])) for j in 1:i]...))
        setdimension!(m::AllElasticArray{T, $i}, v::Int, k::Int) where {T} = m.dims = tuple($([:(k == $j ? v : m.dims[$j]) for j in 1:i]...))
    end
end
getindex(m::AllElasticArray{T, N}, i, j, k, l, I...) where {T, N} = getindex(m.data, i, j, k, l, I...)
view(m::AllElasticArray{T, N}) where {T, N} = view(m, (UnitRange.(1, m.dims))...)
setindex!(m::AllElasticArray{T, N}, I::Vararg{Int, N}) where {T, N} = setindex!(m.data, I...)
setdimension!(m::AllElasticArray{T, N}, v::Int, k::Int) where {T, N} = m.dims = tuple([k == j ? v : m.dims[j] for j in 1:N]...)
setdimension!(m::AllElasticArray, v::Int, k::AbstractArray{Int, 1}) = for i in k setdimension!(m, v, i) end
function grow!(obj::AllElasticArray)
    obj.capacity = obj.capacity .+ obj.stepsize
    resize!(obj)
end
resize!(obj::AllElasticArray) = resize!(obj, obj.data)
function resize!(obj::AllElasticArray, data::AbstractArray{T, N}) where {T, N}
    tmp = zeros(T, obj.capacity...)
    ind = CartesianIndices(Tuple(UnitRange.(1, obj.dims)))
    copyto!(tmp, ind, data, ind)
    obj.data = tmp
    obj.capacity
end

mul!(Y::AbstractArray{T, 1}, M::AllElasticArray{T, 2}, V::AbstractArray{T, 1}) where {T} = mul!(Y, view(M), V)
mul!(Y::AbstractArray{T, 2}, M::AllElasticArray{T, 2}, V::AbstractArray{T, 2}) where {T} = mul!(Y, view(M), V)
mul!(Y::AbstractArray{T, 2}, M1::AllElasticArray{T, 2}, M2::AllElasticArray{T, 2}) where {T} = mul!(Y, view(M1), view(M2))

struct ElasticSymmetricMatrix{T} <: AbstractArray{T, 2}
    m::AllElasticArray{T, 2}
end
function ElasticSymmetricMatrix(m::AbstractArray{T, 2}; N = size(m, 1), capacity = 10^3, stepsize = 10^3) where {T}
    !issymmetric(m) && error("Data is not symmetric.")
    data = zeros(T, capacity, capacity)
    ind = CartesianIndices((1:N, 1:N))
    copyto!(data, ind, m, ind)
    ElasticSymmetricMatrix(AllElasticArray((N, N), (capacity, capacity), (stepsize, stepsize), data))
end
ElasticSymmetricMatrix(; capacity = 10^3, stepsize = 10^3) = ElasticSymmetricMatrix(AllElasticArray((0, 0), (capacity, capacity), (stepsize, stepsize), zeros(capacity, capacity)))

# from Lazy.jl
macro forward(ex, fs)
  @capture(ex, T_.field_) || error("Syntax: @forward T.x f, g, h")
  T = esc(T)
  fs = isexpr(fs, :tuple) ? map(esc, fs.args) : [esc(fs)]
  :($([:($f(x::$T, args...) = (Base.@_inline_meta; $f(x.$field, args...)))
       for f in fs]...);
    nothing)
end
@forward ElasticSymmetricMatrix.m size, getindex, setindex!, view, mul!, grow!, resize!, setnewdata!
setdimension!(e::ElasticSymmetricMatrix, N::Int) = setdimension!(e.m, N, 1:2)
function append!(g::ElasticSymmetricMatrix{T}, data::AbstractArray{T, 2}) where {T}
    n, m = size(data)
    oldm = size(g, 1)
    oldm + m > g.m.capacity[1] && grow!(g)
    gd = g.m.data
    @inbounds @simd for j in 1:m
        for i in 1:min(oldm + j, n)
            gd[i, j + oldm] = gd[j + oldm, i] = data[i, j]
        end
    end
    setdimension!(g, oldm + m) 
    g
end
function deleteat!(g::ElasticSymmetricMatrix, i::Int)
    N = size(g, 1)
    gd = g.m.data
    copyto!(gd, CartesianIndices((1:N, i:N - 1)), 
            gd, CartesianIndices((1:N, i+1:N)))
    copyto!(gd, CartesianIndices((i:N-1, 1:N)), 
            gd, CartesianIndices((i+1:N, 1:N)))
    setdimension!(g, N - 1)
    g
end
function setcapacity!(x::ElasticSymmetricMatrix, c::Int)
    x.m.capacity = (c, c)
    resize!(x)
end
setstepsize!(x::ElasticSymmetricMatrix, c::Int) = x.m.stepsize = (c, c)

mutable struct ElasticCholesky{T, A} <: Factorization{T}
    N::Int
    capacity::Int
    stepsize::Int
    c::Cholesky{T, A}
end
function ElasticCholesky(c::Cholesky{T, A}; capacity = 10^3, stepsize = 10^3) where {T, A}
    N = size(c, 1)
    data = zeros(T, capacity, capacity)
    ind = CartesianIndices((1:N, 1:N))
    copyto!(data, ind, c.factors, ind)
    ElasticCholesky(N, capacity, stepsize, Cholesky(data, 'U', LinearAlgebra.BlasInt(0)))
end
ElasticCholesky(; capacity = 10^3, stepsize = 10^3) = ElasticCholesky(0, capacity, stepsize, Cholesky(zeros(capacity, capacity), 'U', LinearAlgebra.BlasInt(0)))


function setcapacity!(x::ElasticCholesky, c::Int)
    x.capacity = c
    resize!(x)
end
setstepsize!(x::ElasticCholesky, c::Int) = x.stepsize = c

view(c::ElasticCholesky, i, j) = Cholesky(view(c.c.factors, i, j), c.c.uplo, c.c.info)
view(c::ElasticCholesky) = view(c, 1:c.N, 1:c.N)
show(io::IO, m::MIME{Symbol("text/plain")}, c::ElasticCholesky) = show(io, m, view(c))
size(c::ElasticCholesky) = (c.N, c.N)
size(c::ElasticCholesky, i::Int) = c.N

ldiv!(c::ElasticCholesky, x) = ldiv!(view(c), x)

function grow!(c::ElasticCholesky)
    c.capacity += c.stepsize
    resize!(c)
end
resize!(c::ElasticCholesky) = resize!(c, c.c.factors)
function resize!(obj::ElasticCholesky, data::AbstractArray{T, N}) where {T, N}
    tmp = zeros(T, obj.capacity, obj.capacity)
    ind = CartesianIndices((1:obj.N, 1:obj.N))
    copyto!(tmp, ind, data, ind)
    obj.c = Cholesky(tmp, 'U', LinearAlgebra.BlasInt(0))
    obj.capacity
end

append!(c::Union{ElasticCholesky{T, A}, ElasticSymmetricMatrix{T}}, data::Vector{T}) where {T, A} = append!(c, reshape(data, :, 1))
function append!(c::ElasticCholesky{T,A}, data::A) where {T, A}
    n, m = size(data)
    c.N + m > c.capacity && grow!(c)
    s = data[1:c.N, 1:m]
    LAPACK.trtrs!('U', 'C', 'N', view(c).factors, s)
    colrange = c.N + 1:c.N + m
    copyto!(c.c.factors, CartesianIndices((1:c.N, colrange)), s, CartesianIndices((1:c.N, 1:m)))
    copyto!(c.c.factors, CartesianIndices((colrange, colrange)), view(data, colrange,1:m), CartesianIndices((1:m, 1:m)))
    BLAS.syrk!('U', 'T', -1., s, 1., view(c.c.factors, colrange, colrange))
    LinearAlgebra._chol!(view(c.c.factors, colrange, colrange), UpperTriangular)
    c.N += m
    c
end
# TODO: Check if this can be optimized.
function deleteat!(c::ElasticCholesky, i::Int)
    R = view(c.c.factors, i, i+1:c.N) * view(c.c.factors, i, i+1:c.N)' 
    R += view(c, i+1:c.N, i+1:c.N).U' * view(c, i+1:c.N, i+1:c.N).U
    cholesky!(Symmetric(R))
    copyto!(c.c.factors, CartesianIndices((1:i-1, i:c.N-1)),
            c.c.factors, CartesianIndices((1:i-1, i+1:c.N)))
    copyto!(c.c.factors, CartesianIndices((i:c.N-1, i:c.N-1)),
            R, CartesianIndices((1:c.N-i, 1:c.N-i)))
    c.N -= 1
    c
end

struct ElasticPDMat{T, A} <: AbstractPDMat{T}
    mat::ElasticSymmetricMatrix{T}
    chol::ElasticCholesky{T, A}
end
"""
    ElasticPDMat([m [, chol]]; capacity = 10^3, stepsize = 10^3)

Creates an elastic positive definite matrix with initial `capacity = 10^3` and 
`stepsize = 10^3`. The optional argument `m` is a positive definite, symmetric 
matrix and `chol` its cholesky decomposition. Use `append!` and `deleteat!` to
change an ElasticPDMat.
"""
ElasticPDMat(; kwargs...) = ElasticPDMat(ElasticSymmetricMatrix(; kwargs...), ElasticCholesky(; kwargs...))
ElasticPDMat(m; kwargs...) = ElasticPDMat(m, cholesky(m); kwargs...)
function ElasticPDMat(m, chol; kwargs...)
    ElasticPDMat(ElasticSymmetricMatrix(m; kwargs...),
                 ElasticCholesky(chol; kwargs...))
end

function setcapacity!(x::ElasticPDMat, c::Int)
    setcapacity!(x.mat, c)
    setcapacity!(x.chol, c)
end
function setstepsize!(x::ElasticPDMat, c::Int)
    setstepsize!(x.mat, c)
    setstepsize!(x.chol, c)
end

function append!(a::ElasticPDMat, data)
    append!(a.mat, data)
    append!(a.chol, data)
    a
end
function deleteat!(a::ElasticPDMat, i::Int)
    deleteat!(a.mat, i)
    deleteat!(a.chol, i)
    a
end
# TODO: more efficient blockwise deletion
function deleteat!(g::Union{ElasticSymmetricMatrix, ElasticCholesky, ElasticPDMat}, idxs::AbstractArray{Int, 1})
    map(i -> deleteat!(g, i), sort(idxs, rev = true))
end

dim(a::ElasticPDMat) = size(a.mat, 1)
Base.Matrix(a::ElasticPDMat) = Matrix(view(a.mat))
LinearAlgebra.diag(a::ElasticPDMat) = diag(view(a.mat))
function pdadd!(r::Matrix, a::Matrix, gb::ElasticPDMat, c::Real)
    b = view(gb.mat)
    PDMats.@check_argdims size(r) == size(a) == size(b)
    # PDMats._addscal!(r, m, view(a.mat), c) doesn't work because _addscal! does
    # not accept views. Below is copy-paste of PDMats
    if c == one(c)
        for i = 1:length(b)
            @inbounds r[i] = a[i] + b[i]
        end
    else
        for i = 1:length(b)
            @inbounds r[i] = a[i] + b[i] * c
        end
    end
    return r
end

*(a::ElasticPDMat, c::Real) = ElasticPDMat(c * Matrix(a), capacity = a.chol.capacity, stepsize = a.chol.stepsize) 
*(a::ElasticPDMat, x::AbstractArray) = a.mat * x 
\(a::ElasticPDMat, x::AbstractArray) = a.chol \ x

inv(a::ElasticPDMat) = ElasticPDMat(inv(a.chol), capacity = a.chol.capacity, stepsize = a.chol.stepsize) 
logdet(a::ElasticPDMat) = logdet(view(a.chol)) 
eigmax(a::ElasticPDMat) = eigmax(view(a.mat))
eigmin(a::ElasticPDMat) = eigmin(view(a.mat))


function whiten!(r::DenseVecOrMat, a::ElasticPDMat, x::DenseVecOrMat)  
    cf = view(a.chol).UL
    v = PDMats._rcopy!(r, x)
    istriu(cf) ? ldiv!(transpose(cf), v) : ldiv!(cf, v)
end

function unwhiten!(r::DenseVecOrMat, a::ElasticPDMat, x::DenseVecOrMat)  
    cf = view(a.chol).UL
    v = PDMats._rcopy!(r, x)
    istriu(cf) ? lmul!(transpose(cf), v) : lmul!(cf, v)
end

quad(a::ElasticPDMat{T, A}, x::AbstractArray{T, 1}) where {T, A} = dot(x, a * x)
quad!(r::AbstractArray, a::ElasticPDMat, x::DenseMatrix) = PDMats.colwise_dot!(r, x, a.mat * x) 
invquad(a::ElasticPDMat{T, A}, x::AbstractArray{T, 1}) where {T, A} = dot(x, a \ x) 
invquad!(r::AbstractArray, a::ElasticPDMat, x::DenseMatrix) = PDMats.colwise_dot!(r, x, a.mat \ x)
                                                 

function X_A_Xt(a::ElasticPDMat, x::DenseMatrix)        
    z = copy(x)
    cf = view(a.chol).UL
    rmul!(z, istriu(cf) ? transpose(cf) : cf)
    z * transpose(z)
end

function Xt_A_X(a::ElasticPDMat, x::DenseMatrix)        
    cf = view(a.chol).UL
    z = lmul!(istriu(cf) ? cf : transpose(cf), copy(x))
    transpose(z) * z
end

function X_invA_Xt(a::ElasticPDMat, x::DenseMatrix)     
    cf = view(a.chol).UL
    z = rdiv!(copy(x), istriu(cf) ? cf : transpose(cf))
    z * transpose(z)
end

function Xt_invA_X(a::ElasticPDMat, x::DenseMatrix)     
    cf = view(a.chol).UL
    z = ldiv!(istriu(cf) ? transpose(cf) : cf, copy(x))
    transpose(z) * z
end
end # module
