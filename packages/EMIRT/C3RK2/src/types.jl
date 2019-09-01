module Types

export EMImage, Segmentation, AffinityMap, ParamDict, SegMST, SegmentPairs, SegmentPairAffinities
export Timg, Tseg, Tsgm, Tec, Tecs

# type of raw image
const EMImage = Array{UInt8,3}

# type of segmentation
const Segmentation = Array{UInt32,3}

# type of affinity map
const AffinityMap = Array{Float32,4}

# type of parameter dictionary
const ParamDict = Dict{Symbol, Dict{Symbol, Any}}

const SegmentPairs = Array{UInt32,2}

const SegmentPairAffinities = Vector{Float32}

mutable struct SegMST
    segmentation::Segmentation
    segmentPairs::SegmentPairs
    segmentPairAffinities::SegmentPairAffinities
end

# defined for backward compatibility
const Timg  =  EMImage
const Tseg  =  Segmentation
const Taff  =  AffinityMap
const Tsgm  =  SegMST

end # end of module
