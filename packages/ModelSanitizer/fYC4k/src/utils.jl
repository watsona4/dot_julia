_compare(a, b)::Bool = a == b

_compare(a::Number, b::Number)::Bool = isapprox(a, b)
_compare(a::Missing, b::Number)::Bool = false
_compare(a::Number, b::Missing)::Bool = false
_compare(a::Missing, b::Missing)::Bool = false

function _get_property(m, field)
    try
        result = getproperty(m, field)
        return result
    catch ex
        # showerror(stderr, ex)
        # Base.show_backtrace(stderr, catch_backtrace())
        @debug("Ignoring exception", exception=(ex, catch_backtrace()))
    end
    return nothing
end

function _fix_vector_type(original_vector::AbstractVector)
    new_vector = vec([original_vector...])
    return new_vector
end

function _is_iterable(::Type{<:Number})::Bool
    return false
end

function _is_iterable(::Type{<:Char})::Bool
    return false
end

function _is_iterable(::Type{T})::Bool where T
    return hasmethod(iterate, (T,))
end

function _has_isassigned(::Type{T})::Bool where T
    return hasmethod(isassigned, (T, Int,))
end

function _is_indexable(::Type{<:Number})::Bool
    return false
end

function _is_indexable(::Type{<:Char})::Bool
    return false
end

function _is_indexable(::Type{T})::Bool where T
    return hasmethod(length, (T,))
end
