# AsterReader.jl

[![Build Status](https://travis-ci.org/JuliaFEM/AsterReader.jl.svg?branch=master)](https://travis-ci.org/JuliaFEM/AsterReader.jl)[![Coverage Status](https://coveralls.io/repos/github/JuliaFEM/AsterReader.jl/badge.svg?branch=master)](https://coveralls.io/github/JuliaFEM/AsterReader.jl?branch=master)[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliafem.github.io/AsterReader.jl/stable)[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://juliafem.github.io/AsterReader.jl/latest)[![Issues](https://img.shields.io/github/issues/JuliaFEM/AsterReader.jl.svg)](https://github.com/JuliaFEM/AsterReader.jl/issues)

Package can be used to read Code Aster .med and .rmed file formats. To read Code Aster `.med` file (exported using SALOME), one has to write
```julia
aster_read_mesh(fn)
```
where `fn` is the name of the mesh file. Result is a simple dictionary.

In case of several mesh exists in a single file, one must provide also mesh name, e.g.
```julia
aster_read_mesh(fn, mesh_name="my_mesh")
```

Package can also be used to read results from `.rmed` files. This is still highly experimental feature and can be used mainly to compare calculation results done using Code Aster to results produced by own FE code.
