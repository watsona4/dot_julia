# GymSpaces.jl

[![Build Status](https://travis-ci.com/kraftpunk97/GymSpaces.jl.svg?branch=master)](https://travis-ci.com/kraftpunk97/GymSpaces.jl)

This is packages contains the constructs that can be used to define the action and observation spaces of Reinforcement Learning environments. Their design is similar to the spaces provided by OpenAI's [`gym`](https://github.com/openai/gym) package.

To add this package...`] add https://github.com/kraftpunk97/GymSpaces.jl`

## Exportable items

### Abstract Datatypes
* `AbstractSpace`

### Datatypes
* `Box`
* `TupleSpace`
* `Discrete`
* `MultiBinary`
* `MultiDiscrete`
* `DictSpace`

### Methods
* `sample()`
