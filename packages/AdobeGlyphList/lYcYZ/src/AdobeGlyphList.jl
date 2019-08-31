module AdobeGlyphList

export  aglfn,
        agl,
        zapfdingbats

using DelimitedFiles
using Pkg

load_file(filename) = readdlm(filename, ';', String, '\n', comments=true, comment_char='#')

to_uint16(x) = parse(UInt16, x, base=16)

"""
```
    aglfn() -> Matrix{Any}
```
    Returns the mapping of glyph code to unicode character code for new fonts.
"""
function aglfn()
    path = joinpath(@__DIR__, "..", "aglfn.txt")
    a = load_file(path)
    b = similar(a, Any)
    b[:, 2:3] = a[:, 2:3]
    b[:, 1]   = map(x->Char(to_uint16(x)), a[:, 1])
    return b
end

"""
```
    agl() -> Matrix{Any}
```
    Returns the mapping of glyph code to unicode character code.
"""
function agl()
    path = joinpath(@__DIR__, "..", "glyphlist.txt")
    a = load_file(path)
    b = similar(a, Any)
    b[:, 1] = a[:, 1]
    b[:, 2] = map(a[:, 2]) do x
        y = split(x, ' ')[1]
        return Char(to_uint16(y))
    end
    return b
end

"""
```
    zapfdingbats() -> Matrix{Any}
```
    Returns the mapping of glyph code to unicode character code.
"""
function zapfdingbats()
    path = joinpath(@__DIR__, "..", "zapfdingbats.txt")
    a = load_file(path)
    b = similar(a, Any)
    b[:, 1] = a[:, 1]
    b[:, 2] = map(x->Char(to_uint16(x)), a[:, 2])
    return b
end

end
