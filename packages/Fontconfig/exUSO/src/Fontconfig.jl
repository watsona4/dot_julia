__precompile__()

module Fontconfig

depsfile = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if isfile(depsfile)
    include(depsfile)
else
    error("Fontconfig.jl not properly installed. Please run `Pkg.build(\"Fontconfig\")` " *
          "and restart Julia.")
end

using Compat
import Compat.Sys
using Compat.Printf

export format, match, list

function __init__()
    if isdefined(Fontconfig, :FONTCONFIG_FILE)
        ENV["FONTCONFIG_FILE"] = FONTCONFIG_FILE
    end
    ccall((:FcInit, jl_libfontconfig), UInt8, ())

    # By default fontconfig on OSX does not include user fonts.
    @static if Sys.isapple()
        ccall((:FcConfigAppFontAddDir, jl_libfontconfig),
               UInt8, (Ptr{Nothing}, Ptr{UInt8}),
               C_NULL, b"~/Library/Fonts")
    end
end


const FcMatchPattern = UInt32(0)
const FcMatchFont    = UInt32(1)
const FcMatchScan    = UInt32(2)

const string_attrs = Set([:family, :style, :foundry, :file, :lang,
                          :fullname, :familylang, :stylelang, :fullnamelang,
                          :compatibility, :fontformat, :fontfeatures, :namelang,
                          :prgname, :hash, :postscriptname])

const double_attrs = Set([:size, :aspect, :pixelsize, :scale, :dpi])

const integer_attrs =  Set([:slant, :weight, :spacing, :hintstyle, :width, :index,
                            :rgba, :fontversion, :lcdfilter])

const bool_attrs = Set([:antialias, :histing, :verticallayout, :autohint, :outline,
                        :scalable, :minspace, :embolden, :embeddedbitmap,
                        :decorative])

mutable struct Pattern
    ptr::Ptr{Nothing}

    function Pattern(; args...)
        ptr = ccall((:FcPatternCreate, jl_libfontconfig), Ptr{Nothing}, ())

        for (attr, value) in args
            if attr in string_attrs
                ccall((:FcPatternAddString, jl_libfontconfig), Cint,
                      (Ptr{Nothing}, Ptr{UInt8}, Ptr{UInt8}),
                      ptr, string(attr), value)
            elseif attr in double_attrs
                ccall((:FcPatternAddDouble, jl_libfontconfig), Cint,
                      (Ptr{Nothing}, Ptr{UInt8}, Cdouble),
                      ptr, string(attr), value)
            elseif attr in integer_attrs
                ccall((:FcPatternAddInteger, jl_libfontconfig), Cint,
                      (Ptr{Nothing}, Ptr{UInt8}, Cint),
                      ptr, string(attr), value)
            elseif attr in bool_attrs
                ccall((:FcPatternAddBool, jl_libfontconfig), Cint,
                      (Ptr{Nothing}, Ptr{UInt8}, Cint),
                      ptr, string(attr), value)
            end
        end

        pat = new(ptr)
        @compat finalizer(pat -> ccall((:FcPatternDestroy, jl_libfontconfig), Nothing,
                                    (Ptr{Nothing},), pat.ptr), pat)
        return pat
    end

    function Pattern(ptr::Ptr{Nothing})
        return new(ptr)
    end

    function Pattern(name::AbstractString)
        ptr = ccall((:FcNameParse, jl_libfontconfig), Ptr{Nothing}, (Ptr{UInt8},), name)
        pat = new(ptr)
        @compat finalizer(pat -> ccall((:FcPatternDestroy, jl_libfontconfig), Nothing,
                                    (Ptr{Nothing},), pat.ptr), pat)
        return pat
    end
end


function Base.show(io::IO, pat::Pattern)
    desc = ccall((:FcNameUnparse, jl_libfontconfig), Ptr{UInt8},
                 (Ptr{Nothing},), pat.ptr)
    @printf(io, "Fontconfig.Pattern(\"%s\")", unsafe_string(desc))
    Libc.free(desc)
end


function Base.match(pat::Pattern, default_substitute::Bool=true)
    ccall((:FcConfigSubstitute, jl_libfontconfig),
          UInt8, (Ptr{Nothing}, Ptr{Nothing}, Int32),
          C_NULL, pat.ptr, FcMatchPattern)

    if default_substitute
        ccall((:FcDefaultSubstitute, jl_libfontconfig),
              Nothing, (Ptr{Nothing},), pat.ptr)
    end

    result = Int32[0]
    mat = ccall((:FcFontMatch, jl_libfontconfig),
                Ptr{Nothing}, (Ptr{Nothing}, Ptr{Nothing}, Ptr{Int32}),
                C_NULL, pat.ptr, result)

    if result[1] != 0
        error(string("Fontconfig was unable to match font ", pat))
    end

    return Pattern(mat)
end


function format(pat::Pattern, fmt::AbstractString="%{=fclist}")
    desc = ccall((:FcPatternFormat, jl_libfontconfig), Ptr{UInt8},
                 (Ptr{Nothing}, Ptr{UInt8}), pat.ptr, fmt)
    if desc == C_NULL
        error("Invalid fontconfig format.")
    end
    descstr = unsafe_string(desc)
    Libc.free(desc)
    return descstr
end


struct FcFontSet
    nfont::Cint
    sfont::Cint
    fonts::Ptr{Ptr{Nothing}}
end


function list(pat::Pattern=Pattern())
    os = ccall((:FcObjectSetCreate, jl_libfontconfig), Ptr{Nothing}, ())
    ccall((:FcObjectSetAdd, jl_libfontconfig), Cint, (Ptr{Nothing}, Ptr{UInt8}),
          os, "family")
    ccall((:FcObjectSetAdd, jl_libfontconfig), Cint, (Ptr{Nothing}, Ptr{UInt8}),
          os, "style")
    ccall((:FcObjectSetAdd, jl_libfontconfig), Cint, (Ptr{Nothing}, Ptr{UInt8}),
          os, "file")

    fs_ptr = ccall((:FcFontList, jl_libfontconfig), Ptr{FcFontSet},
                   (Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), C_NULL, pat.ptr, os)
    fs = unsafe_load(fs_ptr)

    patterns = Pattern[]
    for i in 1:fs.nfont
        push!(patterns, Pattern(unsafe_load(fs.fonts, i)))
    end

    ccall((:FcObjectSetDestroy, jl_libfontconfig), Nothing, (Ptr{Nothing},), os)

    return patterns
end


end # module
