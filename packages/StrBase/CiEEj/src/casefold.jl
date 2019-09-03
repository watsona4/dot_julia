#=
Case folding for Unicode Str types

Copyright 2017-2018 Gandalf Software, Inc., Scott P. Jones
Licensed under MIT License, see LICENSE.md
=#

const _wide_upper       = ChrBase._wide_upper
const _wide_lower_latin = ChrBase._wide_lower_latin

function uppercase_first(str::MaybeSub{S}) where {C<:ASCIICSE,S<:Str{C}}
    (len = ncodeunits(str)) == 0 && return str
    @preserve str begin
        pnt = pointer(str)
        ch = get_codeunit(pnt)
        _is_lower_a(ch) || return str
        buf, out = _allocate(UInt8, len)
        unsafe_copyto!(out, pnt, len)
        set_codeunit!(out, ch - 0x20)
        Str(C, buf)
    end
end

function lowercase_first(str::MaybeSub{S}) where {C<:ASCIICSE,S<:Str{C}}
    (len = ncodeunits(str)) == 0 && return str
    @preserve str begin
        pnt = pointer(str)
        ch = get_codeunit(pnt)
        _is_upper_a(ch) || return str
        buf, out = _allocate(UInt8, len)
        unsafe_copyto!(out, pnt, len)
        set_codeunit!(out, ch + 0x20)
        Str(C, buf)
    end
end

function _upper(::Type{C}, beg::Ptr{UInt8}, off, len) where {C<:ASCIICSE}
    buf, out = _allocate(UInt8, len)
    fin = out + len
    unsafe_copyto!(out, beg, len)
    out += off
    while out < fin
        ch = get_codeunit(out)
        _is_lower_a(ch) && set_codeunit!(out, ch - 0x20)
        out += 1
    end
    Str(C, buf)
end

function _lower(::Type{C}, beg::Ptr{UInt8}, off, len) where {C<:ASCIICSE}
    buf, out = _allocate(UInt8, len)
    fin = out + len
    unsafe_copyto!(out, beg, len)
    out += off
    while out < fin
        ch = get_codeunit(out)
        _is_upper_a(ch) && set_codeunit!(out, ch + 0x20)
        out += 1
    end
    Str(C, buf)
end

function _upper(::Type{C}, beg::Ptr{UInt8}, off, len) where {C<:LatinCSE}
    buf, out = _allocate(UInt8, len)
    fin = out + len
    unsafe_copyto!(out, beg, len)
    out += off
    while out < fin
        ch = get_codeunit(out)
        _can_upper_al(ch) && set_codeunit!(out, ch - 0x20)
        out += 1
    end
    Str(C, buf)
end

function uppercase(str::MaybeSub{S}) where {C<:ASCIICSE,S<:Str{C}}
    (len = ncodeunits(str)) == 0 && return str
    @preserve str begin
        pnt = beg = pointer(str)
        fin = beg + len
        while pnt < fin
            _is_lower_a(get_codeunit(pnt)) && return _upper(C, beg, pnt-beg, len)
            pnt += 1
        end
    end
    str
end

function lowercase(str::MaybeSub{S}) where {C<:ASCIICSE,S<:Str{C}}
    (len = ncodeunits(str)) == 0 && return str
    @preserve str begin
        pnt = beg = pointer(str)
        fin = beg + len
        while pnt < fin
            _is_upper_a(get_codeunit(pnt)) && return _lower(C, beg, pnt-beg, len)
            pnt += 1
        end
    end
    str
end

function uppercase_first(str::MaybeSub{S}) where {C<:LatinCSE,S<:Str{C}}
    (len = ncodeunits(str)) == 0 && return str
    @preserve str begin
        pnt = pointer(str)
        ch = get_codeunit(pnt)
        _can_upper_al(ch) || return str
        buf, out = _allocate(UInt8, len)
        set_codeunit!(out, ch - 0x20)
        len > 1 && unsafe_copyto!(out + 1, pnt+1, len-1)
        Str(C, buf)
    end
end

# Special handling for characters that can't map into Latin1
function uppercase_first(str::MaybeSub{S}) where {C<:_LatinCSE,S<:Str{C}}
    (len = ncodeunits(str)) == 0 && return str
    @preserve str begin
        pnt = pointer(str)
        ch = get_codeunit(pnt)
        if _wide_lower_latin(ch)
            buf, out = _allocate(UInt16, len)
            _widen!(out, pnt, pnt + len)
            set_codeunit!(out, _wide_upper(ch))
            Str(_UCS2CSE, buf)
        elseif _can_upper_al(ch)
            buf8, out8 = _allocate(UInt8, len)
            len > 1 && unsafe_copyto!(out8, pnt, len)
            set_codeunit!(out8, ch - 0x20)
            Str(_LatinCSE, buf8)
        else
            str
        end
    end
end

function lowercase_first(str::MaybeSub{S}) where {C<:Latin_CSEs,S<:Str{C}}
    (len = ncodeunits(str)) == 0 && return str
    @preserve str begin
        pnt = pointer(str)
        ch = get_codeunit(pnt)
        _is_upper_al(ch) || return str
        buf, out = _allocate(UInt8, len)
        set_codeunit!(out, ch + 0x20)
        len > 1 && unsafe_copyto!(out+1, pnt+1, len-1)
        Str(C, buf)
    end
end

function _upper(::Type{C}, beg::Ptr{UInt8}, off, len) where {C<:_LatinCSE}
    fin = beg + len
    cur = beg + off
    # Need to scan the rest of the string to see if _widenupper needs to be called
    while cur < fin
        _wide_lower_latin(get_codeunit(cur)) && return _widenupper(beg, off, len)
        cur += 1
    end
    buf, out = _allocate(UInt8, len)
    fin = out + len
    unsafe_copyto!(out, beg, len)
    out += off
    while out < fin
        ch = get_codeunit(out)
        _can_upper_al(ch) && set_codeunit!(out, ch - 0x20)
        out += 1
    end
    Str(C, buf)
end

function _widen!(dst::Ptr{T}, src::Ptr{S}, fin::Ptr{S}) where {T<:CodeUnitTypes, S<:CodeUnitTypes}
    while src < fin
        set_codeunit!(dst, get_codeunit(src)%T)
        dst += sizeof(T)
        src += sizeof(S)
    end
    nothing
end
const _narrow! = _widen!  # When this is optimized for SSE/AVX/etc. instructions, will be different

function _widenupper(beg::Ptr{UInt8}, off, len)
    buf, out = _allocate(UInt16, len)
    fin = bytoff(out, len)
    cur = beg + off
    _widen!(out, beg, cur)
    out = bytoff(out, off)
    while out < fin
        ch = get_codeunit(cur)
        set_codeunit!(out, _can_upper_al(ch) ? (ch - 0x20) : _wide_upper(ch))
        cur += 1
        out += 2
    end
    Str(_UCS2CSE, buf)
end

function uppercase(str::MaybeSub{S}) where {C<:LatinCSE,S<:Str{C}}
    (len = ncodeunits(str)) == 0 && return str
    @preserve str begin
        pnt = beg = pointer(str)
        fin = beg + len
        while pnt < fin
            _can_upper_al(get_codeunit(pnt)) && return _upper(C, beg, pnt-beg, len)
            pnt += 1
        end
    end
    str
end

function uppercase(str::MaybeSub{S}) where {C<:_LatinCSE,S<:Str{C}}
    (len = ncodeunits(str)) == 0 && return str
    @preserve str begin
        pnt = beg = pointer(str)
        fin = beg + len
        while pnt < fin
            ch = get_codeunit(pnt)
            _wide_lower_latin(ch) && return _widenupper(beg, pnt-beg, len)
            _can_upper_al(ch) && return _upper(C, beg, pnt-beg, len)
            pnt += 1
        end
    end
    str
end

function _lower(::Type{C}, beg::Ptr{UInt8}, off, len) where {C<:Latin_CSEs}
    buf, out = _allocate(UInt8, len)
    fin = out + len
    unsafe_copyto!(out, beg, len)
    out += off
    while out < fin
        ch = get_codeunit(out)
        _is_upper_al(ch) && set_codeunit!(out, ch + 0x20)
        out += 1
    end
    Str(C, buf)
end

function lowercase(str::MaybeSub{S}) where {C<:Latin_CSEs,S<:Str{C}}
    (len = ncodeunits(str)) == 0 && return str
    @preserve str begin
        pnt = beg = pointer(str)
        fin = beg + len
        while pnt < fin
            _is_upper_al(get_codeunit(pnt)) && return _lower(C, beg, pnt-beg, len)
            pnt += 1
        end
    end
    str
end

_is_latin_ucs2(len, pnt) = _check_mask_ul(pnt, len, _latin_mask(UInt16))

# result must have at least one character > 0xff, so if the only character(s)
# > 0xff became <= 0xff, then the result may need to be narrowed and returned as _LatinStr

function _lower(::Type{C}, beg, off, len) where {C<:_UCS2CSE}
    CU = codeunit(C)
    buf, out = _allocate(CU, len)
    unsafe_copyto!(out, beg, len)
    lenw = len*sizeof(CU)
    fin = out + lenw
    out += off
    flg = false
    while out < fin
        ch = get_codeunit(out)
        if ch <= 0x7f
            _is_upper_a(ch) && set_codeunit!(out, ch += 0x20)
        elseif ch <= 0xff
            _is_upper_l(ch) && set_codeunit!(out, ch += 0x20)
        elseif ch <= 0xffff
            if _can_lower_bmp(ch)
                ch = _lower_bmp(ch)
                flg = ch <= 0xff
                set_codeunit!(out, ch)
            end
        end
        out += sizeof(CU)
    end
    if flg && (src = reinterpret(Ptr{UInt16}, pointer(buf)); _is_latin_ucs2(lenw, src))
        buf8 = _allocate(len)
        _narrow!(pointer(buf8), src, src + lenw)
        Str(_LatinCSE, buf8)
    else
        Str(C, buf)
    end
end

function _lower(::Type{C}, beg, off, len) where {C<:Union{UCS2CSE,UTF32_CSEs}}
    CU = codeunit(C)
    buf, out = _allocate(CU, len)
    unsafe_copyto!(out, beg, len)
    fin = out + (len*sizeof(CU))
    out += off
    while out < fin
        ch = get_codeunit(out)
        if ch <= 0xff
            _is_upper_al(ch) && set_codeunit!(out, ch += 0x20)
        elseif ch <= 0xffff
            _can_lower_bmp(ch) && set_codeunit!(out, _lower_bmp(ch))
        elseif ch <= 0x1ffff
            _can_lower_slp(ch) && set_codeunit!(out, _lower_slp(ch))
        end
        out += sizeof(CU)
    end
    Str(C, buf)
end

function lowercase_first(str::MaybeSub{S}) where {C<:_UCS2CSE,S<:Str{C}}
    (len = ncodeunits(str)) == 0 && return str
    @preserve str begin
        pnt = pointer(str)
        ch = get_codeunit(pnt)
        (ch <= 0xff ? _is_upper_al(ch) : ch <= 0xffff ? _can_lower_bmp(ch) :
         (ch <= 0x1ffff && _can_lower_slp(ch))) ||
         return str
        cl = _lowercase(ch)
        if ch > 0xff && cl <= 0xff && _check_mask_ul(pnt+1, len-1, _latin_mask(UInt16))
            buf8, out8 = _allocate(UInt8, len)
            len > 1 && _narrow!(out8, pnt, pnt + len)
            set_codeunit!(out8, cl)
            Str(_LatinCSE, buf8)
        else
            buf, out = _allocate(codeunit(C), len)
            len > 1 && unsafe_copyto!(out, pnt, len)
            set_codeunit!(out, cl)
            Str(C, buf)
        end
    end
end

function uppercase_first(str::MaybeSub{S}) where {C<:Union{UCS2_CSEs,UTF32_CSEs},S<:Str{C}}
    (len = ncodeunits(str)) == 0 && return str
    @preserve str begin
        pnt = pointer(str)
        ch = get_codeunit(pnt)
        cp = _titlecase(ch)
        ch == cp && return str
        buf, out = _allocate(codeunit(C), len)
        len > 1 && unsafe_copyto!(out, pnt, len)
        set_codeunit!(out, cp)
        Str(C, buf)
    end
end

function lowercase_first(str::MaybeSub{S}) where {C<:Union{UCS2CSE,UTF32_CSEs},S<:Str{C}}
    (len = ncodeunits(str)) == 0 && return str
    @preserve str begin
        pnt = pointer(str)
        ch = get_codeunit(pnt)
        _can_lower_ch(ch) || return str
        buf, out = _allocate(codeunit(C), len)
        len > 1 && unsafe_copyto!(out, pnt, len)
        set_codeunit!(out, _lowercase(ch))
        Str(C, buf)
    end
end

function lowercase(str::MaybeSub{S}) where {C<:Union{UCS2_CSEs,UTF32_CSEs},S<:Str{C}}
    @preserve str begin
        CU = codeunit(C)
        pnt = beg = pointer(str)
        fin = beg + sizeof(str)
        while pnt < fin
            _can_lower_ch(get_codeunit(pnt)) && return _lower(C, beg, pnt-beg, ncodeunits(str))
            pnt += sizeof(CU)
        end
    end
    str
end

function _upper(::Type{C}, beg, off, len) where {C<:Union{UCS2_CSEs,UTF32_CSEs}}
    CU = codeunit(C)
    buf, out = _allocate(CU, len)
    unsafe_copyto!(out, beg, len)
    fin = out + (len*sizeof(CU))
    out += off
    while out < fin
        ch = get_codeunit(out)
        if ch <= 0x7f
            _is_lower_a(ch) && set_codeunit!(out, ch -= 0x20)
        elseif ch <= 0xff
            set_codeunit!(out, _uppercase_l(ch))
        elseif ch <= 0xffff
            _can_upper_bmp(ch) && set_codeunit!(out, _upper_bmp(ch))
        elseif ch <= 0x1ffff
            _can_upper_slp(ch) && set_codeunit!(out, _upper_slp(ch))
        end
        out += sizeof(CU)
    end
    Str(C, buf)
end

function uppercase(str::MaybeSub{S}) where {C<:Union{UCS2_CSEs,UTF32_CSEs},S<:Str{C}}
    @preserve str begin
        CU = codeunit(C)
        pnt = beg = pointer(str)
        fin = beg + sizeof(str)
        while pnt < fin
            _can_upper_ch(get_codeunit(pnt)) && return _upper(C, beg, pnt-beg, ncodeunits(str))
            pnt += sizeof(CU)
        end
        str
    end
end
