![Harlequin](harlequin_logo.svg)

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ziotom78.github.io/Harlequin.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ziotom78.github.io/Harlequin.jl/dev)
[![Build Status](https://travis-ci.com/ziotom78/Harlequin.jl.svg?branch=master)](https://travis-ci.com/ziotom78/Harlequin.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/ziotom78/Harlequin.jl?svg=true)](https://ci.appveyor.com/project/ziotom78/Harlequin-jl)
[![Codecov](https://codecov.io/gh/ziotom78/Harlequin.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ziotom78/Harlequin.jl)

Harlequin is a Julia package that simulates the operations of a space
mission measuring the CMB. The program includes the following basic
features:

- Generation of pointing information;
- Simulation of the CMB dipolar signal;
- Production of maps.

If you are looking for a more mature and comprehensive toolkit, which
includes several more features, be sure to have a look at
[TOAST](https://github.com/hpc4cmb/toast). This includes a full-scale
map-maker (MADAM), beam convolution, half-wave plate simulation,
atmospheric effects (useful for ground experiments). Moreover, it uses
Python instead of Julia, and it is much better supported on HPC
superclusters.

A few advantages of Harlequin over TOAST are the following:

- It works under Linux, Mac, and Windows;
- It strives to have comprehensive documentation;
- It can use the Julia ecosystem, including awesome tools as [plot
  recipes](https://github.com/JuliaPlots/RecipesBase.jl), [interactive
  widgets](https://github.com/JuliaGizmos/Interact.jl), [error
  propagation](https://github.com/JuliaPhysics/Measurements.jl), etc.

# Documentation

It is available both for the
[stable](https://ziotom78.github.io/Harlequin.jl/stable) and
[dev](https://ziotom78.github.io/Harlequin.jl/dev) branches.

# License

Harlequin is released under a permissive MIT license. See
[LICENSE](LICENSE) for more information.
