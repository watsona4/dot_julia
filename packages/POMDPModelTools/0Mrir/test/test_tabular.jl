function test_transition(pb1::Union{MDP, POMDP}, pb2::Union{SparseTabularMDP, SparseTabularPOMDP})
    for s in states(pb1)
        for a in actions(pb1)
            td1 = transition(pb1, s, a)
            si = stateindex(pb1, s)
            ai = actionindex(pb1, a)
            td2 = transition(pb2, si, ai)
            for (sp, p) in weighted_iterator(td1)
                spi = stateindex(pb1, sp)
                @test pdf(td2, spi) == p
            end
        end
    end
end

function test_reward(pb1::Union{MDP, POMDP}, pb2::Union{SparseTabularMDP, SparseTabularPOMDP})
    for s in states(pb1)
        for a in actions(pb1)
            si = stateindex(pb1, s)
            ai = actionindex(pb1, a)
            @test reward(pb1, s, a) == reward(pb2, si, ai)
        end
    end
end

function test_observation(pb1::POMDP, pb2::SparseTabularPOMDP)
    for s in states(pb1)
        for a in actions(pb1)
            od1 = observation(pb1, a, s)
            si = stateindex(pb1, s)
            ai = actionindex(pb1, a)
            od2 = observation(pb2, ai, si)
            for (o, p) in weighted_iterator(od1)
                oi = obsindex(pb1, o)
                @test pdf(od2, oi) == p
            end
        end
    end
end


## MDP 

mdp = RandomMDP(100, 4, 0.95)

@show_requirements SparseTabularMDP(mdp)

smdp = SparseTabularMDP(mdp)

smdp2 = SparseTabularMDP(smdp)

@test smdp2.T == smdp.T
@test smdp2.R == smdp.R
@test smdp2.discount == smdp.discount

smdp3 = SparseTabularMDP(smdp, reward = zeros(n_states(mdp), n_actions(mdp)))
@test smdp3.T == smdp.T
@test smdp3.R != smdp.R
smdp3 = SparseTabularMDP(smdp, transition = [sparse(1:n_states(mdp), 1:n_states(mdp), 1.0) for a in 1:n_actions(mdp)])
@test smdp3.T != smdp.T
@test smdp3.R == smdp.R
smdp3 = SparseTabularMDP(smdp, discount = 0.5)
@test smdp3.discount != smdp.discount

@test size(transition_matrix(smdp, 1)) == (n_states(smdp), n_states(smdp))
@test length(reward_vector(smdp, 1)) == n_states(smdp)

gw = SimpleGridWorld()
sparsegw = SparseTabularMDP(gw)
@test isterminal(sparsegw, 101)
@inferred actions(sparsegw, 101)
@test actions(sparsegw, 101) == collect(actions(sparsegw))

## POMDP 

pomdp = TigerPOMDP()

@show_requirements SparseTabularPOMDP(pomdp)

spomdp = SparseTabularPOMDP(pomdp)

spomdp2 = SparseTabularPOMDP(spomdp)

@test spomdp2.T == spomdp.T
@test spomdp2.R == spomdp.R
@test spomdp2.O == spomdp.O
@test spomdp2.discount == spomdp.discount

spomdp3 = SparseTabularPOMDP(spomdp, reward = zeros(n_states(mdp), n_actions(mdp)))
@test spomdp3.T == spomdp.T
@test spomdp3.R != spomdp.R
spomdp3 = SparseTabularPOMDP(spomdp, transition = [sparse(1:n_states(mdp), 1:n_states(mdp), 1.0) for a in 1:n_actions(mdp)])
@test spomdp3.T != spomdp.T
@test spomdp3.R == spomdp.R
spomdp3 = SparseTabularPOMDP(spomdp, discount = 0.5)
@test spomdp3.discount != spomdp.discount
@test size(observation_matrix(spomdp, 1)) == (n_states(spomdp), n_observations(spomdp))
@test observation_matrices(spomdp) == spomdp2.O
@test transition_matrices(spomdp) == spomdp2.T
@test reward_matrix(spomdp) == spomdp2.R

## Tests 

@test n_states(pomdp) == n_states(spomdp)
@test n_actions(pomdp) == n_actions(spomdp)
@test n_observations(pomdp) == n_observations(spomdp)
@test length(states(spomdp)) == n_states(spomdp)
@test length(actions(spomdp)) == n_actions(spomdp)
@test length(observations(spomdp)) == n_observations(spomdp)
@test statetype(spomdp) == Int64
@test actiontype(spomdp) == Int64
@test obstype(spomdp) == Int64
@test discount(spomdp) == discount(pomdp)
@test isempty(spomdp.terminal_states)

test_transition(mdp, smdp)
test_transition(pomdp, spomdp)
test_reward(pomdp, spomdp)
test_observation(pomdp, spomdp)
