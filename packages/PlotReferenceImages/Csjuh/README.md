# PlotReferenceImages

[![Build Status](https://travis-ci.org/JuliaPlots/PlotReferenceImages.jl.svg?branch=master)](https://travis-ci.org/JuliaPlots/PlotReferenceImages.jl)

This package serves two purposes.
It holds the reference images for the [Plots.jl](https://github.com/JuliaPlots/Plots.jl) test suite and it provides utilities to generate the images for the [Plots.jl documentation](http://docs.juliaplots.org/latest/) at [PlotDocs.jl](https://github.com/JuliaPlots/PlotDocs.jl)

## Installation

To update test reference images for Plots.jl you can develop this package with:

```julia
julia> ]

pkg> dev https://github.com/JuliaPlots/PlotReferenceImages.jl.git
```

## Usage

Plots test images can be updated with the Plots test suite:

```julia
julia> ]

pkg> test Plots
```
If reference images differ from the previously saved images, a window opens showing both versions.
Check carefully if the changes are expected and an improvement.
In that case agree to overwrite the old image.
Otherwise it would be great if you could open an issue on Plots.jl, submit a PR with a fix for the regression or update the PR you are currently working on.
After updating all the images, make sure that all tests pass, `git add` the new files, commit and submit a PR.

---

You can update the images for a specific backend in the backends section of the Plots documentation with:

```julia
using PlotReferenceImages
generate_reference_images(sym)
```

Currently `sym ∈ (:gr, :pyplot, :plotlyjs, :pgfplots)` is supported.
To update only a single image you can do:

```julia
generate_reference_image(sym, i::Int)
```

To update the Plots documentaion images run:

```julia
using PlotReferenceImages
generate_doc_images()
```

This takes some time. So if you only want to update a specific image, run:

```julia
generate_doc_image(id::String)
```
Possible values for `id` can be found in the keys of `PlotReferenceImages.DOC_IMAGE_FILES`.

If you are satisfied with the new images, commit and submit a PR.

## Contributing

Any help to make these processes less complicated or automate them is very much appreciated.
