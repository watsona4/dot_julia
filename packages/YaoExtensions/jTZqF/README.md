# YaoExtensions

[![Build Status](https://travis-ci.com/QuantumBFS/YaoExtensions.jl.svg?branch=master)](https://travis-ci.com/QuantumBFS/YaoExtensions.jl)
[![Codecov](https://codecov.io/gh/QuantumBFS/YaoExtensions.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/QuantumBFS/YaoExtensions.jl)

Extensions for Yao.

## List of features
#### Easy constructions
* variational_circuit(n): construct a random parametrized circuit.
* heisenberg(n): construct a heisenberg hamiltonian.

#### Block extensions
* Bag: a trivil container block that gives the flexibility to change the sub-block, as well as masking. Mainly used for structure learning.
* ConditionBlock: conditional control the excusion of two block.
* Sequence: similar to chain block, but more general, one can put anything inside.
* RotBasis: basis rotor, make measurements on different basis easier.

* Mod: modulo operation block.
* QFTBlock: instead of running QFT circuit faithfully, simulate it with classical `fft` (thus much faster).

#### Utlities
* timer, timing a circuit excution time (experimental feature!),
* gatecount, count the number of gates,
