# ReinforcementLearningEnvironmentClassicControl

[![Build Status](https://travis-ci.com/JuliaReinforcementLearning/ReinforcementLearningEnvironmentClassicControl.jl.svg?branch=master)](https://travis-ci.com/JuliaReinforcementLearning/ReinforcementLearningEnvironmentClassicControl.jl)

[![Coverage Status](https://coveralls.io/repos/JuliaReinforcementLearning/ReinforcementLearningEnvironmentClassicControl.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaReinforcementLearning/ReinforcementLearningEnvironmentClassicControl.jl?branch=master)

[![codecov.io](http://codecov.io/github/JuliaReinforcementLearning/ReinforcementLearningEnvironmentClassicControl.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaReinforcementLearning/ReinforcementLearningEnvironmentClassicControl.jl?branch=master)


Provides the classic CartPole MountainCar and Pendulum environment for the [Julia Reinforcement Learning package](https://github.com/JuliaReinforcementLearning/ReinforcementLearning.jl).

## Usage

```julia
using ReinforcementLearningEnvironmentClassicControl

environment = MountainCar()
environment = CartPole()
environment = Pendulum()
```

See also [examples](examples).


