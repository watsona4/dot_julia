#=
Case folding for UTF-16 encoded strings

Copyright 2018 Gandalf Software, Inc., Scott P. Jones
Licensed under MIT License, see LICENSE.md
=#

# These are more complex, and maybe belong in a separate UTF16Str.jl package

function _lower(::Type{<:Str{UTF16CSE}}, beg, off, len)
    buf, out = _allocate(UInt16, len)
    unsafe_copyto!(out, beg, len)
    fin = out + (len<<1)
    out += off
    while out < fin
        ch = get_codeunit(out)
        if ch <= 0xff
            _is_upper_al(ch) && set_codeunit!(out, ch += 0x20)
        elseif is_surrogate_trail(ch)
            # pick up previous code unit (lead surrogate)
            cp = get_supplementary(get_codeunit(out - 2), ch)
            if cp < 0x1ffff && _can_lower_slp(cp)
                w1, w2 = get_utf16(_lower_slp(cp))
                set_codeunit!(out - 2, w1)
                set_codeunit!(out,     w2)
            end
        elseif _can_lower_bmp(ch)
            set_codeunit!(out, _lower_bmp(ch))
        end
        out += 2
    end
    Str(UTF16CSE, buf)
end

function lowercase(str::MaybeSub{S}) where {C<:UTF16CSE,S<:Str{C}}
    @preserve str begin
        pnt = beg = pointer(str)
        fin = beg + sizeof(str)
        while pnt < fin
            ch = get_codeunit(pnt)
            prv = pnt
            (ch <= 0xff ? _is_upper_al(ch) :
             (is_surrogate_lead(ch)
              ? (cp = get_supplementary(ch, get_codeunit(pnt += 2));
                 cp <= 0x1ffff && _can_lower_slp(cp))
              : _can_lower_bmp(ch))) &&
                  return _lower(UTF16Str, beg, prv-beg, ncodeunits(str))
            pnt += 2
        end
    end
    str
end

function lowercase_first(str::MaybeSub{S}) where {C<:UTF16CSE,S<:Str{C}}
    (len = ncodeunits(str)) == 0 && return str
    @preserve str begin
        pnt = pointer(str)
        ch = get_codeunit(pnt)
        if ch <= 0x7f
            _is_upper_al(ch) || return str
            ch += 0x20
            buf, out = _allocate(codeunit(C), len)
            len > 1 && unsafe_copyto!(out, pnt, len)
        elseif is_surrogate_lead(ch)
            cp = get_supplementary(ch, get_codeunit(pnt + 2))
            (cp <= 0x1ffff && _can_lower_slp(cp)) || return str
            ch, c2 = get_utf16(_lower_slp(cp))
            buf, out = _allocate(codeunit(C), len)
            len > 1 && unsafe_copyto!(out, pnt, len)
            set_codeunit!(out + 2, c2)
        else
            _can_lower_ch(ch) || return str
            ch = _lowercase(ch)
            buf, out = _allocate(codeunit(C), len)
            len > 1 && unsafe_copyto!(out, pnt, len)
        end
        set_codeunit!(out, ch)
        Str(C, buf)
    end
end

function _upper(::Type{<:Str{UTF16CSE}}, beg, off, len)
    buf, out = _allocate(UInt16, len)
    unsafe_copyto!(out, beg, len)
    fin = out + (len<<1)
    out += off
    while out < fin
        ch = get_codeunit(out)
        if ch <= 0x7f
            _is_lower_a(ch) && set_codeunit!(out, ch -= 0x20)
        elseif ch <= 0xff
            set_codeunit!(out, _uppercase_l(ch))
        elseif is_surrogate_trail(ch)
            # pick up previous code unit (lead surrogate)
            cp = get_supplementary(get_codeunit(out - 2), ch)
            if cp <= 0x1ffff && _can_upper_slp(cp)
                w1, w2 = get_utf16(_upper_slp(cp))
                set_codeunit!(out - 2, w1)
                set_codeunit!(out,     w2)
            end
        elseif _can_upper_bmp(ch)
            set_codeunit!(out, _upper_bmp(ch))
        end
        out += 2
    end
    Str(UTF16CSE, buf)
end

function uppercase(str::MaybeSub{S}) where {C<:UTF16CSE,S<:Str{C}}
    @preserve str begin
        pnt = beg = pointer(str)
        fin = beg + sizeof(str)
        while pnt < fin
            ch = get_codeunit(pnt)
            prv = pnt
            if (ch <= 0x7f ? _is_lower_a(ch) : ch <= 0xff ? _can_upper_lat(ch) :
                (is_surrogate_lead(ch)
                 ? (cp = get_supplementary(ch, get_codeunit(pnt += 2));
                    cp <= 0x1ffff && _can_upper_slp(cp))
                 : _can_upper_bmp(ch)))
                return _upper(UTF16Str, beg, prv-beg, ncodeunits(str))
            end
            pnt += 2
        end
    end
    str
end

function uppercase_first(str::MaybeSub{S}) where {C<:UTF16CSE,S<:Str{C}}
    (len = ncodeunits(str)) == 0 && return str
    @preserve str begin
        pnt = pointer(str)
        ch = get_codeunit(pnt)
        if ch <= 0x7f
            _is_lower_a(ch) || return str
            ch -= 0x20
            buf, out = _allocate(codeunit(C), len)
            len > 1 && unsafe_copyto!(out, pnt, len)
        elseif is_surrogate_lead(ch)
            cp = get_supplementary(ch, get_codeunit(pnt + 2))
            (cp <= 0x1ffff && _can_upper_slp(cp)) || return str
            buf, out = _allocate(codeunit(C), len)
            len > 1 && unsafe_copyto!(out, pnt, len)
            ch, c2 = get_utf16(_upper_slp(cp))
            set_codeunit!(out + 2, c2)
        else
            cp = ch
            (ch = _titlecase(ch)) == cp && return str
            buf, out = _allocate(codeunit(C), len)
            len > 1 && unsafe_copyto!(out, pnt, len)
        end
        set_codeunit!(out, ch)
        Str(C, buf)
    end
end
