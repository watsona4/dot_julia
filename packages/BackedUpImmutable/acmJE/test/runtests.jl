using Test
using BackedUpImmutable

d = StaticDict(["a" => 7, "d" => 2])
@test d["d"] == 2

d2 = StaticDict("a" => 7, "d" => 2, "e" => 4)
@test d2["e"] != 3

function testBackedUpImmutableDict()
    fibr = BackedUpImmutableDict{String,Int64}(["a" => 0, "b" => 1, "c" => 1, "d" => 2,
        "e" => 3, "f" => 5, "g" => 8, "h" => 13, "i" => 21, "j" => 34, "extra" => -1])

    x = fibr["extra"]
    @test x == -1
    fibr["extra"] = 0
    y = fibr["extra"]
    @test y == 0
    restore!(fibr, "extra")
    z = fibr["extra"]
    @test z == -1
    
    @test_throws String begin fibr["k"] = 55 end
    
    # test alternative constructor
    fibr = BackedUpImmutableDict{String, Int64}("a" => 0, "b" => 1, "c" => 1, "d" => 2,
        "e" => 3, "f" => 5, "g" => 8, "h" => 13, "i" => 21, "j" => 34, "extra" => -1)
    
    fibr["a"] = 9
    fibr["b"] = 7
    
    # test restore all to default
    restoreall!(fibr)
    
    @test fibr["a"] == 0
end

testBackedUpImmutableDict()
