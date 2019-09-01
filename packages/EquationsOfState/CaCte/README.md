# EquationsOfState.jl

[![master Build Status Travis](https://travis-ci.com/singularitti/EquationsOfState.jl.svg?branch=master)](https://travis-ci.com/singularitti/EquationsOfState.jl) [![develop Build Status Travis](https://travis-ci.com/singularitti/EquationsOfState.jl.svg?branch=develop)](https://travis-ci.com/singularitti/EquationsOfState.jl) [![master Build status Appveyor](https://ci.appveyor.com/api/projects/status/mqfsm1ssxergkmec/branch/master?svg=true)](https://ci.appveyor.com/project/singularitti/equationsofstate-jl/branch/master) [![Build status Appveyor](https://ci.appveyor.com/api/projects/status/mqfsm1ssxergkmec?svg=true)](https://ci.appveyor.com/project/singularitti/equationsofstate-jl) [![codecov](https://codecov.io/gh/singularitti/EquationsOfState.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/singularitti/EquationsOfState.jl)


This package implements some _equations of state_ (EOS) of solid which are useful in research. It includes:

1. `Birch` EOS
2. `Murnaghan` EOS
3. Birch–Murnaghan EOS family:
    1. `BirchMurnaghan2nd`
    2. `BirchMurnaghan3rd`
    3. `BirchMurnaghan4th`
4. `Vinet` EOS
5. Poirier–Tarantola EOS family:
    1. `PoirierTarantola2nd`
    2. `PoirierTarantola3rd`
    3. `PoirierTarantola4th`
6. `Holzapfel` EOS (experimental)
7. `AntonSchmidt` EOS

The formula are referenced from Ref. 1.

This package also includes linear and nonlinear fitting methods, also referenced from Ref. 1.

It is built for Julia v1.0+.

## References

1. A. Otero-De-La-Roza, V. Luaña, *Comput. Phys. Commun.* **182**, 1708–1720 (2011).
