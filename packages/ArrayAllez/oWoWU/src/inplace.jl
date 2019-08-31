
#========== exp! log! inv! ==========#

export exp0, exp_, exp!, exp!!
export log0, log_, log!, log!!
export inv0, inv_, inv!, inv!!

"""
    exp!(A)
    exp_(A) = exp!(similar(A), A)
    exp0(A) ≈ exp.(A)

Element-wise in-place exponential, and friends.
Multi-threaded when `length(A) >= 100`.
Will be handled by `Yeppp` or `AppleAccelerate` if you load one of them,
note that `Yeppp` may well be slower.
"""
function exp! end

exp0(A) = similar(A) .= exp.(A) # maps Adjoint -> Adjoint etc

@doc @doc(exp!)
exp_(A) = exp!(similar(A), A)
exp!(A) = exp!(A, A)
exp!!(A) = exp!(A) # differs in gradient

function exp!(B, A)
    @assert size(A)==size(B)
    if length(A) < 100
        B .= exp.(A)
    else
        Threads.@threads for I in eachindex(A)
            @inbounds B[I] = exp1(A[I])
        end
    end
    B
end

"""
    log!(A)
    log_(A) ≈ log!(similar(A), A)
    log0(A) = log.(A)

Element-wise in-place natural logarithm, and friends.
Multi-threaded when `length(A) >= 100`.
Will be handled by `Yeppp` or `AppleAccelerate` if you load one of them.
"""
function log! end

log0(A) = similar(A) .= log.(A)

@doc @doc(log!)
log_(A) = log!(similar(A), A)
log!(A) = log!(A, A)
log!!(A) = log!(A) # differs in gradient

function log!(B, A)
    @assert size(A)==size(B)
    if length(A) < 100
        B .= log.(A)
    else
        Threads.@threads for I in eachindex(A)
            @inbounds B[I] = log1(A[I])
        end
    end
    B
end

# These are a little faster than Julia's built-in functions?
exp1(x::Float64) = ccall(:exp, Cdouble, (Cdouble,), x)
exp1(x) = exp(x)
log1(x::Float64) = ccall(:log, Cdouble, (Cdouble,), x)
log1(x) = log(x)

# Versions which use cache
exp_(name::Symbol, A) = exp!(similar_(name, A), A)
log_(name::Symbol, A) = log!(similar_(name, A), A)

"""
    inv!(A) ≈ 1 ./ A
    inv!(A, b::Number) ≈ b ./ A

And `inv_(A)` which copies, and `inv0(A)` simple broadcasting.
Multi-threaded when `length(A) >= 1000`.
Will be handled by `AppleAccelerate` if you load it.
"""
function inv! end

inv0(A::AbstractArray, b::Number=1) = similar(A) .= b ./ A # maps Adjoint -> Adjoint etc

@doc @doc(inv!)
inv_(A::AbstractArray, b::Number=1) = inv!(similar(A), A, b)
inv_(a::Number) = 1/a # for iscale_

inv!(A::AbstractArray, b::Number=1) = inv!(A, A, 1)
inv!(a::Number) = 1/a
function inv!(C::AbstractArray, A::AbstractArray, b::Number=1)
    @assert size(A)==size(C)
    if length(A) < 1000
        C .= b ./ A
    else
        Threads.@threads for I in eachindex(A)
            @inbounds C[I] = b / A[I]
        end
    end
    C
end

inv_(name::Symbol, A::AbstractArray, b::Number=1) = inv!(similar_(name, A), A, b)
inv_(name::Symbol, a::Number=1) = 1/a # for iscale_


#========== scale! iscale! ==========#

export scale0, scale_, scale!, scale!!
export iscale0, iscale_, iscale!, iscale!!

using LinearAlgebra: Adjoint, Transpose

const ARVector = Union{Adjoint{<:Any, <:AbstractVector}, Transpose{<:Any, <:AbstractVector}}
const RVector = Union{Adjoint{<:Any, <:Vector}, Transpose{<:Any, <:Vector}}


"""
    scale!(A, b::Number) ≈ A .* b
    scale!(M, v::Vector) ≈ A .* v       # M::Matrix
    scale!(M, r::Adjoint) ≈ A .* r      # r::RowVector / Transpose etc.
    scale!(A, B) ≈ A .* B               # A,B same ndims

In-place scaling by a constant or (in the case of a matrix) by a row- or column-vector.
For each of these, there is also also `scale_(A, ...)` non-mutating but perhaps accellerated,
and `scale0(A, ...)` simple broadcasting.
"""
function scale! end

using LinearAlgebra

scale0(A::AbstractArray, b) = similar(A) .= A .* b

scale_(A::Array, b::Number) = rmul!(copy(A), b)
scale!(A::Array, b::Number) = rmul!(A, b)
scale!!(A::Array, b) = scale!(A,b) # differs in gradient

scale_(A::RVector, b::Number) = rmul!(copy(A), b) # scale_(::Abstract...) causes flux ambiguities
scale!(A::RVector, b::Number) = rmul!(A, b)
scale!!(A::RVector, b) = scale!(A,b)

@doc @doc(scale!)
scale_(A::Matrix, v::Vector) = lmul!(Diagonal(v), copy(A))
scale!(A::Matrix, v::Vector) = lmul!(Diagonal(v), A)

scale_(A::Matrix, r::RVector) = rmul!(copy(A), Diagonal(transpose(r)))
scale!(A::Matrix, r::RVector) = rmul!(A, Diagonal(transpose(r)))

# scale_(A::AbstractArray{T,N}, B::AbstractArray{T,N}) where {T,N} = similar(A) .= A .* B
# scale!(A::AbstractArray{T,N}, B::AbstractArray{T,N}) where {T,N} = A .= A .* B

function scale!(C::AbstractArray{T,N}, A::AbstractArray{TA,N}, B::AbstractArray{TB,N}) where {T,N, TA, TB}
    @assert size(A) == size(B) == size(C)
    for i in eachindex(A)
        @inbounds C[i] = A[i] * B[i]
    end
    C
end
scale_(A::AbstractArray{T,N}, B::AbstractArray{T,N}) where {T,N} = scale!(similar(A), A, B)
scale!(A::AbstractArray{T,N}, B::AbstractArray{T,N}) where {T,N} = scale!(A, A, B)


scale_(name::Symbol, A::Array, b::Number) = rmul!(copy_(name, A), b)
scale_(name::Symbol, A::Matrix, v::Vector) = lmul!(Diagonal(v), copy_(name, A))
scale_(name::Symbol, A::Matrix, r::RVector) = rmul!(copy_(name, A), Diagonal(transpose(r)))
scale_(name::Symbol, A::AbstractArray{T,N}, B::AbstractArray{T,N}) where {T,N} =
    scale!(similar_(name, A), A, B)


"""
    iscale!(A, b::Number) ≈ A ./ b
    iscale!(A, v::Vector) ≈ A ./ v      # A::Matrix
    iscale!(A, r::Adjoint) ≈ A ./ r     # r::RowVector / Transpose etc.
    iscale!(A, B) ≈ A ./ B

For each of these, there is also `iscale_(A, ...)` non-mutating but perhaps accellerated,
and `iscale0(A, ...)` simple broadcasting.
Finally there is `iscale!!(A, x)` which mutate both arguments, wihch may be a terrible idea.
"""
function iscale! end

iscale0(A::AbstractArray, b) = similar(A) .= A ./ b

@doc @doc(iscale!)
iscale_(A::AbstractArray, b) = scale_(A, inv_(b))
iscale!(A::AbstractArray, b) = scale!(A, inv_(b))
iscale!!(A::AbstractArray, b) = scale!(A, inv!(b))

function iscale!(C::Array{T,N}, A::Array{TA,N}, B::Array{TB,N}) where {T,N, TA, TB}
    @assert size(A) == size(B) == size(C)
    for i in eachindex(A)
        @inbounds C[i] = A[i] / B[i]
    end
    C
end
iscale_(A::Array{T,N}, B::Array{T,N}) where {T,N} = iscale!(similar(A), A, B)
iscale!(A::Array{T,N}, B::Array{T,N}) where {T,N} = iscale!(A, A, B)

# On square matrices this is a tie, but on (n,N) ./ N' it is faster
# The equivalent for iscale(Matrix, Vector) however is slower, wrong order
function iscale!(C::Matrix, A::Matrix, r::RVector)
    @assert size(A)==size(C)
    axes(A,2) == axes(r,2) || throw(DimensionMismatch("size disagreement in iscale?(Matrix,RowVector)"))
    @inbounds for j in axes(A,2)
        invr = inv(r[j])
        for i in axes(A,1)
            C[i,j] = A[i,j] * invr
        end
    end
    C
end
iscale_(A::Matrix, r::RVector) = iscale!(similar(A), A, r)
iscale!(A::Matrix, r::RVector) = iscale!(A, A, r)

iscale_(name::Symbol, A::AbstractArray, b) = scale_(name, A, inv_(name, b))
iscale_(name::Symbol, A::Matrix, r::RVector) = iscale!(similar_(name, A), A, r)
iscale_(name::Symbol, A::Array{T,N}, B::Array{T,N}) where {T,N} =
    iscale!(similar_(name, A), A, B)

#========== sum_ ==========#

export sum_

sum_(A::AbstractArray) = sum(A) # differs only in backward pass

#========== Accelerators ==========#

const CFloat = Union{Float64, Float32}
const CFloatArray{N} = Array{<:CFloat, N}
const CFloatMatrix = Matrix{<:CFloat}

IVERBOSE = false

VEC = ""
function load_note(str)
    global VEC
    if VEC == ""
        @info "ArrayAllez loaded code for $str"
        VEC = str
    else
        @warn "ArrayAllez loaded code for $str, perhaps overwriting $VEC"
        VEC *= " then $str"
    end
end

using Requires

@init @require Yeppp = "6310b701-1812-5374-a82f-9f6f2d54a40a" begin
    using .Yeppp

    exp!(B::CFloatArray, A::CFloatArray) = Yeppp.exp!(B, A)

    log!(B::CFloatArray, A::CFloatArray) = Yeppp.log!(B, A) # log_(A) calls log!(B,A)

    scale_(A::Array{T,N}, B::Array{T,N}) where {T<:CFloat,N} = Yeppp.multiply(A,B)
    scale!(A::Array{T,N}, B::Array{T,N}) where {T<:CFloat,N} = Yeppp.multiply!(A,A,B)

    IVERBOSE && load_note("Yeppp")
end

@init @require AppleAccelerate = "13e28ba4-7ad8-5781-acae-3021b1ed3924" begin
    using .AppleAccelerate

    exp!(B::CFloatArray, A::CFloatArray) = AppleAccelerate.exp!(B, A)

    log!(B::CFloatArray, A::CFloatArray) = AppleAccelerate.log!(B, A)

    inv!(A::CFloatArray) = AppleAccelerate.rec!(A, A)

    scale_(A::Vector{T}, B::Vector{T}) where {T<:CFloat} = AppleAccelerate.vmul(A,B)
    scale!(A::Vector{T}, B::Vector{T}) where {T<:CFloat} = AppleAccelerate.vmul!(A,A,B)

    scale_(A::Array{T,N}, B::Array{T,N}) where {T<:CFloat,N} =
        reshape(AppleAccelerate.vmul(vec(A),vec(B)), size(A))  # vmul is literally only vectors
    scale!(A::Array{T,N}, B::Array{T,N}) where {T<:CFloat,N} =
        begin AppleAccelerate.vmul!(vec(A),vec(A),vec(B)); A end

    iscale_(A::Vector{T}, B::Vector{T}) where {T<:CFloat} = AppleAccelerate.vdiv(A,B)
    iscale!(A::Vector{T}, B::Vector{T}) where {T<:CFloat} = AppleAccelerate.vdiv!(A,A,B)

    iscale_(A::Array{T,N}, B::Array{T,N}) where {T<:CFloat,N} =
        reshape(AppleAccelerate.vdiv(vec(A),vec(B)), size(A))
    iscale!(A::Array{T,N}, B::Array{T,N}) where {T<:CFloat,N} =
        begin AppleAccelerate.vdiv!(vec(A),vec(A),vec(B)); A end

    IVERBOSE && load_note("AppleAccelerate")
end

#========== The End ==========#
