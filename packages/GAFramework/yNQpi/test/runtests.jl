using Test
using LinearAlgebra

using GAFramework
using GAFramework.CoordinateGA

function test1()
    model = CoordinateModel(x -> x[1]==0.0 ? 0.0 : x[1] * sin(1/x[1]), [-1.0], [1.0])
    state = GAState(model, ngen=50, npop=300, elite_fraction=0.01,
                    mutation_params=Dict(:rate=>0.1),
                    print_fitness_iter=10)    
    best = ga(state)
    x = best.value[1]
    y = best.objvalue
    println("$best $x $y")
    abs(abs(x) - 0.223126) < 0.1 && abs(y - (-0.217219)) < 0.1
end

function test2()
    model = CoordinateModel(x -> any(z -> z==0.0, x) ? 0.0 : dot(x, sin.(1 ./x)),
                            -ones(Float64,15), ones(Float64,15))
    # do simulated annealing when mutating
    state = GAState(model, ngen=500, npop=300, elite_fraction=0.01,
                    mutation_params=Dict(:rate=>0.1,:sa_rate=>0.1,:k=>1,
                                         :lambda=>1/1000,:maxiter=>1000), print_fitness_iter=50)
    best = ga(state)
    x = best.value
    y = best.objvalue
    println("$best $x $y")
    all(abs.(abs.(x) .- 0.222549) .< 0.1) && abs(y - (-0.21723*15)) < 0.1
end

function test3()
    model = CoordinateModel(x -> 10length(x) + sum(z -> z^2 - 10cos(2pi*z), x),
                            -5.12 .* ones(15), 5.12 .* ones(15))
    state = GAState(model, ngen=500, npop=300, elite_fraction=0.01,
                    mutation_params=Dict(:rate=>0.1,:sa_rate=>0.1,:k=>1,
                                         :lambda=>1/1000,:maxiter=>1000), print_fitness_iter=50)    
    best = ga(state)
    x = best.value
    y = best.objvalue
    println("$best $x $y")
    all(abs.(x) .< 0.1) && abs(y) < 0.1
end

@test test1()
@test test2()
@test test3()
