"""
Table Schema field
https://github.com/frictionlessdata/tableschema-jl#field
"""
mutable struct Field
    descriptor::Dict
    name::String
    typed::String
    format::String
    constraints::Constraints
    # required::Bool

    function Field(d::Dict)
        name = haskey(d, "name") ? d["name"] : ""
        typed = haskey(d, "type") ? d["type"] : DEFAULT_TYPE
        format = haskey(d, "format") ? d["format"] : DEFAULT_FORMAT
        constraints = haskey(d, "constraints") ?
            Constraints(d["constraints"]) : Constraints()
        # required = cons.required
        new(d, name, typed, format, constraints)
    end

    Field(name::String) = Field(Dict( "name" => name ))
end

OPTION_KEYS = ["decimalChar", "groupChar", "bareNumber", "trueValues", "falseValues"]

_TRUE_VALUES = ["true", "True", "TRUE", "1"]
_FALSE_VALUES = ["false", "False", "FALSE", "0"]
_DEFAULT_BARE_NUMBER = true
_DEFAULT_GROUP_CHAR = ""
_DEFAULT_DECIMAL_CHAR = "."

function cast_by_type(value, typed::String, format::String, options::Dict)
    if typed == "any"
        return value

    elseif typed == "boolean"
        isa(value, Bool) && return value
        if !isa(value, String); return CastError(); end
        value = strip(value)
        value in _TRUE_VALUES && return true
        value in _FALSE_VALUES && return false

    elseif typed == "integer"
        isa(value, Integer) && return value
        if !isa(value, String); return CastError(); end
        if !get(options, "bareNumber", _DEFAULT_BARE_NUMBER)
            value = replace(value, r"((^\D*)|(\D*$))" => "")
        end
        try; return parse(Int64, value); catch; return CastError(); end

    elseif typed == "number"
        isa(value, AbstractFloat) && return value
        isa(value, Integer) && return Float64(value)
        if !isa(value, String); return CastError(); end
        group_char = get(options, "groupChar", _DEFAULT_GROUP_CHAR)
        decimal_char = get(options, "decimalChar", _DEFAULT_DECIMAL_CHAR)
        value = replace(value, r"\s" => "")
        value = replace(value, decimal_char => ".")
        value = replace(value, group_char => "")
        if !get(options, "bareNumber", _DEFAULT_BARE_NUMBER)
            value = replace(value, r"((^\D*)|(\D*$))" => "")
        end
        try; return parse(Float64, value); catch; return CastError(); end

    elseif typed == "object"
        typeof(value) == Dict && return value
        if !isa(value, String); return CastError(); end
        try; value = JSON.parse(value); catch; return CastError(); end
        isa(value, Dict) && return value

    elseif typed == "string"
        isa(value, AbstractString) && return value
        isa(value, Number) && return repr(value)
        try; return parse(String, value); catch; return CastError(); end

    else
        throw(ErrorException("Cast by type $typed not implemented"))

    end
    CastError()
end

function build(f::Field)
    d = Dict()
    d["name"] = f.name
    d["type"] = f.typed
    d["format"] = f.format
    d["constraints"] = build(f.constraints)
    f.descriptor = d
    d
end

function cast_value(f::Field, value, constraints=true)

    # TODO: Ignore Missing values
    cast_value = value
    if !isempty(value)

        # Collect options
        d = f.descriptor
        options = Dict(k => d[k] for k in OPTION_KEYS if haskey(d, k) && !isempty(d[k]))
        cast_value = cast_by_type(value, f.typed, f.format, options)
        if isa(cast_value, CastError)
            throw(CastError(
                "Field $(f.name) cannot cast value \"$(value)\" for type $(f.typed) with format $(f.format)"
            ))
        end

    end

    if constraints
        throw(ErrorException("Not implemented"))
    end

    cast_value
end

# test_value = throw(ErrorException("Not implemented"))

function validate(f::Field)
    isempty(f.descriptor) &&
        throw(FieldError("Missing Descriptor"))
    f.name == "" &&
        throw(FieldError("Name is empty"))
    f.typed == "" &&
        throw(FieldError("Type is empty"))
    return true
end
