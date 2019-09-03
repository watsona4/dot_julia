# ScanImageTiffReader.jl Documentation

```@meta
DocTestSetup  = quote
    using Pkg
    Pkg.add(["JSON", "DotEnv"])

    using DotEnv
    DotEnv.config(joinpath(dirname(pwd()), "test", ".env"))
    mytif = joinpath(ENV["TESTBASE"], "linj_00001.tif") # so we don't have to specify full paths in doctests

    using ScanImageTiffReader, JSON
end
```

## About

The ScanImageTiffReader is a [Julia](https://julialang.org) library for extracting data from [Tiff](https://en.wikipedia.org/wiki/Tagged_Image_File_Format) and [BigTiff](http://bigtiff.org/) files recorded using [ScanImage](http://scanimage.org).  It is a very fast tiff reader and provides access to ScanImage-specific metadata.  It should read most tiff files, but as of now we don't support compressed or tiled data.  It is also available as a [Matlab](https://vidriotech.gitlab.io/scanimagetiffreader-matlab/), [Python](https://vidriotech.gitlab.io/scanimagetiffreader-python/),  or [C library](https://vidriotech.gitlab.io/scanimage-tiff-reader).  There's also a [command-line interface](https://vidriotech.gitlab.io/scanimage-tiff-reader).

More information and related tools can be found on [here](http://scanimage.vidriotechnologies.com/display/SIH/Tools).

Both [ScanImage](http://scanimage.org) and this reader are products of [Vidrio Technologies](http://vidriotechnologies.com/).  If you have questions or need support feel free to [submit an issue](https://gitlab.com/vidriotech/scanimagetiffreader-julia/issues) or [contact us](https://vidriotechnologies.com/contact-support/).

## Usage

The [`ScanImageTiffReader.open`](@ref) function attempts to open a file and execute a query on it before closing and handling any exceptions.  The query is passed as an argument and is one of `data`, `metadata`, `pxtype`, etc...  See below for examples.

```julia
julia> using Pkg
julia> Pkg.add("ScanImageTiffReader")
julia> using ScanImageTiffReader
julia> vol = ScanImageTiffReader.open("my.tif") do io
    data(io)
end
```

## API Documentation

```@autodocs
Modules = [ScanImageTiffReader]
Order = [:function, :type]
```
