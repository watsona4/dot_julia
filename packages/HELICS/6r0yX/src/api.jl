import .Utils
import DocStringExtensions

DocStringExtensions.@template (FUNCTIONS, METHODS) =
    """
    $(DocStringExtensions.TYPEDSIGNATURES)
    $(DocStringExtensions.DOCSTRING)
    """

for enum_name in [
                 Lib.helics_iteration_request,
                 Lib.helics_iteration_result,
                 Lib.helics_federate_state,
                 Lib.helics_data_type,
                 Lib.helics_core_type,
                 Lib.helics_federate_flags,
                 Lib.helics_log_levels,
                 Lib.helics_error_types,
                 Lib.helics_properties,
                 Lib.helics_handle_options,
                 Lib.helics_filter_type,
                 ]
    # Hacks to not populate namespace
    eval(:(const $(Symbol(uppercase(split(String(Symbol(enum_name)), ".")[end]))) = $enum_name))

    for _sym in Lib.CEnum.enum_names(enum_name)
        eval( :(const $(Symbol(uppercase(String(_sym)))) = Lib.$_sym) )
    end

end

@doc """
$( join(map(x -> "- `" * uppercase(String(x[1])) * "`: " * string(x[2]), zip(Lib.CEnum.enum_names(HELICS.HELICS_ITERATION_REQUEST), Lib.CEnum.enum_values(HELICS.HELICS_ITERATION_REQUEST))), "\n") )
"""
HELICS.HELICS_ITERATION_REQUEST

@doc """
$( join(map(x -> "- `" * uppercase(String(x[1])) * "`: " * string(x[2]), zip(Lib.CEnum.enum_names(HELICS.HELICS_ITERATION_RESULT), Lib.CEnum.enum_values(HELICS.HELICS_ITERATION_RESULT))), "\n") )
"""
HELICS.HELICS_ITERATION_RESULT

@doc """
$( join(map(x -> "- `" * uppercase(String(x[1])) * "`: " * string(x[2]), zip(Lib.CEnum.enum_names(HELICS.HELICS_FEDERATE_STATE), Lib.CEnum.enum_values(HELICS.HELICS_FEDERATE_STATE))), "\n") )
"""
HELICS.HELICS_FEDERATE_STATE

@doc """
$( join(map(x -> "- `" * uppercase(String(x[1])) * "`: " * string(x[2]), zip(Lib.CEnum.enum_names(HELICS.HELICS_DATA_TYPE), Lib.CEnum.enum_values(HELICS.HELICS_DATA_TYPE))), "\n") )
"""
HELICS.HELICS_DATA_TYPE

@doc """
$( join(map(x -> "- `" * uppercase(String(x[1])) * "`: " * string(x[2]), zip(Lib.CEnum.enum_names(HELICS.HELICS_CORE_TYPE), Lib.CEnum.enum_values(HELICS.HELICS_CORE_TYPE))), "\n") )
"""
HELICS.HELICS_CORE_TYPE

@doc """
$( join(map(x -> "- `" * uppercase(String(x[1])) * "`: " * string(x[2]), zip(Lib.CEnum.enum_names(HELICS.HELICS_FEDERATE_FLAGS), Lib.CEnum.enum_values(HELICS.HELICS_FEDERATE_FLAGS))), "\n") )
"""
HELICS.HELICS_FEDERATE_FLAGS

@doc """
$( join(map(x -> "- `" * uppercase(String(x[1])) * "`: " * string(x[2]), zip(Lib.CEnum.enum_names(HELICS.HELICS_LOG_LEVELS), Lib.CEnum.enum_values(HELICS.HELICS_LOG_LEVELS))), "\n") )
"""
HELICS.HELICS_LOG_LEVELS

@doc """
$( join(map(x -> "- `" * uppercase(String(x[1])) * "`: " * string(x[2]), zip(Lib.CEnum.enum_names(HELICS.HELICS_ERROR_TYPES), Lib.CEnum.enum_values(HELICS.HELICS_ERROR_TYPES))), "\n") )
"""
HELICS.HELICS_ERROR_TYPES

@doc """
$( join(map(x -> "- `" * uppercase(String(x[1])) * "`: " * string(x[2]), zip(Lib.CEnum.enum_names(HELICS.HELICS_PROPERTIES), Lib.CEnum.enum_values(HELICS.HELICS_PROPERTIES))), "\n") )
"""
HELICS.HELICS_PROPERTIES

@doc """
$( join(map(x -> "- `" * uppercase(String(x[1])) * "`: " * string(x[2]), zip(Lib.CEnum.enum_names(HELICS.HELICS_HANDLE_OPTIONS), Lib.CEnum.enum_values(HELICS.HELICS_HANDLE_OPTIONS))), "\n") )
"""
HELICS.HELICS_HANDLE_OPTIONS

@doc """
$( join(map(x -> "- `" * uppercase(String(x[1])) * "`: " * string(x[2]), zip(Lib.CEnum.enum_names(HELICS.HELICS_FILTER_TYPE), Lib.CEnum.enum_values(HELICS.HELICS_FILTER_TYPE))), "\n") )
"""
HELICS.HELICS_FILTER_TYPE

const HELICS_TIME = Union{Int, Float64}

"""
"""
function helicsFederateRegisterEndpoint(fed::Federate, name::String, kind::String)::Endpoint
    @Utils.invoke_and_check Lib.helicsFederateRegisterEndpoint(fed, name, kind)
end

"""
"""
function helicsFederateRegisterGlobalEndpoint(fed::Federate, name::String, kind::String)::Endpoint
    @Utils.invoke_and_check Lib.helicsFederateRegisterGlobalEndpoint(fed, name, kind)
end

"""
"""
function helicsFederateGetEndpoint(fed::Federate, name::String)::Endpoint
    @Utils.invoke_and_check Lib.helicsFederateGetEndpoint(fed, name)
end

"""
"""
function helicsFederateGetEndpointByIndex(fed::Federate, index::Int)::Endpoint
    @Utils.invoke_and_check Lib.helicsFederateGetEndpointByIndex(fed, index)
end

"""
"""
function helicsEndpointSetDefaultDestination(endpoint::Endpoint, dest::String)
    @Utils.invoke_and_check Lib.helicsEndpointSetDefaultDestination(endpoint, dest)
end

"""
"""
function helicsEndpointGetDefaultDestination(endpoint::Endpoint)::String
    Lib.helicsEndpointGetDefaultDestination(endpoint) |> unsafe_string
end

"""
"""
function helicsEndpointSendMessageRaw(endpoint::Endpoint, dest::String, data::String)
    inputDataLength = length(data)
    data = pointer(data)
    @Utils.invoke_and_check Lib.helicsEndpointSendMessageRaw(endpoint, dest, data, inputDataLength)
end

"""
"""
function helicsEndpointSendEventRaw(endpoint::Endpoint, dest::String, data::String, time::HELICS.HELICS_TIME)
    time = convert(Float64, time)
    inputDataLength = length(data)
    data = pointer(data)
    @Utils.invoke_and_check Lib.helicsEndpointSendEventRaw(endpoint, dest, data, inputDataLength, time)
end

"""
"""
function helicsEndpointSendMessage(endpoint::Endpoint, message::Message)
    msg = Ref(unsafe_wrap(message))
    @Utils.invoke_and_check Lib.helicsEndpointSendMessage(endpoint, msg)
end

"""
"""
function helicsEndpointSubscribe(endpoint::Endpoint, key::String)
    @Utils.invoke_and_check Lib.helicsEndpointSubscribe(endpoint, key)
end

"""
"""
function helicsFederateHasMessage(fed::Federate)::Bool
    Lib.helicsFederateHasMessage(fed) == 1 ? true : false
end

"""
"""
function helicsEndpointHasMessage(endpoint::Endpoint)::Bool
    Lib.helicsEndpointHasMessage(endpoint) == 1 ? true : false
end

"""
"""
function helicsFederatePendingMessages(fed::Federate)::Int
    Lib.helicsFederatePendingMessages(fed)
end

"""
"""
function helicsEndpointPendingMessages(endpoint::Endpoint)::Int
    Lib.helicsEndpointPendingMessages(endpoint)
end

"""
"""
function helicsEndpointGetMessage(endpoint::Endpoint)::Message
    Lib.helicsEndpointGetMessage(endpoint)
end

"""
"""
function helicsFederateGetMessage(fed::Federate)::Message
    Lib.helicsFederateGetMessage(fed)
end

"""
"""
function helicsEndpointGetType(endpoint::Endpoint)::String
    Lib.helicsEndpointGetType(endpoint) |> unsafe_string
end

"""
"""
function helicsEndpointGetName(endpoint::Endpoint)::String
    Lib.helicsEndpointGetName(endpoint) |> unsafe_string
end

"""
"""
function helicsFederateGetEndpointCount(fed::Federate)::Int
    Lib.helicsFederateGetEndpointCount(fed)
end

"""
"""
function helicsEndpointGetInfo(_end::Endpoint)::String
    Lib.helicsEndpointGetInfo(_end) |> unsafe_string
end

"""
"""
function helicsEndpointSetInfo(_end::Endpoint, info::String)
    @Utils.invoke_and_check Lib.helicsEndpointSetInfo(_end, info)
end

"""
"""
function helicsEndpointSetOption(_end::Endpoint, option::Int, value::Bool)
    @Utils.invoke_and_check Lib.helicsEndpointSetOption(_end, option, value ? 1 : 0)
end

"""
"""
function helicsEndpointGetOption(_end::Endpoint, option::Int)::Bool
    Lib.helicsEndpointGetOption(_end, option)
end

"""
"""
function helicsFederateRegisterFilter(fed::Federate, kind::Union{Int, HELICS.HELICS_FILTER_TYPE}, name::String)::Filter
    kind = convert(HELICS.HELICS_FILTER_TYPE, kind)
    @Utils.invoke_and_check Lib.helicsFederateRegisterFilter(fed, kind, name)
end

"""
"""
function helicsFederateRegisterGlobalFilter(fed::Federate, kind::Union{Int, HELICS.HELICS_FILTER_TYPE}, name::String)::Filter
    kind = convert(HELICS.HELICS_FILTER_TYPE, kind)
    @Utils.invoke_and_check Lib.helicsFederateRegisterGlobalFilter(fed, kind, name)
end

"""
"""
function helicsFederateRegisterCloningFilter(fed::Federate, deliveryEndpoint::String)::Filter
    @Utils.invoke_and_check Lib.helicsFederateRegisterCloningFilter(fed, deliveryEndpoint)
end

"""
"""
function helicsFederateRegisterGlobalCloningFilter(fed::Federate, deliveryEndpoint::String)::Filter
    @Utils.invoke_and_check Lib.helicsFederateRegisterGlobalCloningFilter(fed, deliveryEndpoint)
end

"""
"""
function helicsCoreRegisterFilter(core::Core, kind::Union{Int, HELICS.HELICS_FILTER_TYPE}, name::String)::Filter
    kind = convert(HELICS.HELICS_FILTER_TYPE, kind)
    @Utils.invoke_and_check Lib.helicsCoreRegisterFilter(core, kind, name)
end

"""
"""
function helicsCoreRegisterCloningFilter(core::Core, deliveryEndpoint::String)::Filter
    @Utils.invoke_and_check Lib.helicsCoreRegisterCloningFilter(core, deliveryEndpoint)
end

"""
"""
function helicsFederateGetFilterCount(fed::Federate)::Int
    Lib.helicsFederateGetFilterCount(fed)
end

"""
"""
function helicsFederateGetFilter(fed::Federate, name::String)::Filter
    @Utils.invoke_and_check Lib.helicsFederateGetFilter(fed, name)
end

"""
"""
function helicsFederateGetFilterByIndex(fed::Federate, index::Int)::Filter
    @Utils.invoke_and_check Lib.helicsFederateGetFilterByIndex(fed, index)
end

"""
"""
function helicsFilterGetName(filt::Filter)::String
    Lib.helicsFilterGetName(filt) |> unsafe_string
end

"""
"""
function helicsFilterSet(filt::Filter, prop::String, val::Float64)
    @Utils.invoke_and_check Lib.helicsFilterSet(filt, prop, val)
end

"""
"""
function helicsFilterSetString(filt::Filter, prop::String, val::String)
    @Utils.invoke_and_check Lib.helicsFilterSetString(filt, prop, val)
end

"""
"""
function helicsFilterAddDestinationTarget(filt::Filter, dest::String)
    @Utils.invoke_and_check Lib.helicsFilterAddDestinationTarget(filt, dest)
end

"""
"""
function helicsFilterAddSourceTarget(filt::Filter, source::String)
    @Utils.invoke_and_check Lib.helicsFilterAddSourceTarget(filt, source)
end

"""
"""
function helicsFilterAddDeliveryEndpoint(filt::Filter, deliveryEndpoint::String)
    @Utils.invoke_and_check Lib.helicsFilterAddDeliveryEndpoint(filt, deliveryEndpoint)
end

"""
"""
function helicsFilterRemoveTarget(filt::Filter, target::String)
    @Utils.invoke_and_check Lib.helicsFilterRemoveTarget(filt, target)
end

"""
"""
function helicsFilterRemoveDeliveryEndpoint(filt::Filter, deliveryEndpoint::String)
    @Utils.invoke_and_check Lib.helicsFilterRemoveDeliveryEndpoint(filt, deliveryEndpoint)
end

"""
"""
function helicsFilterGetInfo(filt::Filter)::String
    Lib.helicsFilterGetInfo(filt) |> unsafe_string
end

"""
"""
function helicsFilterSetInfo(filt::Filter, info::String)
    @Utils.invoke_and_check Lib.helicsFilterSetInfo(filt, info)
end

"""
"""
function helicsFilterSetOption(filt::Filter, option::Int, value::Bool)
    @Utils.invoke_and_check Lib.helicsFilterSetOption(filt, option, value ? 1 : 0)
end

"""
"""
function helicsFilterGetOption(filt::Filter, option::Int)::Bool
    r = Lib.helicsFilterGetOption(filt, option)
    return r == 1 ? true : false
end

"""
"""
function helicsFederateRegisterSubscription(fed::Federate, key::String, units::String="")::Subscription
    @Utils.invoke_and_check Lib.helicsFederateRegisterSubscription(fed, key, units)
end

"""
"""
function helicsFederateRegisterPublication(fed::Federate, key::String, kind::Union{Int, HELICS.HELICS_DATA_TYPE}, units::String="")::Publication
    kind = convert(HELICS.HELICS_DATA_TYPE, kind)
    @Utils.invoke_and_check Lib.helicsFederateRegisterPublication(fed, key, kind, units)
end

"""
"""
function helicsFederateRegisterTypePublication(fed::Federate, key::String, kind::String, units::String="")::Publication
    @Utils.invoke_and_check Lib.helicsFederateRegisterTypePublication(fed, key, kind, units)
end

"""
"""
function helicsFederateRegisterGlobalPublication(fed::Federate, key::String, kind::Union{Int, HELICS.HELICS_DATA_TYPE}, units::String="")::Publication
    kind = convert(HELICS.HELICS_DATA_TYPE, kind)
    @Utils.invoke_and_check Lib.helicsFederateRegisterGlobalPublication(fed, key, kind, units)
end

"""
"""
function helicsFederateRegisterGlobalTypePublication(fed::Federate, key::String, kind::String, units::String="")::Publication
    @Utils.invoke_and_check Lib.helicsFederateRegisterGlobalTypePublication(fed, key, kind, units)
end

"""
"""
function helicsFederateRegisterInput(fed::Federate, key::String, kind::Union{Int, HELICS.HELICS_DATA_TYPE}, units::String="")::Input
    kind = convert(HELICS.HELICS_DATA_TYPE, kind)
    @Utils.invoke_and_check Lib.helicsFederateRegisterInput(fed, key, kind, units)
end

"""
"""
function helicsFederateRegisterTypeInput(fed::Federate, key::String, kind::String, units::String="")::Input
    @Utils.invoke_and_check Lib.helicsFederateRegisterTypeInput(fed, key, kind, units)
end

"""
"""
function helicsFederateRegisterGlobalInput(fed::Federate, key::String, kind::Union{Int, HELICS.HELICS_DATA_TYPE}, units::String="")::Input
    kind = convert(HELICS.HELICS_DATA_TYPE, kind)
    @Utils.invoke_and_check Lib.helicsFederateRegisterGlobalInput(fed, key, kind, units)
end

"""
"""
function helicsFederateRegisterGlobalTypeInput(fed::Federate, key::String, kind::String, units::String="")::Input
    @Utils.invoke_and_check Lib.helicsFederateRegisterGlobalTypeInput(fed, key, kind, units)
end

"""
"""
function helicsFederateGetPublication(fed::Federate, key::String)::Publication
    @Utils.invoke_and_check Lib.helicsFederateGetPublication(fed, key)
end

"""
"""
function helicsFederateGetPublicationByIndex(fed::Federate, index::Int)::Publication
    @Utils.invoke_and_check Lib.helicsFederateGetPublicationByIndex(fed, index)
end

"""
"""
function helicsFederateGetInput(fed::Federate, key::String)::Input
    @Utils.invoke_and_check Lib.helicsFederateGetInput(fed, key)
end

"""
"""
function helicsFederateGetInputByIndex(fed::Federate, index::Int)::Input
    @Utils.invoke_and_check Lib.helicsFederateGetInputByIndex(fed, index)
end

"""
"""
function helicsFederateGetSubscription(fed::Federate, key::String)::Subscription
    @Utils.invoke_and_check Lib.helicsFederateGetSubscription(fed, key)
end

"""
"""
function helicsPublicationPublishRaw(pub::Publication, data)
    inputDataLength = length(data)
    data = pointer(data)
    @Utils.invoke_and_check Lib.helicsPublicationPublishRaw(pub, data, inputDataLength)
end

"""
"""
function helicsPublicationPublishString(pub::Publication, str::String)
    @Utils.invoke_and_check Lib.helicsPublicationPublishString(pub, str)
end

"""
"""
function helicsPublicationPublishInteger(pub::Publication, val::Int)
    @Utils.invoke_and_check Lib.helicsPublicationPublishInteger(pub, val)
end

"""
"""
function helicsPublicationPublishBoolean(pub::Publication, val::Bool)
    @Utils.invoke_and_check Lib.helicsPublicationPublishBoolean(pub, val ? 1 : 0)
end

"""
"""
function helicsPublicationPublishDouble(pub::Publication, val::Float64)
    @Utils.invoke_and_check Lib.helicsPublicationPublishDouble(pub, val)
end

"""
"""
function helicsPublicationPublishTime(pub::Publication, val::HELICS.HELICS_TIME)
    val = convert(Float64, val)
    @Utils.invoke_and_check Lib.helicsPublicationPublishTime(pub, val)
end

"""
"""
function helicsPublicationPublishChar(pub::Publication, val::Char)
    @Utils.invoke_and_check Lib.helicsPublicationPublishChar(pub, val)
end

"""
"""
function helicsPublicationPublishComplex(pub::Publication, c::ComplexF64)
    @Utils.invoke_and_check Lib.helicsPublicationPublishComplex(pub, c.re, c.im)
end

"""
"""
function helicsPublicationPublishVector(pub::Publication, vectorInput::Vector{Float64})
    vectorLength = length(vectorInput)
    @Utils.invoke_and_check Lib.helicsPublicationPublishVector(pub, vectorInput, vectorLength)
end

"""
"""
function helicsPublicationPublishNamedPoint(pub::Publication, str::String, val::Float64)
    @Utils.invoke_and_check Lib.helicsPublicationPublishNamedPoint(pub, str, val)
end

"""
"""
function helicsPublicationAddTarget(pub::Publication, target::String)
    @Utils.invoke_and_check Lib.helicsPublicationAddTarget(pub, target)
end

"""
"""
function helicsInputAddTarget(ipt::Input, target::String)
    @Utils.invoke_and_check Lib.helicsInputAddTarget(ipt, target)
end

"""
"""
function helicsInputGetRawValueSize(ipt::Input)::Int
    Lib.helicsInputGetRawValueSize(ipt)
end

"""
"""
function helicsInputGetRawValue(ipt::Input, data::T)::T where T<:Any
    maxlen = Lib.helicsInputGetRawValueSize(ipt)
    actualSize = Ref(maxlen)
    @Utils.invoke_and_check Lib.helicsInputGetRawValue(ipt, data, maxlen, actualSize)
end

"""
"""
function helicsInputGetStringSize(ipt::Input)::Int
    Lib.helicsInputGetStringSize(ipt)
end

"""
"""
function helicsInputGetString(ipt::Input)::String
    maxStringLen = helicsInputGetStringSize(ipt)
    outputString = repeat(" ", maxStringLen + 2)
    actualLength = Ref{Int32}(maxStringLen)
    @Utils.invoke_and_check Lib.helicsInputGetString(ipt, outputString, maxStringLen, actualLength)
    return outputString[1:(actualLength[]-1)]
end

"""
"""
function helicsInputGetInteger(ipt::Input)::Int
    @Utils.invoke_and_check Lib.helicsInputGetInteger(ipt)
end

"""
"""
function helicsInputGetBoolean(ipt::Input)::Bool
    r = @Utils.invoke_and_check Lib.helicsInputGetBoolean(ipt)
    return r == 1 ? true : false
end

"""
"""
function helicsInputGetDouble(ipt::Input)::Float64
    @Utils.invoke_and_check Lib.helicsInputGetDouble(ipt)
end

"""
"""
function helicsInputGetTime(ipt::Input)::Float64
    @Utils.invoke_and_check Lib.helicsInputGetTime(ipt)
end

"""
"""
function helicsInputGetChar(ipt::Input)::Char
    @Utils.invoke_and_check Lib.helicsInputGetChar(ipt)
end

"""
"""
function helicsInputGetComplexObject(ipt::Input)::ComplexF64
    r = @Utils.invoke_and_check Lib.helicsInputGetComplexObject(ipt)
    return r.real + im * r.imag
end

"""
"""
function helicsInputGetComplex(ipt::Input)::ComplexF64
    real = Ref{Float64}(0)
    imag = Ref{Float64}(0)
    @Utils.invoke_and_check Lib.helicsInputGetComplex(ipt, real, imag)
    return real[] + im * imag[]
end

"""
"""
function helicsInputGetVectorSize(ipt::Input)::Int64
    Lib.helicsInputGetVectorSize(ipt)
end

"""
"""
function helicsInputGetVector(ipt::Input)::Vector{Float64}
    maxlen = Cint(helicsInputGetVectorSize(ipt))
    data = Vector{Float64}(undef, maxlen)
    actualSize = Ref(maxlen)
    @Utils.invoke_and_check Lib.helicsInputGetVector(ipt, data, maxlen, actualSize)
    return data[1:actualSize[]]
end

"""
"""
function helicsInputGetNamedPoint(ipt::Input)::Tuple{String, Float64}
    maxStringLen = helicsInputGetStringSize(ipt)
    outputString = repeat(" ", maxStringLen + 2)
    actualLength = Ref{Int32}(maxStringLen)
    val = Ref{Float64}(0.0)
    @Utils.invoke_and_check Lib.helicsInputGetNamedPoint(ipt, outputString, maxStringLen, actualLength, val)
    return outputString[1:(actualLength[]-1)], val[]
end

"""
"""
function helicsInputSetDefaultRaw(ipt::Input, data)
    inputDataLength = length(data)
    @Utils.invoke_and_check Lib.helicsInputSetDefaultRaw(ipt, data, inputDataLength)
end

"""
"""
function helicsInputSetDefaultString(ipt::Input, str::String)
    @Utils.invoke_and_check Lib.helicsInputSetDefaultString(ipt, str)
end

"""
"""
function helicsInputSetDefaultInteger(ipt::Input, val::Int)
    @Utils.invoke_and_check Lib.helicsInputSetDefaultInteger(ipt, val)
end

"""
"""
function helicsInputSetDefaultBoolean(ipt::Input, val::Bool)
    @Utils.invoke_and_check Lib.helicsInputSetDefaultBoolean(ipt, val ? 1 : 0)
end

"""
"""
function helicsInputSetDefaultTime(ipt::Input, val::HELICS.HELICS_TIME)
    val = convert(Float64, val)
    @Utils.invoke_and_check Lib.helicsInputSetDefaultTime(ipt, val)
end

"""
"""
function helicsInputSetDefaultChar(ipt::Input, val::Char)
    @Utils.invoke_and_check Lib.helicsInputSetDefaultChar(ipt, val)
end

"""
"""
function helicsInputSetDefaultDouble(ipt::Input, val::Float64)
    @Utils.invoke_and_check Lib.helicsInputSetDefaultDouble(ipt, val)
end

"""
"""
function helicsInputSetDefaultComplex(ipt::Input, c::ComplexF64)
    @Utils.invoke_and_check Lib.helicsInputSetDefaultComplex(ipt, c.re, c.im)
end

"""
"""
function helicsInputSetDefaultVector(ipt::Input, vectorInput::Vector{Float64})
    vectorLength = length(vectorInput)
    @Utils.invoke_and_check Lib.helicsInputSetDefaultVector(ipt, vectorInput, vectorLength)
end

"""
"""
function helicsInputSetDefaultNamedPoint(ipt::Input, str::String, val::Float64)
    @Utils.invoke_and_check Lib.helicsInputSetDefaultNamedPoint(ipt, str, val)
end

"""
"""
function helicsInputGetType(ipt::Input)::String
    Lib.helicsInputGetType(ipt) |> unsafe_string
end

"""
"""
function helicsInputGetPublicationType(ipt::Input)::String
    Lib.helicsInputGetPublicationType(ipt) |> unsafe_string
end

"""
"""
function helicsPublicationGetType(pub::Publication)::String
    Lib.helicsPublicationGetType(pub) |> unsafe_string
end

"""
"""
function helicsInputGetKey(ipt::Input)::String
    Lib.helicsInputGetKey(ipt) |> unsafe_string
end

"""
"""
function helicsSubscriptionGetKey(ipt::Input)::String
    Lib.helicsSubscriptionGetKey(ipt) |> unsafe_string
end

"""
"""
function helicsPublicationGetKey(pub::Publication)::String
    Lib.helicsPublicationGetKey(pub) |> unsafe_string
end

"""
"""
function helicsInputGetUnits(ipt::Input)::String
    Lib.helicsInputGetUnits(ipt) |> unsafe_string
end

"""
"""
function helicsPublicationGetUnits(pub::Publication)::String
    Lib.helicsPublicationGetUnits(pub) |> unsafe_string
end

"""
"""
function helicsInputGetInfo(inp::Input)::String
    Lib.helicsInputGetInfo(inp) |> unsafe_string
end

"""
"""
function helicsInputSetInfo(inp::Input, info::String)
    @Utils.invoke_and_check Lib.helicsInputSetInfo(inp, info)
end

"""
"""
function helicsPublicationGetInfo(pub::Publication)::String
    Lib.helicsPublicationGetInfo(pub) |> unsafe_string
end

"""
"""
function helicsPublicationSetInfo(pub::Publication, info::String)
    @Utils.invoke_and_check Lib.helicsPublicationSetInfo(pub, info)
end

"""
"""
function helicsInputGetOption(inp::Input, option::Int)::Bool
    Lib.helicsInputGetOption(inp, option::Int) == 1 ? true : false
end

"""
"""
function helicsInputSetOption(inp::Input, option::Int, value::Bool)
    @Utils.invoke_and_check Lib.helicsInputSetOption(inp, option, value ? 1 : 0)
end

"""
"""
function helicsPublicationGetOption(pub::Publication, option::Int)::Bool
    Lib.helicsPublicationGetOption(pub, option) == 1 ? true : false
end

"""
"""
function helicsPublicationSetOption(pub::Publication, option::Int, val::Bool)
    @Utils.invoke_and_check Lib.helicsPublicationSetOption(pub, option, val ? 1 : 0)
end

"""
"""
function helicsInputIsUpdated(ipt::Input)::Bool
    Lib.helicsInputIsUpdated(ipt) == 1 ? true : false
end

"""
"""
function helicsInputLastUpdateTime(ipt::Input)::Float64
    Lib.helicsInputLastUpdateTime(ipt)
end

"""
"""
function helicsFederateGetPublicationCount(fed::Federate)::Int
    Lib.helicsFederateGetPublicationCount(fed)
end

"""
"""
function helicsFederateGetInputCount(fed::Federate)::Int
    Lib.helicsFederateGetInputCount(fed)
end

"""
Get a version string for HELICS
"""
function helicsGetVersion()::String
    return Lib.helicsGetVersion() |> unsafe_string
end

"""
Return an initialized error object
"""
function helicsErrorInitialize()::Lib.helics_error
    Lib.helicsErrorInitialize()
end

"""
Clear an error object
"""
function helicsErrorClear(err::Lib.helics_error)
    Lib.helicsErrorClear(err)
end

"""
Returns true if core/broker type specified is available in current compilation.

# Arguments

- `type`: a string representing a core type

# Returns

- a `Bool`

possible options include "test","zmq","udp","ipc","interprocess","tcp","default", "mpi"

"""
function helicsIsCoreTypeAvailable(kind::String)::Bool
    Lib.helicsIsCoreTypeAvailable(kind) == 1 ? true : false
end

"""
Create a core object

# Arguments

- `type`: the type of the core to create
- `name`: the name of the core , may be a nullptr or empty string to have a name automatically assigned
- `initString`: an initialization string to send to the core-the format is similar to command line arguments. Typical options include a broker address  --broker="XSSAF" or the number of federates or the address

# Returns

- a [`Core`](@ref) object if the core is invalid err will contain some indication

"""
function helicsCreateCore(kind::String, name::String, initString::String)::Core
    @Utils.invoke_and_check Lib.helicsCreateCore(kind, name, initString)
end

"""
"""
function helicsCreateCoreFromArgs(kind::String, name::String, argc::Int, argv::Vector{String})::Core
    @Utils.invoke_and_check Lib.helicsCreateCoreFromArgs(kind, name, argc, argv)
end

"""
Create a new reference to an existing core

this will create a new broker object that references the existing broker it must be freed as well

# Arguments

- `core`: an existing [`Core`](@ref)

# Returns

- a new reference to the same [`Core`](@ref)
"""
function helicsCoreClone(core::Core)::Core
    @Utils.invoke_and_check Lib.helicsCoreClone(core)
end

"""
Check if a core object is a valid object

# Arguments

- `core`: the [`Core`](@ref) object to test
"""
function helicsCoreIsValid(core::Core)::Bool
    Lib.helicsCoreIsValid(core) == 1 ? true : false
end

"""
Create a broker object

# Arguments

- `type`: the type of the broker to create
- `name`: the name of the broker , may be a nullptr or empty string to have a name automatically assigned
- `initString`: an initialization string to send to the core-the format is similar to command line arguments. Typical options include a broker address  --broker="XSSAF" if this is a subbroker or the number of federates or the address

# Returns

- a [`Broker`](@ref) object, will be NULL if there was an error indicated in the err object

"""
function helicsCreateBroker(kind::String, name::String, initString::String)::Broker
    @Utils.invoke_and_check Lib.helicsCreateBroker(kind, name, initString)
end

"""
"""
function helicsCreateBrokerFromArgs(kind::String, name::String, argc::Int, argv::Vector{String})::Broker
    @Utils.invoke_and_check Lib.helicsCreateBrokerFromArgs(kind, name, argc, argv)
end

"""
Create a new reference to an existing broker

this will create a new broker object that references the existing broker it must be freed as well

# Arguments

- `broker`: an existing [`Broker`](@ref)

# Returns

- a new reference to the same broker
"""
function helicsBrokerClone(broker::Broker)::Broker
    @Utils.invoke_and_check Lib.helicsBrokerClone(broker)
end

"""
Check if a broker object is a valid object

# Arguments

- `broker`: the [`Broker`](@ref) object to test
"""
function helicsBrokerIsValid(broker::Broker)::Bool
    Lib.helicsBrokerIsValid(broker) == 1 ? true : false
end

"""
Check if a broker is connected. A connected broker implies is attached to cores or cores could reach out to communicate. return 0 if not connected , something else if it is connected.
"""
function helicsBrokerIsConnected(broker::Broker)::Bool
    Lib.helicsBrokerIsConnected(broker) == 1 ? true : false
end

"""
Link a named publication and named input using a broker

# Arguments

- `broker`: the [`Broker`](@ref) to generate the connection from
- `source`: the name of the publication (cannot be NULL)
- `target`: the name of the target to send the publication data (cannot be NULL)

"""
function helicsBrokerDataLink(broker::Broker, source::String, target::String)
    @Utils.invoke_and_check Lib.helicsBrokerDataLink(broker, source, target)
end

"""
"""
function helicsBrokerAddSourceFilterToEndpoint(broker::Broker, filter::String, endpoint::String)
    @Utils.invoke_and_check Lib.helicsBrokerAddSourceFilterToEndpoint(broker, filter, endpoint)
end

"""
"""
function helicsBrokerAddDestinationFilterToEndpoint(broker::Broker, filter::String, endpoint::String)
    @Utils.invoke_and_check Lib.helicsBrokerAddDestinationFilterToEndpoint(broker, filter, endpoint)
end

"""
Wait for the broker to disconnect

# Arguments

- `broker`: the broker to wait for
- `msToWait`: the time out in millisecond (<0 for infinite timeout)

# Returns

- `true` if the disconnect was successful, `false` if there was a timeout

"""
function helicsBrokerWaitForDisconnect(broker::Broker, msToWait::Int)::Bool
    r = @Utils.invoke_and_check Lib.helicsBrokerWaitForDisconnect(broker, msToWait)
    return r == 1 ? true : false
end

"""
Check if a core is connected. A connected core implies is attached to federate or federates could be attached to it.

# Returns

- `false` if not connected, `true` if it is connected
"""
function helicsCoreIsConnected(core::Core)::Bool
    Lib.helicsCoreIsConnected(core) == 1 ? true : false
end

"""
Link a named publication and named input using a core

# Arguments

- `core`: the core to generate the connection from
- `source`: the name of the publication (cannot be NULL)
- `target`: the named of the target to send the publication data (cannot be NULL)

"""
function helicsCoreDataLink(core::Core, source::String, target::String)
    @Utils.invoke_and_check Lib.helicsCoreDataLink(core, source, target)
end

"""
Link a named filter to a source endpoint

# Arguments

- `core`: the core to generate the connection from
- `filter`: the name of the filter (cannot be NULL)
- `endpoint`: the name of the endpoint to filter the data from (cannot be NULL)

"""
function helicsCoreAddSourceFilterToEndpoint(core::Core, filter::String, endpoint::String)
    @Utils.invoke_and_check Lib.helicsCoreAddSourceFilterToEndpoint(core, filter, endpoint)
end

"""
"""
function helicsCoreAddDestinationFilterToEndpoint(core::Core, filter::String, endpoint::String)
    @Utils.invoke_and_check Lib.helicsCoreAddDestinationFilterToEndpoint(core, filter, endpoint)
end

"""
Get an identifier for the broker

# Arguments

- `broker`: the broker to query

# Returns

- a string containing the identifier for the broker

"""
function helicsBrokerGetIdentifier(broker::Broker)::String
    Lib.helicsBrokerGetIdentifier(broker) |> unsafe_string
end

"""
Get an identifier for the core

# Arguments

- `core`: the core to query

# Returns

- a string with the identifier of the core

"""
function helicsCoreGetIdentifier(core::Core)::String
    Lib.helicsCoreGetIdentifier(core) |> unsafe_string
end

"""
Get the network address associated with a broker

# Arguments

- `broker`: the broker to query

# Returns

- a string with the network address of the broker

"""
function helicsBrokerGetAddress(broker::Broker)::String
    Lib.helicsBrokerGetAddress(broker) |> unsafe_string
end

"""
Set the core to ready for init

this function is used for cores that have filters but no federates so there needs to be a direct signal to the core to trigger the federation initialization

# Arguments

- `core`: the core object to enable init values for

"""
function helicsCoreSetReadyToInit(core::Core)
    @Utils.invoke_and_check Lib.helicsCoreSetReadyToInit(core)
end

"""
Get an identifier for the core

# Arguments

- `core`: the core to query

# Returns

- a void enumeration indicating any error condition

"""
function helicsCoreDisconnect(core::Core)
    @Utils.invoke_and_check Lib.helicsCoreDisconnect(core)
end

"""
Get an existing [`Federate`](@ref) from a core by name

the federate must have been created by one of the other functions and at least one of the objects referencing the created
    federate must still be active in the process

# Arguments

- `fedName`: the name of the federate to retrieve

# Returns

- NULL if no fed is available by that name otherwise a [`Federate`](@ref) with that name
"""
function helicsGetFederateByName(fedName::String)::CombinationFederate
    @Utils.invoke_and_check Lib.helicsGetFederateByName(fedName)
end

"""
Disconnect a broker

# Arguments

- `broker`: the broker to disconnect

"""
function helicsBrokerDisconnect(broker::Broker)
    @Utils.invoke_and_check Lib.helicsBrokerDisconnect(broker)
end

"""
Disconnect and free a broker
"""
function helicsFederateDestroy(fed::Federate)
    Lib.helicsFederateDestroy(fed)
end

"""
Disconnect and free a broker
"""
function helicsBrokerDestroy(broker::Broker)
    Lib.helicsBrokerDestroy(broker)
end

"""
Disconnect and free a core
"""
function helicsCoreDestroy(core::Core)
    Lib.helicsCoreDestroy(core)
end

"""
Release the memory associated with a core
"""
function helicsCoreFree(core::Core)
    Lib.helicsCoreFree(core)
end

"""
Release the memory associated with a broker
"""
function helicsBrokerFree(broker::Broker)
    Lib.helicsBrokerFree(broker)
end

"""
Create a value federate from a [`FederateInfo`](@ref) object

[`Federate`](@ref) objects can be used in all functions that take a [`Federate`](@ref) object as an argument

# Arguments

- `fedName`: the name of the federate to create, can NULL or an empty string to use the default name from fi or an assigned name
- `fi`: the [`FederateInfo`](@ref) object that contains details on the federate

# Returns

- an opaque value [`Federate`](@ref)

"""
function helicsCreateValueFederate(fedName::String, fi::FederateInfo)::ValueFederate
    @Utils.invoke_and_check Lib.helicsCreateValueFederate(fedName, fi)
end

"""
Create a value federate from a JSON file, JSON string, or TOML file

[`Federate`](@ref) objects can be used in all functions that take a [`Federate`](@ref) object as an argument

# Arguments

- `configFile`:  a JSON file or a JSON string or TOML file that contains setup and configuration information

# Returns

- an opaque value [`Federate`](@ref)

"""
function helicsCreateValueFederateFromConfig(configFile::String)::ValueFederate
    @Utils.invoke_and_check Lib.helicsCreateValueFederateFromConfig(configFile)
end

"""
Create a [`MessageFederate`](@ref) from a [`FederateInfo`](@ref) object

[`MessageFederate`](@ref) objects can be used in all functions that take a [`MessageFederate`](@ref) or [`Federate`](@ref) object as an argument

# Arguments

- `fedName`: the name of the federate to create
- `fi`: the [`FederateInfo`](@ref) object that contains details on the federate

# Returns

- an opaque [`MessageFederate`](@ref)

"""
function helicsCreateMessageFederate(fedName::String, fi::FederateInfo)::MessageFederate
    @Utils.invoke_and_check Lib.helicsCreateMessageFederate(fedName, fi)
end

"""
Create a [`MessageFederate`](@ref) from a JSON file or JSON string or TOML file

[`MessageFederate`](@ref) objects can be used in all functions that take a [`MessageFederate`](@ref) or [`Federate`](@ref) object as an argument

# Arguments

- `configFile`:  a Config(JSON,TOML) file or a JSON string that contains setup and configuration information

# Returns

- an opaque [`MessageFederate`](@ref)

"""
function helicsCreateMessageFederateFromConfig(configFile::String)::MessageFederate
    @Utils.invoke_and_check Lib.helicsCreateMessageFederateFromConfig(configFile)
end

"""
Create a [`CombinationFederate`](@ref) from a [`FederateInfo`](@ref) object

[`CombinationFederate`](@ref) are both [`ValueFederate`](@ref) and [`MessageFederate`](@ref), objects can be used in all functions that take a [`Federate`](@ref), [`MessageFederate`](@ref) or [`ValueFederate`](@ref) object as an argument

# Arguments

- `fedName`: a string with the name of the federate, can be NULL or an empty string to pull the default name from fi
- `fi`: the [`FederateInfo`](@ref) object that contains details on the federate

# Returns

- an opaque [`ValueFederate`](@ref), nullptr if the object creation failed

"""
function helicsCreateCombinationFederate(fedName::String, fi::FederateInfo)::CombinationFederate
    @Utils.invoke_and_check Lib.helicsCreateCombinationFederate(fedName, fi)
end

"""
Create a [`CombinationFederate`](@ref) from a JSON file or JSON string

[`CombinationFederate`](@ref) are both [`ValueFederate`](@ref) and [`MessageFederate`](@ref), objects can be used in all functions that take a [`Federate`](@ref), [`MessageFederate`](@ref) or [`ValueFederate`](@ref) object as an argument

# Arguments

- `configFile`:  a JSON file or a JSON string or TOML file that contains setup and configuration information

# Returns

- an opaque [`CombinationFederate`](@ref)

"""
function helicsCreateCombinationFederateFromConfig(configFile::String)::CombinationFederate
    @Utils.invoke_and_check Lib.helicsCreateCombinationFederateFromConfig(configFile)
end

"""
Create a new reference to an existing federate

this will create a new [`Federate`](@ref) object that references the existing federate it must be freed as well

# Arguments

- `fed`: an existing [`Federate`](@ref)

# Returns

- a new reference to the same federate
"""
function helicsFederateClone(fed::T)::T where T <: Federate
    @Utils.invoke_and_check Lib.helicsFederateClone(fed)
end

"""
Create a [`FederateInfo`](@ref) object for specifying federate information when constructing a federate

# Returns

- a [`FederateInfo`](@ref) object which is a reference to the created object

"""
function helicsCreateFederateInfo()::FederateInfo
    Lib.helicsCreateFederateInfo()
end

"""
Create a [`FederateInfo`](@ref) object from an existing one and clone the information

# Arguments

- `fi`: a [`FederateInfo`](@ref) object to duplicate

# Returns

- a helics_federate_info object which is a reference to the created object

"""
function helicsFederateInfoClone(fi::FederateInfo)::FederateInfo
    @Utils.invoke_and_check Lib.helicsFederateInfoClone(fi)
end

"""
Load a [`FederateInfo`](@ref) from command line arguments

# Arguments

- `fi`: a [`FederateInfo`](@ref) object
- `argc`: the number of command line arguments
- `argv`: an array of strings from the command line

"""
function helicsFederateInfoLoadFromArgs(fi::FederateInfo, argc::Int, argv::Vector{String})
    @Utils.invoke_and_check Lib.helicsFederateInfoLoadFromArgs(fi, argc, argv)
end

"""
Delete the memory associated with a [`FederateInfo`](@ref) object
"""
function helicsFederateInfoFree(fi::FederateInfo)
    Lib.helicsFederateInfoFree(fi)
end

"""
Check if a federate_object is valid

# Returns

- `true` if the federate is a valid active federate, `false` otherwise
"""
function helicsFederateIsValid(fed::Federate)::Bool
    Lib.helicsFederateIsValid(fed) == 1 ? true : false
end

"""
Set the name of the core to link to for a federate

# Arguments

- `fi`: the [`FederateInfo`](@ref) object to alter
- `corename`: the identifier for a core to link to

"""
function helicsFederateInfoSetCoreName(fi::FederateInfo, corename::String)
    @Utils.invoke_and_check Lib.helicsFederateInfoSetCoreName(fi, corename)
end

"""
Set the initialization string for the core usually in the form of command line arguments

# Arguments

- `fi`: the [`FederateInfo`](@ref) object to alter
- `coreInit`: a string with the core initialization strings

"""
function helicsFederateInfoSetCoreInitString(fi::FederateInfo, coreInit::String)
    @Utils.invoke_and_check Lib.helicsFederateInfoSetCoreInitString(fi, coreInit)
end

"""
Set the core type by integer code

valid values available by definitions in api-data.h

# Arguments

- `fi`: the [`FederateInfo`](@ref) object to alter
- `coretype`: an numerical code for a core type see /ref helics_core_type

"""
function helicsFederateInfoSetCoreType(fi::FederateInfo, coretype::Union{Int, HELICS.HELICS_CORE_TYPE})
    coretype = convert(HELICS.HELICS_CORE_TYPE, coretype)
    @Utils.invoke_and_check Lib.helicsFederateInfoSetCoreType(fi, coretype)
end

"""
Set the core type from a string

# Arguments

- `fi`: the [`FederateInfo`](@ref) object to alter
- `coretype`: a string naming a core type

"""
function helicsFederateInfoSetCoreTypeFromString(fi::FederateInfo, coretype::String)
    @Utils.invoke_and_check Lib.helicsFederateInfoSetCoreTypeFromString(fi, coretype)
end

"""
Set the name or connection information for a broker

this is only used if the core is automatically created, the broker information will be transferred to the core for connection

# Arguments

- `fi`: the [`FederateInfo`](@ref) object to alter
- `broker`: a string which defined the connection information for a broker either a name or an address

"""
function helicsFederateInfoSetBroker(fi::FederateInfo, broker::Broker)
    @Utils.invoke_and_check Lib.helicsFederateInfoSetBroker(fi, broker)
end

"""
Set the port to use for the broker

this is only used if the core is automatically created, the broker information will be transferred to the core for connection this will only be useful for network broker connections

# Arguments

- `fi`: the [`FederateInfo`](@ref) object to alter
- `brokerPort`: the integer port number to use for connection with a broker

"""
function helicsFederateInfoSetBrokerPort(fi::FederateInfo, brokerPort::Int)
    @Utils.invoke_and_check Lib.helicsFederateInfoSetBrokerPort(fi, brokerPort)
end

"""
Set the local port to use

this is only used if the core is automatically created, the port information will be transferred to the core for connection

# Arguments

- `fi`: the [`FederateInfo`](@ref) object to alter
- `localPort`: a string with the port information to use as the local server port can be a number or "auto" or "os_local"

"""
function helicsFederateInfoSetLocalPort(fi::FederateInfo, localPort::Int)
    @Utils.invoke_and_check Lib.helicsFederateInfoSetLocalPort(fi, localPort)
end

"""
Get a property index for use in [`helicsFederateInfoSetFlagOption`](@ref), [`helicsFederateInfoSetTimeProperty`](@ref), [`helicsFederateInfoSetIntegerProperty`](@ref)

# Arguments

- `val`: a string with the property name

# Returns

- an int with the property code (-1) if not a valid property

"""
function helicsGetPropertyIndex(val::String)::Int
    Lib.helicsGetPropertyIndex(val)
end

"""
Get an option index for use in [`helicsPublicationSetOption`](@ref), [`helicsInputSetOption`](@ref), [`helicsEndpointSetOption`](@ref), [`helicsFilterSetOption`](@ref), and the corresponding get functions

# Arguments

- `val`: a string with the option name

# Returns

- an int with the option index (-1) if not a valid property

"""
function helicsGetOptionIndex(val::String)::Int
    Lib.helicsGetOptionIndex(val)
end

"""
Set a flag in the info structure

valid flags are available [`HELICS_FEDERATE_FLAGS`](@ref)

# Arguments

- `fi`: the [`FederateInfo`](@ref) object to alter
- `flag`: a numerical index for a flag
- `value`: the desired value of the flag `true` or `false`

"""
function helicsFederateInfoSetFlagOption(fi::FederateInfo, flag::Union{Int, HELICS.HELICS_FEDERATE_FLAGS}, value::Bool)
    flag = convert(HELICS.HELICS_FEDERATE_FLAGS, flag)
    @Utils.invoke_and_check Lib.helicsFederateInfoSetFlagOption(fi, flag, value ? 1 : 0)
end

"""
Set the separator character in the info structure

the separator character is the separation character for local publications/endpoints in creating their global name. for example if the separator character is '/'  then a local endpoint would have a globally reachable name of fedName/localName

# Arguments

- `fi`: the [`FederateInfo`](@ref) object to alter
- `separator`: the character to use as a separator

"""
function helicsFederateInfoSetSeparator(fi::FederateInfo, separator::Char)
    @Utils.invoke_and_check Lib.helicsFederateInfoSetSeparator(fi, separator)
end

"""
"""
function helicsFederateInfoSetTimeProperty(fi::FederateInfo, timeProperty::Union{Int, HELICS.HELICS_PROPERTIES}, propertyValue::HELICS.HELICS_TIME)
    propertyValue = convert(Float64, propertyValue)
    timeProperty = convert(HELICS.HELICS_PROPERTIES, timeProperty)
    @Utils.invoke_and_check Lib.helicsFederateInfoSetTimeProperty(fi, timeProperty, propertyValue)
end

"""
"""
function helicsFederateInfoSetIntegerProperty(fi::FederateInfo, intProperty::Union{Int, HELICS.HELICS_PROPERTIES}, propertyValue::Int)
    intProperty = convert(HELICS.HELICS_PROPERTIES, intProperty)
    @Utils.invoke_and_check Lib.helicsFederateInfoSetIntegerProperty(fi, intProperty, propertyValue)
end

"""
Load interfaces from a file

# Arguments

- `fed`: the federate to which to load interfaces
- `file`: the name of a file to load the interfaces from either JSON, or TOML

"""
function helicsFederateRegisterInterfaces(fed::Federate, file::String)
    @Utils.invoke_and_check Lib.helicsFederateRegisterInterfaces(fed, file)
end

"""
Finalize the federate this function halts all communication in the federate and disconnects it from the core
"""
function helicsFederateFinalize(fed::Federate)
    @Utils.invoke_and_check Lib.helicsFederateFinalize(fed)
end

"""
Finalize the federate in an async call
"""
function helicsFederateFinalizeAsync(fed::Federate)
    @Utils.invoke_and_check Lib.helicsFederateFinalizeAsync(fed)
end

"""
Complete the asynchronous finalize call
"""
function helicsFederateFinalizeComplete(fed::Federate)
    @Utils.invoke_and_check Lib.helicsFederateFinalizeComplete(fed)
end

"""
Release the memory associated withe a federate
"""
function helicsFederateFree(fed::Federate)
    Lib.helicsFederateFree(fed)
end

"""
Call when done using the helics library,  this function will ensure the threads are closed properly if possible
    this should be the last call before exiting,
"""
function helicsCloseLibrary()
    Lib.helicsCloseLibrary()
end

"""
Enter the initialization state of a federate

the initialization state allows initial values to be set and received if the iteration is requested on entry to the execution state. This is a blocking call and will block until the core allows it to proceed.

# Arguments

- `fed`: the federate to operate on

"""
function helicsFederateEnterInitializingMode(fed::Federate)
    @Utils.invoke_and_check Lib.helicsFederateEnterInitializingMode(fed)
end

"""
Non blocking alternative to [`helicsFederateEnterInitializingMode`](@ref).
The function [`helicsFederateFinalize`](@ref) must be called to finish the operation

# Arguments

- `fed`: the federate to operate on

"""
function helicsFederateEnterInitializingModeAsync(fed::Federate)
    @Utils.invoke_and_check Lib.helicsFederateEnterInitializingModeAsync(fed)
end

"""
Check if the current Asynchronous operation has completed

# Arguments

- `fed`: the federate to operate on

# Returns

- `false` if not completed, `true` if completed
"""
function helicsFederateIsAsyncOperationCompleted(fed::Federate)::Bool
    r = @Utils.invoke_and_check Lib.helicsFederateIsAsyncOperationCompleted(fed)
    return r == 1 ? true : false
end

"""
Finalize the entry to initialize mode that was initiated with [`helicsFederateEnterInitializingModeAsync`](@ref)

# Arguments

- `fed`: the federate desiring to complete the initialization step function
"""
function helicsFederateEnterInitializingModeComplete(fed::Federate)
    @Utils.invoke_and_check Lib.helicsFederateEnterInitializingModeComplete(fed)
end

"""
Request that the federate enter the Execution mode

this call is blocking until granted entry by the core object for an asynchronous alternative call [`helicsFederateEnterExecutingModeAsync`](@ref) on return from this call the federate will be at time 0.

# Arguments

- `fed`: a federate to change modes

"""
function helicsFederateEnterExecutingMode(fed::Federate)
    @Utils.invoke_and_check Lib.helicsFederateEnterExecutingMode(fed)
end

"""
Request that the federate enter the Execution mode

this call is non-blocking and will return immediately.
Call [`helicsFederateEnterExecutingModeComplete`](@ref) to finish the call sequence.

# Arguments

- `fed`: the federate object to complete the call

"""
function helicsFederateEnterExecutingModeAsync(fed::Federate)
    @Utils.invoke_and_check Lib.helicsFederateEnterExecutingModeAsync(fed)
end

"""
Complete the call to [`helicsFederateEnterExecutingModeAsync`](@ref)

# Arguments

- `fed`: the federate object to complete the call

"""
function helicsFederateEnterExecutingModeComplete(fed::Federate)
    @Utils.invoke_and_check Lib.helicsFederateEnterExecutingModeComplete(fed)
end

"""
Request an iterative time

this call allows for finer grain control of the iterative process then [`helicsFederateRequestTime`](@ref) it takes a time and iteration request and return a time and iteration status.

# Arguments

- `fed`: the federate to make the request of
- `iterate`: the requested iteration mode

# Returns

- an iteration structure with field containing the time and iteration status

"""
function helicsFederateEnterExecutingModeIterative(fed::Federate, iterate::Union{Int, HELICS.HELICS_ITERATION_REQUEST})::HELICS.HELICS_ITERATION_RESULT
    iterate = convert(HELICS.HELICS_ITERATION_REQUEST, iterate)
    @Utils.invoke_and_check Lib.helicsFederateEnterExecutingModeIterative(fed, iterate)
end

"""
"""
function helicsFederateEnterExecutingModeIterativeAsync(fed::Federate, iterate::Union{Int, HELICS.HELICS_ITERATION_REQUEST})::HELICS.HELICS_ITERATION_RESULT
    iterate = convert(HELICS.HELICS_ITERATION_REQUEST, iterate)
    @Utils.invoke_and_check Lib.helicsFederateEnterExecutingModeIterativeAsync(fed, iterate)
end

"""
Complete the asynchronous iterative call into ExecutionModel

# Arguments

- `fed`: the federate to make the request of

# Returns

- an iteration object containing the iteration time and iteration_status

"""
function helicsFederateEnterExecutingModeIterativeComplete(fed::Federate)::HELICS.HELICS_ITERATION_RESULT
    @Utils.invoke_and_check Lib.helicsFederateEnterExecutingModeIterativeComplete(fed)
end

"""
Get the current state of a federate

# Arguments

- `fed`: the [`Federate`](@ref) to query

# Returns

- state the resulting state if void return helics_ok
"""
function helicsFederateGetState(fed::Federate)::HELICS.HELICS_FEDERATE_STATE
    @Utils.invoke_and_check Lib.helicsFederateGetState(fed)
end

"""
Get the core object associated with a federate

# Arguments

- `fed`: a federate object

# Returns

- a core object, nullptr if invalid

"""
function helicsFederateGetCoreObject(fed::Federate)::Core
    @Utils.invoke_and_check Lib.helicsFederateGetCoreObject(fed)
end

"""
Request the next time for federate execution

# Arguments

- `fed`: the federate to make the request of
- `requestTime`: the next requested time

# Returns

- the time granted to the federate
    invalid
"""
function helicsFederateRequestTime(fed::Federate, requestTime::HELICS.HELICS_TIME)::Float64
    requestTime = convert(Float64, requestTime)
    @Utils.invoke_and_check Lib.helicsFederateRequestTime(fed, requestTime)
end

"""
Request the next time step for federate execution

feds should have setup the period or minDelta for this to work well but it will request the next time step which is the current time plus the minimum time step.

# Arguments

- `fed`: the federate to make the request of

# Returns

- the time granted to the federate
"""
function helicsFederateRequestNextStep(fed::Federate)::Float64
    @Utils.invoke_and_check Lib.helicsFederateRequestNextStep(fed)
end

"""
Request an iterative time

this call allows for finer grain control of the iterative process then [`helicsFederateRequestTime`](@ref) it takes a time and iteration request and return a time and iteration status.

# Arguments

- `fed`: the federate to make the request of
- `requestTime`: the next desired time
- `iterate`: the requested iteration mode

# Returns

- the granted time
- the iteration specification of the result

"""
function helicsFederateRequestTimeIterative(fed::Federate, requestTime::HELICS.HELICS_TIME, iterate::Union{Int, HELICS.HELICS_ITERATION_REQUEST})::Tuple{Float64, HELICS.HELICS_ITERATION_RESULT}
    requestTime = convert(Float64, requestTime)
    iterate = convert(HELICS.HELICS_ITERATION_REQUEST, iterate)
    outIterate = Ref{HELICS.HELICS_ITERATION_RESULT}(0)
    t = @Utils.invoke_and_check Lib.helicsFederateRequestTimeIterative(fed, requestTime, iterate, outIterate)
    return t, outIterate
end

"""
Request the next time for federate execution in an asynchronous call
Call [`helicsFederateRequestTimeComplete`](@ref) to finish the call

# Arguments

- `fed`: the federate to make the request of
- `requestTime`: the next requested time

"""
function helicsFederateRequestTimeAsync(fed::Federate, requestTime::HELICS.HELICS_TIME)
    requestTime = convert(Float64, requestTime)
    @Utils.invoke_and_check Lib.helicsFederateRequestTimeAsync(fed, requestTime)
end

"""
Complete an asynchronous requestTime call

# Arguments

- `fed`: the federate to make the request of

# Returns

- the time granted to the federate
"""
function helicsFederateRequestTimeComplete(fed::Federate)::Float64
    @Utils.invoke_and_check Lib.helicsFederateRequestTimeComplete(fed)
end

"""
Request an iterative time through an asynchronous call

this call allows for finer grain control of the iterative process then [`helicsFederateRequestTime`](@ref) it takes a time an iteration request and returns a time and iteration status call [`helicsFederateRequestTimeIterativeComplete`](@ref) to finish the process.

# Arguments

- `fed`: the federate to make the request of
- `requestTime`: the next desired time
- `iterate`: the requested iteration mode

# Returns

- a void object with a return code of the result

"""
function helicsFederateRequestTimeIterativeAsync(fed::Federate, requestTime::HELICS.HELICS_TIME, iterate::Union{Int, HELICS.HELICS_ITERATION_REQUEST})
    requestTime = convert(Float64, requestTime)
    iterate = convert(HELICS.HELICS_ITERATION_REQUEST, iterate)
    @Utils.invoke_and_check Lib.helicsFederateRequestTimeIterativeAsync(fed, requestTime, iterate)
end

"""
Complete an iterative time request asynchronous call

# Arguments

- `fed`: the federate to make the request of

# Returns

- the granted time
- `outIterate`  the iteration specification of the result

"""
function helicsFederateRequestTimeIterativeComplete(fed::Federate)::Tuple{Float64, HELICS.HELICS_ITERATION_RESULT}
    outIterate = Ref{HELICS.HELICS_ITERATION_RESULT}(0)
    t = @Utils.invoke_and_check Lib.helicsFederateRequestTimeIterativeComplete(fed, outIterate)
    return t, outIterate[]
end

"""
Get the name of the federate

# Arguments

- `fed`: the [`Federate`](@ref) to query

# Returns

- a string with the name

"""
function helicsFederateGetName(fed::Federate)::String
    Lib.helicsFederateGetName(fed) |> unsafe_string
end

"""
Set a time based property for a federate

# Arguments

- `fed`: the [`Federate`](@ref) set the property for
- `timeProperty`: a integer code for a time property
- `time`: the requested value of the property

"""
function helicsFederateSetTimeProperty(fed::Federate, timeProperty::Union{Int, HELICS.HELICS_PROPERTIES}, time::HELICS.HELICS_TIME)
    time = convert(Float64, time)
    timeProperty = convert(HELICS.HELICS_PROPERTIES, timeProperty)
    @Utils.invoke_and_check Lib.helicsFederateSetTimeProperty(fed, timeProperty, time)
end

"""
Set a flag for the federate

# Arguments

- `fed`: the federate to alter a flag for
- `flag`: the flag to change
- `flagValue`: the new value of the flag 0 for false !=0 for true

"""
function helicsFederateSetFlagOption(fed::Federate, flag::Int, flagValue::Bool)
    @Utils.invoke_and_check Lib.helicsFederateSetFlagOption(fed, flag, flagValue ? 1 : 0)
end

"""
Set the separator character in a federate

the separator character is the separation character for local publications/endpoints in creating their global name. for example if the separator character is '/'  then a local endpoint would have a globally reachable name of fedName/localName.

# Arguments

- `fed`: the [`FederateInfo`](@ref) object to alter
- `separator`: the character to use as a separator

"""
function helicsFederateSetSeparator(fed::Federate, separator::Char)
    @Utils.invoke_and_check Lib.helicsFederateSetSeparator(fed, separator)
end

"""
Set an integer based property of a federate

# Arguments

- `fed`: the federate to change the property for
- `intProperty`: the property to set
- `propertyVal`: the value of the property

"""
function helicsFederateSetIntegerProperty(fed::Federate, intProperty::Union{Int, HELICS.HELICS_PROPERTIES}, propertyVal::Int)
    intProperty = convert(HELICS.HELICS_PROPERTIES, intProperty)
    @Utils.invoke_and_check Lib.helicsFederateSetIntegerProperty(fed, intProperty, propertyVal)
end

"""
Get the current value of a time based property in a federate

# Arguments

- `fed`: the federate query
- `timeProperty`: the property to query

"""
function helicsFederateGetTimeProperty(fed::Federate, timeProperty::Union{Int, HELICS.HELICS_PROPERTIES})::Float64
    timeProperty = convert(HELICS.HELICS_PROPERTIES, timeProperty)
    @Utils.invoke_and_check Lib.helicsFederateGetTimeProperty(fed, timeProperty)
end

"""
Get a flag value for a federate

# Arguments

- `fed`: the federate to get the flag for
- `flag`: the flag to query

# Returns

- the value of the flag

"""
function helicsFederateGetFlagOption(fed::Federate, flag::Int)::Bool
    @Utils.invoke_and_check Lib.helicsFederateGetFlagOption(fed, flag)
end

"""
Set the logging level for the federate

debug and trace only do anything if they were enabled in the compilation

# Arguments

- `fed`: the federate to get the flag for
- `intProperty`: a code for the property to set [`HELICS_HANDLE_OPTIONS`](@ref)

# Returns

- the value of the property

"""
function helicsFederateGetIntegerProperty(fed::Federate, intProperty::Union{Int, HELICS.HELICS_HANDLE_OPTIONS})
    intProperty = convert(HELICS.HELICS_HANDLE_OPTIONS, intProperty)
    @Utils.invoke_and_check Lib.helicsFederateGetIntegerProperty(fed, intProperty)
end

"""
Get the current time of the federate

# Arguments

- `fed`: the [`Federate`](@ref) to query

# Returns

- the current time of the federate

"""
function helicsFederateGetCurrentTime(fed::Federate)
    @Utils.invoke_and_check Lib.helicsFederateGetCurrentTime(fed)
end

"""
Set a federation global value through a federate

this overwrites any previous value for this name

# Arguments

- `fed`: the federate to set the global through
- `valueName`: the name of the global to set
- `value`: the value of the global

"""
function helicsFederateSetGlobal(fed::Federate, valueName::String, value::String)
    @Utils.invoke_and_check Lib.helicsFederateSetGlobal(fed, valueName, value)
end

"""
Set a global value in a core

this overwrites any previous value for this name

# Arguments

- `core`: the core to set the global through
- `valueName`: the name of the global to set
- `value`: the value of the global

"""
function helicsCoreSetGlobal(core::Core, valueName::String, value::String)
    @Utils.invoke_and_check Lib.helicsCoreSetGlobal(core, valueName, value)
end

"""
Set a federation global value

this overwrites any previous value for this name

# Arguments

- `broker`: the broker to set the global through
- `valueName`: the name of the global to set
- `value`: the value of the global

"""
function helicsBrokerSetGlobal(broker::Broker, valueName::String, value::String)
    @Utils.invoke_and_check Lib.helicsBrokerSetGlobal(broker, valueName, value)
end

"""
Create a [`Query`](@ref)

a [`Query`](@ref) consists of a target and query string

# Arguments

- `target`: the name of the target to query
- `query`: the query string to make of the target

"""
function helicsCreateQuery(target::String, query::String)::Query
    Lib.helicsCreateQuery(target, query)
end

"""
Execute a query

the call will block until the [`Query`](@ref) finishes which may require communication or other delays

# Arguments

- `query`: the [`Query`](@ref) to use in the query
- `fed`: a federate to send the [`Query`](@ref) through

# Returns

- a string. String will remain valid until the [`Query`](@ref) is freed or executed again
the return will be nullptr if fed or [`Query`](@ref) is an invalid object, the return string will be "#invalid" if the [`Query`](@ref) itself was invalid

"""
function helicsQueryExecute(query::Query, fed::Federate)::String
    r = @Utils.invoke_and_check Lib.helicsQueryExecute(query, fed)
    return r |> unsafe_string
end

"""
Execute a [`Query`](@ref) directly on a core

the call will block until the [`Query`](@ref) finishes which may require communication or other delays

# Arguments

- `query`: the [`Query`](@ref) to use in the query
- `core`: the core to send the [`Query`](@ref) to

# Returns

- a string. String will remain valid until the [`Query`](@ref) is freed or executed again
the return will be nullptr if fed or [`Query`](@ref) is an invalid object, the return string will be "#invalid" if the [`Query`](@ref) itself was invalid

"""
function helicsQueryCoreExecute(query::Query, core::Core)::String
    r = @Utils.invoke_and_check Lib.helicsQueryCoreExecute(query, core)
    return r |> unsafe_string
end

"""
Execute a [`Query`](@ref) directly on a broker

the call will block until the [`Query`](@ref) finishes which may require communication or other delays

# Arguments

- `query`: the [`Query`](@ref) to use in the query
- `broker`: the broker to send the [`Query`](@ref) to

# Returns

- a string. String will remain valid until the [`Query`](@ref) is freed or executed again
the return will be nullptr if fed or [`Query`](@ref) is an invalid object, the return string will be "#invalid" if the [`Query`](@ref) itself was invalid

"""
function helicsQueryBrokerExecute(query::Query, broker::Broker)::String
    r = @Utils.invoke_and_check Lib.helicsQueryBrokerExecute(query, broker)
    return r |> unsafe_string
end

"""
Execute a [`Query`](@ref) in a non-blocking call

# Arguments

- `query`: the [`Query`](@ref) to use in the query
- `fed`: a federate to send the [`Query`](@ref) through

"""
function helicsQueryExecuteAsync(query::Query, fed::Federate)
    @Utils.invoke_and_check Lib.helicsQueryExecuteAsync(query, fed)
end

"""
Complete the return from a [`Query`](@ref) called with [`helicsQueryExecuteAsync`](@ref)

the function will block until the [`Query`](@ref) completes [`helicsQueryIsCompleted`](@ref) can be called to determine if a [`Query`](@ref) has completed or not.

# Arguments

- `query`: the [`Query`](@ref) to complete execution of

# Returns

- a string. String will remain valid until the [`Query`](@ref) is freed or executed again
the return will be nullptr if [`Query`](@ref) is an invalid object

"""
function helicsQueryExecuteComplete(query::Query)::String
    r = @Utils.invoke_and_check Lib.helicsQueryExecuteComplete(query)
    return r |> unsafe_string
end

"""
Check if an asynchronously executed [`Query`](@ref) has completed

this function should usually be called after a QueryExecuteAsync function has been called.

# Arguments

- `query`: the [`Query`](@ref) to check if completed

# Returns

- will return `true` if an asynchronous [`Query`](@ref) has complete or a regular [`Query`](@ref) call was made with a result and `false` if an asynchronous [`Query`](@ref) has not completed or is invalid

"""
function helicsQueryIsCompleted(query::Query)::Bool
    Lib.helicsQueryIsCompleted(query) == 1 ? true : false
end

"""
Free the memory associated with a [`Query`](@ref)
"""
function helicsQueryFree(query::Query)
    Lib.helicsQueryFree(query)
end

"""
Function to do some housekeeping work

this runs some cleanup routines and tries to close out any residual thread that haven't been shutdown yet.
"""
function helicsCleanupLibrary()
    Lib.helicsCleanupLibrary()
end

function helicsBrokerAddLoggingCallback(broker::Broker, logger)
    @Utils.invoke_and_check Lib.helicsBrokerAddLoggingCallback(broker, logger)
end

function helicsCoreAddLoggingCallback(core::Core, logger)
    @Utils.invoke_and_check Lib.helicsCoreAddLoggingCallback(core, logger)
end

function helicsFederateAddLoggingCallback(fed::Federate, logger)
    @Utils.invoke_and_check Lib.helicsFederateAddLoggingCallback(fed, logger)
end

