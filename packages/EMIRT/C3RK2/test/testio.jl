using Test
using EMIRT
using EMIRT.IOs
@testset "test IO" begin

fileName = "$(tempname()).h5"
# test image IO
img = EMImage(rand(UInt8, 300,300,10))
saveimg(fileName, img)
@test img == readimg(fileName)
rm(fileName)

# test segmentation IO
seg = Segmentation(rand(UInt32, 300,300,10))
saveseg(fileName, seg)
@test seg == readseg(fileName)
rm(fileName)

# test affinity IO
aff = AffinityMap(rand(Float32, 300,300,30,3))
saveaff(fileName, aff)
@test aff == readaff(fileName)
rm(fileName)

# test sgm IO
sgm = EMIRT.Segmentations.seg2sgm(seg)
savesgm(fileName, sgm)
sgm2 = readsgm(fileName)
# Note! we can only compare by internal field
# julia == function only compare the memory address for mutable objects.
# see https://github.com/JuliaLang/julia/issues/5340
@test sgm2.segmentation == sgm.segmentation
@test sgm2.segmentPairs == sgm.segmentPairs
@test sgm2.segmentPairAffinities == sgm.segmentPairAffinities
rm(fileName)

end # end of IO test set 
