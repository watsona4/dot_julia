# PrintFileTree

[![Build Status](https://travis-ci.org/NHDaly/PrintFileTree.jl.svg?branch=master)](https://travis-ci.org/NHDaly/PrintFileTree.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/a2map67trmutdf6s?svg=true)](https://ci.appveyor.com/project/NHDaly/printfiletree-jl)


Exports a single utility function, `printfiletree(path)`.

## Compatability
Julia `v0.6`, `v0.7`, `v1.0`, `v1.1`+

## printfiletree(path)

Prints a file tree rooted at path, in the same way as the Unix utility, `tree`.

## Example:
```julia
julia> printfiletree("my/files")
my/files
├── a.txt
├── b.png
├── c
│   ├── a
│   │   ├── a
│   │   │   └── subfile
│   │   └── subfiles
│   ├── cats
│   │   └── are
│   │       └── so
│   │           └── cool
│   └── cool
└── d
```

## Installation

julia v0.6: `julia> Pkg.add("PrintFileTree")`

julia v0.7+: `pkg> add "PrintFileTree"`


