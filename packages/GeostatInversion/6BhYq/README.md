GeostatInversion
================

<!-- [![GeostatInversion](http://pkg.julialang.org/badges/GeostatInversion_0.5.svg)](http://pkg.julialang.org/?pkg=GeostatInversion&ver=0.5)
[![GeostatInversion](http://pkg.julialang.org/badges/GeostatInversion_0.6.svg)](http://pkg.julialang.org/?pkg=GeostatInversion&ver=0.6)
[![GeostatInversion](http://pkg.julialang.org/badges/GeostatInversion_0.7.svg)](http://pkg.julialang.org/?pkg=GeostatInversion&ver=0.7) -->
[![Build Status](https://travis-ci.org/madsjulia/GeostatInversion.jl.svg?branch=master)](https://travis-ci.org/madsjulia/GeostatInversion.jl)
[![Coverage Status](https://coveralls.io/repos/madsjulia/GeostatInversion.jl/badge.svg?branch=master)](https://coveralls.io/r/madsjulia/GeostatInversion.jl?branch=master)

This package provides methods for inverse analysis using parameter fields that are represented using geostatistical (stochastic) methods.
Currently, two geostatistical methods are implemented.
One is the Principal Component Geostatistical Approach (PCGA) proposed by [Kitanidis](http://dx.doi.org/10.1002/2013WR014630) & [Lee](http://dx.doi.org/10.1002/2014WR015483).
The other utilizes a Randomized Geostatistical Approach (RGA) that builds on PCGA.

Randomized Geostatistical Approach (RGA) references:

- [O'Malley, D., Le, E., Vesselinov, V.V., Fast Geostatistical Inversion using Randomized Matrix Decompositions and Sketchings for Heterogeneous Aquifer Characterization, AGU Fall Meeting, San Francisco, CA, December 14–18, 2015.](http://adsabs.harvard.edu/abs/2015AGUFM.T31E..03O)
- [Lin, Y, Le, E.B, O'Malley, D., Vesselinov, V.V., Bui-Thanh, T., Large-Scale Inverse Model Analyses Employing Fast Randomized Data Reduction, 2016.](submitted)

Two versions of PCGA are implemented in this package

- `pcgadirect`, which uses full matrices and direct solvers during iterations
- `pcgalsqr`, which uses low rank representations of the matrices combined with iterative solvers during iterations

The RGA method, `rga`, can use either of these approaches using the keyword argument. That is, by doing `rga(...; pcgafunc=GeostatInversion.pcgadirect)` or `rga(...; pcgafunc=GeostatInversion.pcgalsqr)`.

GeostatInversion is a module of [MADS](http://madsjulia.github.io/Mads.jl).

Example
-------

```julia
import GeostatInversion

Ns = map(x->round(Int, 25 * x), 1 + rand(N))
k0 = randn()
dk = rand()
beta = -2 - rand()
k = GeostatInversion.FFTRF.powerlaw_structuredgrid(Ns, k0, dk, beta)
```

MADS
====

[MADS](http://madsjulia.github.io/Mads.jl) (Model Analysis & Decision Support) is an integrated open-source high-performance computational (HPC) framework in [Julia](http://julialang.org).
MADS can execute a wide range of data- and model-based analyses:

* Sensitivity Analysis
* Parameter Estimation
* Model Inversion and Calibration
* Uncertainty Quantification
* Model Selection and Model Averaging
* Model Reduction and Surrogate Modeling
* Machine Learning and Blind Source Separation
* Decision Analysis and Support

MADS has been tested to perform HPC simulations on a wide-range multi-processor clusters and parallel environments (Moab, Slurm, etc.).
MADS utilizes adaptive rules and techniques which allows the analyses to be performed with a minimum user input.
The code provides a series of alternative algorithms to execute each type of data- and model-based analyses.

Documentation
=============

All the available MADS modules and functions are described at [madsjulia.github.io](http://madsjulia.github.io/Mads.jl)

Installation
============

```julia
Pkg.add("GeostatInversion")
```

Installation behind a firewall
------------------------------

Julia uses git for the package management.
To install Julia packages behind a firewall, add the following lines in the `.gitconfig` file in your home directory:

```git
[url "https://"]
        insteadOf = git://
```

or execute:

```bash
git config --global url."https://".insteadOf git://
```

Set proxies:

```bash
export ftp_proxy=http://proxyout.<your_site>:8080
export rsync_proxy=http://proxyout.<your_site>:8080
export http_proxy=http://proxyout.<your_site>:8080
export https_proxy=http://proxyout.<your_site>:8080
export no_proxy=.<your_site>
```

For example, if you are doing this at LANL, you will need to execute the
following lines in your bash command-line environment:

```bash
export ftp_proxy=http://proxyout.lanl.gov:8080
export rsync_proxy=http://proxyout.lanl.gov:8080
export http_proxy=http://proxyout.lanl.gov:8080
export https_proxy=http://proxyout.lanl.gov:8080
export no_proxy=.lanl.gov
```

MADS examples
=============

In Julia REPL, do the following commands:

```julia
import Mads
```

To explore getting-started instructions, execute:

```julia
Mads.help()
```

There are various examples located in the `examples` directory of the `Mads` repository.

For example, execute

```julia
include(Mads.madsdir * "/../examples/contamination/contamination.jl")
```

to perform various example analyses related to groundwater contaminant transport, or execute

```julia
include(Mads.madsdir * "/../examples/bigdt/bigdt.jl")
```

to perform Bayesian Information Gap Decision Theory (BIG-DT) analysis.

Developers
==========

* [Velimir (monty) Vesselinov](http://www.lanl.gov/orgs/ees/staff/monty) [(publications)](http://scholar.google.com/citations?user=sIFHVvwAAAAJ)
* [Daniel O'Malley](http://www.lanl.gov/expertise/profiles/view/daniel-o'malley) [(publications)](http://scholar.google.com/citations?user=rPzCVjEAAAAJ)
* [see also](https://github.com/madsjulia/GeostatInversion.jl/graphs/contributors)

Publications, Presentations, Projects
=====================================

* [mads.lanl.gov/](http://mads.lanl.gov/)
* [ees.lanl.gov/monty](http://ees.lanl.gov/monty)