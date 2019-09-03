"""
# module Directives



# Examples

```jldoctest
julia>
```
"""
module Directives

using Parameters

export Directive

@with_kw struct Directive{A <: AbstractString,B <: Union{Nothing,AbstractChar},T}
    long::A
    short::B = nothing
    value::T
end

function Base.string(d::Directive; long::Bool = true, with_value::Bool = true)
    key = if long
        "--$(d.long)"
    else
        isnothing(d.short) ? throw(ArgumentError("Directive `$(d.long)` does not have a short form!")) : "-$(d.short)"
    end
    value = if with_value
        long ? "==$(d.value)" : " $(d.value)"
    else
        ""
    end
    return key * value
end

end
