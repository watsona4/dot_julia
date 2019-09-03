using ReinforcementLearningEnvironmentAtari, Flux, GR, JLD2,
ReinforcementLearning
const withgpu = false
const game = "alien"
const gpudevice = 1

"""
AtariPreprocessor(; gpu = false, croptosquare = false,
                    cropfromrow = 34, color = false,
                    outdim = (80, croptosquare ? 80 : 105))
"""
function AtariPreprocessor(; gpu = false, croptosquare = false,
                             cropfromrow = 34, color = false,
                             outdim = (80, croptosquare ? 80 : 105))
    chain = []
    if croptosquare
        push!(chain, ImageCrop(1:160, cropfromrow:cropfromrow + 159))
    end
    if !((croptosquare && outdim == (160, 160)) || outdim == (160, 210))
        push!(chain, ImageResizeNearestNeighbour(outdim))
    end
    if !color
        push!(chain, x -> reshape(x, (outdim[1], outdim[2], 1)))
    end
    if gpu
        push!(chain, togpu)
    end
    ImagePreprocessor(color ? (3, 160, 210) : (160, 210), chain)
end

if withgpu 
    using CUDAnative
    device!(gpudevice)
    using CuArrays
    const inputdtype = Float32
else
    const inputdtype = Float64
end
env = AtariEnv(game)
model = Chain(x -> x./inputdtype(255), Conv((8, 8), 4 => 16, relu, stride = (4, 4)), 
                         Conv((4, 4), 16 => 32, relu, stride = (2, 2)),
                         x -> reshape(x, :, size(x, 4)),
                         Dense(2592, 256, relu), 
                         Dense(256, length(env.actions)));
learner = DQN(model, opttype = x -> Flux.ADAM(x, .0001), 
              loss = huberloss, doubledqn = true,
              updatetargetevery = 2500, nsteps = 10,
              updateevery = 4, replaysize = 10^6, nmarkov = 4,
              startlearningat = 200000);
x = RLSetup(learner, 
            env,
            ConstantNumberSteps(2000),
            preprocessor = AtariPreprocessor(gpu=withgpu, outdim = (84, 84)),
            callbacks = [Visualize(wait = 0)])
GR.inline("mov")
beginprint("before$game.mov")
run!(x)
endprint()
learner.t = 0
x.callbacks = [Progress(5*10^2), EvaluationPerEpisode(TotalReward()),
               LinearDecreaseEpsilon(5 * 10^4, 10^6, 1, .01)];
x.stoppingcriterion = ConstantNumberSteps(4 * 10^6)
@info "start learning."
@time learn!(x)
@save "model$game.jld2" model
x.callbacks = [Visualize(wait = 0)]
x.stoppingcriterion = ConstantNumberSteps(2000)
beginprint("after$game.mov")
run!(x)
endprint()
