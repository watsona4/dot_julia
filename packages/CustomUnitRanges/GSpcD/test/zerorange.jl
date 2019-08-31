module ModZ

using CustomUnitRanges: filename_for_zerorange
include(filename_for_zerorange)

end

using .ModZ: ZeroRange

@testset "ZeroRange" begin
    r = ZeroRange(-5)
    @test isempty(r)
    @test length(r) == 0
    @test size(r) == (0,)
    r = ZeroRange(3)
    @test !isempty(r)
    @test length(r) == 3
    @test size(r) == (3,)
    @test step(r) == 1
    @test first(r) == 0
    @test last(r) == 2
    @test minimum(r) == 0
    @test maximum(r) == 2
    @test r[1] == 0
    @test r[2] == 1
    @test r[3] == 2
    @test_throws BoundsError r[4]
    @test_throws BoundsError r[-1]
    @test r[1:3] === 0:2
    @test_throws BoundsError r[r]
    @test r .+ 1 === 1:3
    @test 2*r === 0:2:4
    k = -1
    for i in r
        j = (k+=1)
        @test i == j
    end
    @test k == length(r)-1
    @test intersect(r, ZeroRange(2)) === intersect(ZeroRange(2), r) === ZeroRange(2)
    @test intersect(r, -1:5) === intersect(-1:5, r) === 0:2
    @test intersect(r, 2:5) === intersect(2:5, r) === 2:2
    @test string(r) == "ZeroRange(3)"

    r = ZeroRange(5)
    @test checkindex(Bool, r, 4)
    @test !checkindex(Bool, r, 5)
    @test checkindex(Bool, r, :)
    @test checkindex(Bool, r, 1:4)
    @test !checkindex(Bool, r, 1:5)
    @test !checkindex(Bool, r, trues(4))
    @test !checkindex(Bool, r, trues(5))
    @test convert(UnitRange, r) == 0:4
    @test convert(StepRange, r) == 0:1:4
    @test !in(-1, r)
    @test in(0, r)
    @test in(4, r)
    @test !in(5, r)
    @test issorted(r)
    @test maximum(r) == 4
    @test minimum(r) == 0
    @test sortperm(r) == 1:5
    @test r == 0:4
    @test r+r == 0:2:8
    @test (5:2:13)-r == 5:9
    @test -r == 0:-1:-4
    @test reverse(r) == 4:-1:0
    @test r/2 == 0:0.5:2

    r = ZeroRange{Int16}(5)
    @test length(r) === 5
    @test iterate(r) == (0,0)
    k = -1
    for i in r
        j = (k+=1)
        @test i == j
    end
    @test k == length(r)-1
    x, y = promote(ZeroRange(5), ZeroRange{Int16}(8))
    @test x === ZeroRange(5)
    @test y === ZeroRange(8)
    x, y = promote(ZeroRange(5), 0:7)
    @test x === 0:4
    @test y === 0:7
    @test convert(ZeroRange{Int16}, ZeroRange(5)) === ZeroRange{Int16}(5)
    @test convert(ZeroRange{Int}, ZeroRange(5)) === ZeroRange(5)
    @test convert(UnitRange, ZeroRange(4)) === 0:3
    r = ZeroRange(Int128(10))
    @test length(r) === Int128(10)
end
