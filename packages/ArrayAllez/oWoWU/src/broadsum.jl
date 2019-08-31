
export broadsum, broadsum!, bsum, bsum!

"""
	broadsum(*, A, B, C)       = sum(A .* B .* C)
	broadsum(f,*, A,B)         = sum(f, A .* B)
These aim to work exactly like `sum(broadcast(...))`, but without materialising the broadcast array.
Simplest case works & is fast. Version with `f` is slow. 

	broadsum(*, A, B; dims=1)  = sum(A .* B; dims=1)
    broadsum!(Z, *,A,B)        = sum!(Z, A .* B)
Similarly immitates `sum!(Z, broadcast(...))` without materialising. 
Now uses `LazyArrays.BroadcastArray`. The in-place form is actually a little slower. 
"""
bsum(op, As...; dims=:) = 
    _bsum(dims, identity, Broadcast.broadcasted(op, As...))
    
bsum(f::Function, op::Function, As...) = 
    _bsum((:), f, Broadcast.broadcasted(op, As...))

@inline function _bsum(::Colon, fun::Function, bc)
    @assert length(bc.args) >= 1

    T = Broadcast.combine_eltypes(fun∘bc.f, bc.args)
    tot = zero(T)
    @simd for I in eachindex(bc)
        @inbounds tot += fun(bc[I])
    end
    tot
end

using LazyArrays: BroadcastArray

_bsum(dims::Union{Int,NTuple}, ::typeof(identity), bc) = sum(BroadcastArray(bc); dims=dims)

bsum!(Z::AbstractArray, op, As...) = sum!(Z, BroadcastArray(op, As...))

const broadsum = bsum
const broadsum! = bsum!

# also dispatch complete sum to method which has better reverse:
# _bsum(::Colon, ::typeof(identity), bc) = sum_(BroadcastArray(bc))
# or not, crashes? 

# Base._sum(A::BroadcastArray, ::Colon) = _bsum((:), identity, A.broadcasted)

