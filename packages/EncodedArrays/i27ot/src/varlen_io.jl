# This file is a part of EncodedArrays.jl, licensed under the MIT License (MIT).

"""
    read_varlen(io::IO, T::Type{<:Unsigned})

Read an unsigned variable-length integer value of type `T` from `io`. If
the next value encoded in x is too large to be represented by `T`, an
exception is thrown.

See [`EncodedArrays.write_varlen`](@ref).
"""
@inline function read_varlen(io::IO, T::Type{<:Unsigned})
    maxPos = 8 * sizeof(T)
    x::T = 0
    pos::Int = 0
    while true
        (pos >= maxPos) && throw(ErrorException("Overflow during decoding of variable-length encoded number."))
        b = read(io, UInt8)
        x = x | (T(b & 0x7f) << pos)
        if ((b & 0x80) == 0)
            return x
        else
            pos += 7
        end
    end
end


"""
    write_varlen(io::IO, x::Unsigned)

Write unsigned integer value `x` to IO using variable-length coding. Data
is written in LSB fashion in units of one byte. The highest bit of each byte
indicates if more bytes will need to be read, the 7 lower bits contain the
next 7 bits of x. 
"""
@inline function write_varlen(io::IO, x::Unsigned)
    T = typeof(x)
    rest::T = x
    done::Bool = false
    while !(done)
        new_rest = rest >>> 7;
        a = UInt8(rest & 0x7F)
        b = (new_rest == 0) ? a : a | UInt8(0x80)
        write(io, b)
        rest = new_rest;
        done = (rest == 0)
    end
    nothing
end


"""
    read_autozz_varlen(io::IO, ::Type{<:Integer})

Read an integer of type `T` from `io`, using zig-zag decoding depending on
whether `T` is signed or unsigned.
"""
function read_autozz_varlen end

@inline read_autozz_varlen(io::IO, T::Type{<:Unsigned}) = read_varlen(io, T)
@inline read_autozz_varlen(io::IO, T::Type{<:Signed}) = zigzagdec(read_varlen(io, unsigned(T)))


"""
    write_autozz_varlen(io::IO, x::Integer)

Write integer value `x` to `io`, using zig-zag encoding depending on
whether the type of x is signed or unsigned.
"""

@inline write_autozz_varlen(io::IO, x::Unsigned) = write_varlen(io, x)
@inline write_autozz_varlen(io::IO, x::Signed) = write_varlen(io, zigzagenc(x))
