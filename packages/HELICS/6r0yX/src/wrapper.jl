import Base: @__doc__

"""
# Summary

abstract type HELICS.CWrapper
"""
abstract type CWrapper end

Base.convert(T::Type{<:CWrapper}, p::Ptr{Nothing}) = T(p)
Base.unsafe_convert(T::Type{Ptr{Nothing}}, t::CWrapper) = t.ptr

"""
# Summary

abstract type HELICS.Federate <: HELICS.CWrapper

# Subtypes

- [`HELICS.CombinationFederate`](@ref)
- [`HELICS.MessageFederate`](@ref)
- [`HELICS.ValueFederate`](@ref)

# Supertype Hierarchy

HELICS.Federate <: HELICS.CWrapper <: Any

"""
abstract type Federate <: CWrapper end

macro define(subtype, supertype)
    docstring = """
# Summary

struct [`HELICS.$subtype`](@ref) <: [`HELICS.$supertype`](@ref)
"""
    quote
        struct $subtype <: $supertype
            ptr::Ptr{Nothing}
            function $subtype(ptr::Ptr{Nothing})
                ptr == C_NULL && error("Failed to create $subtype. Received null pointer from HELICS C interface.")
                new(ptr)
            end
        end
        @doc $docstring $subtype
    end
end

@define Broker CWrapper
@define Core CWrapper
@define FederateInfo CWrapper
@define ValueFederate Federate
@define MessageFederate Federate
@define CombinationFederate Federate
@define Publication CWrapper
@define Subscription CWrapper
@define Endpoint CWrapper
@define Filter CWrapper
@define Query CWrapper

const Input = Subscription

"""
# Summary

struct HELICS.Message

# Fields

```julia
time::Float64
data::String
length::Int64
messageID::Int32
flags::Int16
original_source::String
source::String
dest::String
original_dest::String
```

# Supertype Hierarchy

HELICS.Message <: Any
"""
struct Message
    time::Float64
    data::String
    length::Int64
    messageID::Int32
    flags::Int16
    original_source::String
    source::String
    dest::String
    original_dest::String
end

function Message(msg::Lib.helics_message)

    return Message(
                   msg.time,
                   msg.data |> unsafe_string,
                   msg.length,
                   msg.messageID,
                   msg.flags,
                   msg.original_source |> unsafe_string,
                   msg.source |> unsafe_string,
                   msg.dest |> unsafe_string,
                   msg.original_dest |> unsafe_string,
                  )

end

Base.convert(::Type{Message}, msg::Lib.helics_message) = Message(msg)
function unsafe_wrap(msg::Message)::Lib.helics_message
    Lib.helics_message(
                       msg.time,
                       msg.data |> pointer,
                       msg.length,
                       msg.messageID,
                       msg.flags,
                       msg.original_source |> pointer,
                       msg.source |> pointer,
                       msg.dest |> pointer,
                       msg.original_dest |> pointer,
                      )
end

