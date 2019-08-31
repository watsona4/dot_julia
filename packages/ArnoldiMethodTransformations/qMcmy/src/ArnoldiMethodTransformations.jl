"""
    module ArnoldiMethodTransformations

Provides convenience wrapper for interfacing with the package ArnoldiMethod.

Implements the shift-and-invert transformation detailed [here](https://haampie.github.io/ArnoldiMethod.jl/stable/).

The main functions are `partialschur(A,[B],σ; kwargs...)` and `partialeigen(A,[B],σ; kwargs...)`
"""
module ArnoldiMethodTransformations

using Requires

const LUPACK_AUTO = Ref{Symbol}(:umfpack)

function __init__()
    # @require MUMPS3="da04e1cc-30fd-572f-bb4f-1f8673147195" @eval begin
            # using MUMPS3, MPI
            # LUPACK_AUTO[]=:mumps
            # println("mumps here!")
        # end
    @require Pardiso="46dd5b70-b6fb-5a00-ae2d-e8fea33afaf2" @eval begin
            using Pardiso
            LUPACK_AUTO[]=:pardiso
            println("pardiso here!")
        end
end

using ArnoldiMethod,
LinearAlgebra,
LinearMaps,
SparseArrays

abstract type AbstractSolver end
struct PSolver <: AbstractSolver end
struct MSolver <: AbstractSolver end
struct USolver <: AbstractSolver end

"""
    struct ShiftAndInvert{M,T,U,V,Σ}

Container for arrays in `ArnoldiMethod.partialschur`

-------------

    function ShiftAndInvert(A, [B], σ; diag_inv_B=isdiag(B), lupack=:auto) -> si

create a LinearMap object to feed to ArnoldiMethod.partialschur which transforms `Ax=λBx` into `(A-σB)⁻¹Bx=x/(λ-σ)`.

Set `diag_inv_B=true` if `B` is both diagonal and invertible, so that it is easy to compute `B⁻¹`. In this case instead return a linear map `(B⁻¹A-σI)⁻¹`, which has same evals as above.

`A` and `B` must both be sparse or both dense. `A`, `B`, `σ` need not have common element type.

Keyword `lupack` determines what linear algebra library to use. Options are `:pardiso`, `:mumps`, `:umfpack`,
and the default `:auto`, which chooses based on availability at the top level, in this order:
PARDISO > MUMPS > UMFPACK. For example, if at the top level there is `using ArnoldiMethod, ArnoldiMethodTransformations`,
will default to UMFPACK, while the additional `using MUMPS3` will default to `:mumps`, and so on.

----------

    function ::ShiftAndInvert(y,x)

`A\\B*x = y`, where `A=ShiftAndInvert.A_lu` (factorized), `B=ShiftAndInvert.B`, and `x=ShiftAndInvert.x`
"""
struct ShiftAndInvert{M,T,U,V,Σ}
    A_lu::T
    B::U
    temp::V
    temp2::V
    σ::Σ
    issymmetric::Bool

    function ShiftAndInvert(A::S, B::T, σ::Number; diag_inv_B::Bool, lupack::Symbol=:auto) where {S,T}
        lupack==:auto ? lupack=LUPACK_AUTO[] : nothing
        onetype = one(eltype(S))*one(eltype(T))*one(σ)
        type = typeof(onetype)
        A, B = onetype*A, onetype*B
        @assert supertype(typeof(A))==supertype(typeof(B)) "typeof(A)=$(typeof(A)), typeof(B)=$(typeof(B)). Either both sparse or both dense"
        if diag_inv_B
            if T<:AbstractSparseArray
                α = spdiagm(0=>map(x->1/x,diag(B)))*A-σ*I
                matrix_fun = sparse
            else
                α = Diagonal(map(x->1/x,diag(B)))*A-σ*I
                matrix_fun = Matrix
            end
            β = matrix_fun(onetype*I,size(B))
        else
            α = A-σ*B
            β = onetype*B
        end
        temp = Vector{type}(undef,size(α,1))
        temp2 = Vector{type}(undef,size(α,1))
        issym = issymmetric(α)*issymmetric(β)

        # initialize according to package used
        M, A_lu = initialize_according_to_package(lupack,issym,type,α,temp,temp2)

        return new{M,typeof(A_lu),typeof(β),typeof(temp),typeof(σ)}(A_lu,β,temp,temp2,σ,issym)
    end
    function ShiftAndInvert(A::S, σ::Number; kwargs...) where S
        onetype = one(eltype(S))*one(σ)
        if S<:AbstractSparseArray
            return ShiftAndInvert(A, sparse(onetype*I,size(A)...), σ; diag_inv_B=true, kwargs...)
        else
            return ShiftAndInvert(A, Matrix(onetype*I,size(A)...), σ; diag_inv_B=true, kwargs...)
        end
    end
end

# define action of ShiftAndInvert
function (SI::ShiftAndInvert{M})(y,x) where M<:AbstractSolver
    mul!(SI.temp, SI.B, x)
    if M<:PSolver
        pardiso(SI.A_lu,SI.temp2,spzeros(eltype(SI.B),size(SI.B)...),SI.temp)
        for i ∈ eachindex(y)
            y[i] = SI.temp2[i]
        end
    else
        ldiv!(y, SI.A_lu, SI.temp)
    end
    return nothing
end

function initialize_according_to_package(lupack,issym,type,α,temp1,temp2)
    if lupack ∈ [:Pardiso,:pardiso,:PARDISO,:p]
        M = PSolver
        try PardisoSolver catch; throw(ErrorException("Pardiso not loaded. Try again after `using Pardiso`")) end
        A_lu = PardisoSolver()
        if issym & (type<:Real)
            set_matrixtype!(A_lu,Pardiso.REAL_SYM)
        elseif issym & (type<:Complex)
            set_matrixtype!(A_lu,Pardiso.COMPLEX_SYM)
        elseif !issym & (type<:Real)
            set_matrixtype!(A_lu,Pardiso.REAL_NONSYM)
        else # if !issym & type<:Complex
            set_matrixtype!(A_lu,Pardiso.COMPLEX_NONSYM)
        end
        set_iparm!(A_lu,1,1) # don't revert to defaults
        set_phase!(A_lu,12) # analyze and factorize
        pardiso(A_lu,temp2,sparse(α),temp1)
        set_iparm!(A_lu,12,1) # transpose b/c of CSR vs SCS
        set_phase!(A_lu,33) # set to solve for future calls
    elseif lupack ∈ [:MUMPS,:Mumps,:mumps,:m]
        M = MSolver
        try MPI catch; throw(ErrorException("MUMPS3 not loaded. Try again after `using MUMPS3`")) end
        MPI.Initialized() ? nothing : MPI.Init()
        A_lu = mumps_factorize(α)
    elseif lupack ∈ [:UMFPACK,:Umfpack,:umfpack,:u]
        M = USolver
        A_lu = lu(α)
    else
        throw("unrecognized lupack $lupack, must be one of :Pardiso, :MUMPS, :UMFPACK")
    end
    return M, A_lu
end



"""
    partialschur(A, [B], σ; [diag_inv_B, lupack=:auto, kwargs...]) -> decomp, history

Partial Schur decomposition of `A`, with shift `σ` and mass matrix `B`, solving `A*v=σB*v`

Keyword `diag_inv_B` defaults to `true` if `B` is both diagonal and invertible. This enables
a simplified shift-and-invert scheme.

Keyword `lupack` determines what linear algebra library to use. Options are `:pardiso`, `:mumps`, `:umfpack`,
and the default `:auto`, which chooses based on availability at the top level, in this order:
PARDISO > MUMPS > UMFPACK. For example, if at the top level there is `using ArnoldiMethod, ArnoldiMethodTransformations`,
will default to UMFPACK, while the additional `using MUMPS3` will default to `:mumps`, and so on.

For other keywords, see ArnoldiMethod.partialschur

see also: [`partialeigen`](@ref) in ArnoldiMethod
"""
function ArnoldiMethod.partialschur(si::ShiftAndInvert; kwargs...)
    a = LinearMap{eltype(si.B)}(si, size(si.B,1); ismutating=true, issymmetric=si.issymmetric)
    return partialschur(a; kwargs...)
end
function ArnoldiMethod.partialschur(A, σ::Number; lupack::Symbol=:auto, kwargs...)
    return partialschur(ShiftAndInvert(A, σ; lupack=lupack); kwargs...)
end
function ArnoldiMethod.partialschur(A, B, σ::Number; diag_inv_B::Bool=isdiag(B)&&!any(iszero.(diag(B))), lupack=:auto, kwargs...)
    return partialschur(ShiftAndInvert(A, B, σ; diag_inv_B=diag_inv_B, lupack=lupack); kwargs...)
end


"""
    partialeigen(decomp, σ)

Transforms a partial Schur decomposition into an eigendecomposition, but undoes the
shift-and-invert of the eigenvalues by σ.
"""
function ArnoldiMethod.partialeigen(decomp::ArnoldiMethod.PartialSchur, σ::Number)
    λ, v = partialeigen(decomp)
    return σ.+1 ./λ, v
end
"""
    partialeigen(A, [B], σ; [diag_inv_B, untransform=true, lupack=:auto, kwargs...]) -> λ::Vector, v::Matrix, history

Partial eigendecomposition of `A`, with mass matrix `B` and shift `σ` , solving `A*v=λB*v` for the eigenvalues closest to `σ`

If keyword `untransform=true`, the shift-invert transformation of the eigenvalues is inverted before returning

Keyword `diag_inv_B` defaults to `true` if `B` is both diagonal and invertible. This enables
a simplified shift-and-invert scheme.

Keyword `lupack` determines what linear algebra library to use. Options are `:pardiso`, `:mumps`, `:umfpack`,
and the default `:auto`, which chooses based on availability at the top level, in this order:
PARDISO > MUMPS > UMFPACK. For example, if at the top level there is `using ArnoldiMethod, ArnoldiMethodTransformations`,
will default to UMFPACK, while the additional `using MUMPS3` will default to `:mumps`, and so on.

For other keywords, see ArnoldiMethod.partialschur

see also: [`partialschur`](@ref), [`partialeigen`](@ref) in ArnoldiMethod
"""
function ArnoldiMethod.partialeigen(si::ShiftAndInvert; kwargs...)
    decomp, history = partialschur(si; kwargs...)
    λ, v = partialeigen(decomp)
    get(kwargs,:untransform,true) ? λ = si.σ .+ 1 ./λ : nothing
    return λ, v, history
end
function ArnoldiMethod.partialeigen(A::AbstractArray, σ::Number; lupack::Symbol=:auto, kwargs...)
    return partialeigen(ShiftAndInvert(A, σ; lupack=lupack); kwargs...)
end
function ArnoldiMethod.partialeigen(A::AbstractArray, B::AbstractArray, σ::Number; diag_inv_B::Bool=isdiag(B)&&!any(iszero.(diag(B))), lupack::Symbol=:auto, kwargs...)
    return partialeigen(ShiftAndInvert(A, B, σ; diag_inv_B=diag_inv_B, lupack=lupack); kwargs...)
end


end # module ArnoldiMethodArnoldiMethodTransformations
