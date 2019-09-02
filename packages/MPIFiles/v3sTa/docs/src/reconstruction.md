# Reconstruction Results

MDF files can also contain reconstruction results instead of measurement data.
The low level results can be retrieved using the [Low Level Interface](@ref)
```julia
function recoData(f::MPIFile)
function recoFov(f::MPIFile)
function recoFovCenter(f::MPIFile)
function recoSize(f::MPIFile)
function recoOrder(f::MPIFile)
function recoPositions(f::MPIFile)
```
Instead, one can also combine these data into an `ImageMetadata` object from the
[Images.jl](https://github.com/JuliaImages/Images.jl) package by calling the
functions
```julia
function loadRecoData(filename::AbstractString)
```
The `ImageMetadata` object does also pull all relevant metadata from an MDF
such that the file can be also be stored using
```julia
function saveRecoData(filename, image::ImageMeta)
```
These two functions are especially relevant when using the package  
[MPIReco.jl](https://github.com/MagneticParticleImaging/MPIReco.jl)
