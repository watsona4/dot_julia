#
# client.jl --
#
# Implement XPA client methods.
#
#------------------------------------------------------------------------------
#
# This file is part of XPA.jl released under the MIT "expat" license.
# Copyright (C) 2016-2019, Éric Thiébaut (https://github.com/emmt/XPA.jl).
#

"""

`XPA.TEMPORARY` can be specified wherever an `XPA.Client` instance is expected
to use a non-persistent XPA connection.

"""
const TEMPORARY = Client(C_NULL)

"""
```julia
XPA.Client()
```

yields a persistent XPA client handle which can be used for calls to `XPA.set`
and XPA.get` methods.  Persistence means that a connection to an XPA server is
not closed when one of the above calls is completed but will be re-used on
successive calls.  Using `XPA.Client()` therefore saves the time it takes to
connect to a server, which could be significant with slow connections or if
there will be a large number of exchanges with a given access point.

See also: [`XPA.set`](@ref), [`XPA.get`](@ref)

"""
function Client()
    # The argument of XPAOpen is currently ignored (it is reserved for future
    # use).
    ptr = ccall((:XPAOpen, libxpa), Ptr{Cvoid}, (Ptr{Cvoid},), C_NULL)
    ptr != C_NULL || error("failed to create a persistent XPA connection")
    return finalizer(close, Client(ptr))
end

Base.isopen(xpa::Handle) = xpa.ptr != C_NULL

function Base.close(xpa::Client)
    if (ptr = xpa.ptr) != C_NULL
        xpa.ptr = C_NULL
        ccall((:XPAClose, libxpa), Cvoid, (Ptr{Cvoid},), ptr)
    end
    return nothing
end

"""
```julia
XPA.list(xpa=XPA.TEMPORARY)
```

yields a list of available XPA access points.  Optional argument `xpa` is a
persistent XPA client connection; if omitted, a temporary client connection
will be created.  The result is a vector of `XPA.AccessPoint` instances.

Also see: [`XPA.Client`](@ref).

"""
function list(xpa::Client = TEMPORARY)
    lst = AccessPoint[]
    for str in get_lines(xpa, "xpans")
        arr = split(str)
        if length(arr) != 5
            @warn "expecting 5 fields per access point (\"$str\")"
            continue
        end
        access = UInt(0)
        for c in arr[3]
            if c == 'g'
                access |= GET
            elseif c == 's'
                access |= SET
            elseif c == 'i'
                access |= INFO
            else
                @warn "unexpected access string (\"$(arr[3])\")"
                continue
            end
        end
        push!(lst, AccessPoint(arr[1], arr[2], arr[4], arr[5], access))
    end
    return lst
end

"""
```julia
XPA.get([xpa,] apt [, params...]) -> tup
```

retrieves data from one or more XPA access points identified by `apt` (a
template name, a `host:port` string or the name of a Unix socket file) with
parameters `params` (automatically converted into a single string where the
parameters are separated by a single space).  The result is a tuple of tuples
`(data,name,mesg)` where `data` is a vector of bytes (`UInt8`), `name` is a
string identifying the server which answered the request and `mesg` is a
textual message (a zero-length string `""` if there are no messages).  Optional
argument `xpa` specifies an XPA handle (created by [`XPA.Client`](@ref)) for
faster connections.

The following keywords are available:

* `nmax` specifies the maximum number of answers, `nmax=1` by default.
  Specify `nmax=-1` to use the maximum number of XPA hosts.

* `mode` specifies options in the form `"key1=value1,key2=value2"`.

See also: [`XPA.Client`](@ref), [`XPA.set`](@ref).

"""
function get(xpa::Client, apt::AbstractString, params::AbstractString...;
             mode::AbstractString = "", nmax::Integer = 1)
    return _get(xpa, apt, _join(params), mode, _nmax(nmax))
end

get(args::AbstractString...; kwds...) =
    get(TEMPORARY, args...; kwds...)

function _get(xpa::Client, apt::AbstractString, params::AbstractString,
              mode::AbstractString, nmax::Int)
    bufs = Vector{Ptr{Byte}}(undef, nmax)
    lens = Vector{Csize_t}(  undef, nmax)
    nams = Vector{Ptr{Byte}}(undef, nmax)
    errs = Vector{Ptr{Byte}}(undef, nmax)
    n = ccall((:XPAGet, libxpa), Cint,
              (Client, Cstring, Cstring, Cstring, Ptr{Ptr{Byte}},
               Ptr{Csize_t}, Ptr{Ptr{Byte}}, Ptr{Ptr{Byte}}, Cint),
              xpa, apt, params, mode, bufs, lens, nams, errs, nmax)
    n ≥ 0 || error("unexpected result from XPAGet")
    return ntuple(i -> (_fetch(bufs[i], lens[i]),
                        _fetch(String,  nams[i]),
                        _fetch(String,  errs[i])), n)
end

"""

Private method `_join(tup)` joins a tuple of string into a single string.
It is implemented so as to be faster than `join(tup, " ")` when `tup` has
less than 2 arguments.  It is intended to build XPA command string from
arguments.

"""
_join(args::Tuple{Vararg{AbstractString}}) = join(args, " ")
_join(args::Tuple{AbstractString}) = args[1]
_join(::Tuple{}) = ""

"""

Private method `_nmax(n)` yields the maximum number of expected answers to a
get/set request.  The result is `n` if `n ≥ 1` or `getconfig("XPA_MAXHOSTS")`
otherwise.

"""
_nmax(n::Integer) = (n == -1 ? Int(getconfig("XPA_MAXHOSTS")) : Int(n))

"""

Private method `_fetch(...)` converts a pointer into a Julia vector or a
string and let Julia manage the memory.

"""
function _fetch(ptr::Ptr{T}, nbytes::Integer)::Vector{T} where {T}
    return (ptr == convert(Ptr{T}, 0)
            ? Vector{T}(undef, 0)
            : unsafe_wrap(Array, ptr, div(nbytes, sizeof(T)), own=true))
end

_fetch(::Type{T}, ptr::Ptr, nbytes::Integer) where {T} =
    _fetch(convert(Ptr{T}, ptr), nbytes)

_fetch(ptr::Ptr{Cvoid}, nbytes::Integer) = _fetch(Byte, ptr, nbytes)

function _fetch(::Type{String}, ptr::Ptr{Byte})
    if ptr == NULL
        str = ""
    else
        str = unsafe_string(ptr)
        _free(ptr)
    end
    return str
end

function _fetch(::Type{String}, ptr::Ptr{Byte}, nbytes::Integer)
    if ptr == NULL
        str = ""
    else
        str = unsafe_string(ptr, nbytes)
        _free(ptr)
    end
    return str
end

"""
```julia
XPA.get_bytes([xpa,] apt [, params...]; mode=...) -> buf
```

yields the `data` part of the answer received by an `XPA.get` request as a
vector of bytes.  Arguments `xpa`, `apt` and `params...` and keyword `mode` are
passed to `XPA.get` limiting the number of answers to be at most one.  An error
is thrown if `XPA.get` returns a non-empty error message.

See also: [`XPA.get`](@ref).

"""
function get_bytes(args...; kwds...)::Vector{Byte}
    tup = get(args...; nmax=1, kwds...)
    if length(tup) ≥ 1
        (data, name, mesg) = tup[1]
        length(mesg) > 0 && error(mesg)
        return data
    end
    return Byte[]
end

"""
```julia
XPA.get_text([xpa,] apt [, params...]; mode=...) -> str
```

converts the result of `XPA.get_bytes` into a single string.

See also: [`XPA.get_bytes`](@ref).

"""
get_text(args...; kwds...) =
    unsafe_string(pointer(get_bytes(args...; kwds...)))

"""
```julia
XPA.get_lines([xpa,] apt [, params...]; keepempty=false, mode=...) -> arr
```

splits the result of `XPA.get_text` into an array of strings, one for each
line.  Keyword `keepempty` can be set `true` to keep empty lines.

See also: [`XPA.get_text`](@ref).

"""
get_lines(args...; keepempty::Bool = false, kwds...) =
    split(chomp(get_text(args...; kwds...)), r"\n|\r\n?", keepempty=keepempty)

"""
```julia
XPA.get_words([xpa,] apt [, params...]; mode=...) -> arr
```

splits the result of `XPA.get_text` into an array of words.

See also: [`XPA.get_text`](@ref).

"""
get_words(args...; kwds...) =
    split(get_text(args...; kwds...), r"[ \t\n\r]+", keepempty=false)

"""
```julia
XPA.set([xpa,] apt [, params...]; data=nothing) -> tup
```

sends `data` to one or more XPA access points identified by `apt` with
parameters `params` (automatically converted into a single string where the
parameters are separated by a single space).  The result is a tuple of tuples
`(name,mesg)` where `name` is a string identifying the server which received
the request and `mesg` is an error message (a zero-length string `""` if there
are no errors).  Optional argument `xpa` specifies an XPA handle (created by
[`XPA.Client`](@ref)) for faster connections.

The following keywords are available:

* `data` specifies the data to send, may be `nothing`, an array or a string.
  If it is an array, it must be an instance of a sub-type of `DenseArray` which
  implements the `pointer` and `sizeof` methods.

* `nmax` specifies the maximum number of recipients, `nmax=1` by default.
  Specify `nmax=-1` to use the maximum possible number of XPA hosts.

* `mode` specifies options in the form `"key1=value1,key2=value2"`.

* `check` specifies whether to check for errors.  If this keyword is set true,
  an error is thrown for the first error message `mesg` encountered in the list
  of answers.

See also: [`XPA.Client`](@ref), [`XPA.get`](@ref).

"""
function set(xpa::Client, apt::AbstractString, params::AbstractString...;
             data = nothing,
             mode::AbstractString = "",
             nmax::Integer = 1,
             check::Bool = false)
    tup = _set(xpa, apt, _join(params), mode, buffer(data), _nmax(nmax))
    if check
        for (name, mesg) in tup
            if length(mesg) ≥ 9 && mesg[1:9] == "XPA\$ERROR"
                error(mesg)
            end
        end
    end
    return tup
end

set(args::AbstractString...; kwds...) =
    set(TEMPORARY, args...; kwds...)

function _set(xpa::Client, apt::AbstractString, params::AbstractString,
              mode::AbstractString, data::Union{NullBuffer,DenseArray},
              nmax::Int) :: Tuple{Vararg{Tuple{String,String}}}
    names = Vector{Ptr{Byte}}(undef, nmax)
    errs = Vector{Ptr{Byte}}(undef, nmax)
    n = ccall((:XPASet, libxpa), Cint,
              (Client, Cstring, Cstring, Cstring, Ptr{Cvoid},
               Csize_t, Ptr{Ptr{Byte}}, Ptr{Ptr{Byte}}, Cint),
              xpa, apt, params, mode, data, sizeof(data),
              names, errs, nmax)
    n ≥ 0 || error("unexpected result from XPASet")
    return ntuple(i -> (_fetch(String, names[i]),
                        _fetch(String,  errs[i])), n)
end

"""
```julia
buf = buffer(data)
```

yields an object `buf` representing the contents of `data` and which can be
used as an argument to [`ccall`](@ref) without the risk of having the data
garbage collected.  Argument `data` can be [`nothing`](@ref), a dense array or
a string.  If `data` is an array `buf` is just an alias for `data`.  If `data`
is a string, `buf` is a temporary byte buffer where the string has been copied.

Standard methods [`pointer`](@ref) and [`sizeof`](@ref) can be applied to `buf`
to retieve the address and the size (in bytes) of the data and
`convert(Ptr{Cvoid},buf)` can also be used.

See also [`XPA.set`](@ref).

"""
function buffer(arr::A) :: A where {T,N,A<:DenseArray{T,N}}
    @assert isbitstype(T)
    return arr
end

function buffer(str::AbstractString)
    @assert isascii(str)
    len = length(str)
    buf = Vector{Cchar}(undef, len)
    @inbounds for i in 1:len
        buf[i] = str[i]
    end
    return buf
end

buffer(::Nothing) = NullBuffer()

Base.unsafe_convert(::Type{Ptr{T}}, ::NullBuffer) where {T} = Ptr{T}(0)
Base.pointer(::NullBuffer) = C_NULL
Base.sizeof(::NullBuffer) = 0
