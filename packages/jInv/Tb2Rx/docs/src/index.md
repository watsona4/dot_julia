# jInv - A Flexible Flexible Julia Package for PDE Parameter Estimation

### Build status
[![Build Status](https://travis-ci.org/JuliaInv/jInv.jl.svg?branch=master)](https://travis-ci.org/JuliaInv/jInv.jl)
[![Coverage Status](https://coveralls.io/repos/github/JuliaInv/jInv.jl/badge.svg?branch=master)](https://coveralls.io/github/JuliaInv/jInv.jl?branch=master)
[![Build status](https://ci.appveyor.com/api/projects/status/0pxgtmm08b0w6wgh?svg=true)](https://ci.appveyor.com/project/JuliaInv/jinv-jl-81lel)


`jInv` is a flexible framework for solving PDE parameter estimation problems using Julia. Problems of this sort arise in various applications such as geophysical or medical imaging.  They are typically ill-posed and computationally challenging and developing robust and fast inversion algorithms is an active field of research. `jInv` aims at advancing this field by providing efficient and easy-to-extend core functions commonly used for solving real-world problems.

## Package Structure

The source code of `jInv` is divided into five submodules:

1. `Mesh` - regular and tensor meshes in 2D and 3D as well as differential operators.
2. `LinearSolvers` - interfaces to sparse and (if installed) direct linear solvers that can be used for solving the discretized PDEs.
3. `InverseSolve` - methods commonly used in inverse problems such as misfit functions, regularization and numerical optimization.
4. `ForwardShare` - methods for solving forward problems in parallel.
5. `Vis` - visualization and plotting (requires ![PyPlot.jl](https://github.com/JuliaPy/PyPlot.jl))
5. `Utils` - utility functions

## Basic Installation

To install `jInv` start a Julia session and type in the REPL (we currently support Julia versions 0.5.x):
```@repl
Pkg.clone("https://github.com/JuliaInv/jInv.jl","jInv")
Pkg.build("jInv")
```

The above commands clone the latest version of `jInv` and install the dependency [`KrylovMethods.jl`](https://github.com/lruthotto/KrylovMethods.jl), which provides iterative methods for solving (sparse) linear systems. Finally, some unit tests are run.

## Optional Packages for High-Performance

For better performance when solving parameter estimation problems with linear PDE constraints, `jInv` automatically looks for high-end linear algebra packages. Currently, the following packages are supported:

1. [`MUMPS.jl`](https://github.com/JuliaSparse/MUMPS.jl) - wrapper for MUMPS. Used as a direct PDE solver
2. [`ParSpMatVec.jl`](https://github.com/lruthotto/ParSpMatVec.jl) - shared memory implementation for sparse matrix vector products
3. [`PARDISO.jl`](https://github.com/JuliaSparse/PARDISO.jl) - wrapper for PARDISO solver
