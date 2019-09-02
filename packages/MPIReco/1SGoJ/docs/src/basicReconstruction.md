# Basic Reconstruction

MPIReco.jl provides different reconstruction levels. All of these reconstruction
routines are called `reconstruction` and the dispatch is done based on the input
types.

## On Disk Reconstruction

This is the highest level reconstruction. The function signature is given by
```julia
function reconstruction(d::MDFDatasetStore, study::Study,
                        exp::Experiment, recoParams::Dict)
```
This reconstruction is also called an *on disk* reconstruction because it assumes
that one has a data store (i.e. a structured folder of files) where
the file location is uniquely determined by the study name and experiment number.
All reconstruction parameters are passed to this method by the `recoParams` dictionary.
On disk reconstruction has the advantage that the routine will perform reconstruction
only once for a particular set of parameters. If that parameter set has already
been reconstructed, the data will loaded from disk.
However, the on disk reconstruction needs some experience with dataset stores to
set it up correctly and is not suited for unstructured data.

## In Memory Reconstruction

The next level is the in memory reconstruction. Its function signature reads
```julia
function reconstruction(recoParams::Dict)
```
This routine requires that all parameters are put into a dictionary. An overview
how this dictionary looks like is given in the section [Parameters](@ref).

The above reconstruction method basically does two things
* Pull out the location of measurement data and system matrix from the `recoParams`
  dictionary.
* Pass all parameter to the low level reconstruction method in the form of keyword
  parameters.

In turn the next level reconstruction looks like this
```julia
function reconstruction(bSF::Union{T,Vector{T}}, bMeas::MPIFile; kargs...)
```
There are, however also some reconstruction methods in-between that look like this
```julia
function reconstruction(filenameSF::AbstractString, filenameMeas::AbstractString; kargs...)
function reconstruction(filenameMeas::AbstractString; kargs...)
```
In both cases, an MPIFile is created based on the input filename. The second version
also guesses the system matrix based on what is stored within the measurement
file. This usually only works, if this is executed on a system where the files
are stored at exactly the same location as how they have been measured.

## Middle Level Reconstruction

The middle level reconstruction first checks, whether the dataset is a multi-patch
or a single-patch file. Then it will call either `reconstructionSinglePatch` or
`reconstructionMultiPatch`. Both have essentially the signature
```julia
function reconstructionSinglePatch(bSF::Union{T,Vector{T}}, bMeas::MPIFile;
                                  minFreq=0, maxFreq=1.25e6, SNRThresh=-1,
                                  maxMixingOrder=-1, numUsedFreqs=-1, sortBySNR=false, recChannels=1:numReceivers(bMeas),
                                  bEmpty = nothing, bgFrames = 1, fgFrames = 1,
                                  varMeanThresh = 0, minAmplification=2, kargs...) where {T<:MPIFile}
```
Here, one can see various parameters that can be used to control, which frequency
components are being used for reconstruction. All these parameters are passed
to the `filterFrequencies` function from [MPIFiles.jl](https://github.com/MagneticParticleImaging/MPIFiles.jl).

The function `reconstructionSinglePatch` performs the frequency filtering and then calls
```julia
function reconstruction(bSF::Union{T,Vector{T}}, bMeas::MPIFile, freq::Array;
  bEmpty = nothing, bgFrames = 1,  denoiseWeight = 0, redFactor = 0.0, thresh = nothing,
  loadasreal = false, solver = "kaczmarz", sparseTrafo = nothing, saveTrafo=false,
  gridsize = gridSizeCommon(bSF), fov=calibFov(bSF), center=[0.0,0.0,0.0], useDFFoV=false,
  deadPixels=Int[], bgCorrectionInternal=false, kargs...) where {T<:MPIFile}
```
One can see that the frequency index is passed to this function as the third argument.
All new keyword arguments are essentially used for determining the way how the
system matrix is loaded. For instance with the parameters `gridsize`, `fov`, `center`
it is possible to change the grid at which the system function is being loaded.

Once the system matrix is loaded, the next lower level function is called:
```julia
function reconstruction(S, bSF::Union{T,Vector{T}}, bMeas::MPIFile, freq::Array, grid;
  frames = nothing, bEmpty = nothing, bgFrames = 1, nAverages = 1, numAverages=nAverages,
  sparseTrafo = nothing, loadasreal = false, maxload = 100, maskDFFOV=false,
  weightType=WeightingType.None, weightingLimit = 0, solver = "kaczmarz",
  spectralCleaning=true, fgFrames=1:10, bgCorrectionInternal=false,
  noiseFreqThresh=0.0, kargs...) where {T<:MPIFile}
```
This function is responsible for loading the measurement data and potential background
data that is subtracted from the measurements. For any frame to be reconstructed, the
low level reconstruction routine is called.

## Low Level Reconstruction

Finally, we have arrived at the low level reconstruction routine that has the signature
```julia
function reconstruction(S, u::Array; sparseTrafo = nothing,
                        lambd=0, progress=nothing, solver = "kaczmarz",
                        weights=nothing, kargs...)
```
One can see that it requires the system matrix `S` and the measurements `u` to be
already loaded.

We note that `S` is typeless for a reason here. For a regular reconstruction one
will basically feed in an `Array{ComplexF32,2}` in here, although more precisely
it will be a `Transposed` version of that type if the `Kaczmarz` algorithm is being
used for efficiency reasons.

However, in case that matrix compression is applied `S` will be of type `SparseMatrixCSC`.
And for [Multi-Patch Reconstruction](@ref) `S` will be of type `MultiPatchOperator`. Hence,
the solvers are implemented in a very generic way and require only certain functions
to be implemented. The low level reconstruction method calls one of the solvers
from [RegularizedLeastSquares.jl](https://github.com/tknopp/RegularizedLeastSquares.jl).
