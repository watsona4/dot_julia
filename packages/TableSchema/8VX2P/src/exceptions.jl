"""
Common exceptions
https://github.com/frictionlessdata/tableschema-jl#exceptions
"""
struct ConstraintError <: Exception
    message::String
    field::Field
    value
    expected

    ConstraintError(m::String, f::Field, v, e) = new(m, f, v, e)
    ConstraintError(m::String, f::Field, v) = new(m, f, v, nothing)
    ConstraintError(m::String, v, e) = new(m, nothing, v, e)
    ConstraintError(m::String, v) = new(m, nothing, v, nothing)
end

struct FieldError <: Exception
    message::String
    # key::String
    # line::Int16
end

struct SchemaError <: Exception
    message::String
    key

    SchemaError(m::String, k::String) = new(m, k)
    SchemaError(m::String) = new(m, nothing)
    SchemaError(f::FieldError) = new(f.message, nothing)
end

struct TableValidationException <: Exception
    var::String
end

struct CastError <: Exception
    message::String
    errors::Array{CastError}

    CastError(m::String, e::Array) = new(m, e)
    CastError(m::String) = new(m, [])
    CastError() = new("Cast error", [])
end
