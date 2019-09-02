H5SectionsArrays.jl
===================
[![Build Status](https://travis-ci.org/seung-lab/H5SectionsArrays.jl.svg?branch=master)](https://travis-ci.org/seung-lab/H5SectionsArrays.jl)

cutout arbitrary chunks from a serials of 2D image sections in hdf5 format
- only support cutout, no writting
- used as normal Julia array
- support negative coordinate

Note that we only support UInt8 data type for now, should be easy to extend if neccesary.

# Installation
`Pkg.add("H5SectionsArrays")`

# Usage
```
using H5SectionsArrays
ba = H5SectionsArray("path/of/dataset/")
a = ba[101:300, -99:100, 1:3]
```

# File format
The section format follows the convention of [ImageRegistration.jl](https://github.com/seung-lab/ImageRegistration.jl)

## a registry file 
this file, called `registry.txt` should contain a few columns:
`filename 0 offset-x offset-y size-x size-y true`.

here is an example:
```
2,33_aligned    0   -293    -344    56834   25126   true
2,34_aligned    0   -1352   -1761   59385   28240   true
2,35_aligned    0   -1291   -1438   58320   27505   true
2,36_aligned    0   -1907   -1471   59306   27474   true
2,37_aligned    0   -1912   -2105   59320   28603   true
```

## a image section in hdf5 format
the hdf5 file should contain several datasets:
- img: the image array
- offset: a vector containing x,y offsets
- size: the size of the `img` dataset

For details please take a look of the test script `runtests.jl`, which construct a fake dataset.
