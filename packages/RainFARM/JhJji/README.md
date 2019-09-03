# RainFARM
![RainFARM logo](/docs/src/assets/logo-small.png) 
&nbsp; &nbsp; [![DOI](https://zenodo.org/badge/75199877.svg)](https://zenodo.org/badge/latestdoi/75199877) [![Build Status](https://travis-ci.org/jhardenberg/RainFARM.jl.svg?branch=master)](https://travis-ci.org/jhardenberg/RainFARM.jl) [![Appveyor build](https://ci.appveyor.com/api/projects/status/agoibqta7c88urfv?svg=true)](https://ci.appveyor.com/project/jhardenberg/rainfarm-jl) [![codecov.io](http://codecov.io/github/jhardenberg/RainFARM.jl/coverage.svg?branch=master)](http://codecov.io/github/jhardenberg/RainFARM.jl?branch=master)

RainFARM.jl is a Julia library and a collection of command-line interface tools implementing the RainFARM (Rainfall Filtered Autoregressive Model) stochastic precipitation downscaling method. Adapted for climate downscaling according to (D'Onofrio et al. 2018) and with fine-scale orographic weights (Terzago et al. 2018).

RainFARM (Rebora et al. 2006) is a metagaussian stochastic downscaling procedure based on the extrapolation of the coarse-scale Fourier power spectrum of a spatio-temporal precipitation field to small scales.

## Requires 

julia (>=5.0), cdo (>=1.5)

*Julia packages*: Interpolations, ArgParse, NetCDF

## Installation

You will need an implementation of the [Julia language](https://julialang.org/) on your machine. 

RainFARM is a registered package, so to install it just launch julia and from the REPL type the following:

- in Julia >= 0.7: ```] add RainFARM```
- In Julia 0.6: ```Pkg.add("RainFARM")```
- If you wish to try the very latest development features from this repository do:
```Using Pkg; Pkg.clone("https://github.com/jhardenberg/RainFARM.jl") ```
(the `using Pkg`step is only needed for Julia versions >= 0.7)

Test from the julia REPL calling `using RainFARM`

In the `tools` subdirectory (under .julia in your home) you will find the command line tools. Link or copy these to somewhere in you path in order to use them.

## Documentation

Please see the [full documentation](https://jhardenberg.github.io/RainFARM.jl/dev/) for a list of all available functions.

## Scientific references

- Terzago, S., Palazzi, E., and von Hardenberg, J. (2018). Stochastic downscaling of precipitation in complex orography: a simple method to reproduce a realistic fine-scale climatology, Nat. Hazards Earth Syst. Sci., 18, 2825-2840, doi: <https://doi.org/10.5194/nhess-18-2825-2018>

- D’Onofrio, D., Palazzi, E., von Hardenberg, J., Provenzale, a., & Calmanti, S. (2014). Stochastic Rainfall Downscaling of Climate Models. Journal of Hydrometeorology, 15(2), 830–843. doi: <https://doi.org/10.1175/JHM-D-13-096.1>

- Rebora, N., Ferraris, L., von Hardenberg, J., & Provenzale, A. (2006). RainFARM: Rainfall Downscaling by a Filtered Autoregressive Model. Journal of Hydrometeorology, 7(4), 724–738. doi: <https://doi.org/10.1175/JHM517.1>

## Authors: 

*Julia version* - J. von Hardenberg, ISAC-CNR (2016-2018)

Earlier *Matlab* version for climate downscaling - D. D'Onofrio and J. von Hardenberg, ISAC-CNR (2014)
