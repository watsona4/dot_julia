include("init.jl")

@testset "Query federate tests"  begin

    broker = createBroker(2)
    vFed1, fedinfo1 = createValueFederate(1, "fed0")
    vFed2, fedinfo2 = createValueFederate(1, "fed1")

    h.helicsFederateRegisterGlobalTypePublication(vFed1, "pub1", "double", "")
    h.helicsFederateRegisterTypePublication(vFed1, "pub2", "double", "")
    h.helicsFederateRegisterTypePublication(vFed2, "pub3", "double", "")
    h.helicsFederateEnterInitializingModeAsync(vFed1)
    h.helicsFederateEnterInitializingMode(vFed2)
    h.helicsFederateEnterInitializingModeComplete(vFed1)

    core = h.helicsFederateGetCoreObject(vFed1)

    q1 = h.helicsCreateQuery("Testfed0", "publications")
    res = h.helicsQueryCoreExecute(q1, core)
    @test res == "[pub1;Testfed0/pub2]"
    # res = h.helicsQueryExecute(q1, vFed2)
    # @test res == "[pub1;Testfed0/pub2]"
    h.helicsQueryFree(q1)

    # q1 = h.helicsCreateQuery("Testfed1", "isinit")
    # res = h.helicsQueryExecute(q1, vFed1)
    # @test res, "true"
    # h.helicsQueryFree(q1)

    # q1 = h.helicsCreateQuery("Testfed1", "publications")
    # res = h.helicsQueryExecute(q1, vFed1)
    # @test res == "[Testfed1/pub3]"
    # h.helicsQueryFree(q1)

    h.helicsCoreFree(core)
    h.helicsFederateFinalizeAsync(vFed1)
    h.helicsFederateFinalize(vFed2)
    h.helicsFederateFinalizeComplete(vFed1)

    destroyFederate(vFed1, fedinfo1)
    destroyFederate(vFed2, fedinfo2)
    destroyBroker(broker)

end

@testset "Query broker tests" begin

    broker = createBroker(2)
    vFed1, fedinfo1 = createValueFederate(1, "fed0")
    vFed2, fedinfo2 = createValueFederate(1, "fed1")
    core = h.helicsFederateGetCoreObject(vFed1)

    q1 = h.helicsCreateQuery("root", "federates")
    res = h.helicsQueryCoreExecute(q1, core)
    name1 = h.helicsFederateGetName(vFed1)
    name2 = h.helicsFederateGetName(vFed2)

    @test "[$name1;$name2]" == res

    res = h.helicsQueryExecute(q1, vFed1)
    @test "[$name1;$name2]" == res

    h.helicsFederateEnterInitializingModeAsync(vFed1)
    h.helicsFederateEnterInitializingMode(vFed2)
    h.helicsFederateEnterInitializingModeComplete(vFed1)
    h.helicsQueryFree(q1)
    h.helicsCoreFree(core)
    h.helicsFederateFinalizeAsync(vFed1)
    h.helicsFederateFinalize(vFed2)
    h.helicsFederateFinalizeComplete(vFed1)

    destroyFederate(vFed1, fedinfo1)
    destroyFederate(vFed2, fedinfo2)
    destroyBroker(broker)
end

