#=
Low-level wrapper for PCRE2 library

Copyright 2018 Gandalf Software, Inc., Scott P. Jones, and contributors to pcre.jl and pcre2.h
(Based in part on julia/base/pcre.jl, and on pcre2.h (copyright University of Cambridge))
Licensed under MIT License, see LICENSE.md
=#

__precompile__()
module PCRE2

import Libdl

# Load in `deps.jl`, complaining if it does not exist
const depsjl_path = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if !isfile(depsjl_path)
    error("PCRE2 not installed properly, run Pkg.build(\"PCRE2\"), restart Julia and try again")
end
include(depsjl_path)

PCRE_LOCK = nothing

# Module initialization function
function __init__()
    # Always check your dependencies from `deps.jl`
    check_deps()
    @static if isdefined(Base.PCRE, :PCRE_COMPILE_LOCK)
        global PCRE_LOCK = Base.PCRE.PCRE_COMPILE_LOCK
    else
        global PCRE_LOCK = Threads.SpinLock()
    end
end

const CodeUnitTypes = Union{UInt8, UInt16, UInt32}

import Base.GC: @preserve
evr(str, rep, sub) = Core.eval(@__MODULE__, Meta.parse(replace(str, rep => sub)))
const _ncodeunits = ncodeunits
create_vector(T, len)  = Vector{T}(undef, len)

import Base: RefValue

include("pcre2_h.jl")
include("pcre2_api.jl")

# Create Julia bindings to PCRE2 C API

for siz in (8,16,32), (nam, ret, sig) in funclist
    l = SubString("a,b,c,d,e,f,g,h,i,j,k,l,m", 1, length(sig)*2-1)
    #parms = string(["$('a'+i-1)::$(sig[i]), " for i=1:length(sig)]...)[1:end-1]
    sub = "UInt$siz"
    str = "$nam(::Type{$sub},$l)=ccall((:pcre2_$(nam)_$siz, libpcre2_$siz),$ret,$sig,$l)"
    evr(str, "PCRE2._UCHAR", sub)
end

const UNSET = ~Csize_t(0)  # Indicates that an output vector element is unset

struct PCRE2_Error <: Exception
    errmsg::String
    errno::Int32
    erroff::Int32
    PCRE2_Error(errmsg, errno, erroff = -1) = new(errmsg, errno%Int32, erroff%Int32)
end

Base.show(io::IO, exc::PCRE2_Error) =
    print(io, "PCRE2: ", exc.errmsg,
          exc.errno < 0 ? "" : "error: $(err_message(exc.errno))",
          exc.erroff < 0 ? "" : "at offset $(exc.erroff)")

pcre_error(msg::AbstractString) = throw(PCRE2_Error(msg, -1))
pcre_error(errno::Integer)      = throw(PCRE2_Error("", errno))
jit_error(errno::Integer)       = throw(PCRE2_Error("JIT ", errno))
compile_error(errno, erroff)    = throw(PCRE2_Error("compilation ", errno, erroff))

function info_error(errno)
    errno == Base.PCRE.ERROR_NULL && pcre_error("NULL regex object")
    errno == Base.PCRE.ERROR_BADMAGIC && pcre_error("Invalid regex object")
    errno == Base.PCRE.ERROR_BADOPTION && pcre_error("Invalid option flags")
    pcre_error(errno)
end

"""PCRE2 pattern_info call wrapper"""
function info(::Type{T}, regex::CodeP, what::INFO, ::Type{S}) where {S,T<:CodeUnitTypes}
    buf = RefValue{S}()
    ret = pattern_info(T, regex, what, buf)
    ret == 0 ? buf[] : info_error(ret)
end

get_ovec(::Type{T}, md) where {T<:CodeUnitTypes} =
    unsafe_wrap(Array, get_ovector_pointer(T, md), 2 * get_ovector_count(T, md))

"""Wrapper for compile() function, throw error on error return with error info"""
function compile(pattern::T, options::Integer) where {T<:AbstractString}
    errno = RefValue{Cint}(0)
    erroff = RefValue{Csize_t}(0)
    re_ptr = compile(codeunit(T), pattern, _ncodeunits(pattern), options, errno, erroff, C_NULL)
    re_ptr == C_NULL ? compile_error(errno[], erroff[]) : re_ptr
end

"""Wrapper for jit_compile() function, throw error on error return with error info"""
jit_compile(::Type{T}, regex::CodeP) where {T<:CodeUnitTypes} =
    ((errno = jit_compile(T, regex, JIT_COMPLETE)) == 0 || jit_error(errno) ; nothing)

function err_message(errno)
    buffer = create_vector(UInt8, 256)
    get_error_message(UInt8, errno, buffer, sizeof(buffer))
    @preserve buffer unsafe_string(pointer(buffer))
end

function sub_length_bynumber(::Type{T}, match_data, num) where {T<:CodeUnitTypes}
    s = RefValue{Csize_t}()
    rc = substring_length_bynumber(T, match_data, num, s)
    rc < 0 ? pcre_error(rc) : convert(Int, s[])
end

function sub_copy_bynumber(::Type{T}, match_data, num, buf, siz::Integer) where {T<:CodeUnitTypes}
    s = RefValue{Csize_t}(siz)
    rc = substring_copy_bynumber(T, match_data, num, buf, s)
    rc < 0 ? pcre_error(rc) : convert(Int, s[])
end

function capture_names(T, re)
    name_count = info(T, re, INFO_NAMECOUNT, UInt32)
    name_entry_size = info(T, re, INFO_NAMEENTRYSIZE, UInt32)
    nametable_ptr = info(T, re, INFO_NAMETABLE, Ptr{UInt8})
    names = Dict{Int, String}()
    for i=1:name_count
        offset = (i-1)*name_entry_size + 1
        # The capture group index corresponding to name 'i' is stored as a
        # big-endian 16-bit value.
        high_byte = UInt16(unsafe_load(nametable_ptr, offset))
        low_byte = UInt16(unsafe_load(nametable_ptr, offset+1))
        idx = (high_byte << 8) | low_byte
        # The capture group name is a null-terminated string located directly
        # after the index.
        names[idx] = unsafe_string(nametable_ptr+offset+1)
    end
    names
end

end # module PCRE2
