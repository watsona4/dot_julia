struct PinIndices{T}
    x::T
end
is_pinned(x) = false
is_pinned(x::PinIndices) = true
unpin(x) = x
unpin(x::PinIndices) = x.x

function Base.vcat(X::Union{AbstractVector,PinIndices}...)
    n = sum(is_pinned, X)
    n == 1 || throw(ArgumentError("only one argument can be pinned, got $n"))
    c = vcat(map(unpin, X)...)
    l = f = 0
    for x in X
        if is_pinned(x)
            f = first(axes(unpin(x),1))
            break
        end
        l += length(x)
    end
    OffsetArray(c, (f-l-1,))
end
