using BDF, Compat.Test

#test splitting BDF at single time point
origFilePath = joinpath(dirname(@__FILE__), "Newtest17-256.bdf")
tSplitFilePath1 = joinpath(dirname(@__FILE__), "Newtest17-256_1.bdf")
tSplitFilePath2 = joinpath(dirname(@__FILE__), "Newtest17-256_2.bdf")
tSplitFilePathComb = joinpath(dirname(@__FILE__), "Newtest17-256_comb.bdf")

bdfHeader = readBDFHeader(origFilePath)
dats, evtTab, trigs, statusChan = readBDF(origFilePath)

splitBDFAtTime(origFilePath, 30)
dats1, evtTab1, trigs1, statusChan1 = readBDF(tSplitFilePath1)
dats2, evtTab2, trigs2, statusChan2 = readBDF(tSplitFilePath2)

writeBDF(tSplitFilePathComb, [dats1 dats2], [trigs1; trigs2], [statusChan1; statusChan2], bdfHeader["sampRate"][1])
datsComb, evtTabComb, trigsComb, statusChanComb = readBDF(tSplitFilePathComb)

rm(tSplitFilePath1)
rm(tSplitFilePath2)
rm(tSplitFilePathComb)


@test isequal(dats, datsComb)
@test isequal(evtTab, evtTabComb)
@test isequal(trigs, trigsComb)
@test isequal(statusChan, statusChanComb)
