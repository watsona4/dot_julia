# System Matrices

For loading the system matrix, one could in principle again call `measData` but there
is again a high level function for this job. Since system functions can be very large
it is crucial to load only the subset of frequencies that are used during reconstruction
The high level system matrix loading function is called `getSystemMatrix` and has
the following interface:
```julia
function getSystemMatrix(f::MPIFile,
                         frequencies=1:rxNumFrequencies(f)*rxNumChannels(f);
                         bgCorrection=false,
                         loadasreal=false,
                         kargs...)
```
`loadasreal` can again be used when using a solver requiring real numbers.
The most important parameter is `frequencies`, which defaults to all possible
frequencies over all receive channels. In practice, one will determine the
frequencies using the the [Frequency Filter](@ref) functionality. The parameter
`bgCorrection` controls if a  background correction is applied while loading the
system matrix. The return value of `getSystemMatrix` is a matrix of type `ComplexF32`
or `Float32` with the rows encoding the spatial dimension and the columns encoding
the dimensions frequency, receive channels, and patches.
