# This file contains routines to generate MDF files
export saveasMDF, loadDataset, loadMetadata, loadMetadataOnline, setparam!, compressCalibMDF
export saveasMDFHacking # temporary Hack

function setparam!(params::Dict, parameter, value)
  if value != nothing
    params[parameter] = value
  end
end

# we do not support all conversion possibilities
function loadDataset(f::MPIFile; frames=1:acqNumFrames(f), applyCalibPostprocessing=false)
  params = loadMetadata(f)

  # call API function and store result in a parameter Dict
  if experimentHasMeasurement(f)
    loadMeasParams(f, params, skipMeasData = true)
    if !applyCalibPostprocessing
      if frames!=1:acqNumFrames(f)
        setparam!(params, "measData", measData(f,frames))
        setparam!(params, "acqNumFrames", length(frames))
        setparam!(params, "measIsBGFrame", measIsBGFrame(f)[frames])
      else
        setparam!(params, "measData", measData(f))
      end
    else
        data = getMeasurementsFD(f, false, frames=1:acqNumFrames(f),sortFrames=true,
              spectralLeakageCorrection=false,transposed=true)
        setparam!(params, "measData", data)
        setparam!(params, "measIsFourierTransformed", true)
        setparam!(params, "measIsTransposed", true)
        setparam!(params, "measIsFramePermutation", true)
        setparam!(params, "measFramePermutation", fullFramePermutation(f))

        setparam!(params, "measIsBGFrame",
          cat(zeros(Bool,acqNumFGFrames(f)),ones(Bool,acqNumBGFrames(f)), dims=1))

        try
          setparam!(params, "calibSNR", calibSNR(f))
        catch
          setparam!(params, "calibSNR", calculateSystemMatrixSNR(f, data))
        end
    end
  end

  loadCalibParams(f, params)
  loadRecoParams(f, params)

  return params
end

const defaultParams =[:version, :uuid, :time, :dfStrength, :acqGradient, :studyName, :studyNumber, :studyUuid, :studyTime, :studyDescription,
          :experimentName, :experimentNumber, :experimentUuid, :experimentDescription,
          :experimentSubject,
          :experimentIsSimulation, :experimentIsCalibration,
          :tracerName, :tracerBatch, :tracerVendor, :tracerVolume, :tracerConcentration,
          :tracerSolute, :tracerInjectionTime,
          :scannerFacility, :scannerOperator, :scannerManufacturer, :scannerName,
          :scannerTopology, :acqNumPeriodsPerFrame, :acqNumAverages,
          :acqStartTime, :acqOffsetField, :acqNumFrames,
          :dfNumChannels, :dfPhase, :dfBaseFrequency, :dfDivider,
          :dfCycle, :dfWaveform, :rxNumChannels, :rxBandwidth,
          :rxNumSamplingPoints, :rxTransferFunction, :rxInductionFactor,
          :rxUnit, :rxDataConversionFactor]

function loadMetadata(f, inputParams = MPIFiles.defaultParams)
  params = Dict{String,Any}()
  # call API function and store result in a parameter Dict
  for op in inputParams
    setparam!(params, string(op), eval(op)(f))
  end
  return params
end

function loadRecoParams(f, params = Dict{String,Any}())
  if experimentHasReconstruction(f)
    for op in [:recoData, :recoSize, :recoFov, :recoFovCenter, :recoOrder,
           :recoPositions, :recoParameters]
      setparam!(params, string(op), eval(op)(f))
    end
  end

  return params
end

function loadCalibParams(f, params = Dict{String,Any}())
  if experimentIsCalibration(f)
    for op in [:calibFov, :calibFovCenter,
               :calibSize, :calibOrder, :calibPositions, :calibOffsetField,
             :calibDeltaSampleSize, :calibMethod]
      setparam!(params, string(op), eval(op)(f))
    end
    if !haskey(params, "calibSNR")
      setparam!(params, "calibSNR", calibSNR(f))
    end
  end
  return params
end

function loadMeasParams(f, params = Dict{String,Any}(); skipMeasData = false)
  if experimentHasMeasurement(f)
    for op in [:measIsFourierTransformed, :measIsTFCorrected,
                 :measIsBGCorrected,
                 :measIsTransposed, :measIsFramePermutation, :measIsFrequencySelection,
                 :measIsSpectralLeakageCorrected,
                 :measFramePermutation, :measIsBGFrame]
      setparam!(params, string(op), eval(op)(f))
    end
  end

  if !skipMeasData
    setparam!(params, "measData", measData(f))
  end

  return params
end



function appendBGDataset(params::Dict, filenameBG::String; kargs...)
  fBG = MPIFile(filenameBG)
  return appendBGDataset(params, fBG; kargs...)
end

function appendBGDataset(params::Dict, fBG::MPIFile; frames=1:acqNumFrames(fBG))
  paramsBG = loadDataset(fBG, frames=frames)
  paramsBG["measIsBGFrame"][:] = true

  params["measData"] = cat(4, params["measData"], paramsBG["measData"])
  params["measIsBGFrame"] = cat(params["measIsBGFrame"], paramsBG["measIsBGFrame"], dims=1)
  params["acqNumFrames"] += paramsBG["acqNumFrames"]

  return params
end


function saveasMDF(filenameOut::String, filenameIn::String; kargs...)
  saveasMDF(filenameOut, MPIFile(filenameIn); kargs...)
end

function saveasMDF(filenameOut::String, f::MPIFile; filenameBG = nothing, kargs...)
  params = loadDataset(f;kargs...)
  if filenameBG != nothing
    appendBGDataset(params, filenameBG)
  end
  saveasMDF(filenameOut, params)
end

function saveasMDFHacking(filenameOut::String, f::MPIFile)
    dataSet=loadDataset(f)
    dataSet["acqNumFrames"]=dataSet["acqNumPeriodsPerFrame"]*dataSet["acqNumFrames"]
    dataSet["acqNumPeriodsPerFrame"]=1
    dataSet["measData"]=reshape(dataSet["measData"],size(dataSet["measData"],1),size(dataSet["measData"],2),1,size(dataSet["measData"],3)*size(dataSet["measData"],4))
    dataSet["dfStrength"]=dataSet["dfStrength"][:,:,1:1]
    dataSet["acqOffsetField"]=dataSet["acqOffsetField"]
    #dataSet["acqOffsetFieldShift"]=dataSet["acqOffsetFieldShift"][:,1:1]
    dataSet["dfPhase"]=dataSet["dfPhase"][:,:,1:1]
    saveasMDF(filenameOut, dataSet)
    return dataSet
end

function saveasMDF(filename::String, params::Dict)
  # file has to be removed if exists. Otherwise h5create fails.
  isfile(filename) && rm(filename)
  h5open(filename, "w") do file
    saveasMDF(file, params)
  end
end

function compressCalibMDF(filenameOut::String, f::MPIFile; SNRThresh=2.0, kargs...)
  idx = Int64[]

  SNR = calibSNR(f)[:,:,1]
  for k=1:size(SNR,1)
    if maximum(SNR[k,:]) > SNRThresh
      push!(idx, k)
    end
  end

  compressCalibMDF(filenameOut, f, idx; kargs...)
end

function compressCalibMDF(filenamesOut::Vector{String}, f::MultiMPIFile; SNRThresh=2.0, kargs...)
  idx = Int64[]

  # We take the SNR from the first SF
  SNR = calibSNR(f[1])[:,:,1]
  for k=1:size(SNR,1)
    if maximum(SNR[k,:]) > SNRThresh
      push!(idx, k)
    end
  end

  for (i,f_) in enumerate(f)
    compressCalibMDF(filenamesOut[i], f_, idx; kargs...)
  end
end

function compressCalibMDF(filenameOut::String, f::MPIFile, idx::Vector{Int64};
                          basisTrafoRedFactor=1.0, basisTrafo="DCT-IV")
  params = loadMetadata(f)
  loadMeasParams(f, params, skipMeasData = true)
  loadCalibParams(f, params)
  params["calibSNR"] = calibSNR(f)
  loadRecoParams(f, params)

  data = systemMatrixWithBG(f, idx)

  params["calibSNR"] = params["calibSNR"][idx,:,:]
  if haskey(params, "rxTransferFunction")
    params["rxTransferFunction"] = params["rxTransferFunction"][idx,:]
  end
  params["measIsFrequencySelection"] = true
  params["measFrequencySelection"] = idx

  if basisTrafoRedFactor == 1.0
    params["measData"] = data
  else
    B = linearOperator(basisTrafo, calibSize(f))
    N = prod(calibSize(f))
    NBG = size(data,1) - N
    D = size(data,3)
    P = size(data,4)
    NRed = max(1, floor(Int, basisTrafoRedFactor*N))
    dataOut = similar(data, NBG+NRed, length(idx), D, P)
    basisIndices = zeros(Int32, NRed, length(idx), D, P)

    fgdata = data[measFGFrameIdx(f),:,:,:]
    bgdata = data[measBGFrameIdx(f),:,:,:]

    dataOut[(NRed+1):end,:,:,:] = bgdata

    for k=1:length(idx), d=1:D, p=1:P
      I = B * fgdata[:,k,d,p]
      basisIndices[:,k,d,p] = round.(Int32,reverse(sortperm(abs.(I)),dims=1)[1:NRed])
      dataOut[1:NRed,k,d,p] = I[vec(basisIndices[:,k,d,p])]
    end

    params["measData"] = dataOut
    params["measIsBasisTransformed"] = true
    params["measBasisTransformation"] = basisTrafo
    params["measBasisIndices"] = basisIndices

    bgFrame = zeros(Bool, NRed+NBG)
    bgFrame[(NRed+1):end] .= true
    params["measIsBGFrame"] = bgFrame
    params["acqNumFrames"] = NRed+NBG
  end

  saveasMDF(filenameOut, params)
end



function convertCustomSF(filenameOut::String, f::BrukerFile, fBG::BrukerFile)

  params = loadMetadata(f)
  loadMeasParams(f, params, skipMeasData = true)
  loadCalibParams(f, params)


  #params["calibFoV"] = ???

#  data = systemMatrixWithBG(f, idx)

#  params["calibSNR"] = params["calibSNR"][idx,:,:]
#  if haskey(params, "rxTransferFunction")
#    params["rxTransferFunction"] = params["rxTransferFunction"][idx,:]
#  end
#  params["measIsFrequencySelection"] = true
#  params["measFrequencySelection"] = idx

#  params["measData"] = data


#  params["measData"] = dataOut
#  params["measIsBasisTransformed"] = true
#    params["measBasisTransformation"] = basisTrafo
#    params["measBasisIndices"] = basisIndices

#    bgFrame = zeros(Bool, NRed+NBG)
#    bgFrame[(NRed+1):end] .= true
#    params["measIsBGFrame"] = bgFrame
#    params["acqNumFrames"] = NRed+NBG

  saveasMDF(filenameOut, params)
end


hasKeyAndValue(paramDict,param) = haskey(paramDict, param) && paramDict[param] != nothing

function writeIfAvailable(file, paramOut, paramDict, paramIn )
  if hasKeyAndValue(paramDict, paramIn)
    write(file, paramOut, paramDict[paramIn])
  end
end

function saveasMDF(file::HDF5File, params::Dict)
  # general parameters
  write(file, "/version", "2.0")
  write(file, "/uuid", string(get(params,"uuid",uuid4() )))
  write(file, "/time", "$( get(params,"time", Dates.unix2datetime(time())) )")

  # study parameters
  write(file, "/study/name", get(params,"studyName","default") )
  write(file, "/study/number", get(params,"studyNumber",0))
  if hasKeyAndValue(params,"studyUuid")
    studyUuid = params["studyUuid"]
  else
    studyUuid = uuid4()
  end
  write(file, "/study/uuid", string(studyUuid))
  write(file, "/study/description", get(params,"studyDescription","n.a."))
  if hasKeyAndValue(params,"studyTime")
    write(file, "/study/time", string(params["studyTime"]))
  end

  # experiment parameters
  write(file, "/experiment/name", get(params,"experimentName","default") )
  write(file, "/experiment/number", get(params,"experimentNumber",0))
  if hasKeyAndValue(params,"experimentUuid")
    expUuid = params["experimentUuid"]
  else
    expUuid = uuid4()
  end
  write(file, "/experiment/uuid", string(expUuid))
  write(file, "/experiment/description", get(params,"experimentDescription","n.a."))
  write(file, "/experiment/subject", get(params,"experimentSubject","n.a."))
  write(file, "/experiment/isSimulation", Int8(get(params,"experimentIsSimulation",false)))

  # tracer parameters
  write(file, "/tracer/name", get(params,"tracerName","n.a") )
  write(file, "/tracer/batch", get(params,"tracerBatch","n.a") )
  write(file, "/tracer/vendor", get(params,"tracerVendor","n.a") )
  write(file, "/tracer/volume", get(params,"tracerVolume",0.0))
  write(file, "/tracer/concentration", get(params,"tracerConcentration",0.0) )
  write(file, "/tracer/solute", get(params,"tracerSolute","Fe") )
  tr = [string(t) for t in get(params,"tracerInjectionTime", [Dates.unix2datetime(time())]) ]
  write(file, "/tracer/injectionTime", tr)

  # scanner parameters
  write(file, "/scanner/facility", get(params,"scannerFacility","n.a") )
  write(file, "/scanner/operator", get(params,"scannerOperator","n.a") )
  write(file, "/scanner/manufacturer", get(params,"scannerManufacturer","n.a"))
  write(file, "/scanner/name", get(params,"scannerName","n.a"))
  write(file, "/scanner/topology", get(params,"scannerTopology","FFP"))

  # acquisition parameters
  write(file, "/acquisition/numAverages",  params["acqNumAverages"])
  write(file, "/acquisition/numFrames", get(params,"acqNumFrames",1))
  write(file, "/acquisition/numPeriods", get(params,"acqNumPeriodsPerFrame",1))
  write(file, "/acquisition/startTime", "$( get(params,"acqStartTime", Dates.unix2datetime(time())) )")

  writeIfAvailable(file, "/acquisition/gradient", params, "acqGradient")
  writeIfAvailable(file, "/acquisition/offsetField", params, "acqOffsetField")

  # drivefield parameters
  write(file, "/acquisition/drivefield/numChannels", size(params["dfStrength"],2) )
  write(file, "/acquisition/drivefield/strength", params["dfStrength"])
  write(file, "/acquisition/drivefield/phase", params["dfPhase"])
  write(file, "/acquisition/drivefield/baseFrequency", params["dfBaseFrequency"])
  write(file, "/acquisition/drivefield/divider", params["dfDivider"])
  write(file, "/acquisition/drivefield/cycle", params["dfCycle"])
  if !haskey(params, "dfWaveform")
    params["dfWaveform"] = "sine"
  end
  write(file, "/acquisition/drivefield/waveform", params["dfWaveform"])

  # receiver parameters
  write(file, "/acquisition/receiver/numChannels", params["rxNumChannels"])
  write(file, "/acquisition/receiver/bandwidth", params["rxBandwidth"])
  write(file, "/acquisition/receiver/numSamplingPoints", params["rxNumSamplingPoints"])
  if !haskey(params, "rxUnit")
    params["rxUnit"] = "V"
  end
  write(file, "/acquisition/receiver/unit",  params["rxUnit"])
  write(file, "/acquisition/receiver/dataConversionFactor",  params["rxDataConversionFactor"])
  if hasKeyAndValue(params,"rxTransferFunction")
    tf = params["rxTransferFunction"]
    group = file["/acquisition/receiver"]
    writeComplexArray(group, "transferFunction", tf)
  end
  writeIfAvailable(file, "/acquisition/receiver/inductionFactor",  params, "rxInductionFactor")

  # measurements
  if hasKeyAndValue(params, "measData")
    meas = params["measData"]
    if eltype(meas) <: Complex
      group = g_create(file,"/measurement")
      writeComplexArray(group, "/measurement/data", meas)
    else
      write(file, "/measurement/data", meas)
    end
    write(file, "/measurement/isFourierTransformed", Int8(params["measIsFourierTransformed"]))
    write(file, "/measurement/isSpectralLeakageCorrected", Int8(params["measIsSpectralLeakageCorrected"]))
    write(file, "/measurement/isTransferFunctionCorrected", Int8(params["measIsTFCorrected"]))
    write(file, "/measurement/isFrequencySelection", Int8(params["measIsFrequencySelection"]))
    write(file, "/measurement/isBackgroundCorrected",  Int8(params["measIsBGCorrected"]))
    write(file, "/measurement/isFastFrameAxis",  Int8(params["measIsTransposed"]))
    write(file, "/measurement/isFramePermutation",  Int8(params["measIsFramePermutation"]))
    writeIfAvailable(file, "/measurement/frequencySelection",  params, "measFrequencySelection")

    if hasKeyAndValue(params, "measFramePermutation")
      write(file, "/measurement/framePermutation", params["measFramePermutation"] )
    end
    if hasKeyAndValue(params, "measIsBGFrame")
      write(file, "/measurement/isBackgroundFrame", convert(Array{Int8}, params["measIsBGFrame"]) )
    end
    if hasKeyAndValue(params, "measIsBasisTransformed")
      write(file, "/measurement/isBasisTransformed", params["measIsBasisTransformed"] )
      write(file, "/measurement/basisIndices", params["measBasisIndices"] )
      write(file, "/measurement/basisTransformation", params["measBasisTransformation"] )
    end
  end

  # calibrations
  writeIfAvailable(file, "/calibration/snr",  params, "calibSNR")
  writeIfAvailable(file, "/calibration/fieldOfView",  params, "calibFov")
  writeIfAvailable(file, "/calibration/fieldOfViewCenter",  params, "calibFovCenter")
  writeIfAvailable(file, "/calibration/size",  params, "calibSize")
  writeIfAvailable(file, "/calibration/order",  params, "calibOrder")
  writeIfAvailable(file, "/calibration/positions",  params, "calibPositions")
  writeIfAvailable(file, "/calibration/offsetField",  params, "calibOffsetField")
  writeIfAvailable(file, "/calibration/deltaSampleSize",  params, "calibDeltaSampleSize")
  writeIfAvailable(file, "/calibration/method",  params, "calibMethod")
  if hasKeyAndValue(params, "calibIsMeanderingGrid")
    write(file, "/calibration/isMeanderingGrid", Int8(params["calibIsMeanderingGrid"]))
  end
  # reconstruction
  if hasKeyAndValue(params, "recoData")
    write(file, "/reconstruction/data", params["recoData"])
    write(file, "/reconstruction/fieldOfView", params["recoFov"])
    write(file, "/reconstruction/fieldOfViewCenter", params["recoFovCenter"])
    write(file, "/reconstruction/size", params["recoSize"])
    write(file, "/reconstruction/order", get(params,"recoOrder", "xyz"))
    if hasKeyAndValue(params,"recoPositions")
      write(file, "/reconstruction/positions", params["recoPositions"])
    end
    if hasKeyAndValue(params,"recoParameters")
      saveParams(file, "/reconstruction/parameters", params["recoParameters"])
    end
  end

  writeIfAvailable(file, "/custom/auxiliaryData", params, "auxiliaryData")
end
