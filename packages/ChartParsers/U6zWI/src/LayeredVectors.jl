module LayeredVectors

export LayeredVector,
       push

struct LayeredVector{T} <: AbstractVector{T}
    length::Int
    element::T
    previous::LayeredVector{T}

    function LayeredVector{T}() where {T}
        new{T}(0)
    end

    function LayeredVector{T}(len::Integer, element, previous::LayeredVector) where {T}
        new{T}(len, element, previous)
    end
end

function LayeredVector{T}(x::AbstractVector) where {T}
    v = LayeredVector{T}()
    for element in x
        v = push(v, element)
    end
    v
end

Base.convert(::Type{LayeredVector{T}}, v::LayeredVector{T}) where {T} = v
Base.convert(::Type{LayeredVector{T}}, v::AbstractVector) where {T} = LayeredVector{T}(v)

Base.size(v::LayeredVector) = (v.length,)

function Base.iterate(v::LayeredVector, state=1)
    if state > v.length
        return nothing
    elseif state == v.length
        return (v.element, state + 1)
    else
        return iterate(v.previous, state)
    end
end

function Base.getindex(v::LayeredVector, i::Integer)
    if i > v.length
        throw(BoundsError())
    elseif i == v.length
        return v.element
    else
        return v.previous[i]
    end
end

function push(v::LayeredVector{T}, element::T) where {T}
    LayeredVector{T}(length(v) + 1, element, v)
end

function push(v::AbstractVector{T}, element::T) where {T}
    x = copy(v)
    push!(x, element)
    x
end

end
