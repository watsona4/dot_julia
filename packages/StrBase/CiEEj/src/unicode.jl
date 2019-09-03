#=
String classification, normalization and width functions

Copyright 2017-2018 Gandalf Software, Inc., Scott P. Jones,
Licensed under MIT License, see LICENSE.md
=#

# Recommended by deprecate
text_width(str::Str) = mapreduce(text_width, +, str; init=0)
Base.Unicode.normalize(str::Str, opt::Symbol) = normalize(str, opt)

############################################################################

text_width(str::Str{Union{ASCIICSE,Latin_CSEs}}) = length(str)

############################################################################

function is_latin(str::MaybeSub{String})
    (siz = sizeof(str)) == 0 && return true
    @preserve str begin
        pnt = pointer(str)
        fin = pnt + siz
        while pnt < fin
            cu = get_codeunit(pnt)
            # cu must be 1) 0-0x7f, or 2) 0xc2 or 0xc3 followed by 0x80-0xbf
            (cu < 0x7f ||
             ((cu - 0xc2) < 0x02 &&
              (pnt += 1) < fin && is_valid_continuation(get_codeunit(pnt)))) ||
              return false
            pnt += 1
        end
        true
    end
end

@inline function check_3byte(cu, pnt)
    b2 = get_codeunit(pnt-1)
    b3 = get_codeunit(pnt)
    is_valid_continuation(b2) && is_valid_continuation(b3) &&
        !is_surrogate_codeunit(_mskup32(cu, 0xf, 12) | _mskup32(b2, 0x3f, 6) | (b3 & 0x3f))
end

function is_bmp(str::MaybeSub{String})
    (siz = sizeof(str)) == 0 && return true
    @preserve str begin
        pnt = pointer(str)
        fin = pnt + siz
        while pnt < fin
            cu = get_codeunit(pnt)
            # cu must be 1) 0-0x7f, or 2) 0xc2 or 0xc3 followed by 0x80-0xbf
            # c2-df -> de,df
            (cu < 0x7f ||
             ((cu - 0xc2) < 0x1e && (pnt += 1) < fin && checkcont(pnt)) ||
             ((cu - 0xe0) < 0x0f && (pnt += 2) < fin && check_3byte(cu, pnt))) ||
             return false
             pnt += 1
        end
        true
    end
end

function is_latin(str::AbstractString)
    @inbounds for ch in str
        is_latin(ch) || return false
    end
    true
end

function is_bmp(str::AbstractString)
    @inbounds for ch in str
        is_bmp(ch) || return false
    end
    true
end

function is_unicode(str::AbstractString)
    @inbounds for ch in str
        is_unicode(ch) || return false
    end
    true
end
