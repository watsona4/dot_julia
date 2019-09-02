# Multi-Contrast Reconstruction

Until now we have discussed single-contrast reconstruction in which case
the reconstructed image `c` has a singleton first dimension. To perform
multi-contrast reconstruction one has to specify multiple system matrices
```julia
bSFa = MPIFile(filenameA)
bSFb = MPIFile(filenameB)
```
and can then invoke
```julia
c = reconstruction([bSFa, bSFb], b;
                    SNRThresh=5, frames=1, minFreq=80e3,
                    recChannels=1:2, iterations=1)
```
Now one can access the first and second channel by `c[1,:,:,:]` and `c[2,:,:,:]`.
