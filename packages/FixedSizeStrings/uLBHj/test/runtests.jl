using Test
using FixedSizeStrings

let e = FixedSizeString{0}("")
    @test e == ""
    @test length(e) == 0
    @test convert(String, e) === ""
    @test isa(convert(String, e), String)
    @test convert(FixedSizeString{0}, "") == e
end

@test_throws ArgumentError FixedSizeString{3}("ab")

let s = FixedSizeString{3}("xyZ")
    @test s == "xyZ"
    @test isless(s, "yyZ")
    @test isless("xyY", s)
    @test length(s) == sizeof(s) == 3
    @test collect(s) == ['x', 'y', 'Z']
    @test convert(String, s) == "xyZ"
    @test convert(FixedSizeString{3}, "xyZ") == s
    @test isa(convert(FixedSizeString{3}, "xyZ"), FixedSizeString)
end

@test_throws InexactError FixedSizeString{2}("αb")

let b = IOBuffer()
    write(b, "a tEst str1ng")
    seekstart(b)
    @test read(b, FixedSizeString{4}) == "a tE"
    @test read(b, FixedSizeString{2}) == "st"
    b = IOBuffer()
    data = "\0Te\$t\0_"
    write(b, FixedSizeString(data))
    @test String(take!(b)) == data
end
