module ReinforcementLearningEnvironmentClassicControl
using GR
using ReinforcementLearningBase
import ReinforcementLearningBase: interact!, getstate, reset!, actionspace, plotenv

include("cartpole.jl")
include("mountaincar.jl")
include("pendulum.jl")

export CartPole, MountainCar, Pendulum

end # module
