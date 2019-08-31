using BDF, Compat.Test, HDF5, JLD

#test BDF read and write
origFilePath = "Newtest17-256.bdf"
bdfHeader = readBDFHeader(origFilePath)
dats, evtTab, trigs, statusChan = readBDF(origFilePath)

save("test_data.jld", "bdfHeader", bdfHeader, "EEG", dats,
     "evtTab", evtTab, "trigs", trigs)

headerKeys = collect(keys(bdfHeader))
evtTabKeys = ["idx", "dur", "code"]

h5Out = h5open("Newtest17-256_data.h5", "w")
g = g_create(h5Out, "data")
g["EEG"] = dats
g["trigs"] = trigs
for k in evtTabKeys
    g[k] = evtTab[k]
end
## for k in headerKeys
##     g[k] = bdfHeader[k]
## end
close(h5Out)

#fooData = h5read("Newtest17-256_data.h5", "data")
