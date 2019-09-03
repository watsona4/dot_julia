"""
# module Shells



# Examples

```jldoctest
julia>
```
"""
module Shells

export Shell

struct Shell{T <: AbstractString}
    path::T
end

end
