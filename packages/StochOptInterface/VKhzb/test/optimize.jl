using TimerOutputs

struct MockStochasticProgram <: SOI.AbstractStochasticProgram end
struct MockTransition <: SOI.AbstractTransition end
struct MockSolution <: SOI.AbstractSolution end
SOI.getstatus(::MockSolution) = :Optimal

struct MockAlgorithm <: SOI.AbstractAlgorithm
    npaths::Int
end

function SOI.backward_pass!(sp::MockStochasticProgram, algo::MockAlgorithm,
                            to::TimerOutput, result::SOI.Result, verbose)
end
function SOI.simulate_scenario(sp::MockStochasticProgram, algo::MockAlgorithm, scenario::Vector{<:SOI.AbstractTransition},
                               to::TimerOutput, verbose)
    SOI.Path(scenario, [MockSolution() for i in 0:length(scenario)])
end
function SOI.sample_scenarios(sp::MockStochasticProgram, algo::MockAlgorithm, to::TimerOutput,
                              verbose)
    [fill(MockTransition(), 2) for i in 1:algo.npaths]
end
function SOI.compute_bounds(algo::MockAlgorithm, paths::SOI.Paths, verbose)
    0.0, 0.0
end

@testset "Mock tests" begin
    sp = MockStochasticProgram()
    algo = MockAlgorithm(2)
    info = SOI.optimize!(sp, algo, SOI.IterLimit(100), 3)
    @test SOI.niterations(info) == 100
    @test info.results[end].lowerbound == 0.0
end
