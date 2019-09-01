# Dyn3d

[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://ruizhi92.github.io/Dyn3d.jl/latest)
[![Build Status](https://travis-ci.org/ruizhi92/Dyn3d.jl.png?branch=master)](https://travis-ci.org/ruizhi92/Dyn3d.jl)
[![codecov](https://codecov.io/gh/ruizhi92/Dyn3d.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ruizhi92/Dyn3d.jl)

This is the 2d/3d rigid body dynamics solver using 6d spatial vector. Examples notebooks
are given in notebook folder. User just need to change the configuration files
for different cases, nothing else needed to be changed.

Code is written in Julia and Fortran on different branch.

- branch **master** for `Julia 1.1`
- branch **v0.6** for `Julia 0.6`
- branch **v0.7** for `Julia 0.7`
- branch **Fortran/artic3d** computes dynamics using articulated body method.
- branch **Fortran/HERK** computes dynamics formulating into a half-explicit Runge Kutta method solver in Fortran.

For `Julia 0.7` or higher versions, this package uses the local environment specified
in `Project.toml`. User doesn't need to do any set up except for possible denpendency
package required. For `Julia 0.6` version, this package's local dir need to be set by user.
Find Julia repo address by
`julia> Pkg.dir("Dyn3d")`
Then you can make a symlinking by
`shell$ sudo ln -s actual_address Julia_repo_address`


![](https://github.com/ruizhi92/Dyn3d.jl/raw/master/example_gif.gif)
