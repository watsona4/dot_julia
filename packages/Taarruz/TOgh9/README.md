# Taarruz
[![](https://travis-ci.org/ilkerkesen/Taarruz.jl.svg?branch=master)](https://travis-ci.org/ilkerkesen/Taarruz.jl)

Adversarial Attack Tool for [Knet](https://github.com/denizyuret/Knet.jl).

## Implemented Attacks
- ```FGSM```: Fast Gradient Sign Method ([paper](https://arxiv.org/abs/1412.6572)).

Too see documentation, type ```@doc method_name``` in Julia REPL (e.g. ```@doc FGSM```).

## Example Notebooks
- [lenet-fgsm](examples/lenet-fgsm.ipynb): FGSM attack to Lenet trained on MNIST dataset.
