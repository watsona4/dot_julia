import Base.Broadcast: BroadcastStyle, AbstractArrayStyle, DefaultArrayStyle, Broadcasted

struct NamedArrayStyle{Style <: BroadcastStyle} <: AbstractArrayStyle{Any} end
NamedArrayStyle(::S) where {S} = NamedArrayStyle{S}()
NamedArrayStyle(::S, ::Val{N}) where {S, N} = NamedArrayStyle(S(Val(N)))
NamedArrayStyle(::Val{N}) where {N} = NamedArrayStyle{DefaultArrayStyle{N}}()
NamedArrayStyle(::Broadcast.Unknown) = Broadcast.Unknown()

# promotion rules

function BroadcastStyle(::Type{<:ANA{T, N, Td}}) where {T, N, Td}
    NamedArrayStyle(BroadcastStyle(Td))
end

function BroadcastStyle(::NamedArrayStyle{A}, ::NamedArrayStyle{B}) where {A, B}
    NamedArrayStyle(BroadcastStyle(A(), B()))
end

# Define these with DefaultArrayStyle for disambiguation.
function BroadcastStyle(::NamedArrayStyle{A}, ::B) where {A, B <: DefaultArrayStyle}
    NamedArrayStyle(BroadcastStyle(A(), B()))
end

function BroadcastStyle(::A, ::NamedArrayStyle{B}) where {A <: DefaultArrayStyle, B}
    NamedArrayStyle(BroadcastStyle(A(), B()))
end

# Note: If these want to get called there will be an ambiguity error with Base. But they're here temporarily
# to help us figure out what more specific methods we want to add in practice.
function BroadcastStyle(::NamedArrayStyle{A}, ::B) where {A, B <: AbstractArrayStyle}
    NamedArrayStyle(BroadcastStyle(A(), B()))
end

function BroadcastStyle(::A, ::NamedArrayStyle{B}) where {A <: AbstractArrayStyle, B}
    NamedArrayStyle(BroadcastStyle(A(), B()))
end

#=
design space
    only named arrays
        same axes
            same order
            different order
    named arrays and scalars
    multiplication vs not
=#
@inline function Base.copy(bc::Broadcasted{NamedArrayStyle{Style}}) where Style

    error("Broadcast is currently undergoing renovations. Supporting it will take a lot of care in implementation.")

    # Gather a tuple of all named arrays in this broadcast expression
    As = allnamed(bc)
    A = first(As)

    # Ensure that all named arrays are of equal dimension.
    @argcheck(all(==(ndims(A)), ndims.(As)), "Dimensions of all named arrays must be equal.")

    # Use isequal to correctly handle names that are `missing`.
    noms = names(A)
    @argcheck(
        all(isequal(noms, names(As[i])) for i in 2:length(As)),
        "All names must match to broadcast across multiple named arrays."
    )

    # Ensure that names match along all dimensions of all named arrays.
    @argcheck(
        all(arg isa ANA || size(arg) == () for arg in allargs(bc)),
        "Broadcasting is only supported between associative arrays and scalars. Argument types: $(typeof.(allargs(bc)))"
    )

    @argcheck(
        all(op == (*) for op in allops(bc)),
        "Broadcasting is currently only supported for multiplication."
    )

    # Compute the broadcast result on unwrapped arrays,
    value = copy(unwrap(bc, nothing))

    # Then re-wrap the result in a named array of the appropriate type.
    unparameterized(A)(value, noms)
end

# Our `copy` was based on:
# https://githucom/JuliaDiffEq/RecursiveArrayTools.jl/blob/e666b741ed713e32494de9f164fec13fc15f8391/src/array_partition.jl#L235
# Note: `copyto!` should look essentially the same as above:
# https://githucom/JuliaDiffEq/RecursiveArrayTools.jl/blob/e666b741ed713e32494de9f164fec13fc15f8391/src/array_partition.jl#L243

# Return a tuple of all named arrays
allnamed(bc::Broadcasted) = allnamed(bc.args)
# ::Tuple -> search it
@inline allnamed(args::Tuple) = (allnamed(args[1])..., allnamed(tail(args))...)
# ::ANA -> keep it
allnamed(a::ANA) = (a,)
# ::EmptyTuple -> discard it
allnamed(args::Tuple{}) = ()
# ::Any -> discard it
allnamed(a::Any) = ()

# Return a tuple of all arguments; very similar to the above. unify the code?
allargs(bc::Broadcasted) = allargs(bc.args)
# ::Tuple -> search it
@inline allargs(args::Tuple) = (allargs(args[1])..., allargs(tail(args))...)
# ::Any -> keep it
allargs(a::Any) = (a,)
# ::EmptyTuple -> discard it
allargs(args::Tuple{}) = ()

# Return a tuple of all arguments; very similar to the above. unify the code?
allops(bc::Broadcasted) = (bc.f, allops(bc.args)...)
# ::Tuple -> search it
@inline allops(args::Tuple) = (allops(args[1])..., allops(tail(args))...)
# ::Any -> discard it
allops(a::Any) = ()
# ::EmptyTuple -> discard it
allops(args::Tuple{}) = ()

# Unwrap all of the named arrays within a Broadcasted expression. Note: `param` is currently unused, but is passed down
# to the unwrap(A::ANA, param) method in case we want to control the way an array is unwrapped in the future.
@inline unwrap(bc::Broadcasted{Style}, param) where Style = Broadcasted{Style}(bc.f, unwrap_args(bc.args, param), bc.axes)
@inline unwrap(bc::Broadcasted{NamedArrayStyle{Style}}, param) where Style = Broadcasted{Style}(bc.f, unwrap_args(bc.args, param), bc.axes)
unwrap(x, ::Any) = x
unwrap(A::ANA, param) = data(A)

@inline unwrap_args(args::Tuple, param) = (unwrap(args[1], param), unwrap_args(tail(args), param)...)
unwrap_args(args::Tuple{Any}, param) = (unwrap(args[1], param),)
unwrap_args(args::Tuple{}, ::Any, ) = ()

# todo: copyto!
