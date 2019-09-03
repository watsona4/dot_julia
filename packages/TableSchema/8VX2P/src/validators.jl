"""
Table Schema validators
https://github.com/frictionlessdata/tableschema-jl#validators
"""
function checkrow(f::Field, val, column::Array=[])
    c::Constraints = f.constraints

    c.required && (val == "" || val == nothing) &&
        throw(ConstraintError("required", f, val))

    c.unique && length(findall(in([val]), column)) > 1 &&
        throw(ConstraintError("unique", f, val))

    if typeof(val) == String

        c.minLength !== nothing && c.minLength > -1 &&
            length(val) < c.minLength &&
                throw(ConstraintError("minLength", f, val, c.minLength))

        c.maxLength !== nothing && c.maxLength > -1 &&
            length(val) > c.maxLength &&
                throw(ConstraintError("maxLength", f, val, c.maxLength))

    end

    # c.minimum > -1 && val < c.minimum &&
    #     throw(ConstraintError("minimum", f, val, c.minimum))
    #
    # c.maximum > -1 && val > c.maximum &&
    #     throw(ConstraintError("maximum", f, val, c.maximum))

    return true
end
