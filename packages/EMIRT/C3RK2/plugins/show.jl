# export show, plot
import Images: Image
import ImageView: view
import Base: show
using Gadfly
import Gadfly: plot

using FixedPointNumbers

# include("../src/segmentation.jl")
# include("../src/evaluate.jl")
# include("../src/errorcurve.jl")
using EMIRT
include("utils.jl")

# show segmentationx
function show( seg::Segmentation )
    @assert ndims(seg)==3
    rgbseg = seg2rgb(seg)
    @show size(rgbseg)
    view(Image(rgbseg, spatialorder=["x","y","z"]))
end

# show raw image
function show(arr::EMImage)
    img = Image(Array{UFixed8,3}(arr), spatialorder=["x","y","z"])
    @show img
    view(img)
end

# show raw image and segmentation combined together
function show(img::EMImage, seg::Segmentation)
    # combined rgb image stack
    cmb = seg_overlay_img(img, seg)
    imgc, imgslice = view(Image(cmb, spatialorder=["x","y","z"]))
    # return imgc and imgslice for visualization in a script
    # https://github.com/timholy/ImageView.jl#calling-view-from-a-script-file
    return imgc, imgslice
end

# show affinity map
function show(aff::AffinityMap)
    view(Image(aff, colordim=4, spatialorder=["x","y","z"]))
end

"""
plot multiple error curves
"""
function plot(ecs::ScoreCurves)
    # transform to dataframe
    df = ecs2df(ecs)
    # plot the dataframe
    prf = plot(df, x="thd", y="rf", Geom.line,
               Guide.xlabel("threshold"),
               Guide.ylabel("rand f score"))
    pre = plot(df, x="thd", y="re", Geom.line,
               Guide.xlabel("threshold"),
               Guide.ylabel("rand error"))
    prfms = plot(df, x="rfm", y="rfs", Geom.line,
                 Guide.xlabel("rand f score of mergers"),
                 Guide.ylabel("rand f score of splitters"))
    prems = plot(df, x="rem", y="res", Geom.line,
                 Guide.xlabel("rand error of mergers"),
                 Guide.ylabel("rand error of splitters"))
    # stack the subplots
    plt = vstack(hstack(prf,prfms), hstack(pre, prems))
end

"""
transform single errorcurve to errorcurves
"""
function ec2ecs(ec::ScoreCurve)
  ecs = ScoreCurves()
  append!(ecs, ec)
  ecs
end

"""
plot single error curve
"""
function plot(ec::ScoreCurve)
    ecs = ec2ecs(ec)
    plot(ecs)
end
