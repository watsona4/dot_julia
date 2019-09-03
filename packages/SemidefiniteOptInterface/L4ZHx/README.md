# SemidefiniteOptInterface (SDOI)

| **Build Status** |
|:----------------:|
| [![Build Status][build-img]][build-url] [![Build Status][winbuild-img]][winbuild-url] |
| [![Coveralls branch][coveralls-img]][coveralls-url] [![Codecov branch][codecov-img]][codecov-url] |

This package make it easy to implement the API of [MathOptInterface](https://github.com/JuliaOpt/MathOptInterface.jl) for semidefinite programming solver like [CSDP](https://github.com/JuliaOpt/CSDP.jl), [SDPA](https://github.com/blegat/SDPA.jl), [DSDP](https://github.com/joehuchette/DSDP.jl) and [SDPLR](https://github.com/blegat/SDPLR.jl) that require the problem to be described in the following form:
```
max ⟨C, X⟩            min ⟨b, y⟩
    ⟨A_i, X⟩ = b_i        ∑ A_i y_i ⪰ C
          X  ⪰ 0
```
The well known [SDPA file format](http://plato.asu.edu/ftp/sdpa_format.txt) uses this form but this package communicates to the solver directly and the solver wrappers use the C/C++ API without using a file.

[build-img]: https://travis-ci.org/JuliaOpt/SemidefiniteOptInterface.jl.svg?branch=master
[build-url]: https://travis-ci.org/JuliaOpt/SemidefiniteOptInterface.jl
[winbuild-img]: https://ci.appveyor.com/api/projects/status/r92anpmqeo30rppe/branch/master?svg=true
[winbuild-url]: https://ci.appveyor.com/project/JuliaOpt/semidefiniteoptinterface-jl/branch/master
[coveralls-img]: https://coveralls.io/repos/github/JuliaOpt/SemidefiniteOptInterface.jl/badge.svg?branch=master
[coveralls-url]: https://coveralls.io/github/JuliaOpt/SemidefiniteOptInterface.jl?branch=master
[codecov-img]: http://codecov.io/github/JuliaOpt/SemidefiniteOptInterface.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/JuliaOpt/SemidefiniteOptInterface.jl?branch=master
