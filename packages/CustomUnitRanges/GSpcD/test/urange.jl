module ModU

using CustomUnitRanges: filename_for_urange
include(filename_for_urange)

end

using .ModU: URange

@testset "URange" begin
    @testset "Bool" begin
        r = URange(false, true)
        @test !isempty(r)
        @test length(r) == 2
        @test r[1] == false
        @test r[2] == true
        r = URange(true, false)
        @test isempty(r)
        @test length(r) == 0
        r = URange(false, false)
        @test !isempty(r)
        @test length(r) == 1
        @test r[1] == false
        r = URange(true, true)
        @test !isempty(r)
        @test length(r) == 1
        @test r[1] == true
    end

    @testset "Int/Float" begin
        for T in (Int, Float64)
            r = URange(-T(3),-T(5))
            @test isempty(r)
            @test length(r) == 0
            @test size(r) == (0,)
            r = URange(-T(5),T(3))
            rref = -5:3
            @test !isempty(r)
            @test length(r) == length(rref)
            @test size(r) == size(rref)
            @test step(r) == 1
            @test first(r) == -5
            @test last(r) == 3
            @test minimum(r) == -5
            @test maximum(r) == 3
            @test r[1] == -5
            @test r[2] == -4
            @test r[8] == 2
            @test r[9] == 3
            @test_throws BoundsError r[10]
            @test_throws BoundsError r[0]
            @test r[2:8] === URange(T(-4), T(2))
            @test r .+ 1 === -T(4):T(4)
            @test 2*r === -T(10):T(2):T(6)
            k = -6
            for i in r
                @test i == (k+=1)
            end
            if T<:Integer
                @test intersect(r, URange(-5,2)) === URange(-5,2)
                @test intersect(r, -1:5) === -1:3
                @test intersect(r, 2:5) === 2:3
                @test intersect(r, 2) === intersect(2, r) === 2:2
                @test intersect(r, 7) === intersect(7, r) === 7:6
            else
                @test intersect(r, URange(-5,2)) == collect(URange(-5,2))
                @test intersect(r, -1:5) == collect(-1:3)
                @test intersect(r, 2:5) == collect(2:3)
                @test intersect(r, 2) == intersect(2, r) == [2.0]
                @test intersect(r, 7) == intersect(7, r) == Float64[]
            end
            @test findall(in(0:5), r) == (T<:Integer ? (6:9) : collect(6:9))
            @test findall(in(URange(0,5)), r) == (T<:Integer ? (6:9) : collect(6:9))
            x, y = promote(r, 1:3)
            @test convert(URange{Int16}, 0:3) === URange{Int16}(0,3)
            @test convert(URange{Int16}, Base.OneTo(5)) === URange{Int16}(1,5)
            @test convert(URange{Int16}, r) === URange{Int16}(-5, 3)
            @test x === r
            @test y === URange(T(1),T(3))
            @test string(r) == "URange(-$(T(5)),$(T(3)))"
        end
    end

    @testset "smallint" begin
        r = URange{Int16}(-5, 3)
        @test eltype(r) == Int16
        k = -6
        for i in r
            @test i == (k+=1)
        end
    end

    @testset "promotion" begin
        r = URange{Int16}(-5, 3)
        ri = URange(2,20)
        x, y = promote(r, ri)
        @test isa(x, URange{Int})
        @test isa(y, URange{Int})
        x, y = promote(r, 2:20)
        @test isa(x, URange{Int})
        @test isa(y, URange{Int})
        x, y = promote(r, Base.OneTo(3))
        @test isa(x, URange{Int})
        @test isa(y, URange{Int})
    end
end
