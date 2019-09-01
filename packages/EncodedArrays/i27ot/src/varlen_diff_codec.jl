# This file is a part of EncodedArrays.jl, licensed under the MIT License (MIT).

"""
    VarlenDiffArrayCodec <: AbstractArrayCodec
"""
struct VarlenDiffArrayCodec <: AbstractArrayCodec
end
export VarlenDiffArrayCodec


# function _encode(io::IO, codec::VarlenDiffArrayCodec, x::T, last_x::T) where {T <: Integer}
#     write_autozz_varlen(io, x - last_x)
# end
# 
# 
# function _decode(io::IO, codec::VarlenDiffArrayCodec, last_x::T) where {T <: Integer}
#     read_autozz_varlen(io, T) + last_x
# end

# function _length(io::IO, codec::VarlenDiffArrayCodec, T::Type{<:Integer})
#     n::Int = 0
#     last_x::T = 0
#     while !eof(io)
#         x = _decode(io, T, last_x)
#         last_x = x
#         n += 1
#     end
#     n
# end


function encode_data!(encoded::AbstractVector{UInt8}, codec::VarlenDiffArrayCodec, data::AbstractVector{T}) where {T}
    output = IOBuffer()
    last_x::T = zero(T)
    @inbounds for x in data
        dx = signed(x) - signed(last_x)
        write_autozz_varlen(output, dx)
        last_x = x
    end

    tmp = take!(output)
    resize!(encoded, length(eachindex(tmp)))
    copyto!(encoded, tmp)

    encoded
end


function decode_data!(data::AbstractVector{T}, codec::VarlenDiffArrayCodec, encoded::AbstractVector{UInt8}) where {T}
    input = IOBuffer(encoded)
    last_x::T = zero(T)
    i = firstindex(data)
    while !eof(input)
        if lastindex(data) < i
            if isempty(data)
                resize!(data, length(eachindex(encoded)))
            else
                resize!(data, 2 * (i - firstindex(data)))
            end
        end
        dx = read_autozz_varlen(input, typeof(signed(zero(T))))
        x = last_x + dx
        last_x = x
        data[i] = x
        i += 1
    end
    if i <= lastindex(data)
        resize!(data, i - firstindex(data))
    end

    data
end
