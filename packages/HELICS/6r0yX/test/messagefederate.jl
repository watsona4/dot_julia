include("init.jl")

@testset "MessageFederate test_message_federate_initialize" begin
    broker = createBroker()
    mFed, fedinfo = createMessageFederate()

    state = h.helicsFederateGetState(mFed)
    @test state == 0
    h.helicsFederateEnterExecutingMode(mFed)

    state = h.helicsFederateGetState(mFed)
    @test state == 2

    destroyFederate(mFed, fedinfo)
    destroyBroker(broker)
end

@testset "MessageFederate test_message_federate_endpoint_registration" begin
    broker = createBroker()
    mFed, fedinfo = createMessageFederate()

    epid1 = h.helicsFederateRegisterEndpoint(mFed, "ep1", "")
    epid2 = h.helicsFederateRegisterGlobalEndpoint(mFed, "ep2", "random")

    h.helicsFederateEnterExecutingMode(mFed)

    @test h.HELICS_STATE_EXECUTION == h.helicsFederateGetState(mFed)

    endpoint_name = h.helicsEndpointGetName(epid1)
    @test endpoint_name == "TestA Federate/ep1"

    endpoint_name = h.helicsEndpointGetName(epid2)
    @test endpoint_name == "ep2"

    endpoint_name = h.helicsEndpointGetType(epid1)
    @test endpoint_name == ""

    endpoint_name = h.helicsEndpointGetType(epid2)
    @test endpoint_name == "random"

    epid_b = h.helicsFederateGetEndpoint(mFed, "ep2")
    type = h.helicsEndpointGetType(epid_b)
    @test type == "random"

    epid_c = h.helicsFederateGetEndpointByIndex(mFed, 0)
    name = h.helicsEndpointGetName(epid_c)
    @test name == "TestA Federate/ep1"

    destroyFederate(mFed, fedinfo)
    destroyBroker(broker)
end

@testset "MessageFederate test_message_federate_send" begin
    broker = createBroker()
    mFed, fedinfo = createMessageFederate()

    epid1 = h.helicsFederateRegisterEndpoint(mFed, "ep1", "")
    epid2 = h.helicsFederateRegisterGlobalEndpoint(mFed, "ep2", "random")

    h.helicsFederateSetTimeProperty(mFed, h.HELICS_PROPERTY_TIME_DELTA, 1.0)
    h.helicsFederateEnterExecutingMode(mFed)

    data = "random-data"

    h.helicsEndpointSendEventRaw(epid1, "ep2", data, 1.0)

    granted_time = h.helicsFederateRequestTime(mFed, 2.0)
    @test granted_time == 1.0

    res = h.helicsFederateHasMessage(mFed)
    @test res == true

    res = h.helicsEndpointHasMessage(epid1)
    @test res == false

    res = h.helicsEndpointHasMessage(epid2)
    @test res == true

    message = h.helicsEndpointGetMessage(epid2)

    @test message.data == "random-data"
    @test message.length == 11
    @test message.original_dest == ""
    @test message.original_source == "TestA Federate/ep1"
    @test message.source == "TestA Federate/ep1"
    @test message.time == 1.0

    destroyFederate(mFed, fedinfo)
    destroyBroker(broker)
end

@testset "MessageFederate send_receive_2fed_multisend" begin

    broker = createBroker(2)
    mFed1, fedinfo1 = createMessageFederate(1, "A Federate")
    mFed2, fedinfo2 = createMessageFederate(1, "B Federate")

    epid1 = h.helicsFederateRegisterEndpoint(mFed1, "ep1", "")
    epid2 = h.helicsFederateRegisterGlobalEndpoint(mFed2, "ep2", "random")

    h.helicsFederateSetTimeProperty(mFed1, h.HELICS_PROPERTY_TIME_DELTA, 1.0)
    h.helicsFederateSetTimeProperty(mFed2, h.HELICS_PROPERTY_TIME_DELTA, 1.0)

    h.helicsFederateEnterExecutingModeAsync(mFed1)
    h.helicsFederateEnterExecutingMode(mFed2)
    h.helicsFederateEnterExecutingModeComplete(mFed1)

    @test h.HELICS_STATE_EXECUTION == h.helicsFederateGetState(mFed1)
    @test h.HELICS_STATE_EXECUTION == h.helicsFederateGetState(mFed2)

    h.helicsEndpointSetDefaultDestination(epid1, "ep2");

    h.helicsEndpointSendMessageRaw(epid1, "", "a")
    h.helicsEndpointSendMessageRaw(epid1, "", "a")
    h.helicsEndpointSendMessageRaw(epid1, "", "a")

    h.helicsFederateRequestTimeAsync(mFed1, 1.0)
    granted_time = h.helicsFederateRequestTime(mFed2, 1.0)
    complete_time = h.helicsFederateRequestTimeComplete(mFed1)

    @test granted_time == 1.0
    @test complete_time == 1.0

    res = h.helicsEndpointPendingMessages(epid2)
    @test res == 3

    res = h.helicsFederatePendingMessages(mFed2)
    @test res == 3

    @test h.helicsEndpointGetDefaultDestination(epid1) == "ep2"

    destroyFederate(mFed1, fedinfo1)
    destroyFederate(mFed2, fedinfo2)
    destroyBroker(broker)

end

