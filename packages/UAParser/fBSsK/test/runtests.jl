using UAParser, YAML, Test

# a helper macro for creating tests
macro testparseval(obj::Symbol, valname::String, outputname::Symbol)
    valsymb = Symbol(valname)
    esc(quote
        if $obj[$valname] == nothing
            ismissing($outputname.$valsymb)
        else
            $obj[$valname] == $outputname.$valsymb
        end
    end)
end

#Since parser is known not to be 100% compatible with source Python parser (see README), testing accuracy
#Accuracy stats derived from test files for v0.6 of package
#Any future changes to parsing code will be evaluated against this standard

@testset "parse_device" begin
    #Test 1: Validation of parsedevice
    test_device = YAML.load(open(joinpath(dirname(@__FILE__), "data", "test_device.yaml")))

    pass = 0
    fail = 0
    for test_case in test_device["test_cases"]
        test_case["family"] == parsedevice(test_case["user_agent_string"]).family ? pass += 1 : fail += 1
    end

    @test pass/(pass + fail) >= .945

end

@testset "parse_os" begin
    #Test 2: Validation of parseos
    test_os = YAML.load(open(joinpath(dirname(@__FILE__), "data", "test_os.yaml")))

    pass = 0
    fail = 0

    for value in test_os["test_cases"]
        os = parseos(value["user_agent_string"])
        value["family"] == os.family ? pass += 1 : fail += 1
        (@testparseval value "major" os) ? pass += 1 : fail += 1
        (@testparseval value "minor" os) ? pass += 1 : fail += 1
        (@testparseval value "patch_minor" os) ? pass += 1 : fail += 1
    end

    @test pass/(pass + fail) >= .992

end

@testset "parse_ua" begin
    #Test 4: Validation of parseuseragent
    test_ua = YAML.load(open(joinpath(dirname(@__FILE__), "data", "test_ua.yaml")))

    pass = 0
    fail = 0

    for value in test_ua["test_cases"]
        ua = parseuseragent(value["user_agent_string"])
        value["family"] == ua.family ? pass += 1 : fail += 1
        (@testparseval value "major" ua) ? pass += 1 : fail += 1
        (@testparseval value "minor" ua) ? pass += 1 : fail += 1
        (@testparseval value "patch" ua) ? pass += 1 : fail += 1
    end

    @test pass/(pass + fail) >= .992

end
