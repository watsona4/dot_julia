# Hanabi.jl

This package provides a Julia wrapper for the game [deepmind/hanabi-learning-environment](https://github.com/deepmind/hanabi-learning-environment) with [Clang.jl](https://github.com/JuliaInterop/Clang.jl)

## Install

```julia
pkg> add Hanabi
```

## Usage

All the APIs should be the same with those listed [here](https://github.com/findmyway/hanabi-learning-environment/blob/master/pyhanabi.h) with renaming.

- `CamelFunctionName` -> `camel_function_name`
- `PyStructName` -> `StructName`

## Example

```julia
game = Ref{HanabiGame}()
new_default_game(game)
observation = Ref{HanabiObservation}()
state = Ref{HanabiState}()
new_state(game, state)
observation = Ref{HanabiObservation}()
new_observation(state, 0, observation)
unsafe_string(obs_to_string(observation))
# Life tokens: 3
# Info tokens: 8
# Fireworks: R0 Y0 G0 W0 B0
# Hands:
# -----
# Deck size: 50
# Discards:
```

You may also check some high level APIs in [ReinforcementLearningEnvironments.jl](https://github.com/JuliaReinforcementLearning/ReinforcementLearningEnvironments.jl)

## Play Game Interactively

Check out [src/service.jl](https://github.com/JuliaReinforcementLearning/Hanabi.jl/blob/master/src/service.jl) to see how to play Hanabi interactively.

![play_interactively.png](https://raw.githubusercontent.com/JuliaReinforcementLearning/Hanabi.jl/master/docs/src/assets/play_interactively.png)