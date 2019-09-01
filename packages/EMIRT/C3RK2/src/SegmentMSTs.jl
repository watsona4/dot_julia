module SegmentMSTs
using ..Types
using ..Evaluate

using Base.Threads

export segment, segment!, sgm2error, sgm2ec
#
# """
# equality
# """
# function Base.is(sgm1::SegMST, sgm2::SegMST)
#   sgm1.segmentation==sgm2.segmentation && sgm1.segmentPairs==sgm2.segmentPairs && sgm1.segmentPairAffinities==sgm2.segmentPairAffinities
# end

function Base.size(sgm::SegMST)
    return size( sgm.segmentation )
end 

function Base.ndims(sgm::SegMST)
    ndims(sgm.segmentation)
end

"""
merge supervoxels with high affinity
"""
function Base.merge!(sgm::SegMST, thd::AbstractFloat)
    # the dict of parent and child
    # key->child, value->parent
    pd = Dict{UInt32,UInt32}()
    idxlst = Vector{Int64}()
    for idx in 1:length(sgm.segmentPairAffinities)
        if sgm.segmentPairAffinities[idx] > thd
            # the first one is child, the second one is parent
            pd[sgm.segmentPairs[idx,1]] = sgm.segmentPairs[idx,2]
        end
    end

    # find the root id
    for (c,p) in pd
        # list of child node, for path compression
        clst = [c]
        # find the root
        while haskey(pd, p)
            push!(clst, p)
            p = pd[p]
        end
        # now p is the root id
        # path compression
        for c in clst
            pd[c] = p
        end
    end

    # set each segment id as root id
    gc_enable(false)
    @threads for i in eachindex(sgm.segmentation)
        sgm.segmentation[i] = get(pd, sgm.segmentation[i], sgm.segmentation[i])
    end
    gc_enable(true)

    # update the segmentPairsrogram
    sgm.segmentPairAffinities = sgm.segmentPairAffinities[idxlst]
    sgm.segmentPairs = sgm.segmentPairs[:, idxlst]

    return sgm.segmentation
end

function Base.merge(sgm::SegMST, thd::AbstractFloat)
  sgm2 = deepcopy(sgm)
  return merge!(sgm2, thd)
end

"""
segment the sgm, only return segmentation
"""
function segment(sgm::SegMST, thd::AbstractFloat)
  sgm2 = merge(sgm, thd)
  return sgm2.segmentation
end

function segment!(sgm::SegMST, thd::AbstractFloat)
  sgm = merge!(sgm, thd)
  return sgm.segmentation
end

"""
compute segmentation error using one threshold
"""
function sgm2error(sgm::SegMST, lbl::Segmentation, thd::AbstractFloat)
    @assert thd<=1 && thd>=0
    seg = segment(sgm, thd)
    return evaluate(seg, lbl)
end

"""
compute error curve based on a segmentation (including segmentPairsrogram) and groundtruth label
"""
function sgm2ec(sgm::SegMST, lbl::Segmentation, thds = 0:0.1:1)
    ec = ScoreCurve()
    for thd in thds
        e = sgm2error(sgm, lbl, thd)
        e[:thd] = thd
        append!(ec, e)
    end
    ec
end

end # end of module
