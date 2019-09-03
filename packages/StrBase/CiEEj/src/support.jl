# Based partly on code in LegacyStrings that used to be part of Julia
# Licensed under MIT License, see LICENSE.md

# (Mostly written by Scott P. Jones in series of PRs contributed to the Julia project in 2015)

## Return flags for check_string function

const UTF_LONG      =  1  ##< Long encodings are present
const UTF_LATIN1    =  2  ##< characters in range 0x80-0xFF present
const UTF_UNICODE2  =  4  ##< characters in range 0x100-0x7ff present
const UTF_UNICODE3  =  8  ##< characters in range 0x800-0xd7ff, 0xe000-0xffff
const UTF_UNICODE4  = 16  ##< non-BMP characters present
const UTF_SURROGATE = 32  ##< surrogate pairs present
const UTF_INVALID   = 64  ##< invalid sequences present

# Get a UTF-8 continuation byte, give error if invalid, return updated character value
@propagate_inbounds function check_continuation(dat, pos, ch, flag)
    @inbounds byt = get_codeunit(dat, pos)
    pos += 1
    if is_valid_continuation(byt)
        flag = false
    elseif !flag
        strerror(StrErrors.CONT, pos, byt)
    end
    ((ch%UInt32) << 6) | (byt & 0x3f), pos, flag
end

"""
Validates and calculates number of characters in a UTF-8,UTF-16 or UTF-32 encoded vector/string

Warning: this function does not check the bounds of the start or end positions
Use `check_string` to make sure the bounds are checked

Input Arguments:

* `dat`    UTF-8 (`Vector{UInt8}`), UTF-16 (`Vector{UInt16}`) or UTF-32 (`Vector{UInt32}`, `AbstractString`) encoded string
* `pos`    start position
* `endpos` end position

Keyword Arguments:

* `accept_long_null`  = `false`  # Modified UTF-8 (`\\0` represented as `b\"\\xc0\\x80\"`)
* `accept_surrogates` = `false`  # `CESU-8`
* `accept_long_char`  = `false`  # Accept arbitrary long encodings
* `accept_invalids`   = `false`  # Accept invalid sequences (to be replaced on conversion)

Returns:

* (total characters, flags, 4-byte, 3-byte, 2-byte)

Throws:

* `StringError`
"""
function unsafe_check_string end

_ret_check(totalchar, flags, invalids, latin1byte, num2byte, num3byte, num4byte) =
    (totalchar,
     ifelse(latin1byte == 0, 0, UTF_LATIN1) |
     ifelse(num2byte   == 0, 0, UTF_UNICODE2) |
     ifelse(num3byte   == 0, 0, UTF_UNICODE3) |
     ifelse(num4byte   == 0, 0, UTF_UNICODE4) |
     ifelse(invalids   == 0, 0, UTF_INVALID) | flags,
     num4byte, num3byte, num2byte, latin1byte, invalids)

function unsafe_check_string(dat::T, pos, endpos;
                             accept_long_null  = false,
                             accept_surrogates = false,
                             accept_long_char  = false,
                             accept_invalids   = false
                             ) where {T<:Union{AbstractArray{UInt8}, Ptr{UInt8}, String}}
    flags = 0%UInt
    totalchar = latin1byte = num2byte = num3byte = num4byte = invalids = 0
    @inbounds while pos <= endpos
        ch = get_codeunit(dat, pos)
        pos += 1
        totalchar += 1
        if ch > 0x7f
            # Check UTF-8 encoding
            if ch < 0xe0
                # 2-byte UTF-8 sequence (i.e. characters 0x80-0x7ff)
                if pos > endpos
                    accept_invalids || strerror(StrErrors.SHORT, pos, ch)
                    invalids += 1
                    break
                end
                ch, pos, flg = check_continuation(dat, pos, ch & 0x3f, accept_invalids)
                flg && (invalids += 1 ; continue)
                if ch > 0xff
                    num2byte += 1
                elseif ch > 0x7f
                    latin1byte += 1
                elseif accept_long_char
                    flags |= UTF_LONG
                elseif (ch == 0) && accept_long_null
                    flags |= UTF_LONG
                elseif accept_invalids
                    invalids += 1
                else
                    strerror(StrErrors.LONG, pos, ch)
                end
             elseif ch < 0xf0
                # 3-byte UTF-8 sequence (i.e. characters 0x800-0xffff)
                if pos + 1 > endpos
                    accept_invalids || strerror(StrErrors.SHORT, pos, ch)
                    invalids += 1
                    break
                end
                ch, pos, flg = check_continuation(dat, pos, ch & 0x0f, accept_invalids)
                flg && (invalids += 1 ; continue)
                ch, pos, flg = check_continuation(dat, pos, ch, accept_invalids)
                flg && (invalids += 1 ; continue)
                # check for surrogate pairs, make sure correct
                if is_surrogate_codeunit(ch)
                    if !is_surrogate_lead(ch)
                        accept_invalids || strerror(StrErrors.NOT_LEAD, pos-2, ch)
                        invalids += 1
                        continue
                    end
                    # next character *must* be a trailing surrogate character
                    if pos + 2 > endpos
                        accept_invalids || strerror(StrErrors.MISSING_SURROGATE, pos-2, ch)
                        invalids += 1
                        break
                    end
                    byt = get_codeunit(dat, pos)
                    pos += 1
                    if byt != 0xed
                        accept_invalids || strerror(StrErrors.NOT_TRAIL, pos, byt)
                        invalids += 1
                        continue
                    end
                    surr, pos, flg = check_continuation(dat, pos, 0x0000d, accept_invalids)
                    flg && (invalids += 1 ; continue)
                    surr, pos, flg = check_continuation(dat, pos, surr, accept_invalids)
                    flg && (invalids += 1 ; continue)
                    if !is_surrogate_trail(surr)
                        accept_invalids || strerror(StrErrors.NOT_TRAIL, pos-2, surr)
                        invalids += 1
                    elseif !accept_surrogates
                        accept_invalids || strerror(StrErrors.SURROGATE, pos-2, surr)
                        invalids += 1
                    else
                        flags |= UTF_SURROGATE
                        num4byte += 1
                    end
                elseif ch > 0x07ff
                    num3byte += 1
                elseif accept_long_char
                    flags |= UTF_LONG
                    num2byte += 1
                elseif accept_invalids
                    invalids += 1
                else
                    strerror(StrErrors.LONG, pos-2, ch)
                end
            elseif ch < 0xf5
                # 4-byte UTF-8 sequence (i.e. characters > 0xffff)
                if pos + 2 > endpos
                    accept_invalids || strerror(StrErrors.SHORT, pos, ch)
                    invalids += 1
                    break
                end
                ch, pos, flg = check_continuation(dat, pos, ch & 0x07, accept_invalids)
                flg && (invalids += 1 ; continue)
                ch, pos, flg = check_continuation(dat, pos, ch, accept_invalids)
                flg && (invalids += 1 ; continue)
                ch, pos, flg = check_continuation(dat, pos, ch, accept_invalids)
                flg && (invalids += 1 ; continue)
                if ch > 0x10ffff
                    accept_invalids || strerror(StrErrors.INVALID, pos-3, ch)
                    invalids += 1
                elseif ch > 0xffff
                    num4byte += 1
                elseif is_surrogate_codeunit(ch)
                    accept_invalids || strerror(StrErrors.SURROGATE, pos-3, ch)
                    invalids += 1
                elseif accept_long_char
                    # This is an overly long encoded character
                    flags |= UTF_LONG
                    if ch > 0x7ff
                        num3byte += 1
                    elseif ch > 0x7f
                        num2byte += 1
                    end
                elseif accept_invalids
                    invalids += 1
                else
                    strerror(StrErrors.LONG, pos-2, ch)
                end
            elseif accept_invalids
                invalids += 1
            else
                strerror(StrErrors.INVALID, pos, ch)
            end
        end
    end
    _ret_check(totalchar, flags, invalids, latin1byte, num2byte, num3byte, num4byte)
end

function unsafe_check_string(dat::Union{AbstractArray{T}, Ptr{T}}, pos, endpos;
                             accept_long_null  = false,
                             accept_surrogates = false,
                             accept_long_char  = false,
                             accept_invalids   = false) where {T<:Union{UInt16,UInt32}}
    flags = 0%UInt
    totalchar = latin1byte = num2byte = num3byte = num4byte = invalids = 0
    @inbounds while pos <= endpos
        ch = get_codeunit(dat, pos)%UInt32
        pos += 1
        totalchar += 1
        if ch > 0x7f
            if ch < 0x100
                latin1byte += 1
            elseif ch < 0x800
                num2byte += 1
            elseif ch > 0x0ffff
                if (ch > 0x10ffff)
                    accept_invalids || strerror(StrErrors.INVALID, pos, ch)
                    invalids += 1
                else
                    num4byte += 1
                end
            elseif !is_surrogate_codeunit(ch)
                num3byte += 1
            elseif is_surrogate_lead(ch)
                if pos > endpos
                    accept_invalids || strerror(StrErrors.MISSING_SURROGATE, pos, ch)
                    invalids += 1
                    break
                end
                # next character *must* be a trailing surrogate character
                ch = get_codeunit(dat, pos)
                pos += 1
                if !is_surrogate_trail(ch)
                    accept_invalids || strerror(StrErrors.NOT_TRAIL, pos, ch)
                    invalids += 1
                elseif typeof(dat) <: AbstractArray{UInt16} # fix this test!
                    num4byte += 1
                elseif accept_surrogates
                    flags |= UTF_SURROGATE
                    num4byte += 1
                elseif accept_invalids
                    invalids += 1
                else
                    strerror(StrErrors.SURROGATE, pos, ch)
                end
            elseif accept_invalids
                invalids += 1
            else
                strerror(StrErrors.NOT_LEAD, pos, ch)
            end
        end
    end
    _ret_check(totalchar, flags, invalids, latin1byte, num2byte, num3byte, num4byte)
end

function unsafe_check_string(str::T;
                             accept_long_null  = false,
                             accept_surrogates = false,
                             accept_long_char  = false,
                             accept_invalids   = false) where {T<:AbstractString}
    flags = 0%UInt
    totalchar = latin1byte = num2byte = num3byte = num4byte = invalids = 0
    pos = 1
    @inbounds while !str_done(str, pos)
        chr, nxt = str_next(str, pos)
        ch = chr%UInt32
        totalchar += 1
        if ch > 0x7f
            if ch < 0x100
                latin1byte += 1
            elseif ch < 0x800
                num2byte += 1
            elseif ch > 0x0ffff
                if (ch > 0x10ffff)
                    accept_invalids || strerror(StrErrors.INVALID, pos, ch)
                    invalids += 1
                else
                    num4byte += 1
                end
            elseif !is_surrogate_codeunit(ch)
                num3byte += 1
            elseif is_surrogate_lead(ch)
                if done(str, nxt)
                    accept_invalids || strerror(StrErrors.MISSING_SURROGATE, pos, ch)
                    invalids += 1
                    break
                end
                # next character *must* be a trailing surrogate character
                chr, nxt = str_next(str, nxt)
                if !is_surrogate_trail(chr)
                    accept_invalids || strerror(StrErrors.NOT_TRAIL, pos, chr)
                    invalids += 1
                elseif accept_surrogates
                    flags |= UTF_SURROGATE
                    num4byte += 1
                elseif accept_invalids
                    invalids += 1
                else
                    strerror(StrErrors.SURROGATE, pos, ch)
                end
            elseif accept_invalids
                invalids += 1
            else
                strerror(StrErrors.NOT_LEAD, pos, ch)
            end
        end
        pos = nxt
    end
    _ret_check(totalchar, flags, invalids, latin1byte, num2byte, num3byte, num4byte)
end

@inline function alignpnt(beg::Ptr)
    align = reinterpret(UInt, beg)
    align, reinterpret(Ptr{UInt64}, align & (~CHUNKMSK)%UInt)
end

@inline function skipascii(beg::Ptr{UInt8}, fin::Ptr{UInt8})
    align, pnt = alignpnt(beg)
    v = unsafe_load(pnt)
    (align &= CHUNKMSK) != 0 && (v &= ~_mask_bytes(align))
    while (pnt += CHUNKSZ) < fin
        # find first byte that is not ASCII
        (v &= hi_mask) == 0 || return Int(pnt - CHUNKSZ - beg + (trailing_zeros(v)>>>3))
        v = unsafe_load(pnt)
    end
    Int(pnt - CHUNKSZ - beg +
        (trailing_zeros((pnt == fin ? v : (v | ~_mask_bytes(fin - pnt - CHUNKSZ))) & hi_mask)>>>3))
end

function fast_check_string(beg::Ptr{UInt8}, len)
    pnt = beg
    fin = pnt + len
    flags = 0%UInt
    asciichar = latin1byte = num2byte = num3byte = num4byte = 0
    while pnt < fin
        ch = get_codeunit(pnt)
        if ch < 0x80
            cnt = skipascii(pnt, fin)
            asciichar += cnt
            pnt += cnt
            continue
        # Check UTF-8 encoding
        elseif ch < 0xe0
            # Check that not a continuation character
            ch < 0xc0 && strerror(StrErrors.NOT_LEAD, pnt - beg, ch)
            # 2-byte UTF-8 sequence (i.e. characters 0x80-0x7ff)
            (pnt += 1) < fin || strerror(StrErrors.SHORT, pnt - beg, ch)
            checkcont(pnt) || strerror(StrErrors.INVALID, pnt - beg - 1, ch)
            ch > 0xc1 || strerror(StrErrors.LONG, pnt - beg - 1, get_utf8_2byte(pnt, ch))
            ch > 0xc3 ? (num2byte += 1) : (latin1byte += 1)
        elseif ch < 0xf0
            # 3-byte UTF-8 sequence (i.e. characters 0x800-0xffff)
            (pnt += 2) < fin || strerror(StrErrors.SHORT, pnt - beg - 1, ch)
            b2 = get_codeunit(pnt - 1)
            (is_valid_continuation(b2) && checkcont(pnt)) ||
                strerror(StrErrors.INVALID, pnt - beg - 1, ch)
            if ch == 0xe0 # Might be overlong
                b2 < 0xa0 && strerror(StrErrors.LONG, pnt - beg - 1, get_utf8_3byte(pnt, ch))
            elseif ch == 0xed # Might be surrogate pair
                b2 > 0x9f && strerror(StrErrors.SURROGATE, pnt - beg - 1, get_utf8_3byte(pnt, ch))
            end
            num3byte += 1
        elseif ch < 0xf5
            # 4-byte UTF-8 sequence (i.e. characters > 0xffff)
            (pnt += 3) < fin || strerror(StrErrors.SHORT, pnt - beg - 2, ch)
            b2 = get_codeunit(pnt - 2)
            #println(ch,", ",b2,", ",get_codeunit(pnt-1),", ",get_codeunit(pnt))
            (is_valid_continuation(b2) && checkcont(pnt-1) && checkcont(pnt)) ||
                strerror(StrErrors.INVALID, pnt - beg - 2, ch)
            if ch == 0xf0
                b2 < 0x90 && strerror(StrErrors.LONG, pnt - beg - 2, get_utf8_4byte(pnt, ch))
            elseif ch == 0xf4
                b2 > 0x8f && strerror(StrErrors.INVALID, pnt - beg - 2, get_utf8_4byte(pnt, ch))
            end
            num4byte += 1
        else
            strerror(StrErrors.INVALID, pnt - beg + 1, ch)
        end
        pnt += 1
    end
    _ret_check(asciichar+latin1byte+num2byte+num3byte+num4byte,
               flags, 0, latin1byte, num2byte, num3byte, num4byte)
end

const _bmp_mask = 0xd800_d800_d800_d800
@inline _mask_allsurr(v)  = xor((v | v<<1 | v<<2 | v<<3 | v<<4) & _hi_bit_16, _hi_bit_16)

@inline _get_bmp_mask(v::UInt64) = _mask_allsurr(xor(v, _bmp_mask))

const msk_ascii_16 = 0xff80ff80ff80ff80
const msk_latin_16 = 0xff00ff00ff00ff00
const msk_num2b_16 = 0xf800f800f800f800

# v -> 1111 1yyy l000 0000 1111 1yyy l000 0000 1111 1yyy l000 0000 1111 1yyy l000 0000

@inline function countmask(v, cnta, cntl, cnt2, cnt3)
    # First mask off ASCII bits: 0xff80ff80ff80ff80, count all 0 words (0-4)
    # Then mask off Latin1 bits: 0xff00ff00ff00ff00, count all 0 words (0-4)
    # Then mask off num2byte:    0xf800f800f800f800, count all 0 words (0-4)
    va = v & msk_ascii_16
    vl = v & msk_latin_16
    v2 = v & msk_num2b_16
    println("v=$v, 0x$(hex(va)), 0x$(hex(vl)), 0x$(hex(v2)), $cnta, $cntl, $cnt2, $cnt3")
    cnta, cntl, cnt2, cnt3
end

@inline function skipbmp(beg::Ptr{UInt16}, fin, cnta, cntl, cnt2, cnt3)
    align, pnt = alignpnt(beg)
    v = unsafe_load(pnt)
    (align &= CHUNKMSK) != 0 && (v &= ~_mask_bytes(align))
    while (pnt += CHUNKSZ) < fin
        # If vm is 0, it means there are non-BMP characters present
        if (vm = _get_bmp_mask(v)) == 0
            # Get how many characters are before the non-BMP character
            cnt = (leading_zeros(vm)>>>3)&~1
            v &= _mask_bytes(cnt)
            return pnt - CHUNKSZ + cnt, countmask(v, cnta, cntl, cnt2, cnt3)...
        end
        cnta, cntl, cnt2, cnt3 = countmask(v, cnta, cntl, cnt2, cnt3)
        v = unsafe_load(pnt)
    end
    v = (pnt == fin ? v : (v & _mask_bytes(fin - pnt - CHUNKSZ)))
    if (vm = _get_bmp_mask(v)) == 0
        # Get how many characters are before the non-BMP character
        cnt = (leading_zeros(vm)>>>3)&~1
        v &= _mask_bytes(cnt)
        fin = pnt - CHUNKSZ + cnt
    end
    fin, countmask(v, cnta, cntl, cnt2, cnt3)...
end

# Check for valid UTF-16
function fast_check_string(beg::Ptr{UInt16}, len)
    pnt = beg
    fin = bytoff(pnt, len)
    flags = 0%UInt
    asciichar = latin1byte = num2byte = num3byte = num4byte = 0
    while pnt < fin
        ch = get_codeunit(pnt)
        #=
        if !is_surrogate_codepoint(ch)
            pnt, asciichar, latin1byte, num2byte, num3byte =
                skipbmp(pnt, fin, asciichar, latin1byte, num2byte, num3byte)
        =#
        if ch <= 0x7f
            asciichar += 1
        elseif ch <= 0xff
            latin1byte += 1
        elseif ch < 0x7ff
            num2byte += 1
        elseif !is_surrogate_codeunit(ch)
            num3byte += 1
        elseif !is_surrogate_lead(ch)
            strerror(StrErrors.NOT_LEAD, Int((pnt - beg)>>>1), ch)
        elseif (pnt += 2) >= fin
            strerror(StrErrors.SHORT, Int((pnt - beg - 2)>>>1), ch)
        else
            c2 = get_codeunit(pnt)
            is_surrogate_trail(c2) || strerror(StrErrors.NOT_TRAIL, Int((pnt - beg)>>>1), c2)
            pnt += 2
            num4byte += 1
        end
        pnt += 2
    end
    _ret_check(asciichar+latin1byte+num2byte+num3byte+num4byte,
               flags, 0, latin1byte, num2byte, num3byte, num4byte)
end

# Check for valid UTF-32
function fast_check_string(beg::Ptr{UInt32}, len)
    pnt = beg
    fin = bytoff(pnt, len)
    flags = 0%UInt
    asciichar = latin1byte = num2byte = num3byte = num4byte = 0
    while pnt < fin
        ch = get_codeunit(pnt)
        if ch <= 0x7f
            asciichar += 1
        elseif ch <= 0xff
            latin1byte += 1
        elseif ch <= 0x7ff
            num2byte += 1
        elseif ch <= 0xd7ff
            num3byte += 1
        elseif ch <= 0xdfff
            strerror(StrErrors.SURROGATE, (pnt-beg+4)>>>2, ch)
        elseif ch <= 0xffff
            num3byte += 1
        elseif ch <= 0x10ffff
            num4byte += 1
        else
            strerror(StrErrors.INVALID, (pnt-beg+4)>>>2, ch)
        end
        pnt += 4
    end
    _ret_check(asciichar+latin1byte+num2byte+num3byte+num4byte,
               flags, 0, latin1byte, num2byte, num3byte, num4byte)
end

"""
Calculate the total number of characters, as well as number of
latin1, 2-byte, 3-byte, and 4-byte sequences in a validated UTF-8 string
"""
function count_chars(::Type{UTF8Str}, ::Type{S}, pnt::Ptr{S}, pos, len) where {S<:CodeUnitTypes}
    totalchar = latin1byte = num2byte = num3byte = num4byte = 0
    fin = bytoff(pnt, len)
    pnt = bytoff(pnt, pos - 1)
    while pnt < fin
        ch = get_codeunit(pnt)
        pnt += 1
        totalchar += 1
        if ch > 0x7f # non-ASCII characters
            pnt += 1
            if ch < 0xc4 # 2-byte Latin 1 characters (0x80-0xff)
                latin1byte += 1
            elseif ch < 0xe0 # 2-byte BMP sequence (i.e. characters 0x100-0x7ff)
                num2byte += 1
            elseif ch < 0xf0 # 3-byte BMP sequence (0x800-0xffff)
                pnt += 1
                num3byte += 1
            else # 4-byte non-BMP sequence (0x10000 - 0x10ffff)
                pnt += 2
                num4byte += 1
            end
        end
    end
    _ret_check(totalchar, 0%UInt, 0, latin1byte, num2byte, num3byte, num4byte)
end

"""
Calculate the total number of characters, as well as number of
latin1, 2-byte, 3-byte, and 4-byte sequences in a validated UTF-16, UCS2, or UTF-32 string
"""
function count_chars(::Type{T}, ::Type{S}, pnt::Ptr{S}, pos, len) where {S<:CodeUnitTypes,T<:Str}
    totalchar = latin1byte = num2byte = num3byte = num4byte = 0
    fin = bytoff(pnt, len)
    pnt = bytoff(pnt, pos - 1)
    while pnt < fin
        ch = get_codeunit(pnt)%UInt32
        pnt += sizeof(S)
        totalchar += 1
        if ch > 0x7f # non-ASCII characters
            if ch <= 0xff # 2-byte Latin 1 characters (0x80-0xff)
                latin1byte += 1
            elseif ch <= 0x7ff # 2-byte BMP sequence (i.e. characters 0x100-0x7ff)
                num2byte += 1
            elseif T == UTF16Str
                if is_surrogate_lead(ch)
                    pnt += sizeof(S)
                    num4byte += 1
                else
                    num3byte += 1
                end
            elseif ch <= 0xffff # 3-byte BMP sequence (0x800-0xffff)
                num3byte += 1
            else # 4-byte non-BMP sequence (0x10000 - 0x10ffff)
                num4byte += 1
            end
        end
    end
    _ret_check(totalchar, 0%UInt, 0, latin1byte, num2byte, num3byte, num4byte)
end

count_chars(T, dat, len) = count_chars(T, codeunit(T), dat, 1, len)

@inline function _count_mask_al(pnt, siz, msk, v)
    cnt = 0
    fin = pnt + siz
    while (pnt += CHUNKSZ) < fin
        cnt += count_ones(v & msk)
        v = unsafe_load(pnt)
    end
    cnt + count_ones((siz & CHUNKMSK == 0 ? v : (v & _mask_bytes(siz))) & msk)
end
@inline _count_mask_al(pnt, siz, msk) = _count_mask_al(pnt, siz, msk, unsafe_load(pnt))

@inline function _count_mask_ul(beg, siz, msk)
    align, pnt = alignpnt(beg)
    v = unsafe_load(pnt)
    if (align &= CHUNKMSK) != 0
        v &= ~_mask_bytes(align)
        siz += align
    end
    _count_mask_al(pnt, siz, msk, v)
end
"""
Calculate the total number of bytes > 0x7f
"""
count_latin(len, pnt::Ptr{UInt8}) = _count_mask_ul(pnt, len, hi_mask)

"""
Validates and calculates number of characters in a UTF-8,UTF-16 or UTF-32 encoded vector/string

This function checks the bounds of the start and end positions
Use `unsafe_check_string` to avoid that overhead if the bounds have already been checked

Input Arguments:

* `dat`    UTF-8 (`Vector{UInt8}`), UTF-16 (`Vector{UInt16}`) or UTF-32 (`Vector{UInt32}`, `AbstractString`) encoded string

Optional Input Arguments:

* `startpos` start position (defaults to 1)
* `endpos`   end position   (defaults to `lastindex(dat)`)

Keyword Arguments:

* `accept_long_null`  = `false`  # Modified UTF-8 (`\\0` represented as `b\"\\xc0\\x80\"`)
* `accept_surrogates` = `false`  # `CESU-8`
* `accept_long_char`  = `false`  # Accept arbitrary long encodings
* `accept_invalids`   = `false`  # Accept invalid sequences (to be replaced on conversion)

Returns:

* (total characters, flags, 4-byte, 3-byte, 2-byte)

Throws:

* `StringError`
"""
function check_string end

# No need to check bounds if using defaults
check_string(dat; kwargs...) = unsafe_check_string(dat, 1, lastindex(dat); kwargs...)

# Make sure that beginning and end positions are bounds checked
function check_string(dat, startpos, endpos = lastindex(dat); kwargs...)
    @boundscheck checkbounds(dat, startpos)
    @boundscheck checkbounds(dat, endpos)
    endpos < startpos && argerror(startpos, endpos)
    unsafe_check_string(dat, startpos, endpos; kwargs...)
end

is_unicode(arr::AbstractArray{<:CodeUnitTypes}) =
    (try check_string(arr) ; catch ; return false ; end ; true)

is_valid(::Type{<:Str{ASCIICSE}},  s::Vector{UInt8}) = is_ascii(s)
is_valid(::Type{<:Str{LatinCSE}},  s::Vector{UInt8}) = true
# This should be optimized, stop at first character > 0x7f
is_valid(::Type{<:Str{_LatinCSE}}, s::Vector{UInt8}) = !is_ascii(s)

is_valid(::Type{<:Str{UTF8CSE}},   s::AbstractArray{UInt8}) = is_unicode(s)
is_valid(::Type{UniStr}, s::String) = is_unicode(s)
is_valid(::Type{<:Str{C}}, s::String) where {C<:Union{UTF8CSE,UTF16CSE,UTF32CSE}} = is_unicode(s)
is_valid(::Type{<:Str{ASCIICSE}}, s::String) = is_ascii(s)
is_valid(::Type{<:Str{UCS2CSE}}, s::String)  = is_bmp(s)
is_valid(::Type{<:Str{LatinCSE}}, s::String) = is_latin(s)

function _copysub(pnt::Ptr{T}, len) where {T<:CodeUnitTypes}
    buf, out = _allocate(eltype(pnt), len)
    _memcpy(out, pnt, len)
    buf
end
_copysub(str::String)    = str
_copysub(str::Str)       = str.data
_copysub(str::SubString) = @preserve str _copysub(pointer(str), ncodeunits(str))
_copysub(vec::Vector)    = @preserve vec _copysub(pointer(vec), length(vec))

function _cvtsize(::Type{T}, dat, len) where {T <: CodeUnitTypes}
    buf, pnt = _allocate(T, len)
    @inbounds for i = 1:len
        set_codeunit!(pnt, get_codeunit(dat, i))
        pnt += sizeof(T)
    end
    buf
end

function _cvtsize(::Type{T}, pnt::Ptr{S}, len) where {S<:CodeUnitTypes,T<:CodeUnitTypes}
    buf, out = _allocate(T, len)
    fin = bytoff(pnt, len)
    #println("buf=$buf, out=$out, pnt=$pnt, fin=$fin, len=$len")
    while pnt < fin
        set_codeunit!(out, get_codeunit(pnt)%T)
        out += sizeof(T)
        pnt += sizeof(S)
    end
    buf
end

(*)(s1::Union{C1, S1}, ss::Union{C2, S2}...) where {C1<:Chr,C2<:Chr,S1<:Str,S2<:Str} =
    string(s1, ss...)

thisind(str::MaybeSub{<:Str}, i::Integer) = thisind(str, Int(i))

function filter(fun, str::MaybeSub{T}) where {C<:CSE,T<:Str{C}}
    out = get_iobuffer(sizeof(str))
    @inbounds for ch in codepoints(str)
        fun(ch) && _write(C, out, ch)
    end
    Str{C}(String(take!(out)))
end

# Todo: These should be optimized based on the traits, and return internal substrings, once
# I've implemented those

first(str::Str, n::Integer) = str[1:min(end, nextind(str, 0, n))]
last(str::Str, n::Integer)  = str[max(1, prevind(str, ncodeunits(str)+1, n)):end]

# low level mem support functions

const HAS_WMEM = !Sys.iswindows()

@static if HAS_WMEM

const (WidChr,OthChr) = @static sizeof(Cwchar_t) == 4 ? (UInt32,UInt16) : (UInt16,UInt32)

@inline _memcmp(a::Ptr{T}, b::Ptr{T}, len) where {T<:WidChr} =
    ccall(:wmemcmp, Int32, (Ptr{T}, Ptr{T}, UInt), a, b, len)
@inline _memcpy(a::Ptr{T}, b::Ptr{T}, len) where {T<:WidChr} =
    ccall(:wmemcpy, Ptr{T}, (Ptr{T}, Ptr{T}, UInt), a, b, len)
@inline _memset(pnt::Ptr{T}, ch::T, cnt) where {T<:WidChr} =
    ccall(:wmemset, Ptr{T}, (Ptr{T}, Cuint, Csize_t), pnt, ch, cnt)

_fwd_memchr(ptr::Ptr{T}, wchr::T, len::Integer) where {T<:WidChr} =
    ccall(:wmemchr, Ptr{T}, (Ptr{T}, Int32, Csize_t), ptr, wchr, len)
_fwd_memchr(ptr::Ptr{T}, wchr::T, fin::Ptr{T}) where {T<:WidChr} =
    ptr < fin ? _fwd_memchr(ptr, wchr, chroff(fin - ptr)) : C_NULL

else
    const OthChr = Union{UInt16, UInt32}
end

_fwd_memchr(ptr::Ptr{T}, byt::T, len::Integer) where {T<:UInt8} =
    ccall(:memchr, Ptr{T}, (Ptr{T}, Int32, Csize_t), ptr, byt, len)

_fwd_memchr(beg::Ptr{T}, wchr::T, len::Integer) where {T<:OthChr} =
    _fwd_memchr(beg, ch, bytoff(beg, len))

_fwd_memchr(ptr::Ptr{T}, byt::T, fin::Ptr{T}) where {T<:UInt8} =
    ptr < fin ? _fwd_memchr(ptr, byt, fin - ptr) : C_NULL

function _fwd_memchr(pnt::Ptr{T}, wchr::T, fin::Ptr{T}) where {T<:OthChr}
    while pnt < fin
        get_codeunit(pnt) == ch && return pnt
        pnt += sizeof(T)
    end
    C_NULL
end

_rev_memchr(ptr::Ptr{T}, byt::T, len::Integer) where {T<:UInt8} =
    ccall(:memrchr, Ptr{T}, (Ptr{T}, Int32, Csize_t), ptr, byt, len)

function _rev_memchr(beg::Ptr{T}, ch::T, len::Integer) where {T<:Union{UInt16,UInt32}}
    pnt = bytoff(beg, len)
    while (pnt -= sizeof(T)) >= beg
        get_codeunit(pnt) == ch && return pnt
    end
    C_NULL
end

_memcmp(a::Ptr{T}, b::Ptr{T}, len) where {T<:UInt8} =
    ccall(:memcmp, Int32, (Ptr{T}, Ptr{T}, UInt), a, b, len)

function _memcmp(apnt::Ptr{T}, bpnt::Ptr{T}, len) where {T<:OthChr}
    fin = bytoff(apnt, len)
    while apnt < fin
        (c1 = get_codeunit(apnt)) == (c2 = get_codeunit(bpnt)) || return _cmp(c1, c2)
        apnt += sizeof(T)
        bpnt += sizeof(T)
    end
    0
end

# These should probably be handled by traits, or dispatched by getting the codeunit type for each
_memcmp(a::Union{String, Str{<:Byte_CSEs}},
        b::Union{String, Str{<:Byte_CSEs}, SubString{String}, SubString{<:Str{<:Byte_CSEs}}}, siz) =
    _memcmp(pointer(a), pointer(b), siz)
_memcmp(a::SubString{<:Union{String, Str{<:Byte_CSEs}}}, b::Union{String, Str{<:Byte_CSEs}}, siz) =
    _memcmp(pointer(a), pointer(b), siz)
_memcmp(a::SubString{<:Union{String, Str{<:Byte_CSEs}}},
        b::SubString{<:Union{String, Str{<:Byte_CSEs}}}, siz) =
    _memcmp(pointer(a), pointer(b), siz)

_memcmp(a::Str{<:Word_CSEs}, b::MaybeSub{<:Str{<:Word_CSEs}}, siz) =
    _memcmp(pointer(a), pointer(b), siz)
_memcmp(a::Str{<:Quad_CSEs}, b::MaybeSub{<:Str{<:Quad_CSEs}}, siz) =
    _memcmp(pointer(a), pointer(b), siz)
_memcmp(a::SubString{<:Str{<:Word_CSEs}}, b::Str{<:Word_CSEs}, siz) =
    _memcmp(pointer(a), pointer(b), siz)
_memcmp(a::SubString{<:Str{<:Quad_CSEs}}, b::Str{<:Quad_CSEs}, siz) =
    _memcmp(pointer(a), pointer(b), siz)
_memcmp(a::SubString{<:Str{<:Word_CSEs}}, b::SubString{<:Str{Word_CSEs}}, siz) =
    _memcmp(pointer(a), pointer(b), siz)
_memcmp(a::SubString{<:Str{<:Quad_CSEs}}, b::SubString{<:Str{Quad_CSEs}}, siz) =
    _memcmp(pointer(a), pointer(b), siz)

_memcpy(dst::Ptr{UInt8}, src::Ptr, siz) =
    ccall(:memcpy, Ptr{UInt8}, (Ptr{Cvoid}, Ptr{Cvoid}, UInt), dst, src, siz)
_memcpy(a::Ptr{T}, b::Ptr{T}, len) where {T<:OthChr} =
    ccall(:memcpy, Ptr{T}, (Ptr{T}, Ptr{T}, UInt), a, b, bytoff(T, len))

@inline _memset(pnt::Ptr{T}, ch::T, cnt) where {T<:UInt8} =
    ccall(:memset, Ptr{T}, (Ptr{T}, Cint, Csize_t), pnt, ch, cnt)

@inline function _memset(pnt::Ptr{T}, ch::T, cnt) where {T<:OthChr}
    fin = bytoff(pnt, cnt)
    while pnt < fin
        set_codeunit!(pnt, ch)
        pnt += sizeof(T)
    end
end

@inline _aligned_set(pnt::Ptr{UInt8}, ch::UInt8, cnt) = _memset(pnt, ch, cnt)

@inline function _aligned_set(pnt::Ptr{UInt16}, ch::UInt16, cnt)
    val = ch%UInt64
    val |= (val<<16) | (val<<32) | (val<<48)
    p64 = reinterpret(Ptr{UInt64}, pnt)
    @inbounds for i = 1:((cnt + 3)>>2)
        unsafe_store!(p64, val, i)
    end
    #=
    fin = p64 + (((cnt + 3)>>2)<<3)
    while p64 < fin
        unsafe_store!(p64, val)
        p64 += 8
    end
    =#
end

@inline function _aligned_set(pnt::Ptr{UInt32}, ch::UInt32, cnt)
    val = ((ch%UInt64)<<32) | ch
    p64 = reinterpret(Ptr{UInt64}, pnt)
    @inbounds for i = 1:((cnt + 1)>>1)
        unsafe_store!(p64, val, i)
    end
    #=
    fin = p64 + (((cnt + 1)>>1)<<3)
    while p64 < fin
        unsafe_store!(p64, val)
        p64 += 8
    end
    =#
end

@inline function _repeat_chr(::Type{T}, ch, cnt) where {T<:CodeUnitTypes}
    #println("_repeat_chr($T, $ch, $cnt)")
    buf, pnt = _allocate(T, cnt)
    _memset(pnt, ch%T, cnt)
    buf
end

@inline function _repeat_3(ch, cnt)
    buf, pnt = _allocate(UInt8, cnt*3)
    b1, b2, b3 = get_utf8_3(ch)
    fin = pnt + cnt*3
    while pnt < fin
        set_codeunit!(pnt,     b1)
        set_codeunit!(pnt + 1, b2)
        set_codeunit!(pnt + 2, b3)
        pnt += 3
    end
    buf
end

_repeat(::SingleCU, ::Type{C}, ch::T, cnt) where {T,C<:CSE} =
    _repeat_chr(basetype(T), ch, cnt)

function _repeat(::MultiCU, ::Type{UTF8CSE}, ch, cnt)
    if ch <= 0x7f
        _repeat_chr(UInt8, ch, cnt)
    elseif ch <= 0x7ff
        _repeat_chr(UInt16, get_utf8_16(ch), cnt)
    elseif ch <= 0xffff
        _repeat_3(ch, cnt)
    else
        _repeat_chr(UInt32, get_utf8_32(ch), cnt)
    end
end

_repeat(::MultiCU, ::Type{UTF16CSE}, ch, cnt) =
    ch <= 0xffff ? _repeat_chr(UInt16, ch, cnt) : _repeat_chr(UInt32, get_utf16_32(ch), cnt)

function _repeat_str(str::T, cnt) where {C<:CSE,T<:Str{C}}
    cnt <= 0 && (cnt < 0 ? repeaterr(cnt) : return empty_str(C))
    CU = codeunit(T)
    @preserve str begin
        len = ncodeunits(str)
        if len == 1 # common case: repeating a single codeunit string
            buf, out = _allocate(CU, cnt)
            _memset(out, get_codeunit(pointer(str)), cnt)
        else
            totlen = len * cnt
            buf, out = _allocate(CU, totlen)
            pnt = pointer(str)
            fin = bytoff(out, totlen)
            siz = bytoff(CU, len)
            while out < fin
                _memcpy(out, pnt, len)
                out += siz
            end
        end
    end
    Str(C, buf)
end

@inline repeat(str::Str, cnt::Integer) = cnt == 1 ? str : _repeat_str(str, cnt)

(^)(str::T, cnt::Integer) where {T<:Str} = repeat(str, cnt)

function repeat(ch::CP, cnt::Integer) where {CP <: Chr}
    C = codepoint_cse(CP)
    cnt > 1 && return Str(C, _repeat(EncodingStyle(C), C, codepoint(ch), cnt))
    cnt == 1 && return _convert(C, codepoint(ch))
    cnt == 0 && return empty_str(C)
    repeaterr(cnt)
end

(^)(ch::CP, cnt::Integer) where {CP <: Chr} = repeat(ch, cnt)

function repeat(ch::C, cnt::Integer) where {C<:Union{ASCIIChr,LatinChr}}
    if cnt > 0
        cu = ch%UInt8
        buf, pnt = _allocate(UInt8, cnt)
        _memset(pnt, cu, cnt)
        C == ASCIIChr ? Str(ASCIICSE, buf) : Str(LatinCSE, buf)
    else
        cnt < 0 ? repeaterr(cnt) : C == ASCIIStr ? empty_ascii : empty_latin
    end
end

function repeat(ch::_LatinChr, cnt::Integer)
    if cnt > 0
        cu = ch%UInt8
        buf, pnt = _allocate(UInt8, cnt)
        _memset(pnt, cu, cnt)
        cu <= 0x7f ? Str(ASCIICSE, buf) : Str(_LatinCSE, buf)
    else
        cnt == 0 ? empty_ascii : repeaterr(cnt)
    end
end

function repeat(ch::UCS2Chr, cnt::Integer)
    if cnt > 0
        buf, pnt = _allocate(UInt16, cnt)
        cnt == 1 ? set_codeunit!(pnt, ch%UInt16) : _aligned_set(pnt, ch%UInt16, cnt)
        Str(UCS2CSE, buf)
    else
        cnt == 0 ? empty_ucs2 : repeaterr(cnt)
    end
end

function repeat(ch::UTF32Chr, cnt::Integer)
    if cnt > 0
        buf, pnt = _allocate(UInt32, cnt)
        cnt == 1 ? set_codeunit!(pnt, ch%UInt32) : _aligned_set(pnt, ch%UInt32, cnt)
        Str(UTF32CSE, buf)
    else
        cnt == 0 ? empty_utf32 : repeaterr(cnt)
    end
end


# Definitions for C compatible strings, that don't allow embedded
# '\0', and which are terminated by a '\0'

containsnul(str::Str{<:Byte_CSEs}) = containsnul(unsafe_convert(Ptr{Cchar}, str), sizeof(str))

# Check 4 characters at a time
function containsnul(str::Str{<:Word_CSEs})
    (siz = sizeof(str)) == 0 && return true
    @preserve str begin
        pnt, fin = _calcpnt(str, siz)
        while (pnt += CHUNKSZ) <= fin
            ((v = unsafe_load(pnt))%UInt16 == 0 || (v>>>16)%UInt16 == 0 ||
             (v>>>32)%UInt16 == 0 || (v>>>48) == 0) && return true
        end
        pnt - CHUNKSZ != fin &&
            ((v = (unsafe_load(pnt) | ~_mask_bytes(siz)))%UInt16 == 0 ||
             (v>>>16)%UInt16 == 0 || (v>>>32)%UInt16 == 0)
    end
end

function containsnul(str::Str{<:Quad_CSEs})
    (siz = sizeof(str)) == 0 && return true
    @preserve str begin
        pnt, fin = _calcpnt(str, siz)
        while (pnt += CHUNKSZ) <= fin
            ((v = unsafe_load(pnt))%UInt32 == 0 || (v>>>32) == 0) && return true
        end
        pnt - CHUNKSZ != fin && unsafe_load(reinterpret(Ptr{UInt32}, pnt)) == 0x00000
    end
end
