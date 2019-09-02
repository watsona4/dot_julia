[![Build Status](https://travis-ci.org/JuliaInv/ParSpMatVec.jl.svg?branch=master)](https://travis-ci.org/JuliaInv/ParSpMatVec.jl)
[![Coverage Status](https://coveralls.io/repos/github/JuliaInv/ParSpMatVec.jl/badge.svg?branch=master)](https://coveralls.io/github/JuliaInv/ParSpMatVec.jl?branch=master)
[![Build status](https://ci.appveyor.com/api/projects/status/rhce77smh99fag93?svg=true)](https://ci.appveyor.com/project/lruthotto/parspmatvec-jl-fmwu5)



# ParSpMatVec.jl
Shared-memory implementation of parallel sparse matrix vector product in Julia. We thank Roman Shekhtman (UBC) for providing the Fortran code. 

## Installation
To install on a unix machine, follow these steps
```
Pkg.add("ParSpMatVec")
Pkg.test("ParSpMatVec")
```
The first line downloads the package and (on unix) compiles the Fortran codes (`gfortran` is used by default). Currently there is no automatic build procedure for Windows. Pull requests are welcome. 

The second line tests the package.

## Usage
Currently, we do not overload the matrix vector product in `Base` (this might be added in the future). Let `A` be a sparse matrix, `alpha` and `beta` floating point numbers and `x` and `y` be real- or complex values vectors of appropriate size. Then, the following commands are equivalent 
```
nproc = 4; # choose number of OMP threads
yt = copy(y)
y = beta*y + alpha * A*x
ParSpMatVec.A_mul_B!( alpha, A, x, beta, yt, nproc)
```
Similarly, for the transpose matrix-vector product:
```
yt= copy(y)
y = beta*y + alpha * A'*x
ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, yt, nproc)
```

The last input, `nproc`, determines how many OpenMP threads are used. Note that, due to the compressed column storage, products with the adjoint of `A` are expected to scale better. 

## ToDo

A few things to do:
- [ ] automatic build on Windows

