using BDF, Compat.Test

#test BDF read and write
origFilePath = joinpath(dirname(@__FILE__), "Newtest17-256.bdf")
copyFilePath = joinpath(dirname(@__FILE__), "Newtest17-256_copy.bdf")
bdfHeader = readBDFHeader(origFilePath)
dats, evtTab, trigs, statusChan = readBDF(origFilePath)
writeBDF(copyFilePath, dats, trigs, statusChan, bdfHeader["sampRate"][1],
         subjID=bdfHeader["subjID"], recID=bdfHeader["recID"],
         startDate=bdfHeader["startDate"],
         startTime=bdfHeader["startTime"],
         versionDataFormat=bdfHeader["versionDataFormat"],
         chanLabels=bdfHeader["chanLabels"][1:end-1],
         transducer=bdfHeader["transducer"][1:end-1],
         physDim=bdfHeader["physDim"][1:end-1],
         physMin=bdfHeader["physMin"][1:end-1],
         physMax=bdfHeader["physMax"][1:end-1],
         prefilt=bdfHeader["prefilt"][1:end-1],
         reserved=bdfHeader["reserved"])

bdfHeader2 = readBDFHeader(copyFilePath)
dats2, evtTab2, trigs2, statusChan2 = readBDF(copyFilePath)
rm(copyFilePath)
bdfHeader["fileName"] = copyFilePath

@test isequal(bdfHeader2, bdfHeader)
@test isequal(dats2, dats)
@test isequal(evtTab2, evtTab)
@test isequal(trigs2, trigs)
@test isequal(statusChan2, statusChan)
