module EMIRT
include("types.jl")
include("ios.jl")
include("Domains.jl")
include("common.jl")
include("sys.jl")
include("Images.jl")
include("Segmentations.jl")
include("AffinityMaps.jl")
include("evaluate.jl")
include("SegmentMSTs.jl")
include("parser.jl")

using .Types
using .Images
using .IOs
using .AffinityMaps
using .Segmentations
using .Evaluate
using .SegmentMSTs

export EMImage, Segmentation, AffinityMap, ParamDict, SegMST, SegmentPairs, SegmentPairAffities

end
