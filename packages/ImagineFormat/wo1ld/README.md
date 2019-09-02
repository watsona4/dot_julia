# ImagineFormat

[![Build Status](https://travis-ci.org/timholy/ImagineFormat.jl.svg?branch=master)](https://travis-ci.org/timholy/ImagineFormat.jl)

Imagine is an acquisition program for light sheet microscopy written
by Zhongsheng Guo in Tim Holy's lab. This package implements a loader
for the file format for the Julia programming language. Each Imagine
"file" consists of two parts (as two separate files): a `*.imagine`
file which contains the (ASCII) header, and a `*.cam` file which
contains the camera data.  The `*.cam` file is a raw byte dump, and is
compatible with the NRRD "raw" file.

## Usage

Read Imagine files like this:
```jl
using Images
img = load("filename")
```

## Converting to NRRD

You can write an NRRD header (`*.nhdr`) from an Imagine header as follows:
```jl
h = ImagineFormat.parse_header(filename)  # the .imagine file name
imagine2nrrd(nrrdname, h, datafilename)
```
where `datafilename` is the name of the `*.cam` file. It is required by the `*.nhdr` file to point to the actual data.

## Writing Imagine headers

You can use the non-exported function `ImagineFormat.save_header`:

```jl
save_header(destname, srcname, img, [T])
```

`destname` is the output `*.imagine` file; `srcname` is the name of
the "template" file.  Certain header values (e.g., size information)
are updated by reference to `img`.  The optional argument `T` allows
you to specify a different element type than possessed by `img`.
