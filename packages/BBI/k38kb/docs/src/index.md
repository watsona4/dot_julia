## Description
BBI handles the shared parts of [bigWig.jl](https://github.com/BioJulia/bigWig.jl) and [bigBed.jl](https://github.com/BioJulia/bigBed.jl).

## Installation
BBI is bundled into the [bigWig.jl](https://github.com/BioJulia/bigWig.jl) and [bigBed.jl](https://github.com/BioJulia/bigBed.jl)
packages, so you may not need to install this package explicitly.
However, if you do, you can install BBI from the Julia REPL:

```julia
using Pkg
add("BBI")
#Pkg.add("BBI") for julia prior to v0.7
```

If you are interested in the cutting edge of the development, please check out
the `develop` branch to try new features before release.
