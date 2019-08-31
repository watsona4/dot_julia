__precompile__()

module OptionalData

export @OptionalData, OptData, show, push!, isavailable, get

import Base: push!, get, show

mutable struct OptData{T}
    data::Union{T, Nothing}
    name::String
    msg::String
end
OptData{T}(name, msg="") where {T} = OptData{T}(nothing, name, msg)

function show(io::IO, opt::OptData{T}) where T
    val = isavailable(opt) ? get(opt) : ""
    print(io, "OptData{$T}($val)")
end

"""
    push!(opt::OptData{T}, data::T) where T

Push `data` of type `T` to `opt`.
"""
function push!(opt::OptData{T}, data::T) where T
    opt.data = data
    opt
end

"""
    push!(opt::OptData, ::Type{T}, args...) where T

Construct an object of type `T` from `args` and push it to `opt`.
"""
function push!(opt::OptData, ::Type{T}, args...) where {T}
    push!(opt, T(args...))
    opt
end
push!(opt::OptData{T}, args...) where {T} = push!(opt, T, args...)

"""
    get(opt::OptData)

Get data from `opt`. Throw an exception if no data has been pushed to `opt` before.
"""
function get(opt::OptData{T}) where T
    !isavailable(opt) && error(opt.name, " is not available. ", opt.msg)
    opt.data::T
end

"""
    @OptionalData name type msg=""

Initialise a constant `name` with type `OptData{type}`.
An exception with the custom error message `msg` is thrown when `name` is
accessed before data has been pushed to it.

# Example

```julia
@OptionalData OPT_FLOAT Float64
```
"""
macro OptionalData(name, typ, msg="")
   :(const $(esc(name)) = OptData{$(esc(typ))}($(string(name)), $msg))
end

"""
    isavailable(opt::OptData)

Check whether data has been pushed to `opt`.
"""
isavailable(opt::OptData) = opt.data !== nothing

end # module
