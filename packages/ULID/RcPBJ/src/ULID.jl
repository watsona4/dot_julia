module ULID

using Random
using Dates

export ulid

# Crockford's base-32 encoding
const _ENCODING = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
const _BASE = 32

@inline prng() = rand(RandomDevice(), UInt16) / 0xFFFF

function encodetime(now, n)
    # now should be in milliseconds-since-epoch
    s = Vector{Char}(undef, n)
    @inbounds for i = n:-1:1
        m = now % _BASE
        s[i] = _ENCODING[m+1]
        now = (now - m) ÷ _BASE
    end
    String(s)
end

function encoderandom(n)
    s = Vector{Char}(undef, n)
    @inbounds for i = n:-1:1
        r = floor(Int, _BASE * prng()) + 1
        s[i] = _ENCODING[r]
    end
    String(s)
end

"""
    ulid()

Generate a Universally Unique Lexicographically Sortable Identifier
(ULID) as a string.
"""
ulid() = encodetime(trunc(Int, datetime2unix(Dates.now()) * 1000), 10) * encoderandom(16)

end # module
