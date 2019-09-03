"""
Read Stan samples from a CSV file. Columns that belong to the same variable are grouped into
arrays.

The single exported function is [`read_samples`](@ref).
"""
module StanSamples

export read_samples

using ArgCheck: @argcheck
using DocStringExtensions: FIELDS, SIGNATURES, TYPEDEF
using ElasticArrays: ElasticArray

####
#### utilities
####

"""
$(SIGNATURES)

Test if the argument is a comment line in Stan sample output.
"""
iscommentline(s::String) = occursin(r"^ *#", s)

"""
$(SIGNATURES)

Return the fields of a line in Stan sample output. The format is CSV,
but never quoted or escaped, so splitting on `,` is sufficient.
"""
fields(line::String) = split(chomp(line), ',')

"""
$(SIGNATURES)

Specification of a variable in the column of the posterior sample.

# Fields

$(FIELDS)
"""
struct ColVar{N}
    "variable name"
    name::Symbol
    "index (may be empty)"
    index::CartesianIndex{N}
end

ColVar(name::Symbol, index::Int...) = ColVar(name, CartesianIndex(tuple(index...)))

"""
$(SIGNATURES)

Test if two `ColVar`s can be merged (same `name` and number of indices).
"""
≅(::ColVar, ::ColVar) = false
≅(v1::ColVar{N}, v2::ColVar{N}) where {N} = v1.name == v2.name

"""
$(SIGNATURES)

Parse a string as a column variable.
"""
function ColVar(s::AbstractString)
    s = split(s, ".")
    name = Symbol(s[1])
    indexes = parse.(Int, s[2:end])
    @argcheck all(indexes .≥ 1) "Non-positive index in $(s)."
    ColVar(name, indexes...)
end

"""
    $(SIGNATURES)

For a vector of indexes, calculate the size (the largest one) and
check that they are contiguous and column-major. Return a tuple of
`Int`s (empty for scalars.)
"""
function combined_size(indexes)
    siz = reduce(max, indexes)
    ran = CartesianIndices(siz)
    # FIXME inelegant collect below
    @argcheck collect(indexes) == vec(collect(ran)) "Non-contiguous indexes."
    siz.I
end

"""
A variable denoting a Stan value, combined from adjacent columns of
with the same variable name. Always has a `name::Symbol`
field. Determines the type of the resulting values.
"""
abstract type StanVar end

"""
$(TYPEDEF)

A scalar (always Float64).
"""
struct StanScalar <: StanVar
    name::Symbol
end

"""
$(TYPEDEF)

An array (always of Float64 elements).
"""
struct StanArray{N} <: StanVar
    name::Symbol
    size::NTuple{N, Int}
end

# this is a shorthand, mainly useful for unit tests
StanArray(name::Symbol, size::Int...) = StanArray(name, size)

"""
$(SIGNATURES)

Empty values for a `var`, can be appended to using `append!`.
"""
empty_values(var::StanScalar) = Vector{Float64}()
empty_values(var::StanArray) = ElasticArray{Float64}(undef, var.size..., 0)

"""
$(SIGNATURES)

Number of columns that correspond to a [`StanVar`](@ref).
"""
ncols(::StanScalar) = 1
ncols(sa::StanArray) = prod(sa.size)

"""
$(SIGNATURES)

Combine column variables into a Stan variable.
"""
function _combine_colvars(colvars)
    var = first(colvars)
    len = findfirst(v -> !(v ≅ var), colvars)
    len = len ≡ nothing ? length(colvars) : len - 1
    siz = combined_size(v.index for v in colvars[1:len])
    if isempty(siz)
        StanScalar(var.name)
    else
        StanArray(var.name, siz)
    end
end

"""
$(SIGNATURES)

Combine column variables, returning a `Tuple` of `StanVar`s.
"""
function combine_colvars(colvars)
    header = StanVar[]
    position = 1
    while position ≤ length(colvars)
        v = _combine_colvars(@view colvars[position:end])
        @argcheck v.name ∉ (h.name for h in header) "Duplicate variable $(v.name)."
        position += ncols(v)
        push!(header, v)
    end
    tuple(header...)
end

"""
$(SIGNATURES)

Read values for `var` from `buffer`, starting at index `1`.
"""
_read_values(var::StanScalar, buffer) = buffer[1]

function _read_values(var::StanArray, buffer)
    a = Array{Float64}(undef, var.size...)
    a[:] .= buffer[1:length(a)]
    a
end

"""
$(SIGNATURES)

Create an empty container for variable values, accessed by variable names.
"""
function empty_vars_values(vars::Tuple)
    NamedTuple{map(var -> var.name, vars)}(map(empty_values, vars))
end

"""
$(SIGNATURES)

Read values from a single line of `io` using the variable
specification `vars`.

The fields are combined into variables and appended into the
corresponding vectors in `vars_values`.

Return `false` for comment lines, `true` lines with data. All other
cases (ie incomplete lines) throw an error. Note that in this case the
vectors in `vars_values` may have an inconsistent length.

`buffer` is pre-allocated for reading in a line at a time.
"""
function read_values(io::IO, vars::Tuple, vars_values::NamedTuple,
                     buffer::Vector{Float64} = Vector{Float64}(undef, length(vars)))
    line = readline(io)
    iscommentline(line) && return false
    buffer .= parse.(Float64, fields(line))
    position = 1
    for var in vars
        a = _read_values(var, @view buffer[position:end])
        append!(vars_values[var.name], a)
        position += ncols(var)
    end
    @assert position == length(buffer) + 1 "Fields remaining after parsing."
    true
end

"""
$(SIGNATURES)

Helper function to read data from a Stan samples CSV file.
"""
function _read_samples(io, vars, vars_values, buffer)
    while !eof(io)
        read_values(io, vars, vars_values, buffer)
    end
    vars_values
end

function read_samples(io::IO)
    while !eof(io)
        line = readline(io)
        if !iscommentline(line)
            colvars = ColVar.(fields(line))
            vars = combine_colvars(colvars)
            vars_values = empty_vars_values(vars)
            buffer = Vector{Float64}(undef, sum(ncols, vars))
            return _read_samples(io, vars, vars_values, buffer)
        end
    end
    error("Could not find non-empty lines.")
end

"""
$(SIGNATURES)

Read Stan samples from a CSV file or a `IO` stream.

Return a container of arrays, accessed by variables names (eg like a `NamedTuple`, which is
in fact the current implementation, but can possibly change). Each array has samples for a
variable, with the last index varying for each draw.

```jldoctest
julia> io = IOBuffer("a,b.1,b.2,c.1.1,c.2.1,c.1.2,c.2.2\n" *
                     "1.0,2.0,3.0,4.0,5.0,6.0,7.0\n" *
                     "8.0,9.0,10.0,11.0,12.0,13.0,14.0");

julia> samples = read_samples(io);

julia> samples.a
2-element Array{Float64,1}:
 1.0
 8.0

julia> samples.b
2×2 ElasticArrays.ElasticArray{Float64,2,1}:
 2.0   9.0
 3.0  10.0

julia> samples.c
2×2×2 ElasticArrays.ElasticArray{Float64,3,2}:
[:, :, 1] =
 4.0  6.0
 5.0  7.0

[:, :, 2] =
 11.0  13.0
 12.0  14.0
```
"""
read_samples(filename::AbstractString) = open(read_samples, filename, "r")

end # module
