include("init.jl")

@testset "ValueFederate Creation" begin
    broker = createBroker()
    vFed, fedinfo = createValueFederate()
    destroyFederate(vFed, fedinfo)
    destroyBroker(broker)
end

@testset "ValueFederate State" begin

    broker = createBroker()
    vFed, fedinfo = createValueFederate()

    state = h.helicsFederateGetState(vFed)
    @test state == 0

    h.helicsFederateEnterExecutingMode(vFed)

    state = h.helicsFederateGetState(vFed)
    @test state == 2

    destroyFederate(vFed, fedinfo)
    destroyBroker(broker)
end

@testset "ValueFederate publication registration" begin
    broker = createBroker()
    vFed, fedinfo = createValueFederate()

    pubid1 = h.helicsFederateRegisterTypePublication(vFed, "pub1", "string", "")
    pubid2 = h.helicsFederateRegisterGlobalTypePublication(vFed, "pub2", "int", "")
    pubid3 = h.helicsFederateRegisterTypePublication(vFed, "pub3", "double", "V")

    h.helicsFederateEnterExecutingMode(vFed)

    @test h.helicsPublicationGetKey(pubid1) == "TestA Federate/pub1"
    @test h.helicsPublicationGetKey(pubid2) == "pub2"

    @test h.helicsPublicationGetKey(pubid3) == "TestA Federate/pub3"
    @test h.helicsPublicationGetType(pubid3) == "double"
    @test h.helicsPublicationGetUnits(pubid3) == "V"

    destroyFederate(vFed, fedinfo)
    destroyBroker(broker)
end

@testset "ValueFederate named point" begin
    broker = createBroker()
    vFed, fedinfo = createValueFederate()

    defaultValue = "start of a longer string in place of the shorter one and now this should be very long"
    defVal = 5.3
    #testValue1 = "inside of the functional relationship of helics"
    testValue1 = "short string"
    testVal1 = 45.7823
    testValue2 = "I am a string"
    testVal2 = 0.0

    pubid = h.helicsFederateRegisterGlobalPublication(vFed, "pub1", h.HELICS_DATA_TYPE_NAMED_POINT, "")
    subid = h.helicsFederateRegisterSubscription(vFed, "pub1", "")

    h.helicsInputSetDefaultNamedPoint(subid, defaultValue, defVal)

    h.helicsFederateEnterExecutingMode(vFed)

    # publish string1 at time=0.0
    h.helicsPublicationPublishNamedPoint(pubid, testValue1, testVal1)

    @test h.helicsInputGetNamedPoint(subid) == (defaultValue, defVal)

    @test h.helicsFederateRequestTime(vFed, 1.0) == 0.01

    # # get the value
    @test h.helicsInputGetNamedPoint(subid) == (testValue1, testVal1)

    # publish a second string
    h.helicsPublicationPublishNamedPoint(pubid, testValue2, testVal2)

    # # make sure the value is still what we expect
    @test h.helicsInputGetNamedPoint(subid) == (testValue1, testVal1)
    # # make sure the string is what we expect
    # # @test value3 == testValue1
    # @test val3 == [testValue1, testVal1]

    # # advance time
    @test h.helicsFederateRequestTime(vFed, 2.0) == 0.02

    # # make sure the value was updated
    @test h.helicsInputGetNamedPoint(subid) == (testValue2, testVal2)

    destroyFederate(vFed, fedinfo)
    destroyBroker(broker)

end

@testset "ValueFederate Test Bool" begin
    broker = createBroker()
    vFed, fedinfo = createValueFederate()

    defaultValue = true
    testValue1 = true
    testValue2 = false

    # register the publications
    pubid = h.helicsFederateRegisterGlobalPublication(vFed, "pub1", h.HELICS_DATA_TYPE_BOOLEAN, "")
    subid = h.helicsFederateRegisterSubscription(vFed, "pub1", "")

    h.helicsInputSetDefaultBoolean(subid, defaultValue)

    h.helicsFederateEnterExecutingMode(vFed)

    # publish string1 at time=0.0
    h.helicsPublicationPublishBoolean(pubid, testValue1)
    val = h.helicsInputGetBoolean(subid)

    @test val == defaultValue

    grantedtime = h.helicsFederateRequestTime(vFed, 1.0)
    @test grantedtime == 0.01

    # get the value
    val = h.helicsInputGetBoolean(subid)

    # make sure the string is what we expect
    @test val == testValue1

    # publish a second string
    h.helicsPublicationPublishBoolean(pubid, testValue2)

    # make sure the value is still what we expect
    val = h.helicsInputGetBoolean(subid)
    @test val == testValue1
    # advance time
    grantedtime = h.helicsFederateRequestTime(vFed, 2.0)
    # make sure the value was updated
    @test grantedtime == 0.02

    val = h.helicsInputGetBoolean(subid)
    @test val == testValue2

    destroyFederate(vFed, fedinfo)
    destroyBroker(broker)

end

@testset "ValueFederate publisher registration" begin
    broker = createBroker()
    vFed, fedinfo = createValueFederate()

    pubid1 = h.helicsFederateRegisterPublication(vFed, "pub1", h.HELICS_DATA_TYPE_STRING, "")
    pubid2 = h.helicsFederateRegisterGlobalPublication(vFed, "pub2", h.HELICS_DATA_TYPE_INT, "")
    pubid3 = h.helicsFederateRegisterPublication(vFed, "pub3", h.HELICS_DATA_TYPE_DOUBLE, "V")
    h.helicsFederateEnterExecutingMode(vFed)

    publication_key = h.helicsPublicationGetKey(pubid1)
    @test publication_key == "TestA Federate/pub1"
    publication_type = h.helicsPublicationGetType(pubid1)
    @test publication_type == "string"
    publication_key = h.helicsPublicationGetKey(pubid2)
    @test publication_key == "pub2"
    publication_key = h.helicsPublicationGetKey(pubid3)
    @test publication_key == "TestA Federate/pub3"
    publication_type = h.helicsPublicationGetType(pubid3)
    @test publication_type == "double"
    publication_units = h.helicsPublicationGetUnits(pubid3)
    @test publication_units == "V"
    publication_type = h.helicsPublicationGetType(pubid2)
    @test publication_type == "int64"

    destroyFederate(vFed, fedinfo)
    destroyBroker(broker)
end

@testset "ValueFederate subscription and publication registration" begin

    broker = createBroker()
    vFed, fedinfo = createValueFederate()

    pubid3 = h.helicsFederateRegisterTypePublication(vFed, "pub3", "double", "V")

    subid1 = h.helicsFederateRegisterSubscription(vFed, "sub1", "")
    subid2 = h.helicsFederateRegisterSubscription(vFed, "sub2", "")
    subid3 = h.helicsFederateRegisterSubscription(vFed, "sub3", "V")

    h.helicsFederateEnterExecutingMode(vFed)

    publication_type = h.helicsPublicationGetType(pubid3)
    @test publication_type == "double"

    sub_key = h.helicsSubscriptionGetKey(subid1)
    @test sub_key == "sub1"
    sub_type = h.helicsInputGetType(subid1)
    @test sub_type == ""
    sub_key = h.helicsSubscriptionGetKey(subid2)
    @test sub_key == "sub2"
    sub_key = h.helicsSubscriptionGetKey(subid3)
    @test sub_key == "sub3"
    sub_type = h.helicsInputGetType(subid3)
    @test sub_type == ""
    sub_units = h.helicsInputGetUnits(subid3)
    @test sub_units == "V"
    sub_type = h.helicsInputGetType(subid2)
    @test sub_type == ""

    destroyFederate(vFed, fedinfo)
    destroyBroker(broker)

end


@testset "ValueFederate single transfer" begin

    broker = createBroker()
    vFed, fedinfo = createValueFederate()

    pubid = h.helicsFederateRegisterGlobalPublication(vFed, "pub1", h.HELICS_DATA_TYPE_STRING, "")
    subid = h.helicsFederateRegisterSubscription(vFed, "pub1", "")

    h.helicsFederateEnterExecutingMode(vFed)

    h.helicsPublicationPublishString(pubid, "string1")

    grantedtime = h.helicsFederateRequestTime(vFed, 1.0)
    @test grantedtime == 0.01

    s = h.helicsInputGetString(subid)
    @test s == "string1"

    destroyFederate(vFed, fedinfo)
    destroyBroker(broker)
end

@testset "ValueFederate test double" begin
    broker = createBroker()
    vFed, fedinfo = createValueFederate()

    defaultValue = 1.0
    testValue = 2.0
    pubid = h.helicsFederateRegisterGlobalPublication(vFed, "pub1", h.HELICS_DATA_TYPE_DOUBLE, "")
    subid = h.helicsFederateRegisterSubscription(vFed, "pub1", "")
    h.helicsInputSetDefaultDouble(subid, defaultValue)

    h.helicsFederateEnterExecutingMode(vFed)

    # publish string1 at time=0.0
    h.helicsPublicationPublishDouble(pubid, testValue)

    value = h.helicsInputGetDouble(subid)
    @test value == defaultValue

    grantedtime = h.helicsFederateRequestTime(vFed, 1.0)
    @test grantedtime == 0.01

    value = h.helicsInputGetDouble(subid)
    @test value == testValue

    # publish string1 at time=0.0
    h.helicsPublicationPublishDouble(pubid, testValue + 1)

    grantedtime = h.helicsFederateRequestTime(vFed, 2.0)
    @test grantedtime == 0.02

    value = h.helicsInputGetDouble(subid)
    @test value == testValue + 1

    destroyFederate(vFed, fedinfo)
    destroyBroker(broker)
end

@testset "ValueFederate test complex" begin
    broker = createBroker()
    vFed, fedinfo = createValueFederate()

    rDefaultValue = 1.0
    iDefaultValue = 1.0
    rTestValue = 2.0
    iTestValue = 2.0
    pubid = h.helicsFederateRegisterGlobalPublication(vFed, "pub1", h.HELICS_DATA_TYPE_COMPLEX, "")
    subid = h.helicsFederateRegisterSubscription(vFed, "pub1", "")
    h.helicsInputSetDefaultComplex(subid, (rDefaultValue + im * iDefaultValue))

    h.helicsFederateEnterExecutingMode(vFed)

    # publish string1 at time=0.0
    h.helicsPublicationPublishComplex(pubid, (rTestValue + im * iTestValue))

    @test rDefaultValue + im * iDefaultValue == h.helicsInputGetComplex(subid)

    grantedtime = h.helicsFederateRequestTime(vFed, 1.0)
    @test grantedtime == 0.01

    @test (rTestValue + im * iTestValue) == h.helicsInputGetComplex(subid)

    destroyFederate(vFed, fedinfo)
    destroyBroker(broker)
end

@testset "ValueFederate test integer" begin
    broker = createBroker()
    vFed, fedinfo = createValueFederate()

    defaultValue = 1
    testValue = 2
    pubid = h.helicsFederateRegisterGlobalPublication(vFed, "pub1", h.HELICS_DATA_TYPE_INT, "")
    subid = h.helicsFederateRegisterSubscription(vFed, "pub1", "")
    h.helicsInputSetDefaultInteger(subid, defaultValue)

    h.helicsFederateEnterExecutingMode(vFed)

    h.helicsPublicationPublishInteger(pubid, testValue)

    value = h.helicsInputGetInteger(subid)
    @test value == defaultValue

    grantedtime = h.helicsFederateRequestTime(vFed, 1.0)
    @test grantedtime == 0.01

    value = h.helicsInputGetInteger(subid)
    @test value == testValue

    h.helicsPublicationPublishInteger(pubid, testValue + 1)

    grantedtime = h.helicsFederateRequestTime(vFed, 2.0)
    @test grantedtime == 0.02

    value = h.helicsInputGetInteger(subid)
    @test value == testValue + 1

    destroyFederate(vFed, fedinfo)
    destroyBroker(broker)
end

@testset "ValueFederate test string" begin
    broker = createBroker()
    vFed, fedinfo = createValueFederate()

    defaultValue = "String1"
    testValue = "String2"
    pubid = h.helicsFederateRegisterGlobalPublication(vFed, "pub1", h.HELICS_DATA_TYPE_STRING, "")
    subid = h.helicsFederateRegisterSubscription(vFed, "pub1", "")
    h.helicsInputSetDefaultString(subid, defaultValue)

    h.helicsFederateEnterExecutingMode(vFed)

    h.helicsPublicationPublishString(pubid, testValue)

    value = h.helicsInputGetString(subid)
    @test value == defaultValue

    grantedtime = h.helicsFederateRequestTime(vFed, 1.0)
    @test grantedtime == 0.01

    value = h.helicsInputGetString(subid)
    @test value == testValue

    destroyFederate(vFed, fedinfo)
    destroyBroker(broker)
end

@testset "ValueFederate test vectorD" begin
    broker = createBroker()
    vFed, fedinfo = createValueFederate()

    defaultValue = [0.0, 1.0, 2.0]
    testValue = [3.0, 4.0, 5.0]
    pubid = h.helicsFederateRegisterGlobalPublication(vFed, "pub1", h.HELICS_DATA_TYPE_VECTOR, "")
    subid = h.helicsFederateRegisterSubscription(vFed, "pub1", "")
    h.helicsInputSetDefaultVector(subid, defaultValue)

    h.helicsFederateEnterExecutingMode(vFed)

    h.helicsPublicationPublishVector(pubid, testValue)

    @test h.helicsInputGetVector(subid) == defaultValue

    grantedtime = h.helicsFederateRequestTime(vFed, 1.0)
    @test grantedtime == 0.01

    value = h.helicsInputGetVector(subid)

    if typeof(1) == Int32
        @test_broken value == testValue
    else
        @test value == testValue
    end

    destroyFederate(vFed, fedinfo)
    destroyBroker(broker)
end

@testset "ValueFederate test single transfer" begin
    broker = createBroker()
    vFed, fedinfo = createValueFederate()

    s = "n2"

    pubid = h.helicsFederateRegisterGlobalPublication(vFed, "pub1", h.HELICS_DATA_TYPE_STRING, "")
    subid = h.helicsFederateRegisterSubscription(vFed, "pub1", "")

    h.helicsFederateEnterExecutingMode(vFed)

    h.helicsPublicationPublishString(pubid, "string1")

    grantedtime = h.helicsFederateRequestTime(vFed, 1.0)
    @test grantedtime == 0.01

    s = h.helicsInputGetString(subid)

    @test s == "string1"

    time = h.helicsInputLastUpdateTime(subid)
    @test time == 0.01

    h.helicsPublicationPublishString(pubid, "string2")

    destroyFederate(vFed, fedinfo)
    destroyBroker(broker)

end

