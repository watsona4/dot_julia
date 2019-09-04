#
# misc.jl --
#
# Implement XPA configuration methods and miscellaneous methods.
#
#------------------------------------------------------------------------------
#
# This file is part of XPA.jl released under the MIT "expat" license.
# Copyright (C) 2016-2019, Éric Thiébaut (https://github.com/emmt/XPA.jl).
#

#------------------------------------------------------------------------------
# CONFIGURATION METHODS

# The following default values are defined in "xpap.c" and can be changed by
# user environment variables.
const _DEFAULTS = Dict{String,Any}("XPA_MAXHOSTS" => 100,
                                   "XPA_SHORT_TIMEOUT" => 15,
                                   "XPA_LONG_TIMEOUT" => 180,
                                   "XPA_CONNECT_TIMEOUT" => 10,
                                   "XPA_TMPDIR" => "/tmp/.xpa",
                                   "XPA_VERBOSITY" => true,
                                   "XPA_IOCALLSXPA" => false)

"""
```julia
XPA.getconfig(key) -> val
```

yields the value associated with configuration parameter `key` (a string or a
symbol).  The following parameters are available (see XPA doc. for more
information):

| Key Name                | Default Value |
|:----------------------- |:------------- |
| `"XPA_MAXHOSTS"`        | `100`         |
| `"XPA_SHORT_TIMEOUT"`   | `15`          |
| `"XPA_LONG_TIMEOUT"`    | `180`         |
| `"XPA_CONNECT_TIMEOUT"` | `10`          |
| `"XPA_TMPDIR"`          | `"/tmp/.xpa"` |
| `"XPA_VERBOSITY"`       | `true`        |
| `"XPA_IOCALLSXPA"`      | `false`       |

Also see [`XPA.setconfig!`](@ref).

"""
function getconfig(key::AbstractString)
    haskey(_DEFAULTS, key) || error("unknown XPA parameter \"$key\"")
    def = _DEFAULTS[key]
    if haskey(ENV, key)
        val = haskey(ENV, key)
        return (isa(def, Bool) ? (parse(Int, val) != 0) :
                isa(def, Integer) ? parse(Int, val) :
                isa(def, AbstractString) ? val :
                error("unexpected type $(typeof(def)) for default value of \"$key\""))
    else
        return def
    end
end

"""
```julia
XPA.setconfig!(key, val) -> oldval
```

set the value associated with configuration parameter `key` to be `val`.  The
previous value is returned.

Also see [`XPA.getconfig`](@ref).

"""
function setconfig!(key::AbstractString,
                    val::T) where {T<:Union{Integer,Bool,AbstractString}}
    global _DEFAULTS, ENV
    old = getconfig(key) # also check validity of key
    def = _DEFAULTS[key]
    if isa(def, Integer) && isa(val, Integer)
        ENV[key] = string(val)
    elseif isa(def, Bool) && isa(val, Bool)
        ENV[key] = (val ? "1" : "0")
    elseif isa(def, AbstractString) && isa(val, AbstractString)
        ENV[key] = val
    else
        error("invalid type for XPA parameter \"$key\"")
    end
    return old
end

getconfig(key::Symbol) = getconfig(string(key))
setconfig!(key::Symbol, val) = setconfig!(string(key), val)

@deprecate config(key::AbstractString) getconfig(key)
@deprecate config!(key::AbstractString, val) setconfig!(key, val)

#------------------------------------------------------------------------------
# PRIVATE METHODS

"""
Private methods:

```julia
_get_field(T, ptr, off, def)
```

and

```julia
_get_field(T, ptr, off1, off2, def)
```

retrieve a field of type `T` at offset `off` (in bytes) with respect to address
`ptr`.  If two offsets are given, the first one refers to a pointer with
respect to which the second is applied.  If `ptr` is NULL, `def` is returned.

"""
_get_field(::Type{T}, ptr::Ptr{Cvoid}, off::Int, def::T) where {T} =
    (ptr == C_NULL ? def : unsafe_load(convert(Ptr{T}, ptr + off)))

_get_field(::Type{String}, ptr::Ptr{Cvoid}, off::Int, def::String) =
    (ptr == C_NULL ? def : unsafe_string(convert(Ptr{Ptr{Byte}}, ptr + off)))

function _get_field(::Type{T}, ptr::Ptr{Cvoid}, off1::Int, off2::Int,
                    def::T) where {T}
    _get_field(T, _get_field(Ptr{Cvoid}, ptr, off1, C_NULL), off2, def)
end

function _set_field(::Type{T}, ptr::Ptr{Cvoid}, off::Int, val) where {T}
    @assert ptr != C_NULL
    unsafe_store!(convert(Ptr{T}, ptr + off), val)
end

_get_comm(xpa::Handle) =
    _get_field(Ptr{Cvoid}, xpa.ptr, _offsetof_comm, C_NULL)

for (memb, T, def) in ((:name,      String, ""),
                       (:class,     String, ""),
                       (:send_mode, Cint,   Cint(0)),
                       (:recv_mode, Cint,   Cint(0)),
                       (:method,    String, ""),
                       (:sendian,   String, "?"))
    off = Symbol(:_offsetof_, memb)
    func = Symbol(:get_, memb)
    @eval begin
        $func(xpa::Handle) = _get_field($T, xpa.ptr, $off, $def)
    end
end

for (memb, T, def) in ((:comm_status,  Cint,       Cint(0)),
                       (:comm_cmdfd,   Cint,       Cint(-1)),
                       (:comm_datafd,  Cint,       Cint(-1)),
                       (:comm_ack,     Cint,       Cint(1)),
                       (:comm_cendian, String,     "?"),
                       (:comm_buf,     Ptr{Byte},  NULL),
                       (:comm_len,     Csize_t,    Csize_t(0)))
    off = Symbol(:_offsetof_, memb)
    func = Symbol(:get_, memb)
    @eval begin
        $func(xpa::Handle) = _get_field($T, _get_comm(xpa), $off, $def)
    end
    if memb == :comm_buf || memb == :comm_len
        func = Symbol(:_set_, memb)
        @eval begin
            $func(xpa::Handle, val) =
                unsafe_store!(convert(Ptr{$T}, _get_comm(xpa) + $off), val)
        end
    end
end

"""
```julia
_malloc(len)
```

dynamically allocates `len` bytes and returns the corresponding byte pointer
(type `Ptr{UInt8}`).

"""
function _malloc(len::Integer) :: Ptr{Byte}
    ptr = ccall(:malloc, Ptr{Byte}, (Csize_t,), len)
    ptr != NULL || throw(OutOfMemoryError())
    return ptr
end

"""
```julia
_free(ptr)
```

frees dynamically allocated memory at address givne by `ptr` unless it is NULL.

"""
_free(ptr::Ptr{T}) where T =
    (ptr == Ptr{T}(0) || ccall(:free, Cvoid, (Ptr{T},), ptr))

"""
```julia
_memcpy!(dst, src, len)` -> dst
```

copies `len` bytes from address `src` to `dst` and return `dst` as a byte
pointer (type `Ptr{UInt8}`).

"""
_memcpy!(dst::Ptr, src::Ptr, len::Integer) :: Ptr{Byte} =
    ccall(:memcpy, Ptr{Byte}, (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t), dst, src, len)
