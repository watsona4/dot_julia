"""
# module SystemModules



# Examples

```jldoctest
julia>
```
"""
module SystemModules

export SystemModule

struct SystemModule{T <: AbstractString}
    name::T
end

function Base.string(m::SystemModule)
    string(m.name)
end

end
