# jInv Examples

This folder contains examples, tutorials and drivers that can be used to reproduce experiments in our publications. 

## Requirements 

The tutorials and inversion examples are provided as IJulia notebooks and can be viewed in the browser (just click on them). However, we highly recommend running (and modyfying them) on your own. You can do this for free and without installing julia yourself using [juliabox](http:://juliabox.org) or you can run it locally after installing [IJulia](https://github.com/JuliaLang/IJulia.jl). Please refer to the latter site for more general info about this format.

## Tutorials

Tutorials aim at explaining certain features of jInv providing use some simple cases. We use them for teaching but also as a starting point for exploring new codes. Currently, there are the following tutorials

1. [`tutorialMeshes.ipynb`](https://github.com/JuliaInv/jInv.jl/blob/master/examples/tutorialMeshes.ipynb) - gives an overview about mesh types available in `jInv` and related packages.
1. [`tutorialParallelization.ipynb`](https://github.com/JuliaInv/jInv.jl/blob/master/examples/tutorialParallelization.ipynb) - shows how to easily run simulations in parallel using the tools provided in `jInv.ForwardShare`
1. [`tutorialBuildYourOwn.ipynb`](https://github.com/JuliaInv/jInv.jl/blob/master/examples/tutorialBuildYourOwn.ipynb) - case study on how to extend `jInv` for your forward problem. Here, we code a 2D Full Waveform Inversion code. 

## Inversion Examples

For educational purposes we have created some examples and inversion tests. These are typically unrealistically small-scale but show how `jInv` can be used and set up to solve also bigger problems. The examples are also a great starting point for experiments with different parameters, solvers, etc.  Currently, there are the following examples:

1. [`exDCResistivity.ipynb`](https://github.com/JuliaInv/jInv.jl/blob/master/examples/exDCResistivity.ipynb) - 3D example for parameter estimation for the Poisson equation. The example is motivated by the geophysical imaging technique of DC Resistivity.
1. [`exEikonal.ipynb`](https://github.com/JuliaInv/jInv.jl/blob/master/examples/exEikonal.ipynb) - 3D example for parameter estimation for the nonlinear Eikonal equation. Example is motivated by travel time tomography, which is a geophysical imaging technique.
1. [`exJointEikonalDC.ipynb`](https://github.com/JuliaInv/jInv.jl/blob/master/examples/exJointEikonalDC.ipynb) - example of a multiphysics inversion. The example combines both previous datasets and aims at estimating a single model that explains both measurements.  

## Drivers

The folder `2016-RTH-SISC` contains drivers that can be used to re-produce the results in the [paper](http://arxiv.org/abs/1606.07399).  
