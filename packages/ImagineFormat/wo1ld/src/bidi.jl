import Base: size, getindex, setindex!

#z indices are flipped for even-numbered timepoints
struct BidiImageArray{T} <: AbstractArray{T,4}
    A::AbstractArray{T,4}
    z_size::Int
end

BidiImageArray(A::AbstractArray{T,4}) where {T} = BidiImageArray(A, size(A,3))

size(B::BidiImageArray) = size(B.A)

Base.IndexStyle(::Type{<:BidiImageArray}) = IndexCartesian()

function getindex(B::BidiImageArray, I::Vararg{Int, 4})
    t_ind = I[4]
    z_ind = ifelse(isodd(t_ind), I[3], B.z_size-I[3]+1)
    return getindex(B.A, I[1], I[2], z_ind, t_ind)
end

function setindex!(B::BidiImageArray, v, I::Vararg{Int, 4})
    t_ind = I[4]
    z_ind = ifelse(isodd(t_ind), I[3], B.z_size-I[3]+1)
    setindex!(B.A, v, I[1], I[2], z_ind, t_ind)
end
