#=
CRC and Hashing functions for Str types (to make compatible with String hashes)

Copyright 2018 Gandalf Software, Inc., Scott P. Jones
Licensed under MIT License, see LICENSE.md
=#

using MurmurHash3

# Support for higher performance hashing, while still compatible with hashed UTF8 String

mmhash128(str::Union{String, Str}, seed::UInt32) =
    @preserve str mmhash128_a(sizeof(str), pointer(str), seed)

is_aligned(pnt::Ptr) = (reinterpret(UInt, pnt) & (sizeof(UInt) - 1)%UInt) == 0

# Check alignment of substrings first
function mmhash128(str::SubString, seed::UInt32)
    @preserve str begin
        pnt = pointer(str)
        if is_aligned(pnt)
            mmhash128_a(sizeof(str), pnt, seed)
        elseif sizeof(Int) == 8
            mmhash128_c(str, seed)
        else
            s = string(str)
            @preserve s mmhash128_a(sizeof(s), pointer(s), seed)
        end
    end
end

# This are for debugging purposes, to compare against current C implementation, will be removed
_memhash(siz, ptr, seed) =
    ccall(Base.memhash, UInt, (Ptr{UInt8}, Csize_t, UInt32), ptr, siz, seed % UInt32)

# Optimized code for hashing empty string
_hash(seed)          = last(mmhash128_a(seed%UInt32)) + seed
# Optimized for hashing a UTF-8 compatible aligned string
_hash(str, seed)     = last(mmhash128(str, seed%UInt32)) + seed
# For hashing generic abstract strings as if UTF-8 encoded
@static if sizeof(Int) == 8
    _hash_abs(str, seed) = last(mmhash128_c(str, seed%UInt32)) + seed
else
    function _hash_abs(str, seed)
        s = string(str)
        @preserve s last(mmhash128_a(sizeof(s), pointer(s), seed%UInt32)) + seed
    end
end

hash(str::Union{S,SubString{S}}, seed::UInt) where {S<:Str} =
    isempty(str) ? _hash(seed + Base.memhash_seed) : _hash_abs(str, seed + Base.memhash_seed)

# Check for UTF-8 compatible (i.e. only ASCII)
function hash(str::Union{S,SubString{S}}, seed::UInt) where {S<:Str{LatinCSE}}
    seed += Base.memhash_seed
    isempty(str) ? _hash(seed) : (is_ascii(str) ? _hash(str, seed) : _hash_abs(str, seed))
end

# Directly calculate hash for "compatible" types

hash(str::Union{S,SubString{S}},
     seed::UInt) where {S<:Str{<:Union{ASCIICSE,UTF8CSE,Binary_CSEs}}} =
         isempty(str) ? _hash(seed + Base.memhash_seed) : _hash(str, seed + Base.memhash_seed)

# Use crc32c to make CRC32c of UTF8 view of string, for use with hashing
# where different string types are supposed to compare as ==

function utf8crc(str::Union{S,SubString{S}}, seed::UInt) where {S<:Str}
    (len = ncodeunits(str)) == 0 && return utf8crc(str, seed)
    @preserve str begin
        pnt = pointer(str)
        len, flags, num4byte, num3byte, num2byte, latin1 = count_chars(S, pnt, len)
        # could be UCS2, _UCS2, UTF32, _UTF32, Text2, Text4
        utf8crc((flags == 0
                 ? _cvtsize(UInt8, pnt, len)
                 : _encode_utf8(pnt, len += latin1 + num2byte + num3byte*2 + num4byte*3)),
                seed)
    end
end

function utf8crc(str::Union{S,SubString{S}},
                 seed::UInt) where {S<:Str{<:Union{Text1CSE,Latin_CSEs}}}
    (len = ncodeunits(str)) == 0 && return utf8crc(str, seed)
    @preserve str begin
        pnt = pointer(str)
        utf8crc((cnt = count_latin(len, pnt)) == 0 ? str : _latin_to_utf8(pnt, len + cnt), seed)
    end
end

function utf8crc(str::Union{S,SubString{S}}, seed::UInt) where {S<:Str{UTF16CSE}}
    (len = ncodeunits(str)) == 0 && return utf8crc(str, seed)
    @preserve str begin
        pnt = pointer(str)
        len, flags, num4byte, num3byte, num2byte, latin1 = count_chars(S, pnt, len)
        utf8crc((flags == 0
                 ? _cvtsize(UInt8, pnt, len)
                 : _cvt_16_to_utf8(S, pnt, len += latin1 + num2byte + num3byte*2 + num4byte*3)),
                seed)
    end
end

utf8crc(str::Union{S,SubString{S}},
    seed::UInt32=0%UInt32) where {S<:Str{<:Union{ASCIICSE,UTF8CSE,BinaryCSE}}} =
        unsafe_crc32c(pointer(str), sizeof(s) % Csize_t, seed)

# Optimize conversion to ASCII or UTF8 to calculate compatible hash value
                          
function cvthash(str::Union{S,SubString{S}}, seed::UInt) where {S<:Str}
    seed += Base.memhash_seed
    (len = ncodeunits(str)) == 0 && return _hash(seed)
    @preserve str begin
        pnt = pointer(str)
        len, flags, num4byte, num3byte, num2byte, latin1 = count_chars(S, pnt, len)
        # could be UCS2, _UCS2, UTF32, _UTF32, Text2, Text4
        _hash((flags == 0
               ? _cvtsize(UInt8, pnt, len)
               : _encode_utf8(pnt, len + latin1 + num2byte + num3byte*2 + num4byte*3)),
              seed)
    end
end

function cvthash(str::Union{S,SubString{S}}, seed::UInt) where {S<:Str{<:Latin_CSEs}}
    seed += Base.memhash_seed
    (len = ncodeunits(str)) == 0 && return _hash(seed)
    @preserve str begin
        pnt = pointer(str)
        _hash((cnt = count_latin(len, pnt)) == 0 ? str : _latin_to_utf8(pnt, len + cnt), seed)
    end
end

function cvthash(str::Union{S,SubString{S}}, seed::UInt) where {S<:Str{UTF16CSE}}
    seed += Base.memhash_seed
    (len = ncodeunits(str)) == 0 && return _hash(seed)
    @preserve str begin
        pnt = pointer(str)
        len, flags, num4byte, num3byte, num2byte, latin1 = count_chars(S, pnt, len)
        _hash((flags == 0
               ? _cvtsize(UInt8, pnt, len)
               : _cvt_16_to_utf8(S, pnt, len + latin1 + num2byte + num3byte*2 + num4byte*3)),
              seed)
    end
end


