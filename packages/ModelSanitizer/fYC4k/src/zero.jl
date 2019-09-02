function zero!(arr::A; kwargs...) where A <: AbstractArray{T, N} where T where N
    arr[:] .= zero(T)
    return arr
end

Base.zero(::Type{Any}) = 0

Base.zero(::Type{T}) where T = 0

Base.zero(::Type{T}) where T <: AbstractString = ""

Base.zero(::Type{T}) where T <: Nothing = nothing

Base.zero(::Type{T}) where T <: Missing = missing
