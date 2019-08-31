#=
Case folding for Unicode Chr types

Copyright 2017-2018 Gandalf Software, Inc., Scott P. Jones
Licensed under MIT License, see LICENSE.md
=#

@inline _can_upper_lat(c) = ifelse(c > (V6_COMPAT ? 0xdf : 0xde), c != 0xf7, c == 0xb5)

_wide_lower_latin(ch) = (ch == 0xb5) | (ch == 0xff) | (!V6_COMPAT && (ch == 0xdf))

_wide_upper(ch) =
    ifelse(ch == 0xb5, 0x39c,
           ifelse(ch == 0xff, 0x178, ifelse(!V6_COMPAT && ch == 0xdf, 0x1e9e, ch%UInt16)))

_lowercase_l(ch) = _is_upper_al(ch)  ? (ch + 0x20) : ch
_uppercase_l(ch) = _can_upper_al(ch) ? (ch - 0x20) : _wide_upper(ch)

lowercase(ch::T) where {T<:Chr} = T(_lowercase(codepoint(ch)))
uppercase(ch::T) where {T<:Chr} = T(_uppercase(codepoint(ch)))
titlecase(ch::T) where {T<:Chr} = T(_titlecase(codepoint(ch)))

lowercase(ch::ASCIIChr) = _is_upper_a(ch) ? ASCIIChr(ch + 0x20) : ch
uppercase(ch::ASCIIChr) = _is_lower_a(ch) ? ASCIIChr(ch - 0x20) : ch
titlecase(ch::ASCIIChr) = uppercase(ch)

lowercase(ch::T) where {T<:LatinChars} = T(_lowercase_l(codepoint(ch)))

_uppercase_latin(ch) = _can_upper_al(ch) ? (ch - 0x20) : ch
uppercase(ch::LatinChr) = LatinChr(_uppercase_latin(codepoint(ch)))

# Special handling for case where this is just an optimization of the first 256 bytes of Unicode,
# and not the 8-bit ISO 8859-1 character set
function uppercase(ch::_LatinChr)
    cb = codepoint(ch)
    _can_upper_al(cb) && return _LatinChr(cb - 0x20)
    # We didn't used to uppercase 0xdf, the ß character, now we do
    !V6_COMPAT && cb == 0xdf && return UCS2Chr(0x1e9e)
    cb == 0xb5 ? UCS2Chr(0x39c) : cb == 0xff ? UCS2Chr(0x178) : ch
end
titlecase(ch::LatinChars) = uppercase(ch)

@inline function _check_tab(mask, tab, ch)
    t = (ch >>> 9)
    ((mask >>> (t & 0x7f)) & 1) != 0 && (off = tab[t+1]) != 0 &&
        (CaseTables.bitvec[off][((ch >>> 5) & 0xf) + 1] & (UInt32(1) << (ch & 0x1f))) != 0
end

@inline _get_tab(off, ch, base) =
    off == 0 ? ch : (off = CaseTables.offvec[off][((ch >>> 5) & 0x1f) + 1]) == 0 ? ch :
    (base + CaseTables.tupvec[off][(ch & 0x1f) + 1])

@inline _get_tab_bmp(mask, tab, ch) =
    (t = (ch >>> 9); ((mask >>> t) & 1) == 0 ? ch : _get_tab(tab[(t>>1)+1], ch, 0x0000))
@inline _get_tab_slp(mask, tab, ch) =
    (t = (ch >>> 9); ((mask >>> (t & 0x7f)) & 1) == 0 ? ch : _get_tab(tab[(t>>1)+1], ch, 0x10000))

@inline _upper_lat(ch) = _get_tab(CaseTables.ct.u_tab[1], ch, 0x0000)

@inline _upper_bmp(ch) = _get_tab_bmp(CaseTables.ct.can_u_flg,  CaseTables.ct.u_tab, ch)
@inline _lower_bmp(ch) = _get_tab_bmp(CaseTables.ct.can_l_flg,  CaseTables.ct.l_tab, ch)
@inline _title_bmp(ch) = _get_tab_bmp(CaseTables.ct.can_u_flg,  CaseTables.ct.t_tab, ch)
@inline _upper_slp(ch) = _get_tab_slp(CaseTables.ct.can_su_flg, CaseTables.ct.u_tab, ch)
@inline _lower_slp(ch) = _get_tab_slp(CaseTables.ct.can_sl_flg, CaseTables.ct.l_tab, ch)

@inline _can_lower_bmp(ch) = _check_tab(CaseTables.ct.can_l_flg,  CaseTables.ct.can_l_tab, ch)
@inline _can_upper_bmp(ch) = _check_tab(CaseTables.ct.can_u_flg,  CaseTables.ct.can_u_tab, ch)
@inline _can_lower_slp(ch) = _check_tab(CaseTables.ct.can_sl_flg, CaseTables.ct.can_l_tab, ch)
@inline _can_upper_slp(ch) = _check_tab(CaseTables.ct.can_su_flg, CaseTables.ct.can_u_tab, ch)
@inline _is_lower_bmp(ch)  = _check_tab(CaseTables.ct.is_l_flg,   CaseTables.ct.is_l_tab,  ch)
@inline _is_upper_bmp(ch)  = _check_tab(CaseTables.ct.is_u_flg,   CaseTables.ct.is_u_tab,  ch)
@inline _is_lower_slp(ch)  = _check_tab(CaseTables.ct.is_sl_flg,  CaseTables.ct.is_l_tab,  ch)
@inline _is_upper_slp(ch)  = _check_tab(CaseTables.ct.is_su_flg,  CaseTables.ct.is_u_tab,  ch)

@inline _is_lower_ch(ch) =
    ch <= 0x7f ? _is_lower_a(ch) :
    ch <= 0xff ? _is_lower_l(ch) :
    ch <= 0xffff ? _is_lower_bmp(ch) :
    ch <= 0x1ffff ? _is_lower_slp(ch) : false

@inline _is_upper_ch(ch) =
    ch <= 0x7f ? _is_upper_a(ch) :
    ch <= 0xff ? _is_upper_l(ch) :
    ch <= 0xffff ? _is_upper_bmp(ch) :
    ch <= 0x1ffff ? _is_upper_slp(ch) : false

@inline _can_lower_ch(ch) =
    ch <= 0x7f ? _is_upper_a(ch) :
    ch <= 0xff ? _is_upper_l(ch) :
    ch <= 0xffff ? _can_lower_bmp(ch) :
    ch <= 0x1ffff ? _can_lower_slp(ch) : false

@inline _can_upper_ch(ch) =
    ch <= 0x7f ? _is_lower_a(ch) :
    ch <= 0xff ? _can_upper_lat(ch) :
    ch <= 0xffff ? _can_upper_bmp(ch) :
    ch <= 0x1ffff ? _can_upper_slp(ch) : false

@inline _lowercase(ch) =
    ch <= 0x7f ? (ch + (_is_upper_a(ch)<<5)) :
    ch <= 0xff ? (ch + (_is_upper_l(ch)<<5)) :
    ch <= 0xffff ? _lower_bmp(ch) :
    ch <= 0x1ffff ? _lower_slp(ch) : ch

@inline _uppercase(ch) =
    ch <= 0x7f ? (_is_lower_a(ch) ? (ch - 0x20) : ch) :
    ch <= 0xff ? _upper_lat(ch) :
    ch <= 0xffff ? _upper_bmp(ch) :
    ch <= 0x1ffff ? _upper_slp(ch) : ch

@inline _titlecase(ch) =
    ch <= 0x7f ? (_is_lower_a(ch) ? (ch - 0x20) : ch) :
    ch <= 0xff ? _upper_lat(ch) :
    ch <= 0xffff ? _title_bmp(ch) :
    ch <= 0x1ffff ? _upper_slp(ch) : ch

# 0xb5, 0xdf, and 0xff cannot be uppercased in LatinCSE, although they are lowercase
@inline _can_upper_l(c) = (0xe0 <= c <= 0xfe) & (c != 0xf7)
@inline _can_upper_al(c) = _is_lower_a(c) | _can_upper_l(c)

@api develop _is_lower_ch, _is_upper_ch, _can_lower_ch, _can_upper_ch,
             _upper_bmp, _lower_bmp, _title_bmp, _upper_slp, _lower_slp,
             _can_upper_al, _can_upper_lat, _can_lower_bmp, _can_upper_bmp,
             _can_lower_slp, _can_upper_slp
