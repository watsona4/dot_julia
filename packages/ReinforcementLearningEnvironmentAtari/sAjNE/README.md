# ReinforcementLearningEnvironmentAtari

[![Build Status](https://travis-ci.com/JuliaReinforcementLearning/ReinforcementLearningEnvironmentAtari.jl.svg?branch=master)](https://travis-ci.com/JuliaReinforcementLearning/ReinforcementLearningEnvironmentAtari.jl)

[![Coverage Status](https://coveralls.io/repos/JuliaReinforcementLearning/ReinforcementLearningEnvironmentAtari.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaReinforcementLearning/ReinforcementLearningEnvironmentAtari.jl?branch=master)

[![codecov.io](http://codecov.io/github/JuliaReinforcementLearning/ReinforcementLearningEnvironmentAtari.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaReinforcementLearning/ReinforcementLearningEnvironmentAtari.jl?branch=master)

Makes the [ArcadeLearningEnvironment](https://github.com/JuliaReinforcementLearning/ArcadeLearningEnvironment.jl) available as an environment for the [Julia Reinforcement Learning package](https://github.com/JuliaReinforcementLearning/ReinforcementLearning.jl).

## Usage

```julia
using ReinforcementLearningEnvironmentAtari

?AtariEnv
environment = AtariEnv("breakout")
preprocessor = AtariPreprocessor()
```

See also [examples](examples).


