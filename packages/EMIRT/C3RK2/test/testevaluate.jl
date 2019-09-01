using Test
# test the seg error functions
using EMIRT
using EMIRT.Evaluate

@testset "test evaluate" begin 

# get test data
aff = EMIRT.IOs.imread(joinpath(dirname(@__FILE__),"../assets/aff.h5"))
lbl = EMIRT.IOs.imread(joinpath(dirname(@__FILE__),"../assets/lbl.h5"))

lbl = Array{UInt32,3}(lbl)

# compare python code and julia
seg = EMIRT.AffinityMaps.aff2seg(aff)
judec = evaluate(seg, lbl)
@show judec

# dict of evaluation curve
@time ecd = evaluate(lbl,lbl)
@show ecd
@test abs(ecd[:rf]-1) < 0.01

seg = Array{UInt32,3}(reshape(range(1,length=length(lbl)), size(lbl)))
@time ecd = evaluate(seg,lbl)
@show ecd
@test abs(ecd[:rf]-0) < 0.01

end # end of test set
