
@testset "Utilities" begin

    empty = RegexDict{Number}()
    @test 3.2 == get(empty, "foo", 3.2)
    @test 3.2 == get(empty, :foo, 3.2)
    @test_throws BoundsError empty["foo"]
    @test_throws BoundsError empty[:foo]


    dict = RegexDict((r"^Hello", 52), (r"bar", 32), ("foo", 45), ("^baz", 66))

    @test 52 == get(dict, "Hello", -1)
    @test 52 == get(dict, "Hello World", -1)
    @test -1 == get(dict, "not Hello", -1)
    @test 52 == dict["Hello"]
    @test 52 == dict["Hello World"]

    @test 32 == get(dict, "bar", -1)
    @test 32 == get(dict, "qux bar", -1)
    @test 32 == get(dict, "bar qux", -1)
    @test 32 == dict["bar"]
    @test 32 == dict["qux bar"]
    @test 32 == dict["bar qux"]

    @test 45 == get(dict, "foo", -1)
    @test 45 == get(dict, "foo qux", -1)
    @test 45 == get(dict, "qux foo", -1)

    @test 66 == get(dict, "baz", -1)
    @test 66 == get(dict, "baz World", -1)
    @test -1 == get(dict, "not baz", -1)


    @test_throws BoundsError dict["asdf"]

end
