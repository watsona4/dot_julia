using EMIRT
using Watershed
using Agglomeration
using Process
using ImageView

#include(joinpath(dirname(@__FILE__), "../plugins/show.jl"))
include(joinpath(Pkg.dir(), "EMIRT/plugins/show.jl"))

# define
faffs = Dict{Symbol, AbstractString}(
        :jnet       => "/usr/people/jingpeng/seungmount/research/kisuklee/Sharing/Jingpeng/blend_test/JNet/chunk_33405_8905_229.aff.h5",
        :ensemble   => "/usr/people/jingpeng/seungmount/research/kisuklee/Sharing/Jingpeng/blend_test/Ensemble/chunk_33405_8905_229.aff.h5",
        :multiscale => "/usr/people/jingpeng/seungmount/research/kisuklee/Sharing/Jingpeng/blend_test/MS/chunk_33405_8905_229.aff.h5",
        :msf        => "/usr/people/jingpeng/seungmount/research/kisuklee/Sharing/Jingpeng/blend_test/MSF/chunk_33405_8905_229.aff.h5" )

flbl = "/usr/people/jingpeng/seungmount/Omni/TracerTasks/ZFishEnsembleValidation/zfish_chunk_33405_8905_229.omni.seg.ben.h5"
lbl  = readseg(flbl)

ecs = ScoreCurves()
for (name,faff) in faffs
  aff = readaff(faff)
  seg = atomicseg(aff; is_threshold_relative=true)
  segmentPairs, segmentPairAffinities = Process.forward(aff, seg)
  sgm = EMIRT.SegMST(seg, segmentPairs, segmentPairAffinities)

  errorcurve = sgm2ec(sgm, lbl, 0:0.2:1)
  append!(ecs, errorcurve; tag=name)
end

save("/tmp/ecs.zfish.h5", ecs);
# transform to dataframes
df = ecs2df(ecs)

# %% plot
plot(df, x="thd", y="rf", Geom.line,
               Guide.xlabel("threshold"),
               Guide.ylabel("rand f score"))

plot(df, x="thd", y="re", Geom.line,
              Guide.xlabel("threshold"),
              Guide.ylabel("rand error"))

# %%
# run(`julia overlay_img_seg.jl $fimg $flbl`)
