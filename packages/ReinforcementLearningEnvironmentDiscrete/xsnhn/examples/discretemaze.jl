using ReinforcementLearningEnvironmentDiscrete, ReinforcementLearning

env = DiscreteMaze(ngoals = 5)
rlsetup = RLSetup(SmallBackups(na = 4, ns = env.mdp.observationspace.n, γ = .99), 
                  env, ConstantNumberSteps(200), 
                  callbacks = [Visualize()])
@info("Before learning.") 
run!(rlsetup)
rlsetup.callbacks = []
rlsetup.stoppingcriterion = ConstantNumberSteps(10^6)
learn!(rlsetup)
@info("After learning.")
rlsetup.callbacks = [Visualize()]
rlsetup.stoppingcriterion = ConstantNumberSteps(100)
run!(rlsetup)
