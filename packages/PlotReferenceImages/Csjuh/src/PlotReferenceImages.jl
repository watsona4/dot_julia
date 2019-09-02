module PlotReferenceImages

using DataStructures, Random
using StatsPlots, RDatasets, ProgressMeter, DataFrames, Distributions, StatsBase
# For Plots' Examples
using Statistics, FileIO, ImageMagick, SparseArrays

# import and initialize plotting backends
import PyPlot, PlotlyJS, ORCA, PGFPlots
PyPlot.ioff()

theme(:default)

local_path(args...) = normpath(@__DIR__, "..", args...)


"""
    reference_file(backend::Symbol, i::Int, version::String)

Find the latest version of the reference image file for the reference image `i` and the backend `be`.
This returns a path to the file in the folder of the latest version.
If no file is found, a path pointing to the file of the folder specified by `version` is returned.
"""
function reference_file(backend, i, version)
    refdir = local_path("Plots", string(backend))
    fn = "ref$i.png"
    versions = sort(VersionNumber.(readdir(refdir)), rev = true)

    reffn = joinpath(refdir, string(version), fn)
    for v in versions
        tmpfn = joinpath(refdir, string(v), fn)
        if isfile(tmpfn)
            reffn = tmpfn
            break
        end
    end

    return reffn
end


reference_path(backend, version) = local_path("Plots", string(backend), string(version))


include("doc_examples.jl")
include("plotdocs.jl")

export generate_doc_image, generate_doc_images, generate_reference_image, generate_reference_images, reference_file, reference_path

end # module
