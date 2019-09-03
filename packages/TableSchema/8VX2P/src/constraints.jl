"""
Table Schema field constraints
https://github.com/frictionlessdata/tableschema-jl#constraints
"""
mutable struct Constraints
    required::Bool
    unique::Bool
    minLength::Union{Integer, Nothing}
    maxLength::Union{Integer, Nothing}
    # minimum::Integer
    # maximum::Integer
    # pattern
    # enum

    function Constraints(d::Dict)
        # Defaults
        c = new(
            false, # required::Bool
            false, # unique::Bool
            nothing, # minlength::Integer
            nothing, # maxlength::Integer
            # nothing, # minimum::Integer
            # nothing, # maximum::Integer
                # pattern
                # enum
        )
        # Map from dictionary using all the field names of this type
        for fld in fieldnames(typeof(c))
            if haskey(d, String(fld))
                setfield!(c, fld, d[String(fld)])
            end
        end
        return c
    end

    Constraints(required::Bool, unique::Bool) = new(required, unique, nothing, nothing)
    Constraints() = Constraints(Dict())
end

function build(c::Constraints)
    d = Dict()
    for fld in fieldnames(typeof(c))
        d[fld] = getfield(c, fld)
    end
    d
end
