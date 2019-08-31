struct TestSourceWithoutLength
end

function Base.eltype(iter::TestSourceWithoutLength)
    return NamedTuple{(:a, :b), Tuple{Int, Float64}}
end

Base.IteratorSize(::Type{T}) where {T <: TestSourceWithoutLength} = Base.SizeUnknown()

function Base.iterate(iter::TestSourceWithoutLength, state=1)
    if state==1
        return (a=1, b=1.), 2
    elseif state==2
        return (a=2, b=2.), 3
    else
        return nothing
    end
end
