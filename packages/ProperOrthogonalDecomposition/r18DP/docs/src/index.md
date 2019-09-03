# ProperOrthogonalDecomposition

## Introduction
*ProperOrthogonalDecomposition* is a Julia package for performing the Proper Orthogonal modal Decomposition (POD) technique. The technique has been used 
to, among other things, extract turbulent flow features. The POD methods available in this package is the Singular Value Decomposition (SVD) based method and the eigen-decomposition based *method of snapshots*. The method is snapshots is the most commonly used method for fluid flow analysis where the number of 
datapoints is larger than the number of snapshots.

The POD technique goes under several names; Karhunen-Loèven (KL), Principal Component Analysis (PCA) and Hotelling analysis. The method has been used for error analysis, reduced order modeling, fluid flow reconstruction, turbulent flow feature extraction, etc. A descriptive overview of the method is given in [1].

## Installation
The package is registered and can be installed with `Pkg.add`.

```julia
julia> Pkg.add("ProperOrthogonalDecomposition")
```

### Reference
[1]: Taira et al. "Modal Analysis of Fluid Flows: An Overview", arXiv:1702.01453 [physics], () http://arxiv.org/abs/1702.01453
