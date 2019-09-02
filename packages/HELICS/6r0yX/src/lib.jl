module Lib

    if Sys.iswindows()
        const LIBRARY_FOLDER = joinpath(@__DIR__, "../deps/windows") |> abspath
        const LIBRARY_EXT = "dll"
        const HELICS_LIBRARY = joinpath(LIBRARY_FOLDER, "helicsSharedLib.$LIBRARY_EXT")
    elseif Sys.islinux()
        const LIBRARY_FOLDER = joinpath(@__DIR__, "../deps/linux") |> abspath
        const LIBRARY_EXT = "so"
        const HELICS_LIBRARY = joinpath(LIBRARY_FOLDER, "libhelicsSharedLib.$LIBRARY_EXT")
    elseif Sys.isapple()
        const LIBRARY_FOLDER = joinpath(@__DIR__, "../deps/apple") |> abspath
        const LIBRARY_EXT = "dylib"
        const HELICS_LIBRARY = joinpath(LIBRARY_FOLDER, "libhelicsSharedLib.$LIBRARY_EXT")
    else
        error("Unknown operating system. Cannot use HELICS.jl")
    end

    HELICS_EXPORT = nothing
    HELICS_NO_EXPORT = nothing
    include("CEnum.jl")
    using .CEnum

    include("ctypes.jl")

    include("common.jl")

    # Julia wrapper for header: /Users/$USER/local/helics-v2.0.0/include/helics/shared_api_library/MessageFederate.h
    # Automatically generated using Clang.jl wrap_c


    function helicsFederateRegisterEndpoint(fed, name, kind, err)
        ccall((:helicsFederateRegisterEndpoint, HELICS_LIBRARY), helics_endpoint, (helics_federate, Cstring, Cstring, Ptr{helics_error}), fed, name, kind, err)
    end

    function helicsFederateRegisterGlobalEndpoint(fed, name, kind, err)
        ccall((:helicsFederateRegisterGlobalEndpoint, HELICS_LIBRARY), helics_endpoint, (helics_federate, Cstring, Cstring, Ptr{helics_error}), fed, name, kind, err)
    end

    function helicsFederateGetEndpoint(fed, name, err)
        ccall((:helicsFederateGetEndpoint, HELICS_LIBRARY), helics_endpoint, (helics_federate, Cstring, Ptr{helics_error}), fed, name, err)
    end

    function helicsFederateGetEndpointByIndex(fed, index, err)
        ccall((:helicsFederateGetEndpointByIndex, HELICS_LIBRARY), helics_endpoint, (helics_federate, Cint, Ptr{helics_error}), fed, index, err)
    end

    function helicsEndpointSetDefaultDestination(endpoint, dest, err)
        ccall((:helicsEndpointSetDefaultDestination, HELICS_LIBRARY), Cvoid, (helics_endpoint, Cstring, Ptr{helics_error}), endpoint, dest, err)
    end

    function helicsEndpointGetDefaultDestination(endpoint)
        ccall((:helicsEndpointGetDefaultDestination, HELICS_LIBRARY), Cstring, (helics_endpoint,), endpoint)
    end

    function helicsEndpointSendMessageRaw(endpoint, dest, data, inputDataLength, err)
        ccall((:helicsEndpointSendMessageRaw, HELICS_LIBRARY), Cvoid, (helics_endpoint, Cstring, Ptr{Cvoid}, Cint, Ptr{helics_error}), endpoint, dest, data, inputDataLength, err)
    end

    function helicsEndpointSendEventRaw(endpoint, dest, data, inputDataLength, time, err)
        ccall((:helicsEndpointSendEventRaw, HELICS_LIBRARY), Cvoid, (helics_endpoint, Cstring, Ptr{Cvoid}, Cint, helics_time, Ptr{helics_error}), endpoint, dest, data, inputDataLength, time, err)
    end

    function helicsEndpointSendMessage(endpoint, message, err)
        ccall((:helicsEndpointSendMessage, HELICS_LIBRARY), Cvoid, (helics_endpoint, Ptr{helics_message}, Ptr{helics_error}), endpoint, message, err)
    end

    function helicsEndpointSubscribe(endpoint, key, err)
        ccall((:helicsEndpointSubscribe, HELICS_LIBRARY), Cvoid, (helics_endpoint, Cstring, Ptr{helics_error}), endpoint, key, err)
    end

    function helicsFederateHasMessage(fed)
        ccall((:helicsFederateHasMessage, HELICS_LIBRARY), helics_bool, (helics_federate,), fed)
    end

    function helicsEndpointHasMessage(endpoint)
        ccall((:helicsEndpointHasMessage, HELICS_LIBRARY), helics_bool, (helics_endpoint,), endpoint)
    end

    function helicsFederatePendingMessages(fed)
        ccall((:helicsFederatePendingMessages, HELICS_LIBRARY), Cint, (helics_federate,), fed)
    end

    function helicsEndpointPendingMessages(endpoint)
        ccall((:helicsEndpointPendingMessages, HELICS_LIBRARY), Cint, (helics_endpoint,), endpoint)
    end

    function helicsEndpointGetMessage(endpoint)
        ccall((:helicsEndpointGetMessage, HELICS_LIBRARY), helics_message, (helics_endpoint,), endpoint)
    end

    function helicsFederateGetMessage(fed)
        ccall((:helicsFederateGetMessage, HELICS_LIBRARY), helics_message, (helics_federate,), fed)
    end

    function helicsEndpointGetType(endpoint)
        ccall((:helicsEndpointGetType, HELICS_LIBRARY), Cstring, (helics_endpoint,), endpoint)
    end

    function helicsEndpointGetName(endpoint)
        ccall((:helicsEndpointGetName, HELICS_LIBRARY), Cstring, (helics_endpoint,), endpoint)
    end

    function helicsFederateGetEndpointCount(fed)
        ccall((:helicsFederateGetEndpointCount, HELICS_LIBRARY), Cint, (helics_federate,), fed)
    end

    function helicsEndpointGetInfo(_end)
        ccall((:helicsEndpointGetInfo, HELICS_LIBRARY), Cstring, (helics_endpoint,), _end)
    end

    function helicsEndpointSetInfo(_end, info, err)
        ccall((:helicsEndpointSetInfo, HELICS_LIBRARY), Cvoid, (helics_endpoint, Cstring, Ptr{helics_error}), _end, info, err)
    end

    function helicsEndpointSetOption(_end, option, value, err)
        ccall((:helicsEndpointSetOption, HELICS_LIBRARY), Cvoid, (helics_endpoint, Cint, helics_bool, Ptr{helics_error}), _end, option, value, err)
    end

    function helicsEndpointGetOption(_end, option)
        ccall((:helicsEndpointGetOption, HELICS_LIBRARY), helics_bool, (helics_endpoint, Cint), _end, option)
    end
    # Julia wrapper for header: /Users/$USER/local/helics-v2.0.0/include/helics/shared_api_library/MessageFilters.h
    # Automatically generated using Clang.jl wrap_c


    function helicsFederateRegisterFilter(fed, kind, name, err)
        ccall((:helicsFederateRegisterFilter, HELICS_LIBRARY), helics_filter, (helics_federate, helics_filter_type, Cstring, Ptr{helics_error}), fed, kind, name, err)
    end

    function helicsFederateRegisterGlobalFilter(fed, kind, name, err)
        ccall((:helicsFederateRegisterGlobalFilter, HELICS_LIBRARY), helics_filter, (helics_federate, helics_filter_type, Cstring, Ptr{helics_error}), fed, kind, name, err)
    end

    function helicsFederateRegisterCloningFilter(fed, deliveryEndpoint, err)
        ccall((:helicsFederateRegisterCloningFilter, HELICS_LIBRARY), helics_filter, (helics_federate, Cstring, Ptr{helics_error}), fed, deliveryEndpoint, err)
    end

    function helicsFederateRegisterGlobalCloningFilter(fed, deliveryEndpoint, err)
        ccall((:helicsFederateRegisterGlobalCloningFilter, HELICS_LIBRARY), helics_filter, (helics_federate, Cstring, Ptr{helics_error}), fed, deliveryEndpoint, err)
    end

    function helicsCoreRegisterFilter(core, kind, name, err)
        ccall((:helicsCoreRegisterFilter, HELICS_LIBRARY), helics_filter, (helics_core, helics_filter_type, Cstring, Ptr{helics_error}), core, kind, name, err)
    end

    function helicsCoreRegisterCloningFilter(core, deliveryEndpoint, err)
        ccall((:helicsCoreRegisterCloningFilter, HELICS_LIBRARY), helics_filter, (helics_core, Cstring, Ptr{helics_error}), core, deliveryEndpoint, err)
    end

    function helicsFederateGetFilterCount(fed)
        ccall((:helicsFederateGetFilterCount, HELICS_LIBRARY), Cint, (helics_federate,), fed)
    end

    function helicsFederateGetFilter(fed, name, err)
        ccall((:helicsFederateGetFilter, HELICS_LIBRARY), helics_filter, (helics_federate, Cstring, Ptr{helics_error}), fed, name, err)
    end

    function helicsFederateGetFilterByIndex(fed, index, err)
        ccall((:helicsFederateGetFilterByIndex, HELICS_LIBRARY), helics_filter, (helics_federate, Cint, Ptr{helics_error}), fed, index, err)
    end

    function helicsFilterGetName(filt)
        ccall((:helicsFilterGetName, HELICS_LIBRARY), Cstring, (helics_filter,), filt)
    end

    function helicsFilterSet(filt, prop, val, err)
        ccall((:helicsFilterSet, HELICS_LIBRARY), Cvoid, (helics_filter, Cstring, Cdouble, Ptr{helics_error}), filt, prop, val, err)
    end

    function helicsFilterSetString(filt, prop, val, err)
        ccall((:helicsFilterSetString, HELICS_LIBRARY), Cvoid, (helics_filter, Cstring, Cstring, Ptr{helics_error}), filt, prop, val, err)
    end

    function helicsFilterAddDestinationTarget(filt, dest, err)
        ccall((:helicsFilterAddDestinationTarget, HELICS_LIBRARY), Cvoid, (helics_filter, Cstring, Ptr{helics_error}), filt, dest, err)
    end

    function helicsFilterAddSourceTarget(filt, source, err)
        ccall((:helicsFilterAddSourceTarget, HELICS_LIBRARY), Cvoid, (helics_filter, Cstring, Ptr{helics_error}), filt, source, err)
    end

    function helicsFilterAddDeliveryEndpoint(filt, deliveryEndpoint, err)
        ccall((:helicsFilterAddDeliveryEndpoint, HELICS_LIBRARY), Cvoid, (helics_filter, Cstring, Ptr{helics_error}), filt, deliveryEndpoint, err)
    end

    function helicsFilterRemoveTarget(filt, target, err)
        ccall((:helicsFilterRemoveTarget, HELICS_LIBRARY), Cvoid, (helics_filter, Cstring, Ptr{helics_error}), filt, target, err)
    end

    function helicsFilterRemoveDeliveryEndpoint(filt, deliveryEndpoint, err)
        ccall((:helicsFilterRemoveDeliveryEndpoint, HELICS_LIBRARY), Cvoid, (helics_filter, Cstring, Ptr{helics_error}), filt, deliveryEndpoint, err)
    end

    function helicsFilterGetInfo(filt)
        ccall((:helicsFilterGetInfo, HELICS_LIBRARY), Cstring, (helics_filter,), filt)
    end

    function helicsFilterSetInfo(filt, info, err)
        ccall((:helicsFilterSetInfo, HELICS_LIBRARY), Cvoid, (helics_filter, Cstring, Ptr{helics_error}), filt, info, err)
    end

    function helicsFilterSetOption(filt, option, value, err)
        ccall((:helicsFilterSetOption, HELICS_LIBRARY), Cvoid, (helics_filter, Cint, helics_bool, Ptr{helics_error}), filt, option, value, err)
    end

    function helicsFilterGetOption(filt, option)
        ccall((:helicsFilterGetOption, HELICS_LIBRARY), helics_bool, (helics_filter, Cint), filt, option)
    end
    # Julia wrapper for header: /Users/$USER/local/helics-v2.0.0/include/helics/shared_api_library/ValueFederate.h
    # Automatically generated using Clang.jl wrap_c


    function helicsFederateRegisterSubscription(fed, key, units, err)
        ccall((:helicsFederateRegisterSubscription, HELICS_LIBRARY), helics_input, (helics_federate, Cstring, Cstring, Ptr{helics_error}), fed, key, units, err)
    end

    function helicsFederateRegisterPublication(fed, key, kind, units, err)
        ccall((:helicsFederateRegisterPublication, HELICS_LIBRARY), helics_publication, (helics_federate, Cstring, helics_data_type, Cstring, Ptr{helics_error}), fed, key, kind, units, err)
    end

    function helicsFederateRegisterTypePublication(fed, key, kind, units, err)
        ccall((:helicsFederateRegisterTypePublication, HELICS_LIBRARY), helics_publication, (helics_federate, Cstring, Cstring, Cstring, Ptr{helics_error}), fed, key, kind, units, err)
    end

    function helicsFederateRegisterGlobalPublication(fed, key, kind, units, err)
        ccall((:helicsFederateRegisterGlobalPublication, HELICS_LIBRARY), helics_publication, (helics_federate, Cstring, helics_data_type, Cstring, Ptr{helics_error}), fed, key, kind, units, err)
    end

    function helicsFederateRegisterGlobalTypePublication(fed, key, kind, units, err)
        ccall((:helicsFederateRegisterGlobalTypePublication, HELICS_LIBRARY), helics_publication, (helics_federate, Cstring, Cstring, Cstring, Ptr{helics_error}), fed, key, kind, units, err)
    end

    function helicsFederateRegisterInput(fed, key, kind, units, err)
        ccall((:helicsFederateRegisterInput, HELICS_LIBRARY), helics_input, (helics_federate, Cstring, helics_data_type, Cstring, Ptr{helics_error}), fed, key, kind, units, err)
    end

    function helicsFederateRegisterTypeInput(fed, key, kind, units, err)
        ccall((:helicsFederateRegisterTypeInput, HELICS_LIBRARY), helics_input, (helics_federate, Cstring, Cstring, Cstring, Ptr{helics_error}), fed, key, kind, units, err)
    end

    function helicsFederateRegisterGlobalInput(fed, key, kind, units, err)
        ccall((:helicsFederateRegisterGlobalInput, HELICS_LIBRARY), helics_publication, (helics_federate, Cstring, helics_data_type, Cstring, Ptr{helics_error}), fed, key, kind, units, err)
    end

    function helicsFederateRegisterGlobalTypeInput(fed, key, kind, units, err)
        ccall((:helicsFederateRegisterGlobalTypeInput, HELICS_LIBRARY), helics_publication, (helics_federate, Cstring, Cstring, Cstring, Ptr{helics_error}), fed, key, kind, units, err)
    end

    function helicsFederateGetPublication(fed, key, err)
        ccall((:helicsFederateGetPublication, HELICS_LIBRARY), helics_publication, (helics_federate, Cstring, Ptr{helics_error}), fed, key, err)
    end

    function helicsFederateGetPublicationByIndex(fed, index, err)
        ccall((:helicsFederateGetPublicationByIndex, HELICS_LIBRARY), helics_publication, (helics_federate, Cint, Ptr{helics_error}), fed, index, err)
    end

    function helicsFederateGetInput(fed, key, err)
        ccall((:helicsFederateGetInput, HELICS_LIBRARY), helics_input, (helics_federate, Cstring, Ptr{helics_error}), fed, key, err)
    end

    function helicsFederateGetInputByIndex(fed, index, err)
        ccall((:helicsFederateGetInputByIndex, HELICS_LIBRARY), helics_input, (helics_federate, Cint, Ptr{helics_error}), fed, index, err)
    end

    function helicsFederateGetSubscription(fed, key, err)
        ccall((:helicsFederateGetSubscription, HELICS_LIBRARY), helics_input, (helics_federate, Cstring, Ptr{helics_error}), fed, key, err)
    end

    function helicsPublicationPublishRaw(pub, data, inputDataLength, err)
        ccall((:helicsPublicationPublishRaw, HELICS_LIBRARY), Cvoid, (helics_publication, Ptr{Cvoid}, Cint, Ptr{helics_error}), pub, data, inputDataLength, err)
    end

    function helicsPublicationPublishString(pub, str, err)
        ccall((:helicsPublicationPublishString, HELICS_LIBRARY), Cvoid, (helics_publication, Cstring, Ptr{helics_error}), pub, str, err)
    end

    function helicsPublicationPublishInteger(pub, val, err)
        ccall((:helicsPublicationPublishInteger, HELICS_LIBRARY), Cvoid, (helics_publication, Int64, Ptr{helics_error}), pub, val, err)
    end

    function helicsPublicationPublishBoolean(pub, val, err)
        ccall((:helicsPublicationPublishBoolean, HELICS_LIBRARY), Cvoid, (helics_publication, helics_bool, Ptr{helics_error}), pub, val, err)
    end

    function helicsPublicationPublishDouble(pub, val, err)
        ccall((:helicsPublicationPublishDouble, HELICS_LIBRARY), Cvoid, (helics_publication, Cdouble, Ptr{helics_error}), pub, val, err)
    end

    function helicsPublicationPublishTime(pub, val, err)
        ccall((:helicsPublicationPublishTime, HELICS_LIBRARY), Cvoid, (helics_publication, helics_time, Ptr{helics_error}), pub, val, err)
    end

    function helicsPublicationPublishChar(pub, val, err)
        ccall((:helicsPublicationPublishChar, HELICS_LIBRARY), Cvoid, (helics_publication, UInt8, Ptr{helics_error}), pub, val, err)
    end

    function helicsPublicationPublishComplex(pub, real, imag, err)
        ccall((:helicsPublicationPublishComplex, HELICS_LIBRARY), Cvoid, (helics_publication, Cdouble, Cdouble, Ptr{helics_error}), pub, real, imag, err)
    end

    function helicsPublicationPublishVector(pub, vectorInput, vectorLength, err)
        ccall((:helicsPublicationPublishVector, HELICS_LIBRARY), Cvoid, (helics_publication, Ptr{Cdouble}, Cint, Ptr{helics_error}), pub, vectorInput, vectorLength, err)
    end

    function helicsPublicationPublishNamedPoint(pub, str, val, err)
        ccall((:helicsPublicationPublishNamedPoint, HELICS_LIBRARY), Cvoid, (helics_publication, Cstring, Cdouble, Ptr{helics_error}), pub, str, val, err)
    end

    function helicsPublicationAddTarget(pub, target, err)
        ccall((:helicsPublicationAddTarget, HELICS_LIBRARY), Cvoid, (helics_publication, Cstring, Ptr{helics_error}), pub, target, err)
    end

    function helicsInputAddTarget(ipt, target, err)
        ccall((:helicsInputAddTarget, HELICS_LIBRARY), Cvoid, (helics_input, Cstring, Ptr{helics_error}), ipt, target, err)
    end

    function helicsInputGetRawValueSize(ipt)
        ccall((:helicsInputGetRawValueSize, HELICS_LIBRARY), Cint, (helics_input,), ipt)
    end

    function helicsInputGetRawValue(ipt, data, maxlen, actualSize, err)
        ccall((:helicsInputGetRawValue, HELICS_LIBRARY), Cvoid, (helics_input, Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{helics_error}), ipt, data, maxlen, actualSize, err)
    end

    function helicsInputGetStringSize(ipt)
        ccall((:helicsInputGetStringSize, HELICS_LIBRARY), Cint, (helics_input,), ipt)
    end

    function helicsInputGetString(ipt, outputString, maxStringLen, actualLength, err)
        ccall((:helicsInputGetString, HELICS_LIBRARY), Cvoid, (helics_input, Cstring, Cint, Ptr{Cint}, Ptr{helics_error}), ipt, outputString, maxStringLen, actualLength, err)
    end

    function helicsInputGetInteger(ipt, err)
        ccall((:helicsInputGetInteger, HELICS_LIBRARY), Int64, (helics_input, Ptr{helics_error}), ipt, err)
    end

    function helicsInputGetBoolean(ipt, err)
        ccall((:helicsInputGetBoolean, HELICS_LIBRARY), helics_bool, (helics_input, Ptr{helics_error}), ipt, err)
    end

    function helicsInputGetDouble(ipt, err)
        ccall((:helicsInputGetDouble, HELICS_LIBRARY), Cdouble, (helics_input, Ptr{helics_error}), ipt, err)
    end

    function helicsInputGetTime(ipt, err)
        ccall((:helicsInputGetTime, HELICS_LIBRARY), helics_time, (helics_input, Ptr{helics_error}), ipt, err)
    end

    function helicsInputGetChar(ipt, err)
        ccall((:helicsInputGetChar, HELICS_LIBRARY), UInt8, (helics_input, Ptr{helics_error}), ipt, err)
    end

    function helicsInputGetComplexObject(ipt, err)
        ccall((:helicsInputGetComplexObject, HELICS_LIBRARY), helics_complex, (helics_input, Ptr{helics_error}), ipt, err)
    end

    function helicsInputGetComplex(ipt, real, imag, err)
        ccall((:helicsInputGetComplex, HELICS_LIBRARY), Cvoid, (helics_input, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{helics_error}), ipt, real, imag, err)
    end

    function helicsInputGetVectorSize(ipt)
        ccall((:helicsInputGetVectorSize, HELICS_LIBRARY), Cint, (helics_input,), ipt)
    end

    function helicsInputGetVector(ipt, data, maxlen, actualSize, err)
        ccall((:helicsInputGetVector, HELICS_LIBRARY), Cvoid, (helics_input, Ptr{Cdouble}, Cint, Ptr{Cint}, Ptr{helics_error}), ipt, data, maxlen, actualSize, err)
    end

    function helicsInputGetNamedPoint(ipt, outputString, maxStringLen, actualLength, val, err)
        ccall((:helicsInputGetNamedPoint, HELICS_LIBRARY), Cvoid, (helics_input, Cstring, Cint, Ptr{Cint}, Ptr{Cdouble}, Ptr{helics_error}), ipt, outputString, maxStringLen, actualLength, val, err)
    end

    function helicsInputSetDefaultRaw(ipt, data, inputDataLength, err)
        ccall((:helicsInputSetDefaultRaw, HELICS_LIBRARY), Cvoid, (helics_input, Ptr{Cvoid}, Cint, Ptr{helics_error}), ipt, data, inputDataLength, err)
    end

    function helicsInputSetDefaultString(ipt, str, err)
        ccall((:helicsInputSetDefaultString, HELICS_LIBRARY), Cvoid, (helics_input, Cstring, Ptr{helics_error}), ipt, str, err)
    end

    function helicsInputSetDefaultInteger(ipt, val, err)
        ccall((:helicsInputSetDefaultInteger, HELICS_LIBRARY), Cvoid, (helics_input, Int64, Ptr{helics_error}), ipt, val, err)
    end

    function helicsInputSetDefaultBoolean(ipt, val, err)
        ccall((:helicsInputSetDefaultBoolean, HELICS_LIBRARY), Cvoid, (helics_input, helics_bool, Ptr{helics_error}), ipt, val, err)
    end

    function helicsInputSetDefaultTime(ipt, val, err)
        ccall((:helicsInputSetDefaultTime, HELICS_LIBRARY), Cvoid, (helics_input, helics_time, Ptr{helics_error}), ipt, val, err)
    end

    function helicsInputSetDefaultChar(ipt, val, err)
        ccall((:helicsInputSetDefaultChar, HELICS_LIBRARY), Cvoid, (helics_input, UInt8, Ptr{helics_error}), ipt, val, err)
    end

    function helicsInputSetDefaultDouble(ipt, val, err)
        ccall((:helicsInputSetDefaultDouble, HELICS_LIBRARY), Cvoid, (helics_input, Cdouble, Ptr{helics_error}), ipt, val, err)
    end

    function helicsInputSetDefaultComplex(ipt, real, imag, err)
        ccall((:helicsInputSetDefaultComplex, HELICS_LIBRARY), Cvoid, (helics_input, Cdouble, Cdouble, Ptr{helics_error}), ipt, real, imag, err)
    end

    function helicsInputSetDefaultVector(ipt, vectorInput, vectorLength, err)
        ccall((:helicsInputSetDefaultVector, HELICS_LIBRARY), Cvoid, (helics_input, Ptr{Cdouble}, Cint, Ptr{helics_error}), ipt, vectorInput, vectorLength, err)
    end

    function helicsInputSetDefaultNamedPoint(ipt, str, val, err)
        ccall((:helicsInputSetDefaultNamedPoint, HELICS_LIBRARY), Cvoid, (helics_input, Cstring, Cdouble, Ptr{helics_error}), ipt, str, val, err)
    end

    function helicsInputGetType(ipt)
        ccall((:helicsInputGetType, HELICS_LIBRARY), Cstring, (helics_input,), ipt)
    end

    function helicsInputGetPublicationType(ipt)
        ccall((:helicsInputGetPublicationType, HELICS_LIBRARY), Cstring, (helics_input,), ipt)
    end

    function helicsPublicationGetType(pub)
        ccall((:helicsPublicationGetType, HELICS_LIBRARY), Cstring, (helics_publication,), pub)
    end

    function helicsInputGetKey(ipt)
        ccall((:helicsInputGetKey, HELICS_LIBRARY), Cstring, (helics_input,), ipt)
    end

    function helicsSubscriptionGetKey(ipt)
        ccall((:helicsSubscriptionGetKey, HELICS_LIBRARY), Cstring, (helics_input,), ipt)
    end

    function helicsPublicationGetKey(pub)
        ccall((:helicsPublicationGetKey, HELICS_LIBRARY), Cstring, (helics_publication,), pub)
    end

    function helicsInputGetUnits(ipt)
        ccall((:helicsInputGetUnits, HELICS_LIBRARY), Cstring, (helics_input,), ipt)
    end

    function helicsPublicationGetUnits(pub)
        ccall((:helicsPublicationGetUnits, HELICS_LIBRARY), Cstring, (helics_publication,), pub)
    end

    function helicsInputGetInfo(inp)
        ccall((:helicsInputGetInfo, HELICS_LIBRARY), Cstring, (helics_input,), inp)
    end

    function helicsInputSetInfo(inp, info, err)
        ccall((:helicsInputSetInfo, HELICS_LIBRARY), Cvoid, (helics_input, Cstring, Ptr{helics_error}), inp, info, err)
    end

    function helicsPublicationGetInfo(pub)
        ccall((:helicsPublicationGetInfo, HELICS_LIBRARY), Cstring, (helics_publication,), pub)
    end

    function helicsPublicationSetInfo(pub, info, err)
        ccall((:helicsPublicationSetInfo, HELICS_LIBRARY), Cvoid, (helics_publication, Cstring, Ptr{helics_error}), pub, info, err)
    end

    function helicsInputGetOption(inp, option)
        ccall((:helicsInputGetOption, HELICS_LIBRARY), helics_bool, (helics_input, Cint), inp, option)
    end

    function helicsInputSetOption(inp, option, value, err)
        ccall((:helicsInputSetOption, HELICS_LIBRARY), Cvoid, (helics_input, Cint, helics_bool, Ptr{helics_error}), inp, option, value, err)
    end

    function helicsPublicationGetOption(pub, option)
        ccall((:helicsPublicationGetOption, HELICS_LIBRARY), helics_bool, (helics_publication, Cint), pub, option)
    end

    function helicsPublicationSetOption(pub, option, val, err)
        ccall((:helicsPublicationSetOption, HELICS_LIBRARY), Cvoid, (helics_publication, Cint, helics_bool, Ptr{helics_error}), pub, option, val, err)
    end

    function helicsInputIsUpdated(ipt)
        ccall((:helicsInputIsUpdated, HELICS_LIBRARY), helics_bool, (helics_input,), ipt)
    end

    function helicsInputLastUpdateTime(ipt)
        ccall((:helicsInputLastUpdateTime, HELICS_LIBRARY), helics_time, (helics_input,), ipt)
    end

    function helicsFederateGetPublicationCount(fed)
        ccall((:helicsFederateGetPublicationCount, HELICS_LIBRARY), Cint, (helics_federate,), fed)
    end

    function helicsFederateGetInputCount(fed)
        ccall((:helicsFederateGetInputCount, HELICS_LIBRARY), Cint, (helics_federate,), fed)
    end
    # Julia wrapper for header: /Users/$USER/local/helics-v2.0.0/include/helics/shared_api_library/api-data.h
    # Automatically generated using Clang.jl wrap_c

    # Julia wrapper for header: /Users/$USER/local/helics-v2.0.0/include/helics/shared_api_library/helics-config.h
    # Automatically generated using Clang.jl wrap_c

    # Julia wrapper for header: /Users/$USER/local/helics-v2.0.0/include/helics/shared_api_library/helics.h
    # Automatically generated using Clang.jl wrap_c


    function helicsGetVersion()
        ccall((:helicsGetVersion, HELICS_LIBRARY), Cstring, ())
    end

    function helicsErrorInitialize()
        ccall((:helicsErrorInitialize, HELICS_LIBRARY), helics_error, ())
    end

    function helicsErrorClear(err)
        ccall((:helicsErrorClear, HELICS_LIBRARY), Cvoid, (Ptr{helics_error},), err)
    end

    function helicsIsCoreTypeAvailable(kind)
        ccall((:helicsIsCoreTypeAvailable, HELICS_LIBRARY), helics_bool, (Cstring,), kind)
    end

    function helicsCreateCore(kind, name, initString, err)
        ccall((:helicsCreateCore, HELICS_LIBRARY), helics_core, (Cstring, Cstring, Cstring, Ptr{helics_error}), kind, name, initString, err)
    end

    function helicsCreateCoreFromArgs(kind, name, argc, argv, err)
        ccall((:helicsCreateCoreFromArgs, HELICS_LIBRARY), helics_core, (Cstring, Cstring, Cint, Ptr{Cstring}, Ptr{helics_error}), kind, name, argc, argv, err)
    end

    function helicsCoreClone(core, err)
        ccall((:helicsCoreClone, HELICS_LIBRARY), helics_core, (helics_core, Ptr{helics_error}), core, err)
    end

    function helicsCoreIsValid(core)
        ccall((:helicsCoreIsValid, HELICS_LIBRARY), helics_bool, (helics_core,), core)
    end

    function helicsCreateBroker(kind, name, initString, err)
        ccall((:helicsCreateBroker, HELICS_LIBRARY), helics_broker, (Cstring, Cstring, Cstring, Ptr{helics_error}), kind, name, initString, err)
    end

    function helicsCreateBrokerFromArgs(kind, name, argc, argv, err)
        ccall((:helicsCreateBrokerFromArgs, HELICS_LIBRARY), helics_broker, (Cstring, Cstring, Cint, Ptr{Cstring}, Ptr{helics_error}), kind, name, argc, argv, err)
    end

    function helicsBrokerClone(broker, err)
        ccall((:helicsBrokerClone, HELICS_LIBRARY), helics_broker, (helics_broker, Ptr{helics_error}), broker, err)
    end

    function helicsBrokerIsValid(broker)
        ccall((:helicsBrokerIsValid, HELICS_LIBRARY), helics_bool, (helics_broker,), broker)
    end

    function helicsBrokerIsConnected(broker)
        ccall((:helicsBrokerIsConnected, HELICS_LIBRARY), helics_bool, (helics_broker,), broker)
    end

    function helicsBrokerDataLink(broker, source, target, err)
        ccall((:helicsBrokerDataLink, HELICS_LIBRARY), Cvoid, (helics_broker, Cstring, Cstring, Ptr{helics_error}), broker, source, target, err)
    end

    function helicsBrokerAddSourceFilterToEndpoint(broker, filter, endpoint, err)
        ccall((:helicsBrokerAddSourceFilterToEndpoint, HELICS_LIBRARY), Cvoid, (helics_broker, Cstring, Cstring, Ptr{helics_error}), broker, filter, endpoint, err)
    end

    function helicsBrokerAddDestinationFilterToEndpoint(broker, filter, endpoint, err)
        ccall((:helicsBrokerAddDestinationFilterToEndpoint, HELICS_LIBRARY), Cvoid, (helics_broker, Cstring, Cstring, Ptr{helics_error}), broker, filter, endpoint, err)
    end

    function helicsBrokerWaitForDisconnect(broker, msToWait, err)
        ccall((:helicsBrokerWaitForDisconnect, HELICS_LIBRARY), helics_bool, (helics_broker, Cint, Ptr{helics_error}), broker, msToWait, err)
    end

    function helicsCoreIsConnected(core)
        ccall((:helicsCoreIsConnected, HELICS_LIBRARY), helics_bool, (helics_core,), core)
    end

    function helicsCoreDataLink(core, source, target, err)
        ccall((:helicsCoreDataLink, HELICS_LIBRARY), Cvoid, (helics_core, Cstring, Cstring, Ptr{helics_error}), core, source, target, err)
    end

    function helicsCoreAddSourceFilterToEndpoint(core, filter, endpoint, err)
        ccall((:helicsCoreAddSourceFilterToEndpoint, HELICS_LIBRARY), Cvoid, (helics_core, Cstring, Cstring, Ptr{helics_error}), core, filter, endpoint, err)
    end

    function helicsCoreAddDestinationFilterToEndpoint(core, filter, endpoint, err)
        ccall((:helicsCoreAddDestinationFilterToEndpoint, HELICS_LIBRARY), Cvoid, (helics_core, Cstring, Cstring, Ptr{helics_error}), core, filter, endpoint, err)
    end

    function helicsBrokerGetIdentifier(broker)
        ccall((:helicsBrokerGetIdentifier, HELICS_LIBRARY), Cstring, (helics_broker,), broker)
    end

    function helicsCoreGetIdentifier(core)
        ccall((:helicsCoreGetIdentifier, HELICS_LIBRARY), Cstring, (helics_core,), core)
    end

    function helicsBrokerGetAddress(broker)
        ccall((:helicsBrokerGetAddress, HELICS_LIBRARY), Cstring, (helics_broker,), broker)
    end

    function helicsCoreSetReadyToInit(core, err)
        ccall((:helicsCoreSetReadyToInit, HELICS_LIBRARY), Cvoid, (helics_core, Ptr{helics_error}), core, err)
    end

    function helicsCoreDisconnect(core, err)
        ccall((:helicsCoreDisconnect, HELICS_LIBRARY), Cvoid, (helics_core, Ptr{helics_error}), core, err)
    end

    function helicsGetFederateByName(fedName, err)
        ccall((:helicsGetFederateByName, HELICS_LIBRARY), helics_federate, (Cstring, Ptr{helics_error}), fedName, err)
    end

    function helicsBrokerDisconnect(broker, err)
        ccall((:helicsBrokerDisconnect, HELICS_LIBRARY), Cvoid, (helics_broker, Ptr{helics_error}), broker, err)
    end

    function helicsFederateDestroy(fed)
        ccall((:helicsFederateDestroy, HELICS_LIBRARY), Cvoid, (helics_federate,), fed)
    end

    function helicsBrokerDestroy(broker)
        ccall((:helicsBrokerDestroy, HELICS_LIBRARY), Cvoid, (helics_broker,), broker)
    end

    function helicsCoreDestroy(core)
        ccall((:helicsCoreDestroy, HELICS_LIBRARY), Cvoid, (helics_core,), core)
    end

    function helicsCoreFree(core)
        ccall((:helicsCoreFree, HELICS_LIBRARY), Cvoid, (helics_core,), core)
    end

    function helicsBrokerFree(broker)
        ccall((:helicsBrokerFree, HELICS_LIBRARY), Cvoid, (helics_broker,), broker)
    end

    function helicsCreateValueFederate(fedName, fi, err)
        ccall((:helicsCreateValueFederate, HELICS_LIBRARY), helics_federate, (Cstring, helics_federate_info, Ptr{helics_error}), fedName, fi, err)
    end

    function helicsCreateValueFederateFromConfig(configFile, err)
        ccall((:helicsCreateValueFederateFromConfig, HELICS_LIBRARY), helics_federate, (Cstring, Ptr{helics_error}), configFile, err)
    end

    function helicsCreateMessageFederate(fedName, fi, err)
        ccall((:helicsCreateMessageFederate, HELICS_LIBRARY), helics_federate, (Cstring, helics_federate_info, Ptr{helics_error}), fedName, fi, err)
    end

    function helicsCreateMessageFederateFromConfig(configFile, err)
        ccall((:helicsCreateMessageFederateFromConfig, HELICS_LIBRARY), helics_federate, (Cstring, Ptr{helics_error}), configFile, err)
    end

    function helicsCreateCombinationFederate(fedName, fi, err)
        ccall((:helicsCreateCombinationFederate, HELICS_LIBRARY), helics_federate, (Cstring, helics_federate_info, Ptr{helics_error}), fedName, fi, err)
    end

    function helicsCreateCombinationFederateFromConfig(configFile, err)
        ccall((:helicsCreateCombinationFederateFromConfig, HELICS_LIBRARY), helics_federate, (Cstring, Ptr{helics_error}), configFile, err)
    end

    function helicsFederateClone(fed, err)
        ccall((:helicsFederateClone, HELICS_LIBRARY), helics_federate, (helics_federate, Ptr{helics_error}), fed, err)
    end

    function helicsCreateFederateInfo()
        ccall((:helicsCreateFederateInfo, HELICS_LIBRARY), helics_federate_info, ())
    end

    function helicsFederateInfoClone(fi, err)
        ccall((:helicsFederateInfoClone, HELICS_LIBRARY), helics_federate_info, (helics_federate_info, Ptr{helics_error}), fi, err)
    end

    function helicsFederateInfoLoadFromArgs(fi, argc, argv, err)
        ccall((:helicsFederateInfoLoadFromArgs, HELICS_LIBRARY), Cvoid, (helics_federate_info, Cint, Ptr{Cstring}, Ptr{helics_error}), fi, argc, argv, err)
    end

    function helicsFederateInfoFree(fi)
        ccall((:helicsFederateInfoFree, HELICS_LIBRARY), Cvoid, (helics_federate_info,), fi)
    end

    function helicsFederateIsValid(fed)
        ccall((:helicsFederateIsValid, HELICS_LIBRARY), helics_bool, (helics_federate,), fed)
    end

    function helicsFederateInfoSetCoreName(fi, corename, err)
        ccall((:helicsFederateInfoSetCoreName, HELICS_LIBRARY), Cvoid, (helics_federate_info, Cstring, Ptr{helics_error}), fi, corename, err)
    end

    function helicsFederateInfoSetCoreInitString(fi, coreInit, err)
        ccall((:helicsFederateInfoSetCoreInitString, HELICS_LIBRARY), Cvoid, (helics_federate_info, Cstring, Ptr{helics_error}), fi, coreInit, err)
    end

    function helicsFederateInfoSetCoreType(fi, coretype, err)
        ccall((:helicsFederateInfoSetCoreType, HELICS_LIBRARY), Cvoid, (helics_federate_info, Cint, Ptr{helics_error}), fi, coretype, err)
    end

    function helicsFederateInfoSetCoreTypeFromString(fi, coretype, err)
        ccall((:helicsFederateInfoSetCoreTypeFromString, HELICS_LIBRARY), Cvoid, (helics_federate_info, Cstring, Ptr{helics_error}), fi, coretype, err)
    end

    function helicsFederateInfoSetBroker(fi, broker, err)
        ccall((:helicsFederateInfoSetBroker, HELICS_LIBRARY), Cvoid, (helics_federate_info, Cstring, Ptr{helics_error}), fi, broker, err)
    end

    function helicsFederateInfoSetBrokerPort(fi, brokerPort, err)
        ccall((:helicsFederateInfoSetBrokerPort, HELICS_LIBRARY), Cvoid, (helics_federate_info, Cint, Ptr{helics_error}), fi, brokerPort, err)
    end

    function helicsFederateInfoSetLocalPort(fi, localPort, err)
        ccall((:helicsFederateInfoSetLocalPort, HELICS_LIBRARY), Cvoid, (helics_federate_info, Cstring, Ptr{helics_error}), fi, localPort, err)
    end

    function helicsGetPropertyIndex(val)
        ccall((:helicsGetPropertyIndex, HELICS_LIBRARY), Cint, (Cstring,), val)
    end

    function helicsGetOptionIndex(val)
        ccall((:helicsGetOptionIndex, HELICS_LIBRARY), Cint, (Cstring,), val)
    end

    function helicsFederateInfoSetFlagOption(fi, flag, value, err)
        ccall((:helicsFederateInfoSetFlagOption, HELICS_LIBRARY), Cvoid, (helics_federate_info, Cint, helics_bool, Ptr{helics_error}), fi, flag, value, err)
    end

    function helicsFederateInfoSetSeparator(fi, separator, err)
        ccall((:helicsFederateInfoSetSeparator, HELICS_LIBRARY), Cvoid, (helics_federate_info, UInt8, Ptr{helics_error}), fi, separator, err)
    end

    function helicsFederateInfoSetTimeProperty(fi, timeProperty, propertyValue, err)
        ccall((:helicsFederateInfoSetTimeProperty, HELICS_LIBRARY), Cvoid, (helics_federate_info, Cint, helics_time, Ptr{helics_error}), fi, timeProperty, propertyValue, err)
    end

    function helicsFederateInfoSetIntegerProperty(fi, intProperty, propertyValue, err)
        ccall((:helicsFederateInfoSetIntegerProperty, HELICS_LIBRARY), Cvoid, (helics_federate_info, Cint, Cint, Ptr{helics_error}), fi, intProperty, propertyValue, err)
    end

    function helicsFederateRegisterInterfaces(fed, file, err)
        ccall((:helicsFederateRegisterInterfaces, HELICS_LIBRARY), Cvoid, (helics_federate, Cstring, Ptr{helics_error}), fed, file, err)
    end

    function helicsFederateFinalize(fed, err)
        ccall((:helicsFederateFinalize, HELICS_LIBRARY), Cvoid, (helics_federate, Ptr{helics_error}), fed, err)
    end

    function helicsFederateFinalizeAsync(fed, err)
        ccall((:helicsFederateFinalizeAsync, HELICS_LIBRARY), Cvoid, (helics_federate, Ptr{helics_error}), fed, err)
    end

    function helicsFederateFinalizeComplete(fed, err)
        ccall((:helicsFederateFinalizeComplete, HELICS_LIBRARY), Cvoid, (helics_federate, Ptr{helics_error}), fed, err)
    end

    function helicsFederateFree(fed)
        ccall((:helicsFederateFree, HELICS_LIBRARY), Cvoid, (helics_federate,), fed)
    end

    function helicsCloseLibrary()
        ccall((:helicsCloseLibrary, HELICS_LIBRARY), Cvoid, ())
    end

    function helicsFederateEnterInitializingMode(fed, err)
        ccall((:helicsFederateEnterInitializingMode, HELICS_LIBRARY), Cvoid, (helics_federate, Ptr{helics_error}), fed, err)
    end

    function helicsFederateEnterInitializingModeAsync(fed, err)
        ccall((:helicsFederateEnterInitializingModeAsync, HELICS_LIBRARY), Cvoid, (helics_federate, Ptr{helics_error}), fed, err)
    end

    function helicsFederateIsAsyncOperationCompleted(fed, err)
        ccall((:helicsFederateIsAsyncOperationCompleted, HELICS_LIBRARY), helics_bool, (helics_federate, Ptr{helics_error}), fed, err)
    end

    function helicsFederateEnterInitializingModeComplete(fed, err)
        ccall((:helicsFederateEnterInitializingModeComplete, HELICS_LIBRARY), Cvoid, (helics_federate, Ptr{helics_error}), fed, err)
    end

    function helicsFederateEnterExecutingMode(fed, err)
        ccall((:helicsFederateEnterExecutingMode, HELICS_LIBRARY), Cvoid, (helics_federate, Ptr{helics_error}), fed, err)
    end

    function helicsFederateEnterExecutingModeAsync(fed, err)
        ccall((:helicsFederateEnterExecutingModeAsync, HELICS_LIBRARY), Cvoid, (helics_federate, Ptr{helics_error}), fed, err)
    end

    function helicsFederateEnterExecutingModeComplete(fed, err)
        ccall((:helicsFederateEnterExecutingModeComplete, HELICS_LIBRARY), Cvoid, (helics_federate, Ptr{helics_error}), fed, err)
    end

    function helicsFederateEnterExecutingModeIterative(fed, iterate, err)
        ccall((:helicsFederateEnterExecutingModeIterative, HELICS_LIBRARY), helics_iteration_result, (helics_federate, helics_iteration_request, Ptr{helics_error}), fed, iterate, err)
    end

    function helicsFederateEnterExecutingModeIterativeAsync(fed, iterate, err)
        ccall((:helicsFederateEnterExecutingModeIterativeAsync, HELICS_LIBRARY), Cvoid, (helics_federate, helics_iteration_request, Ptr{helics_error}), fed, iterate, err)
    end

    function helicsFederateEnterExecutingModeIterativeComplete(fed, err)
        ccall((:helicsFederateEnterExecutingModeIterativeComplete, HELICS_LIBRARY), helics_iteration_result, (helics_federate, Ptr{helics_error}), fed, err)
    end

    function helicsFederateGetState(fed, err)
        ccall((:helicsFederateGetState, HELICS_LIBRARY), helics_federate_state, (helics_federate, Ptr{helics_error}), fed, err)
    end

    function helicsFederateGetCoreObject(fed, err)
        ccall((:helicsFederateGetCoreObject, HELICS_LIBRARY), helics_core, (helics_federate, Ptr{helics_error}), fed, err)
    end

    function helicsFederateRequestTime(fed, requestTime, err)
        ccall((:helicsFederateRequestTime, HELICS_LIBRARY), helics_time, (helics_federate, helics_time, Ptr{helics_error}), fed, requestTime, err)
    end

    function helicsFederateRequestNextStep(fed, err)
        ccall((:helicsFederateRequestNextStep, HELICS_LIBRARY), helics_time, (helics_federate, Ptr{helics_error}), fed, err)
    end

    function helicsFederateRequestTimeIterative(fed, requestTime, iterate, outIterate, err)
        ccall((:helicsFederateRequestTimeIterative, HELICS_LIBRARY), helics_time, (helics_federate, helics_time, helics_iteration_request, Ptr{helics_iteration_result}, Ptr{helics_error}), fed, requestTime, iterate, outIterate, err)
    end

    function helicsFederateRequestTimeAsync(fed, requestTime, err)
        ccall((:helicsFederateRequestTimeAsync, HELICS_LIBRARY), Cvoid, (helics_federate, helics_time, Ptr{helics_error}), fed, requestTime, err)
    end

    function helicsFederateRequestTimeComplete(fed, err)
        ccall((:helicsFederateRequestTimeComplete, HELICS_LIBRARY), helics_time, (helics_federate, Ptr{helics_error}), fed, err)
    end

    function helicsFederateRequestTimeIterativeAsync(fed, requestTime, iterate, err)
        ccall((:helicsFederateRequestTimeIterativeAsync, HELICS_LIBRARY), Cvoid, (helics_federate, helics_time, helics_iteration_request, Ptr{helics_error}), fed, requestTime, iterate, err)
    end

    function helicsFederateRequestTimeIterativeComplete(fed, outIterate, err)
        ccall((:helicsFederateRequestTimeIterativeComplete, HELICS_LIBRARY), helics_time, (helics_federate, Ptr{helics_iteration_result}, Ptr{helics_error}), fed, outIterate, err)
    end

    function helicsFederateGetName(fed)
        ccall((:helicsFederateGetName, HELICS_LIBRARY), Cstring, (helics_federate,), fed)
    end

    function helicsFederateSetTimeProperty(fed, timeProperty, time, err)
        ccall((:helicsFederateSetTimeProperty, HELICS_LIBRARY), Cvoid, (helics_federate, Cint, helics_time, Ptr{helics_error}), fed, timeProperty, time, err)
    end

    function helicsFederateSetFlagOption(fed, flag, flagValue, err)
        ccall((:helicsFederateSetFlagOption, HELICS_LIBRARY), Cvoid, (helics_federate, Cint, helics_bool, Ptr{helics_error}), fed, flag, flagValue, err)
    end

    function helicsFederateSetSeparator(fed, separator, err)
        ccall((:helicsFederateSetSeparator, HELICS_LIBRARY), Cvoid, (helics_federate, UInt8, Ptr{helics_error}), fed, separator, err)
    end

    function helicsFederateSetIntegerProperty(fed, intProperty, propertyVal, err)
        ccall((:helicsFederateSetIntegerProperty, HELICS_LIBRARY), Cvoid, (helics_federate, Cint, Cint, Ptr{helics_error}), fed, intProperty, propertyVal, err)
    end

    function helicsFederateGetTimeProperty(fed, timeProperty, err)
        ccall((:helicsFederateGetTimeProperty, HELICS_LIBRARY), helics_time, (helics_federate, Cint, Ptr{helics_error}), fed, timeProperty, err)
    end

    function helicsFederateGetFlagOption(fed, flag, err)
        ccall((:helicsFederateGetFlagOption, HELICS_LIBRARY), helics_bool, (helics_federate, Cint, Ptr{helics_error}), fed, flag, err)
    end

    function helicsFederateGetIntegerProperty(fed, intProperty, err)
        ccall((:helicsFederateGetIntegerProperty, HELICS_LIBRARY), Cint, (helics_federate, Cint, Ptr{helics_error}), fed, intProperty, err)
    end

    function helicsFederateGetCurrentTime(fed, err)
        ccall((:helicsFederateGetCurrentTime, HELICS_LIBRARY), helics_time, (helics_federate, Ptr{helics_error}), fed, err)
    end

    function helicsFederateSetGlobal(fed, valueName, value, err)
        ccall((:helicsFederateSetGlobal, HELICS_LIBRARY), Cvoid, (helics_federate, Cstring, Cstring, Ptr{helics_error}), fed, valueName, value, err)
    end

    function helicsCoreSetGlobal(core, valueName, value, err)
        ccall((:helicsCoreSetGlobal, HELICS_LIBRARY), Cvoid, (helics_core, Cstring, Cstring, Ptr{helics_error}), core, valueName, value, err)
    end

    function helicsBrokerSetGlobal(broker, valueName, value, err)
        ccall((:helicsBrokerSetGlobal, HELICS_LIBRARY), Cvoid, (helics_broker, Cstring, Cstring, Ptr{helics_error}), broker, valueName, value, err)
    end

    function helicsCreateQuery(target, query)
        ccall((:helicsCreateQuery, HELICS_LIBRARY), helics_query, (Cstring, Cstring), target, query)
    end

    function helicsQueryExecute(query, fed, err)
        ccall((:helicsQueryExecute, HELICS_LIBRARY), Cstring, (helics_query, helics_federate, Ptr{helics_error}), query, fed, err)
    end

    function helicsQueryCoreExecute(query, core, err)
        ccall((:helicsQueryCoreExecute, HELICS_LIBRARY), Cstring, (helics_query, helics_core, Ptr{helics_error}), query, core, err)
    end

    function helicsQueryBrokerExecute(query, broker, err)
        ccall((:helicsQueryBrokerExecute, HELICS_LIBRARY), Cstring, (helics_query, helics_broker, Ptr{helics_error}), query, broker, err)
    end

    function helicsQueryExecuteAsync(query, fed, err)
        ccall((:helicsQueryExecuteAsync, HELICS_LIBRARY), Cvoid, (helics_query, helics_federate, Ptr{helics_error}), query, fed, err)
    end

    function helicsQueryExecuteComplete(query, err)
        ccall((:helicsQueryExecuteComplete, HELICS_LIBRARY), Cstring, (helics_query, Ptr{helics_error}), query, err)
    end

    function helicsQueryIsCompleted(query)
        ccall((:helicsQueryIsCompleted, HELICS_LIBRARY), helics_bool, (helics_query,), query)
    end

    function helicsQueryFree(query)
        ccall((:helicsQueryFree, HELICS_LIBRARY), Cvoid, (helics_query,), query)
    end

    function helicsCleanupLibrary()
        ccall((:helicsCleanupLibrary, HELICS_LIBRARY), Cvoid, ())
    end
    # Julia wrapper for header: /Users/$USER/local/helics-v2.0.0/include/helics/shared_api_library/helicsCallbacks.h
    # Automatically generated using Clang.jl wrap_c


    function helicsBrokerAddLoggingCallback(broker, logger, err)
        ccall((:helicsBrokerAddLoggingCallback, HELICS_LIBRARY), Cvoid, (helics_broker, Ptr{Cvoid}, Ptr{helics_error}), broker, logger, err)
    end

    function helicsCoreAddLoggingCallback(core, logger, err)
        ccall((:helicsCoreAddLoggingCallback, HELICS_LIBRARY), Cvoid, (helics_core, Ptr{Cvoid}, Ptr{helics_error}), core, logger, err)
    end

    function helicsFederateAddLoggingCallback(fed, logger, err)
        ccall((:helicsFederateAddLoggingCallback, HELICS_LIBRARY), Cvoid, (helics_federate, Ptr{Cvoid}, Ptr{helics_error}), fed, logger, err)
    end
    # Julia wrapper for header: /Users/$USER/local/helics-v2.0.0/include/helics/shared_api_library/helics_enums.h
    # Automatically generated using Clang.jl wrap_c

    # Julia wrapper for header: /Users/$USER/local/helics-v2.0.0/include/helics/shared_api_library/helics_export.h
    # Automatically generated using Clang.jl wrap_c

end

