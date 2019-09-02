__precompile__(true)
module Optionals

import Base: convert, promote_rule, show, repr, isless, ==
import Missings: Missing, MissingException, ismissing, missing, coalesce
using Nullables

export Missing, ismissing, missing, coalesce, Optional

@static if VERSION < v"0.7.0-alpha"
    struct Optional{T}
        nullable::Nullable{T}
        Optional{T}() where T = new(Nullable{T}())
        Optional{T}(x::Any) where T = new(Nullable{T}(x))
        Optional{T}(::Missing) where T = new(Nullable{T}())
    end

    ismissing(x::Optional) = isnull(x.nullable)

    coalesce(x::Optional) =
        ismissing(x) ? missing : unsafe_get(x.nullable)

    _unwrap(x::Optional{T}) where T =
        ismissing(x) ? throw(MissingException()) : unsafe_get(x.nullable)

    repr(x::Optional) = ismissing(x) ? repr(missing) : repr(_unwrap(x))
    repr(mime::Union{MIME, AbstractString}, x::Optional) =
        ismissing(x) ? repr(mime, missing) : repr(mime, _unwrap(x))
else

    struct Optional{T}
        value::Union{T, Missing}
        Optional{T}() where T = new(missing)
        Optional{T}(x) where T = new(x)
        Optional{T}(::Missing) where T = new(missing)
    end

    ismissing(x::Optional) = x.value === missing

    coalesce(x::Optional) = x.value

    _unwrap(x::Optional{T}) where T = x.value::T

    repr(x::Optional, context=nothing) =
        ismissing(x) ?
          repr(missing, context=context) :
          repr(_unwrap(x), context=context)

    repr(mime::Union{MIME, AbstractString}, x::Optional, context=nothing) =
        ismissing(x) ?
          repr(mime, missing, context=context) :
          repr(mime, _unwrap(x), context=context)
end

Optional(x) = Optional{typeof(x)}(x)

convert(::Type{Optional{T}}, x::Optional{T}) where T = x
convert(::Type{Optional{T}}, x::Optional) where T =
    ismissing(x) ? Optional{T}() : Optional(convert(T, unwrap(x)))
convert(::Type{Optional{T}}, ::Missing) where T = Optional{T}()
convert(::Type{Optional{T}}, x::Any) where T = Optional{T}(convert(T, x))
convert(::Type{Optional}, x::Optional) = x
convert(::Type{Optional}, x::Any) = Optional(x)

promote_rule(::Type{Optional{T}}, ::Type{Optional{U}}) where {T, U} =
    Optional{promote_type(T, U)}
promote_rule(::Type{Optional{T}}, ::Type{Missing}) where T = Optional{T}
promote_rule(::Type{Optional{T}}, U::Type) where T =
    Optional{promote_type(T, U)}

coalesce(x::Optional, ys...) = coalesce(coalesce(x), ys...)
coelesce(x::Optional, y) = ismissing(x) ? y : _unwrap(x)

show(io::IO, x::Optional) =
    ismissing(x) ? show(io, missing) : show(io, _unwrap(x))
show(io::IO, mime, x::Optional) =
    ismissing(x) ? show(io, mime, missing) : show(io, mime, _unwrap(x))


function isless(x::Optional, y::Optional)
    ismissing(x) && return missing
    ismissing(y) && return missing
    return isless(_unwrap(x), _unwrap(y))
end

function isless(x, y::Optional)
    ismissing(y) && return missing
    return isless(x, _unwrap(y))
end

function isless(x::Optional, y)
    ismissing(x) && return missing
    return isless(_unwrap(x), y)
end

function ==(x::Optional, y::Optional)
    ismissing(x) && return missing
    ismissing(y) && return missing
    return _unwrap(x) == _unwrap(y)
end

function ==(x, y::Optional)
    ismissing(y) && return missing
    return x == _unwrap(y)
end

function ==(x::Optional, y)
    ismissing(x) && return missing
    return _unwrap(x) == y
end

end # module
