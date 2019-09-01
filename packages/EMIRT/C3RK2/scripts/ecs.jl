using EMIRT
include(joinpath(Pkg.dir(), "EMIRT/plugins/emshow.jl"))
using Gadfly

if length(ARGS)>0
    sgm = readsgm(ARGS[1])
else
    sgm = readsgm("/tmp/sgm.h5")
end

if length(ARGS)>1
    lbl = readseg(ARGS[2])
else
    lbl = readseg("/tmp/lbl.h5")
end

ec = sgm2ec(sgm, lbl)

ecs = ScoreCurves()
ecs[:ec] = ec
df = ecs2df(ecs)

plot(df, x="thd", y="re")
