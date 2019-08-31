using Trajectories
using Tables
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

t = 0:10
x = rand(11)
X = trajectory(t, x)

@test keys(X) === t
@test values(X) === x
@test eltype(X) === eltype(x)
@test eltype(X) === eltype(x)

@test Pair(X) === Pair(t, x)
@test [pair for pair in pairs(X)] == map(t->Pair(t...), collect(zip(t, x)))

@test trajectory(zip(t, x)) == X

@test get(X, 5) == x[6]
@test_throws ErrorException get(X, 5.5)
@test_throws ErrorException get(X, 11)

#@test [y for y in X] == [t, x]

for i in 5:10
    @test Trajectories._find(5:10, i) == i - 4
end
@test_throws ErrorException Trajectories._find(5:10, 4)
@test_throws ErrorException Trajectories._find(5:10, 11)

@test interpolate(Linear(), X, 0) == interpolate(Linear(), X, -0.5) == x[1]
@test interpolate(Linear(), X, 10) == interpolate(Linear(), X, 10.5) == x[end]
@test interpolate(Linear(), X, 1/3) ≈ (2x[1] + x[2])/3

@test interpolate(Left(), X, 0) == interpolate(Left(), X, 0.5) == x[1]
@test interpolate(Left(), X, 10) == interpolate(Linear(), X, 10.5) == x[end]
@test_throws BoundsError interpolate(Left(), X, -1/3)

@test piecewise(Trajectory([1,2,3], [1,2])) == ([1, 2, 2, 3], [1, 1, 2, 2])

@test searchsorted(sort([1,missing, NaN, missing]), NaN) == 2:2
@test searchsorted(sort([1,missing, NaN, missing]), missing) == 3:4

@test Tables.schema(Tables.columns(trajectory(1:10, rand(10)))) == Tables.Schema{(:t, :x),Tuple{Int,Float64}}()

Y = map(collect, X)
push!(Y, 12=>0.0)
@test keys(Y) == [t; 12]
@test values(Y) == [x; 0.0]

Y = copy(X)
Y = vcat(Y, Y)
@test collect(pairs(Y))[end÷2+1:end] == collect(pairs(X))
