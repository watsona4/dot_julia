# Map-making

Harlequin includes a routine that applies the destriping algorithm to
time-ordered data, producing a maximum-likelihood map of the intensity
and polarization signal.

The destriping algorithm used in the code is described in the paper
[*Destiping CMB temperature and polarization
maps*](https://dx.doi.org/10.1051/0004-6361/200912361), Kurki-Suonio
et al., A/A 506, 1511-1539 (2009), and the source code closely follows
the terminology introduced in that paper.

The destriping algorithm is effective in removing 1/f noise originated
within the detectors of an instrument, provided that the noise is
uncorrelated among detectors. It requires the user to specify a
*baseline*, i.e., the maximum time span in which the noise can be
assumed to be uncorrelated (i.e., white).

Since the destriper is effective only when much data is available, it
is often the case that the input data to be fed to the algorithm is
larger than the available memory on a machine. In this case, the
destriper can take advantage of a distributed-memory environment and
of the MPI libraries, if they have been loaded *before* Harlequin,
like in the following example:

```julia
import MPI
import Harlequin  # Ok, use MPI whenever possible

# ...
```

You can check if MPI is being used with the function
[`use_mpi`](@ref).

Destriping is based on a datatype, [`DestripingData`](@ref), and on
the function [`destripe!`](@ref). To use the destriper, you create an
object of type [`DestripingData`](@ref) and then call
[`destripe!`](@ref) on it. The TOD must be split in a set of
*observations*, using the datatype [`Observation`](@ref); we will see
how to use them in the section [Splitting a TOD into
observations](@ref).

## Splitting a TOD into observations

```@docs
Observation
```

## High-level functions

```@docs
DestripingData
destripe!
use_mpi
```

## Low-level functions

The following functions are listed here for reference. You are not
expected to use them, unless you want to debug the destriper or dig
into its internals.

```@docs
update_nobs!
update_nobs_matrix!
compute_nobs_matrix!
update_binned_map!
reset_maps!
compute_z_and_subgroup!
compute_z_and_group!
compute_residuals!
array_dot
calc_stopping_factor
apply_offset_to_baselines!
calculate_cleaned_map!
```
