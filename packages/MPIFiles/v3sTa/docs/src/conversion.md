# Conversion

With the support for reading different file formats and the ability to store
data in the MDF, it is also possible to convert files into MDF. This can be done by
calling
```julia
saveasMDF(filenameOut, filenameIn)
```
The second argument can alternatively also be an `MPIFile` handle.

Alternatively, there is also a more low level interface which gives the user the control to
change parameters before storing. This look like this
```julia
params = loadDataset(f)
# do something with params
saveasMDF(filenameOut, params)
```
Here, `f` is an `MPIFile` handle and the command `loadDataset` loads the entire
dataset including all parameters into a Julia `Dict`, which can be modified by the
user. After modification one can store the data by passing the `Dict` as the
second argument to the `saveasMDF` function.

!!! note
    The parameters in the `Dict` returned by `loadDataset` have the same keys
    as the corresponding accessor functions listed in the [Low Level Interface](@ref).
