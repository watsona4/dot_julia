mutable struct VoidUpdater <: Updater end
POMDPs.update(::VoidUpdater, ::B, ::Any, ::Any, b=nothing) where B = nothing

mutable struct RandomPolicy{P <: Union{MDP, POMDP}} <: Policy
    rng::AbstractRNG
    problem::P
end
RandomPolicy(problem::Union{POMDP,MDP};
            rng=Random.GLOBAL_RNG) = RandomPolicy(rng, problem)

function POMDPs.action(policy::RandomPolicy, s)
    return rand(policy.rng, actions(policy.problem, s))
end

mutable struct RandomSolver <: Solver
    rng::AbstractRNG
end

RandomSolver(;rng=Base.GLOBAL_RNG) = RandomSolver(rng)
POMDPs.solve(solver::RandomSolver, problem::P) where {P<:Union{POMDP,MDP}} = RandomPolicy(solver.rng, problem)

let
    rng = MersenneTwister(7)

    mdp = LegacyGridWorld()
    s = initialstate(mdp, rng)
    a = rand(rng, actions(mdp))
    @inferred generate_sri(mdp, s, a, rng)

    pomdp = TigerPOMDP()
    s = initialstate(pomdp, rng)
    a = rand(rng, actions(pomdp))
    @inferred generate_sori(pomdp, s, a, rng)

    up = VoidUpdater()
    policy = RandomPolicy(rng, pomdp)
    @inferred action_info(policy, s)

    solver = RandomSolver(rng=rng)
    policy, sinfo = solve_info(solver, pomdp)
    @test isa(sinfo, Nothing)

    d = initialstate_distribution(pomdp)
    b = initialize_belief(up, d)
    a = action(policy, b)
    sp, o = generate_so(pomdp, rand(rng, d), a, rng)
    @inferred update_info(up, b, a, o)
end
