include("init.jl")

@testset "Broker API tests" begin

    @test h.helicsIsCoreTypeAvailable("zmq") == 1
    broker1 = h.helicsCreateBroker("zmq", "broker1", "--federates 3 --loglevel 1")
    broker2 = h.helicsBrokerClone(broker1)
    address_string = h.helicsBrokerGetAddress(broker1)
    occursin("tcp://127.0.0.1:23404", address_string)
    occursin("broker1", h.helicsBrokerGetIdentifier(broker1))
    @test h.helicsBrokerIsValid(broker1) == 1
    @test h.helicsBrokerIsConnected(broker1) == 1
    h.helicsBrokerDisconnect(broker1)
    @test h.helicsBrokerIsConnected(broker1) == 0
    h.helicsBrokerDisconnect(broker2)
    h.helicsBrokerFree(broker1)
    h.helicsBrokerFree(broker2)
    h.helicsCloseLibrary()

end

@testset "Core API tests" begin

    core1 = h.helicsCreateCore("test", "core1", "--autobroker")
    core2 = h.helicsCoreClone(core1)
    @test occursin("core1", h.helicsCoreGetIdentifier(core1))

    @test h.helicsCoreIsConnected(core1) == 0

    sourceFilter1 = h.helicsCoreRegisterFilter(core1, h.HELICS_FILTER_TYPE_DELAY, "core1SourceFilter")
    h.helicsFilterAddSourceTarget(sourceFilter1, "ep1")
    destinationFilter1 = h.helicsCoreRegisterFilter(core1, h.HELICS_FILTER_TYPE_DELAY, "core1DestinationFilter")
    h.helicsFilterAddDestinationTarget(destinationFilter1, "ep2")
    cloningFilter1 = h.helicsCoreRegisterCloningFilter(core1, "ep3")
    h.helicsFilterRemoveDeliveryEndpoint(cloningFilter1, "ep3")

    h.helicsCoreSetReadyToInit(core1)
    h.helicsCoreDisconnect(core1)
    h.helicsCoreDisconnect(core2)
    h.helicsCoreFree(core1)
    h.helicsCoreFree(core2)
    h.helicsCloseLibrary()

end

@testset "Misc API tests" begin
    fedInfo1 = h.helicsCreateFederateInfo()
    h.helicsFederateInfoSetCoreInitString(fedInfo1, "-f 1")
    h.helicsFederateInfoSetCoreName(fedInfo1, "core3")
    h.helicsFederateInfoSetCoreType(fedInfo1, 3)
    h.helicsFederateInfoSetCoreTypeFromString(fedInfo1, "zmq")
    h.helicsFederateInfoSetFlagOption(fedInfo1, 1, true)
    h.helicsFederateInfoSetTimeProperty(fedInfo1,
            h.HELICS_PROPERTY_TIME_INPUT_DELAY, 1.0)
    h.helicsFederateInfoSetIntegerProperty(fedInfo1,
            h.HELICS_PROPERTY_INT_LOG_LEVEL, 1)
    h.helicsFederateInfoSetIntegerProperty(fedInfo1,
            h.HELICS_PROPERTY_INT_MAX_ITERATIONS, 100)
    h.helicsFederateInfoSetTimeProperty(fedInfo1,
            h.HELICS_PROPERTY_TIME_OUTPUT_DELAY, 1.0)
    h.helicsFederateInfoSetTimeProperty(fedInfo1,
            h.HELICS_PROPERTY_TIME_PERIOD, 1.0)
    h.helicsFederateInfoSetTimeProperty(fedInfo1,
            h.HELICS_PROPERTY_TIME_DELTA, 1.0)
    h.helicsFederateInfoSetTimeProperty(fedInfo1,
            h.HELICS_PROPERTY_TIME_OFFSET, 0.1)
    h.helicsFederateInfoFree(fedInfo1)

    broker3 = h.helicsCreateBroker("zmq", "broker3", "--federates 1 --loglevel 1")
    fedInfo2 = h.helicsCreateFederateInfo()
    coreInitString = "--federates 1"
    h.helicsFederateInfoSetCoreInitString(fedInfo2, coreInitString)
    h.helicsFederateInfoSetCoreTypeFromString(fedInfo2, "zmq")
    h.helicsFederateInfoSetIntegerProperty(fedInfo2, h.HELICS_PROPERTY_INT_LOG_LEVEL, 1)
    h.helicsFederateInfoSetTimeProperty(fedInfo2, h.HELICS_PROPERTY_TIME_DELTA, 1.0)
    fed1 = h.helicsCreateCombinationFederate("fed1", fedInfo2)
    fed2 = h.helicsFederateClone(fed1)
    fed3 = h.helicsGetFederateByName("fed1")
    h.helicsFederateSetFlagOption(fed2, 1, false)

    h.helicsFederateSetTimeProperty(fed2, h.HELICS_PROPERTY_TIME_INPUT_DELAY, 1.0)
    h.helicsFederateSetIntegerProperty(fed1, h.HELICS_PROPERTY_INT_LOG_LEVEL, 1)
    h.helicsFederateSetIntegerProperty(fed2, h.HELICS_PROPERTY_INT_MAX_ITERATIONS, 100)
    h.helicsFederateSetTimeProperty(fed2, h.HELICS_PROPERTY_TIME_OUTPUT_DELAY, 1.0)
    h.helicsFederateSetTimeProperty(fed2, h.HELICS_PROPERTY_TIME_PERIOD, 0.0)
    h.helicsFederateSetTimeProperty(fed2, h.HELICS_PROPERTY_TIME_DELTA, 1.0)

    fed1CloningFilter = h.helicsFederateRegisterCloningFilter(fed1, "fed1/Ep1")
    fed1DestinationFilter = h.helicsFederateRegisterFilter(fed1, h.HELICS_FILTER_TYPE_DELAY, "fed1DestinationFilter")
    h.helicsFilterAddDestinationTarget(fed1DestinationFilter, "ep2")

    ep1 = h.helicsFederateRegisterEndpoint(fed1, "Ep1", "string")
    ep2 = h.helicsFederateRegisterGlobalEndpoint(fed1, "Ep2", "string")
    pub1 = h.helicsFederateRegisterGlobalPublication(fed1, "pub1", h.HELICS_DATA_TYPE_DOUBLE, "")
    pub2 = h.helicsFederateRegisterGlobalTypePublication(fed1, "pub2", "complex", "")

    sub1 = h.helicsFederateRegisterSubscription(fed1, "pub1")
    sub2 = h.helicsFederateRegisterSubscription(fed1, "pub2")
    h.helicsInputAddTarget(sub2, "Ep2")
    pub3 = h.helicsFederateRegisterPublication(fed1, "pub3", h.HELICS_DATA_TYPE_STRING, "")

    pub1KeyString = h.helicsPublicationGetKey(pub1)
    pub1TypeString = h.helicsPublicationGetType(pub1)
    pub1UnitsString = h.helicsPublicationGetUnits(pub1)
    sub1KeyString = h.helicsSubscriptionGetKey(sub1)
    sub1UnitsString = h.helicsInputGetUnits(sub1)
    @test "pub1" == pub1KeyString
    @test "double" == pub1TypeString
    @test "" == pub1UnitsString
    @test "pub1" == sub1KeyString
    @test "" == sub1UnitsString

    fed1SourceFilter = h.helicsFederateRegisterFilter(fed1,
            h.HELICS_FILTER_TYPE_DELAY, "fed1SourceFilter")
    h.helicsFilterAddSourceTarget(fed1SourceFilter, "Ep2")
    h.helicsFilterAddDestinationTarget(fed1SourceFilter, "fed1/Ep1")
    h.helicsFilterRemoveTarget(fed1SourceFilter, "fed1/Ep1")
    h.helicsFilterAddSourceTarget(fed1SourceFilter, "Ep2")
    h.helicsFilterRemoveTarget(fed1SourceFilter, "Ep2")

    fed1SourceFilterNameString = h.helicsFilterGetName(fed1SourceFilter)
    @test fed1SourceFilterNameString == "fed1/fed1SourceFilter"

    sub3 = h.helicsFederateRegisterSubscription(fed1, "fed1/pub3", "")
    pub4 = h.helicsFederateRegisterTypePublication(fed1, "pub4", "int", "")

    sub4 = h.helicsFederateRegisterSubscription(fed1, "fed1/pub4", "")
    pub5 = h.helicsFederateRegisterGlobalTypePublication(fed1, "pub5", "boolean", "")

    sub5 = h.helicsFederateRegisterSubscription(fed1, "pub5", "")
    pub6 = h.helicsFederateRegisterGlobalPublication(fed1, "pub6", h.HELICS_DATA_TYPE_VECTOR, "")
    sub6 = h.helicsFederateRegisterSubscription(fed1, "pub6", "")
    pub7 = h.helicsFederateRegisterGlobalPublication(fed1, "pub7",
            h.HELICS_DATA_TYPE_NAMED_POINT, "")
    sub7 = h.helicsFederateRegisterSubscription(fed1, "pub7", "")

    h.helicsInputSetDefaultBoolean(sub5, false)
    h.helicsInputSetDefaultComplex(sub2, -9.9 + im * 2.5)
    h.helicsInputSetDefaultDouble(sub1, 3.4)
    h.helicsInputSetDefaultInteger(sub4, 6)
    h.helicsInputSetDefaultNamedPoint(sub7, "hollow", 20.0)
    h.helicsInputSetDefaultString(sub3, "default")
    sub6Default = [ 3.4, 90.9, 4.5 ]
    h.helicsInputSetDefaultVector(sub6, sub6Default)
    h.helicsEndpointSubscribe(ep2, "fed1/pub3")
    h.helicsFederateEnterInitializingModeAsync(fed1)
    rs = h.helicsFederateIsAsyncOperationCompleted(fed1)
    if (rs == 0)
        sleep(0.500)
        rs = h.helicsFederateIsAsyncOperationCompleted(fed1)
        if (rs == 0)
            sleep(.500)
            rs = h.helicsFederateIsAsyncOperationCompleted(fed1)
            if (rs == 0)
                @test true == false
            end
        end
    end
    h.helicsFederateEnterInitializingModeComplete(fed1)
    h.helicsFederateEnterExecutingModeAsync(fed1)
    h.helicsFederateEnterExecutingModeComplete(fed1)
    mesg1 = h.Message(
                      0.0,
                      "Hello",
                      length("Hello"),
                      0,
                      0,
                      "fed1/Ep1",
                      "fed1/Ep1",
                      "Ep2",
                      "Ep2",
                     )

    h.helicsEndpointSendMessage(ep1, mesg1)
    mesg1 = h.Message(
                      0.0,
                      "There",
                      length("There"),
                      0,
                      0,
                      "fed1/Ep1",
                      "fed1/Ep1",
                      "Ep2",
                      "Ep2",
                     )
    h.helicsEndpointSendMessage(ep1, mesg1)
    h.helicsEndpointSetDefaultDestination(ep2, "fed1/Ep1")

    ep1NameString = h.helicsEndpointGetName(ep1)
    ep1TypeString = h.helicsEndpointGetType(ep1)

    @test ep1NameString == "fed1/Ep1"
    @test ep1TypeString == "string"

    coreFed1 = h.helicsFederateGetCoreObject(fed1)

    fed1Time = h.helicsFederateGetCurrentTime(fed1)
    @test fed1Time == 0.0
    fed1EndpointCount = h.helicsFederateGetEndpointCount(fed1)
    @test fed1EndpointCount == 2

    fed1NameString = h.helicsFederateGetName(fed1)
    @test fed1NameString == "fed1"

    fed1State = h.helicsFederateGetState(fed1)
    @test fed1State == 2
    fed1PubCount = h.helicsFederateGetPublicationCount(fed1)
    @test fed1PubCount == 7
    fed1SubCount = h.helicsFederateGetInputCount(fed1)
    @test fed1SubCount == 7

    h.helicsPublicationPublishBoolean(pub5, true)
    h.helicsPublicationPublishComplex(pub2, 5.6 + im * -0.67)
    h.helicsPublicationPublishDouble(pub1, 457.234)
    h.helicsPublicationPublishInteger(pub4, 1)
    h.helicsPublicationPublishNamedPoint(pub7, "Blah Blah", 20.0)
    h.helicsPublicationPublishString(pub3, "Mayhem")
    pub6Vector = [ 4.5, 56.5 ]
    h.helicsPublicationPublishVector(pub6, pub6Vector)
    sleep(0.500)
    h.helicsFederateRequestTimeAsync(fed1, 1.0)

    returnTime = h.helicsFederateRequestTimeComplete(fed1)
    @test returnTime == 1.0
    ep2MsgCount = h.helicsEndpointPendingMessages(ep2)
    @test ep2MsgCount == 2
    ep2HasMsg = h.helicsEndpointHasMessage(ep2)
    @test ep2HasMsg == 1

    msg2 = h.helicsEndpointGetMessage(ep2)
    @test msg2.time == 1.0
    @test "Hello" == msg2.data
    @test msg2.length == 5
    @test msg2.original_source == "fed1/Ep1"
    @test msg2.source == "fed1/Ep1"
    @test msg2.dest == "Ep2"
    @test_broken msg2.original_dest == "Ep2"

    fed1MsgCount = h.helicsFederatePendingMessages(fed1)
    @test fed1MsgCount == 1

    @test h.helicsFederateHasMessage(fed1) == 1

    msg3 = h.helicsFederateGetMessage(fed1)
    @test msg3.time == 1.0
    @test msg3.data == "There"
    @test msg3.length == 5
    @test msg3.original_source == "fed1/Ep1"
    @test msg3.source == "fed1/Ep1"
    @test msg3.dest == "Ep2"
    @test_broken msg3.original_dest == "Ep2"

    sub1Updated = h.helicsInputIsUpdated(sub1)
    @test sub1Updated == 1

    @test h.helicsInputLastUpdateTime(sub2) == 1.0

    @test h.helicsInputGetComplex(sub2) == 5.6 - im * 0.67

    @test h.helicsInputGetDouble(sub1) == 457.234
    @test h.helicsInputGetInteger(sub4) == 1
    sub7PointString, sub7DoubleValue = h.helicsInputGetNamedPoint(sub7)
    @test sub7PointString == "Blah Blah"
    @test sub7DoubleValue == 20.0
    @test h.helicsInputGetBoolean(sub5) == 1
    @test h.helicsInputGetString(sub3) == "Mayhem"

    sub3ValueSize = h.helicsInputGetRawValueSize(sub3)
    @test sub3ValueSize == 6

    if typeof(1) == Int32
        @test_broken h.helicsInputGetVector(sub6) == [4.5, 56.5]
    else
        @test h.helicsInputGetVector(sub6) == [4.5, 56.5]
    end

    h.helicsFederateFinalize(fed1)
    h.helicsFederateFinalize(fed2)
    h.helicsFederateFree(fed1)
    h.helicsFederateFinalize(fed2)
    h.helicsFederateFree(fed2)
    h.helicsFederateInfoFree(fedInfo2)
    h.helicsBrokerDisconnect(broker3)

    h.helicsBrokerFree(broker3)

    h.helicsCleanupLibrary()
    h.helicsCloseLibrary()
end

