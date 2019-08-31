# CondaBinDeps.jl

[![Build Status — OS X and Linux](https://travis-ci.org/JuliaPackaging/CondaBinDeps.jl.svg?branch=master)](https://travis-ci.org/JuliaPackaging/CondaBinDeps.jl)
[![Build status — Windows](https://ci.appveyor.com/api/projects/status/utfqcbtfjm385xwb?svg=true)](https://ci.appveyor.com/project/StevenGJohnson/condabindeps-jl)

This package, which builds on the [Conda.jl package](https://github.com/JuliaPy/Conda.jl) allows one to use [conda](http://conda.pydata.org/) as a [BinDeps](https://github.com/JuliaPackaging/BinDeps.jl) binary
provider for Julia. While other binary providers like
[Homebrew.jl](https://github.com/JuliaLang/Homebrew.jl),
[AptGet](https://en.wikipedia.org/wiki/Advanced_Packaging_Tool#apt-get) or
[WinRPM.jl](https://github.com/JuliaLang/WinRPM.jl) are platform-specific,
CondaBinDeps.jl is a cross-platform alternative. It can also be used without
administrator rights, in contrast to the current Linux-based providers.

As such, `Conda.jl` primary audience is Julia packages developers who have a dependency on  some native library.

`conda` is a package manager which started as the binary package manager for the
Anaconda Python distribution, but it also provides arbitrary packages. Instead
of the full Anaconda distribution, `Conda.jl` uses the miniconda Python
environment, which only includes `conda` and its dependencies.

`CondaBinDeps.jl` is **NOT** an alternative Julia package manager, nor a way to manage
Python installations. It will not use any pre-existing Anaconda or Python
installation on  your machine.

## Basic functionality

You can install this package by running `Pkg.add("CondaBinDeps")` at the Julia prompt.  See the [Conda.jl package](https://github.com/JuliaPy/Conda.jl) for information on setting
up `conda` environments, etcetera.

## BinDeps integration: using Conda.jl as a package author

CondaBinDeps.jl can be used as a `Provider` for
[BinDeps](https://github.com/JuliaPackaging/BinDeps.jl) with the `Conda.Manager`
type. You first need to write a [conda
recipe](http://conda.pydata.org/docs/building/recipe.html), and upload the
corresponding build to [binstar](https://binstar.org/). Then, add CondaBinDeps in your
`REQUIRE` file, and add the following to your `deps/build.jl` file:

```julia
using BinDeps
@BinDeps.setup
netcdf = library_dependency("netcdf", aliases = ["libnetcdf" "libnetcdf4"])

...

using CondaBinDeps
provides(CondaBinDeps.Manager, "libnetcdf", netcdf)
```

If your dependency is available in another channel than the default one, you
should register that channel.

```julia
CondaBinDeps.Conda.add_channel("my_channel")
provides(CondaBinDeps.Manager, "libnetcdf", netcdf)
```

If the binary dependency is only available for some OS, give this information to
BinDeps:

```julia
provides(CondaBinDeps.Manager, "libnetcdf", netcdf, os=:Linux)
```

To tell BinDeps to install the package to an environment different from the
root environment, use `EnvManager`.

```julia
provides(CondaBinDeps.EnvManager{:my_env}, "libnetcdf", netcdf)
```

## Bugs and suggestions

CondaBinDeps has been tested on Linux, OS X, and Windows. It should work on all these
platforms.

Please report any bug or suggestion as a
[github issue](https://github.com/JuliaPackaging/CondaBinDeps.jl/issues)

## License

The CondaBinDeps.jl package is licensed under the MIT Expat license, and is copyrighted
by Guillaume Fraux and contributors.
