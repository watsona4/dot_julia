using EMIRT
using EMIRT.SegmentMSTs
using EMIRT.IOs
using Watershed
using Test

@testset "test segmentation with mst" begin 
aff = readaff(joinpath(dirname(@__FILE__),"../assets/piriform.aff.h5"))

seg, rg = watershed(aff; is_threshold_relative=true);
segmentPairs, segmentPairAffinities = rg2segmentPairs(rg)
sgm = SegMST(seg, segmentPairs, segmentPairAffinities)

println("merge mst: ")
@time merge!(sgm, 0.5);


# include(joinpath(Pkg.dir(), "EMIRT/plugins/emshow.jl"))
# show(sgm.seg)
#save(joinpath(dirname(@__FILE__),"../assets/sgm.h5", sgm)

end # end of test set 
