# Measurements

The low level interface allows to load measured MPI data via the `measData` function.
The returned data is exactly how it is stored on disc. This has the disadvantage
that the user needs to handle different sorts of data that can be stored in the
`measData` field. To cope with this issue, the MDF also has a high level interface
for loading measurement data. The first is the function
```julia
function getMeasurements(f::MPIFile, neglectBGFrames=true;
                frames=neglectBGFrames ? (1:acqNumFGFrames(f)) : (1:acqNumFrames(f)),
                numAverages=1,
                bgCorrection=false,
                interpolateBG=false,
                tfCorrection=measIsTFCorrected(f),
                sortFrames=false,
                spectralLeakageCorrection=true,
                kargs...)
```
that loads the MPI data in time domain. Background frames can be neglected or included,
frames can be selected by specifying `frames`, block averaging can be applied by
specifying `numAverages`, `bgCorrection` allows to apply background correction,
`tfCorrection` allows for a correction of the transfer function,
`interpolateBG` applies an optional interpolation in case that multiple background
intervals are included in the measurement, `sortFrames` puts all background frames
to the end of the returned data file, and `spectralLeakageCorrection` controls
whether a spectral leakage correction is applied.

The array returned by `getMeasurements` is of type `Float32` and has four dimensions
1. time dimension (over one period)
2. receive channel dimension
3. patch dimension
4. frame dimension

Instead of loading the data in time domain, one can also load the frequency domain data
by calling
```julia
function getMeasurementsFD(f::MPIFile, neglectBGFrames=true;
                  loadasreal=false,
                  transposed=false,
                  frequencies=nothing,
                  tfCorrection=measIsTFCorrected(f),
                  kargs...)
```
The function has basically the same parameters as `getMeasurements` but, additionally,
it is possible to load the data in real form (useful when using a solver that cannot
handle complex numbers), it is possible to specify the frequencies (specified by
the indices) that should be loaded, and it is possible to transpose the data
in a special way, where the frame dimension is changed to be the first dimension.
`getMeasurementsFD` returns a 4D array where of type `ComplexF32` with dimensions
1. frequency dimension
2. receive channel dimension
3. patch dimension
4. frame dimension
