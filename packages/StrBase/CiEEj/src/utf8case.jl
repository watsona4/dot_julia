#=
Copyright 2018 Gandalf Software, Inc., Scott P. Jones
Licensed under MIT License, see LICENSE.md
=#

const CT = ChrBase.CaseTables

function _check_char(ch, tab)
    cmp = ch & ~0x001f
    for (c, mask) in tab
        cmp < c && break
        cmp == c && return ((mask%Int64) << (62 - ((ch & 0x1f)<<1))) >> 62
    end
    0
end

function _calc_len(pnt, fin, len, mask, tab)
    while pnt < fin
        ch = get_codeunit(pnt)
        if ch < 0xf0
            if ch > 0x7f
                c16 = ch < 0xe0 ? get_utf8_2byte(pnt += 1, ch) : get_utf8_3byte(pnt += 2, ch)
                ((mask >>> (c16 >>> 9)) & 1) != 0 && (len += _check_char(c16, tab))
            end
            pnt += 1
        else
            pnt += 4 # no 4 byte changes size in UTF-8
        end
    end
    len
end

# These are more complex case folding functions, and maybe belong in a separate UTF8Str.jl package

# Note: these only check for cases in Unicode where 2 byte sequences
# could expand to 3 byte sequences.  In the standard Unicode tables,
# that is the only expansion that occurs for upper or lower case

function _lower_utf8(beg, off, len)
    # Note, the final length may be larger or smaller
    fin = beg + len
    pnt = beg + off
    # Calculate final length
    len = _calc_len(pnt, fin, len, CT.ct.siz_l_flg, CT.sizvecl)
    buf, out = _allocate(UInt8, len)
    unsafe_copyto!(out, beg, off)
    out += off
    pnt = beg + off
    while pnt < fin
        ch = get_codeunit(pnt)
        if ch < 0x80
            set_codeunit!(out, ch + (_is_upper_a(ch) << 5))
            out += 1
        elseif ch < 0xc4
            ch = (ch << 6) | (get_codeunit(pnt += 1) & 0x3f)
            out = output_utf8_2byte!(out, ch + (_is_upper_l(ch) << 5))
        elseif ch < 0xe0
            # 2 byte
            c16 = get_utf8_2byte(pnt += 1, ch)
            if _can_lower_bmp(c16)
                c16 = _lower_bmp(c16)
                if c16 < 0x80
                    set_codeunit!(out, c16%UInt8)
                    out += 1
                elseif c16 < 0x800
                    out = output_utf8_2byte!(out, c16)
                else
                    out = output_utf8_3byte!(out, c16)
                end
            else
                out = output_utf8_2byte!(out, c16)
            end
        elseif ch < 0xf0
            # 3 byte
            c16 = get_utf8_3byte(pnt += 2, ch)
            if _can_lower_bmp(c16)
                c16 = _lower_bmp(c16)
                if c16 < 0x800
                    out = output_utf8_2byte!(out, c16)
                else
                    out = output_utf8_3byte!(out, c16)
                end
            else
                out = output_utf8_3byte!(out, c16)
            end
        else
            # 4 byte
            c32 = get_utf8_4byte(pnt += 3, ch)
            c32 <= 0x1ffff && _can_lower_slp(c32) && (c32 = _lower_slp(c32))
            out = output_utf8_4byte!(out, c32)
        end
        pnt += 1
    end
    Str(UTF8CSE, buf)
end

function _upper_utf8(beg, off, len)
    fin = beg + len
    pnt = beg + off
    # Note, the final length may be larger or smaller
    len = _calc_len(pnt, fin, len, CT.ct.siz_u_flg, CT.sizvecu)

    buf, out = _allocate(UInt8, len)
    unsafe_copyto!(out, beg, off)
    out += off
    while pnt < fin
        ch = get_codeunit(pnt)
        if ch < 0x80
            set_codeunit!(out, ch - (_is_lower_a(ch)<<5))
            out += 1
        elseif ch < 0xc4
            ch = (ch << 6) | (get_codeunit(pnt += 1) & 0x3f)
            out = (ch == 0xdf
                   ? output_utf8_3byte!(out, 0x1e9e)
                   : output_utf8_2byte!(out, _upper_bmp(ch)))
        elseif ch < 0xe0
            # 2 byte
            c16 = get_utf8_2byte(pnt += 1, ch)
            if _can_upper_bmp(c16)
                c16 = _upper_bmp(c16)
                # Check if still 2 byte, could increase to 3 byte, or decrease to 1 byte
                if c16 < 0x80
                    set_codeunit!(out, c16%UInt8)
                    out += 1
                elseif c16 < 0x800
                    out = output_utf8_2byte!(out, c16)
                else
                    out = output_utf8_3byte!(out, c16)
                end
            else
                out = output_utf8_2byte!(out, c16)
            end
        elseif ch < 0xf0
            # 3 byte
            c16 = get_utf8_3byte(pnt += 2, ch)
            if _can_upper_bmp(c16)
                c16 = _upper_bmp(c16)
                # Check if still 3 byte, uppercase form could drop to 2 byte
                out = (c16 < 0x800) ? output_utf8_2byte!(out, c16) : output_utf8_3byte!(out, c16)
            else
                out = output_utf8_3byte!(out, c16)
            end
        else
            # 4 byte
            c32 = get_utf8_4byte(pnt += 3, ch)
            c32 <= 0x1ffff && _can_upper_slp(c32) && (c32 = _upper_slp(c32))
            out = output_utf8_4byte!(out, c32)
        end
        pnt += 1
    end
    Str(UTF8CSE, buf)
end

function lowercase(str::MaybeSub{S}) where {C<:UTF8CSE,S<:Str{C}}
    @preserve str begin
        pnt = beg = pointer(str)
        fin = beg + sizeof(str)
        while pnt < fin
            ch = get_codeunit(pnt)
            prv = pnt
            (ch < 0x80
             ? _is_upper_a(ch)
             : (ch < 0xc4
                ? _is_upper_l((ch << 6) | (get_codeunit(pnt += 1) & 0x3f))
                : _can_lower_ch(ch >= 0xf0
                                ? get_utf8_4byte(pnt += 3, ch)
                                : (ch < 0xe0
                                   ? get_utf8_2byte(pnt += 1, ch)
                                   : get_utf8_3byte(pnt += 2, ch))%UInt32))) &&
                            return _lower_utf8(beg, prv-beg, ncodeunits(str))
            pnt += 1
        end
        str
    end
end

function lowercase_first(str::MaybeSub{S}) where {C<:UTF8CSE,S<:Str{C}}
    (len = ncodeunits(str)) == 0 && return str
    @preserve str begin
        pnt = pointer(str)
        ch = get_codeunit(pnt)
        if ch <= 0x7f
            _is_upper_a(ch) || return str
            buf, out = _allocate(UInt8, len)
            len > 1 && unsafe_copyto!(out, pnt, len)
            set_codeunit!(out, ch + 0x20)
        elseif ch < 0xf0
            siz = 2 + (ch >= 0xe0)
            c16 = (ch < 0xe0 ? get_utf8_2byte(pnt + 1, ch) : get_utf8_3byte(pnt + 2, ch))
            _can_lower_bmp(c16) || return str
            # BMP characters might change size on lowercasing
            #print("lf: $c16")
            c16 = _lower_bmp(c16)
            ns = 1 + (c16 >= 0x80) + (c16 >= 0x800)
            buf, out = _allocate(UInt8, len - siz + ns)
            len > siz && unsafe_copyto!(out + ns, pnt + siz, len - siz)
            #println(" => $c16 len=$len ns=$ns siz=$siz out=$out pnt=$pnt $buf")
            (c16 < 0x80
             ? set_codeunit!(out, c16%UInt8)
             : (c16 < 0x800
                ? output_utf8_2byte!(out, c16)
                : output_utf8_3byte!(out, c16)))
            #println(" => $buf")
        else
            c32 = get_utf8_4byte(pnt + 3, ch)
            (c32 <= 0x1ffff && _can_lower_slp(c32)) || return str
            buf, out = _allocate(UInt8, len)
            len > 4 && unsafe_copyto!(out + 4, pnt + 4, len - 4)
            output_utf8_4byte!(out, _lower_slp(c32))
        end
        Str(C, buf)
    end
end

# Check if can be uppercased
@inline function _check_uppercase(ch, pnt)
    # ch < 0xc2 && return false (not needed, validated UTF-8 string)
    cont = get_codeunit(pnt)
    ch == 0xc3 ? ((cont > 0x9e) & (cont != 0xb7)) : (cont == 0xb5)
end

function uppercase(str::MaybeSub{S}) where {C<:UTF8CSE,S<:Str{C}}
    @preserve str begin
        pnt = beg = pointer(str)
        fin = beg + sizeof(str)
        while pnt < fin
            ch = get_codeunit(pnt)
            prv = pnt
            (ch < 0x80
             ? _is_lower_a(ch)
             : (ch > 0xc3
                ? _can_upper_ch(ch >= 0xf0
                                ? get_utf8_4byte(pnt += 3, ch)
                                : (ch < 0xe0
                                   ? get_utf8_2byte(pnt += 1, ch)
                                   : get_utf8_3byte(pnt += 2, ch))%UInt32)
                : _check_uppercase(ch, pnt += 1))) &&
                    return _upper_utf8(beg, prv-beg, ncodeunits(str))
            pnt += 1
        end
        str
    end
end

function uppercase_first(str::MaybeSub{S}) where {C<:UTF8CSE,S<:Str{C}}
    (len = ncodeunits(str)) == 0 && return str
    @preserve str begin
        pnt = pointer(str)
        ch = get_codeunit(pnt)
        if ch <= 0x7f
            _is_lower_a(ch) || return str
            buf, out = _allocate(UInt8, len)
            len > 1 && unsafe_copyto!(out, pnt, len)
            set_codeunit!(out, ch - 0x20)
        elseif ch < 0xf0
            siz = 2 + (ch >= 0xe0)
            c16 = (ch < 0xe0 ? get_utf8_2byte(pnt + 1, ch) : get_utf8_3byte(pnt + 2, ch))
            (tc = _titlecase(c16)) == c16 && return str
            # BMP characters might change size on titlecasing
            ns = 1 + (tc >= 0x80) + (tc >= 0x800)
            buf, out = _allocate(UInt8, len - siz + ns)
            len > siz && unsafe_copyto!(out + ns, pnt + siz, len - siz)
            (tc < 0x80
             ? set_codeunit!(out, tc%UInt8)
             : (tc < 0x800
                ? output_utf8_2byte!(out, tc)
                : output_utf8_3byte!(out, tc)))
        else
            c32 = get_utf8_4byte(pnt + 3, ch)
            (c32 <= 0x1ffff && _can_upper_slp(c32)) || return str
            buf, out = _allocate(UInt8, len)
            len > 4 && unsafe_copyto!(out + 4, pnt + 4, len - 4)
            output_utf8_4byte!(out, _upper_slp(c32))
        end
        Str(C, buf)
    end
end
