using BDF, Compat.Test

#test split BDF at trigger


origFilePath = joinpath(dirname(@__FILE__), "Newtest17-256.bdf")
copyFilePath = joinpath(dirname(@__FILE__), "Newtest17-256_midtrig.bdf")
copyFilePath1 = joinpath(dirname(@__FILE__), "Newtest17-256_midtrig_1.bdf")
copyFilePath2 = joinpath(dirname(@__FILE__), "Newtest17-256_midtrig_2.bdf")
copyFilePathComb = joinpath(dirname(@__FILE__), "Newtest17-256_comb.bdf")

bdfHeader = readBDFHeader(origFilePath)
dats, evtTab, trigs, statusChan = readBDF(origFilePath)

trigs[bdfHeader["sampRate"][1]*30] = 200

writeBDF(copyFilePath, dats, trigs, statusChan, bdfHeader["sampRate"][1],
         subjID=bdfHeader["subjID"], recID=bdfHeader["recID"], startDate=bdfHeader["startDate"],
         startTime=bdfHeader["startTime"], versionDataFormat=bdfHeader["versionDataFormat"],
                  chanLabels=bdfHeader["chanLabels"][1:end-1], transducer=bdfHeader["transducer"][1:end-1],
                  physDim=bdfHeader["physDim"][1:end-1], physMin=bdfHeader["physMin"][1:end-1], physMax=bdfHeader["physMax"][1:end-1],
                  prefilt=bdfHeader["prefilt"][1:end-1])

splitBDFAtTrigger(copyFilePath, 200)
dats1, evtTab1, trigs1, statusChan1 = readBDF(copyFilePath1)
dats2, evtTab2, trigs2, statusChan2 = readBDF(copyFilePath2)

writeBDF(copyFilePathComb, [dats1 dats2], [trigs1; trigs2], [statusChan1; statusChan2], bdfHeader["sampRate"][1])
datsCopy, evtTabCopy, trigsCopy, statusChanCopy = readBDF(copyFilePath)

datsComb, evtTabComb, trigsComb, statusChanComb = readBDF(copyFilePathComb)

rm(copyFilePath)
rm(copyFilePath1)
rm(copyFilePath2)
rm(copyFilePathComb)


@test isequal(datsCopy, datsComb)
@test isequal(evtTabCopy, evtTabComb)
@test isequal(trigsCopy, trigsComb)
@test isequal(statusChanCopy, statusChanComb)
