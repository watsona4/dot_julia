__precompile__()

"""
The CondaBinDeps module provides access to the [conda](http://conda.pydata.org/) packages
manager as a BinDeps provider, to install binary
dependencies of other Julia packages.

To use Anaconda as a binary provider for BinDeps, the `CondaBinDeps.Manager` type is proposed. A
small example looks like this:

```julia
# Declare dependency
using BinDeps
@BinDeps.setup
netcdf = library_dependency("netcdf", aliases = ["libnetcdf","libnetcdf4"])

using CondaBinDeps
#  Use alternative conda channel.
CondaBinDeps.Conda.add_channel("my_channel")
provides(CondaBinDeps.Manager, "libnetcdf", netcdf)
```
"""
module CondaBinDeps
import Conda
using BinDeps

include("bindeps_conda.jl")

end
