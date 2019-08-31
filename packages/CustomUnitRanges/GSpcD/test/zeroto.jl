module ModZT

include(joinpath(dirname(@__FILE__), "..", "src", "ZeroTo.jl"))

end

using .ModZT: ZeroTo

r = ZeroTo(-5)
@test isempty(r)
@test length(r) == 0
@test size(r) == (0,)
r = ZeroTo(3)
@test !isempty(r)
@test length(r) == 4
@test size(r) == (4,)
@test step(r) == 1
@test first(r) == 0
@test last(r) == 3
@test minimum(r) == 0
@test maximum(r) == 3
@test r[1] == 0
@test r[2] == 1
@test r[3] == 2
@test r[4] == 3
@test_throws BoundsError r[5]
@test_throws BoundsError r[-1]
@test r .+ 1 === 1:4
@test 2*r === 0:2:6
k = -1
for i in r
    @test i == (global k += 1)
end
@test intersect(r, ZeroRange(2)) == ZeroRange(2)  # deprecated
@test intersect(r, -1:5) == 0:3
@test intersect(r, 2:5) == 2:3
@test string(r) == "ZeroTo(3)"
