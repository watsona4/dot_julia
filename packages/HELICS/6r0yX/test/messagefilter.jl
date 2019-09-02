include("init.jl")

@testset "Broker" begin
    broker = createBroker(1)
    initstring = "--broker="
    identifier = h.helicsBrokerGetIdentifier(broker)
    initstring = initstring * identifier
    initstring = initstring * " --broker_address "
    address = h.helicsBrokerGetAddress(broker)
    initstring = initstring * address
    @test initstring == "--broker=mainbroker --broker_address tcp://127.0.0.1:23404"
    destroyBroker(broker)

end

@testset "MessageFilter Registration" begin

    broker = createBroker(2)

    fFed, ffedinfo = createMessageFederate(1, "filter")
    mFed, mfedinfo = createMessageFederate(1, "message")

    h.helicsFederateRegisterGlobalEndpoint(mFed, "port1", "")
    h.helicsFederateRegisterGlobalEndpoint(mFed, "port2", "")

    f1 = h.helicsFederateRegisterFilter(fFed, h.HELICS_FILTER_TYPE_CUSTOM, "filter1")
    f2 = h.helicsFederateRegisterFilter(fFed, h.HELICS_FILTER_TYPE_CUSTOM, "filter2")
    h.helicsFederateRegisterEndpoint(fFed, "fout", "")
    h.helicsFederateRegisterFilter(fFed, h.HELICS_FILTER_TYPE_CUSTOM,  "filter0/fout")
    h.helicsFederateEnterExecutingModeAsync(fFed)
    h.helicsFederateEnterExecutingMode(mFed)
    h.helicsFederateEnterExecutingModeComplete(fFed)

    filter_name = h.helicsFilterGetName(f1)
    @test filter_name == "Testfilter/filter1"

    filter_name = h.helicsFilterGetName(f2)
    @test filter_name == "Testfilter/filter2"

    # filter_target = h.helicsFilterGetTarget(f2)
    # @test filter_target == "port2"

    h.helicsFederateFinalize(mFed)
    h.helicsFederateFinalize(fFed)

    destroyFederate(fFed, ffedinfo)
    destroyFederate(mFed, mfedinfo)
    sleep(1.0)

    destroyBroker(broker)
end

@testset "MessageFilter Info" begin

    broker = createBroker(2)

    fFed, ffedinfo = createMessageFederate(1, "filter")
    mFed, mfedinfo = createMessageFederate(1, "message")

    p1 = h.helicsFederateRegisterGlobalEndpoint(mFed, "port1", "")
    p2 = h.helicsFederateRegisterGlobalEndpoint(mFed, "port2", "")

    h.helicsEndpointSetInfo(p1, "p1_test")
    h.helicsEndpointSetInfo(p2, "p2_test")

    f1 = h.helicsFederateRegisterFilter(fFed, h.HELICS_FILTER_TYPE_CUSTOM, "filter1")
    h.helicsFilterAddSourceTarget(f1, "port1")
    h.helicsFilterSetInfo(f1, "f1_test")

    f2 = h.helicsFederateRegisterFilter(fFed, h.HELICS_FILTER_TYPE_CUSTOM, "filter2")
    h.helicsFilterAddSourceTarget(f2, "port2")
    h.helicsFilterSetInfo(f2, "f2_test")

    ep1 = h.helicsFederateRegisterEndpoint(fFed, "fout", "")
    h.helicsEndpointSetInfo(ep1, "ep1_test")

    f3 = h.helicsFederateRegisterFilter(fFed, h.HELICS_FILTER_TYPE_CUSTOM,  "c4")
    h.helicsFilterAddSourceTarget(f3, "filter0/fout")
    h.helicsFilterSetInfo(f3, "f3_test")

    h.helicsFederateEnterExecutingModeAsync(fFed)
    h.helicsFederateEnterExecutingMode(mFed)
    h.helicsFederateEnterExecutingModeComplete(fFed)

    filter_name = h.helicsFilterGetName(f1)
    @test filter_name == "Testfilter/filter1"

    filter_name = h.helicsFilterGetName(f2)
    @test filter_name == "Testfilter/filter2"

    @test h.helicsEndpointGetInfo(p1) == "p1_test"
    @test h.helicsEndpointGetInfo(p2) == "p2_test"
    @test h.helicsEndpointGetInfo(ep1) == "ep1_test"

    @test h.helicsFilterGetInfo(f1) == "f1_test"
    @test h.helicsFilterGetInfo(f2) == "f2_test"
    @test h.helicsFilterGetInfo(f3) == "f3_test"

    h.helicsFederateFinalize(mFed)
    h.helicsFederateFinalize(fFed)

    destroyFederate(fFed, ffedinfo)
    destroyFederate(mFed, mfedinfo)
    sleep(1.0)

    destroyBroker(broker)
end


@testset "MessageFilter Function" begin
    broker = createBroker(2)

    fFed, ffedinfo = createMessageFederate(1, "filter")
    mFed, mfedinfo = createMessageFederate(1, "message")

    p1 = h.helicsFederateRegisterGlobalEndpoint(mFed, "port1", "")
    p2 = h.helicsFederateRegisterGlobalEndpoint(mFed, "port2", "random")

    f1 = h.helicsFederateRegisterGlobalFilter(fFed, h.HELICS_FILTER_TYPE_CUSTOM, "filter1")
    h.helicsFilterAddSourceTarget(f1, "port1")
    f2 = h.helicsFederateRegisterGlobalFilter(fFed, h.HELICS_FILTER_TYPE_DELAY, "filter2")
    h.helicsFilterAddSourceTarget(f2, "port1")
    h.helicsFederateRegisterEndpoint(fFed,"fout","")
    f3 = h.helicsFederateRegisterFilter(fFed, h.HELICS_FILTER_TYPE_RANDOM_DELAY, "filter3")
    h.helicsFilterAddSourceTarget(f3,"filter/fout")

    h.helicsFilterSet(f2, "delay", 2.5)
    h.helicsFederateEnterExecutingModeAsync(fFed)
    h.helicsFederateEnterExecutingMode(mFed)
    h.helicsFederateEnterExecutingModeComplete(fFed)
    state = h.helicsFederateGetState(fFed)
    @test state == 2
    data = "hello world"

    filt_key = h.helicsFilterGetName(f1)
    @test filt_key == "filter1"

    filt_key = h.helicsFilterGetName(f2)
    @test filt_key == "filter2"

    h.helicsEndpointSendMessageRaw(p1, "port2", data)
    h.helicsFederateRequestTimeAsync(mFed, 1.0)
    grantedtime = h.helicsFederateRequestTime(fFed, 1.0)
    @test grantedtime == 1.0
    grantedtime = h.helicsFederateRequestTimeComplete(mFed)
    @test grantedtime == 1.0
    res = h.helicsFederateHasMessage(mFed)
    @test res == 0
    res = h.helicsEndpointHasMessage(p2)
    @test res == 0
    #grantedtime = h.helicsFederateRequestTime(fFed, 3.0)
    #@test res==h.helics_true

    h.helicsFederateFinalize(mFed)
    h.helicsFederateFinalize(fFed)
    #f2 = h.helicsFederateRegisterDestinationFilter(fFed, h.helics_custom_filter, "filter2", "port2")
    #ep1 = h.helicsFederateRegisterEndpoint(fFed, "fout", "")
    #f3 = h.helicsFederateRegisterSourceFilter(fFed, h.helics_custom_filter, "", "filter0/fout")

    destroyFederate(fFed, ffedinfo)
    destroyFederate(mFed, mfedinfo)
    sleep(1.0)
    destroyBroker(broker)

end

