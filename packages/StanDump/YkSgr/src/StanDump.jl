"""
StanDump --- a package for writing data in the CmdStan dump data format.

The single exported function is [`stan_dump`](@ref).
"""
module StanDump

using ArgCheck: @argcheck
using DocStringExtensions: SIGNATURES

export stan_dump

####
#### Representation of formatting
####

"""
Wrapper for an IO stream for writing data for use by Stan. See constructor for documentation
of slots.

Part of the API, but not exported.
"""
struct StanDumpIO{T <: IO}
    io::T
    def_arrow::Bool
    def_newline::Bool
    compact::Bool
end

"""
    StanDumpIO(io; def_arrow = false, def_newline = false, compact = false)

Wrap an IO stream `io` for writing data to be read by Stan.

# Arguments

- `def_arrow::Bool`: when `true` use `<-`, otherwise `=` for variable definitions.

- `def_newline::Bool`: when `true`, each `=` or `<-` is followed by a newline.

- `compact::Bool`: when `true`, drop whitespace when possible.
"""
function StanDumpIO(io; def_arrow = true, def_newline = false, compact = false)
    StanDumpIO(io, def_arrow, def_newline, compact)
end

####
#### Internals
####

"""
    dump(sd, xs...)

Write arguments `xs...` as data for Stan into `sd`. For internal use.

NOTE: Define methods only for valid Stan objects, using `_dump` for everything else.
"""
dump(sd::StanDumpIO, x) = throw(ArgumentError("Can't represent $(x) as data for Stan."))

dump(sd::StanDumpIO, x::Float64) = print(sd.io, x)

dump(sd::StanDumpIO, x::Real) = dump(sd, Float64(x))

function dump(sd::StanDumpIO, x::Integer)
    if typemin(Int32) ≤ x ≤ typemax(Int32)
        print(sd.io, x)
    elseif typemin(Int64) ≤ x ≤ typemax(Int64)
        print(sd.io, x, "L")
    else
        throw(ArgumentError("Integer too large to represent in Stan."))
    end
end

"""
$(SIGNATURES)

Write arguments arguments as data for Stan into `sd`, passing through strings and
characters, and allowing other special objects which are not valid data.

For internal implementation. also defined for objects which are not valid in Stan.
"""
_dump(sd::StanDumpIO, xs...) = for x in xs _dump(sd, x) end

_dump(sd::StanDumpIO, x) = dump(sd, x)

_dump(sd::StanDumpIO, x::Union{Char,String}) = print(sd.io, x)

"Write a space unless output is requested to be compact."
struct Space end

const SPACE = Space()

_dump(sd::StanDumpIO, ::Space) = sd.compact || print(sd.io, " ")

"""
$(SIGNATURES)

Test if the argument is valid as a Stan variable name.

NOTE: only basic checks, does not test conflicts with reserved names.
"""
function is_valid_varname(name::String)
    isvalid(c) = isascii(c) && (isdigit(c) || isletter(c) || c == '_')
    all(isvalid, name) && isletter(name[1]) && !endswith(name, "__")
end

function _dump(sd::StanDumpIO, x::Symbol)
    v = string(x)
    @argcheck is_valid_stan_varname(v) "Invalid variable name $(v)."
    print(sd.io, v)
end

function _dump(sd::StanDumpIO, x::Pair)
    name, value = x
    @argcheck name isa Union{AbstractString, Symbol} "Use symbols or strings for variable names."
    varname = string(name)
    @argcheck is_valid_varname(varname)
    _dump(sd, varname, SPACE, sd.def_arrow ? "<-" : '=',
          sd.def_newline ? "\n" : SPACE, value, "\n")
end

"""
$(SIGNATURES)

Dump elements of a vector (or iterable, considered as a vector).

When the element type is `<:Integer`, dump as `Int`s, otherwise as `Float64`; all values are
converted for consistency.
"""
function _dump_vector(sd::StanDumpIO, x)
    S = eltype(x) <: Integer ? Int : Float64
    if isempty(x)
        _dump(sd, S ≡ Int ? "integer" : "double", "(0)")
    else
        _dump(sd, "c(")
        for (i, x) in enumerate(x)
            i > 1 && _dump(sd, ",", SPACE)
            dump(sd, S(x))      # convert value for consistency
        end
        _dump(sd, ")")
    end
end

dump(sd::StanDumpIO, x::AbstractVector) = _dump_vector(sd, x)

function dump(sd::StanDumpIO, r::UnitRange{<: Integer})
    isempty(r) ? _dump_vector(sd, r) : _dump(sd, minimum(r), ":", maximum(r))
end

function dump(sd::StanDumpIO, A::AbstractArray)
    _dump(sd, "structure(", view(A, :), ",", SPACE, ".Dim", SPACE, "=",
          SPACE, collect(size(A)), ")")
end

####
#### Interface
####

"""
    stan_dump(filename, data; force = false, kwargs...)
    stan_dump(io, data; kwargs...)
    stan_dump(StanDump.StanDumpIO(io; kwargs...), data)

Write `data`, which is a value that supports `pairs` (eg a `NamedTuple` or a `Dict`) to
`filename` or `io`.

Using a `filename`, it will not be overwritten unless `force = true` is specified.

Keyword arguments are passed to `StanDumpIO` to govern formatting (most users should not
care about this, except for debugging purposes).

# Example

```jldoctest
julia> stan_dump(stdout, (N = 1, a = 1:5, b = ones(2, 2)))
N <- 1
a <- 1:5
b <- structure(c(1.0, 1.0, 1.0, 1.0), .Dim = c(2, 2))
```
"""
stan_dump(sd::StanDumpIO, data) = foreach(p -> _dump(sd, p), pairs(data))

stan_dump(io::IO, data; kwargs...) = stan_dump(StanDumpIO(io; kwargs...), data)

function stan_dump(filename::AbstractString, data; force::Bool = false, kwargs...)
    @argcheck force || !ispath(filename) "$(filename) already exists"
    open(io -> stan_dump(StanDumpIO(io; kwargs...), data), filename, "w")
end

end # module
