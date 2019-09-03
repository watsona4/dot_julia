using ReinforcementLearningEnvironmentGym, Flux, ReinforcementLearning
# List all envs

listallenvs()

# CartPole example

env = GymEnv("CartPole-v0")
learner = DQN(Chain(Dense(4, 48, relu), Dense(48, 24, relu), Dense(24, 2)),
                  updateevery = 1, updatetargetevery = 100,
                  startlearningat = 50, minibatchsize = 32,
                  doubledqn = false, replaysize = 10^3, 
                  opttype = x -> ADAM(x, .0005))
x = RLSetup(learner, env, ConstantNumberEpisodes(10),
            callbacks = [Progress(), EvaluationPerEpisode(TimeSteps()),
                         Visualize(wait = 0)])
@info("Before learning.")
run!(x)
pop!(x.callbacks)
x.stoppingcriterion = ConstantNumberEpisodes(400)
@time learn!(x)
x.stoppingcriterion = ConstantNumberEpisodes(10)
push!(x.callbacks, Visualize(wait = 0))
@info("After learning.")
run!(x)
