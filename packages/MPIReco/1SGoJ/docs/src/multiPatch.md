# Multi-Patch Reconstruction

For multi-patch reconstruction the method proposed by [Szwargulski et al.](https://www.ncbi.nlm.nih.gov/pubmed/30334751) is implemented in MPIReco. It is generalized however.

We first discuss the measurements for the multi-patch case. On modern MPI
scanners the `BrukerFile` or `MDFFile` can be used as is. However, the data
that we use in our unit tests consists of several single-patch measurements.
to combine these measurements we call
```julia
b = MultiMPIFile(["dataMP01", "dataMP02", "dataMP03", "dataMP04"])
```
`b` now can be uses as if were a multi-patch file.

Now we get to the system matrix. The most simple approach is to use a single system
matrix that was measured at the center. This can be done using
```julia 
bSF = MultiMPIFile(["SF_MP"])

c = reconstruction(bSF, b; SNRThresh=5, frames=1, minFreq=80e3,
                   recChannels=1:2, iterations=1, spectralLeakageCorrection=false)
```
The reconstruction parameters are not special here but are the same as discussed
in the [Parameters](@ref) section.

It is also possible to use multiple system matrices, which is currently the
best way to take field imperfection into account. Our test data has four patches
and we therefore can use
```julia
bSF = MultiMPIFile(["SF_MP01", "SF_MP02", "SF_MP03", "SF_MP04"])

c = reconstruction(bSF, b; SNRThresh=5, frames=1, minFreq=80e3,
                   recChannels=1:2, iterations=1, spectralLeakageCorrection=false)
```
Now we want somewhat more flexibility and
* define a mapping between the system matrix and the patches, here we allow to
  use the same system matrix for multiple patches
* make it possible to change the FFP position. Usually the value stored in the
  file is not 100% correct due to field imperfections.
* we might also want to preload the system matrices
All those thing can be done as is shown in the following example
```julia
bSFs = MultiMPIFile(["SF_MP01", "SF_MP02", "SF_MP03", "SF_MP04"])
mapping = [1,2,3,4]
freq = filterFrequencies(bSFs, SNRThresh=5, minFreq=80e3)
S = [getSF(SF,freq,nothing,"kaczmarz", bgcorrection=false)[1] for SF in bSFs]
SFGridCenter = zeros(3,4)
FFPos = zeros(3,4)
FFPos[:,1] = [-0.008, 0.008, 0.0]
FFPos[:,2] = [-0.008, -0.008, 0.0]
FFPos[:,3] = [0.008, 0.008, 0.0]
FFPos[:,4] = [0.008, -0.008, 0.0]
c4 = reconstruction(bSFs, b; SNRThresh=5, frames=1, minFreq=80e3,
        recChannels=1:2,iterations=1, spectralLeakageCorrection=false,
        mapping=mapping, systemMatrices = S, SFGridCenter=SFGridCenter,
        FFPos=FFPos, FFPosSF=FFPos)
```
