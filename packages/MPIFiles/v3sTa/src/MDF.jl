export MDFFile, MDFFileV1, MDFFileV2, addTrailingSingleton, addLeadingSingleton

abstract type MDFFile <: MPIFile end

# We use a dedicated type for v1 and v2. If both versions
# are the same we use the abstract type MDFFile
mutable struct MDFFileV1 <: MDFFile
  filename::String
  file::HDF5File
  mmap_measData
end

MDFFileV1(filename::String, file=h5open(filename,"r")) =
   MDFFileV1(filename, file, nothing)

mutable struct MDFFileV2 <: MDFFile
  filename::String
  file::HDF5File
  mmap_measData
end

function MDFFileV2(filename::String, file=h5open(filename,"r"))
  f = MDFFileV2(filename, file, nothing)

  parameter = "/measurement/data"
  if exists(f.file, "/measurement/data")
    if !isComplexArray(f.file, parameter)
      f.mmap_measData = readmmap(f.file[parameter])
    else
      f.mmap_measData = readmmap(f.file[parameter], Array{getComplexType(f.file,parameter)} )
    end
  end
  return f
end

# This dispatches on the file extension and automatically
# generates the correct type
function MDFFile(filename::String, file = h5open(filename,"r"))
  vers = VersionNumber( read(file, "/version") )
  if vers < v"2.0"
    return MDFFileV1(filename, file)
  else
    return MDFFileV2(filename, file)
  end
end

function Base.show(io::IO, f::MDFFileV1)
  print(io, "MDF v1: ", f.filename)
end

function Base.show(io::IO, f::MDFFileV2)
  print(io, "MDF v2: ", f.filename)
end

function h5exists(filename, parameter)
  return h5open(filename) do file
    exists(file, parameter)
  end
end

#function h5readornull(filename, parameter)
#  if h5exists(filename, parameter)
#    return h5read(filename, parameter)
#  else
#    return nothing
#  end
#end

#function h5read_(filename, parameter, default)
#  if h5exists(filename, parameter)
#    return h5read(filename, parameter)
#  else
#    return default
#  end
#end

function getindex(f::MDFFile, parameter)
  #if !haskey(f.param_cache,parameter)
  #  f.param_cache[parameter] = h5readornull(f.filename, parameter)
  #end
  #return f.param_cache[parameter]
  #return read(f.file[parameter])
  if exists(f.file, parameter)
    return read(f.file, parameter)
  else
    return nothing
  end
end

function getindex(f::MDFFile, parameter, default)
  #if !haskey(f.param_cache,parameter)
  #  f.param_cache[parameter] = h5read_(f.filename, parameter, default)
  #end
  #return f.param_cache[parameter]
  if exists(f.file, parameter)
    return read(f.file, parameter)
  else
    return default
  end
end



# general parameters
version(f::MDFFile) = VersionNumber( f["/version"] )
uuid(f::MDFFile) = str2uuid(f["/uuid"])
time(f::MDFFileV1) = DateTime( f["/date"] )
time(f::MDFFileV2) = DateTime( f["/time"] )

# study parameters
studyName(f::MDFFile) = f["/study/name"]
studyNumber(f::MDFFileV1) = 0
studyNumber(f::MDFFileV2) = f["/study/number"]
studyUuid(f::MDFFileV1) = nothing
studyUuid(f::MDFFileV2) = str2uuid(f["/study/uuid"])
studyDescription(f::MDFFileV1) = "n.a."
studyDescription(f::MDFFileV2) = f["/study/description"]
function studyTime(f::MDFFile)
  t = f["/study/time"]
  if typeof(t)==String
   return DateTime(t)
  else
   return nothing
  end
end
  
# experiment parameters
experimentName(f::MDFFileV1) = "n.a."
experimentName(f::MDFFileV2) = f["/experiment/name"]
experimentNumber(f::MDFFileV1) = parse(Int64, f["/study/experiment"])
experimentNumber(f::MDFFileV2) = f["/experiment/number"]
experimentUuid(f::MDFFileV1) = nothing
experimentUuid(f::MDFFileV2) = str2uuid(f["/experiment/uuid"])
experimentDescription(f::MDFFileV1) = f["/study/description"]
experimentDescription(f::MDFFileV2) = f["/experiment/description"]
experimentSubject(f::MDFFileV1) = f["/study/subject"]
experimentSubject(f::MDFFileV2) = f["/experiment/subject"]
experimentIsSimulation(f::MDFFileV2) = Bool( f["/experiment/isSimulation"] )
experimentIsSimulation(f::MDFFileV1) = Bool( f["/study/simulation"] )
experimentIsCalibration(f::MDFFile) = exists(f.file, "/calibration")
experimentHasReconstruction(f::MDFFile) = exists(f.file, "/reconstruction")
experimentHasMeasurement(f::MDFFileV1) = exists(f.file, "/measurement") ||
                                         exists(f.file, "/calibration")
experimentHasMeasurement(f::MDFFileV2) = exists(f.file, "/measurement")

_makeStringArray(s::String) = [s]
_makeStringArray(s::Vector{T}) where {T<:AbstractString} = s

# tracer parameters
tracerName(f::MDFFileV1)::Vector{String} = [f["/tracer/name"]]
tracerName(f::MDFFileV2)::Vector{String} = _makeStringArray(f["/tracer/name"])
tracerBatch(f::MDFFileV1)::Vector{String} = [f["/tracer/batch"]]
tracerBatch(f::MDFFileV2)::Vector{String} = _makeStringArray(f["/tracer/batch"])
tracerVolume(f::MDFFileV1)::Vector{Float64} = [f["/tracer/volume"]]
tracerVolume(f::MDFFileV2)::Vector{Float64} = [f["/tracer/volume"]...]
tracerConcentration(f::MDFFileV1)::Vector{Float64} = [f["/tracer/concentration"]]
tracerConcentration(f::MDFFileV2)::Vector{Float64} = [f["/tracer/concentration"]...]
tracerSolute(f::MDFFileV2)::Vector{String} = _makeStringArray(f["/tracer/solute"])
tracerSolute(f::MDFFileV1)::Vector{String} = ["Fe"]
function tracerInjectionTime(f::MDFFile)::Vector{DateTime}
  p = typeof(f) == MDFFileV1 ? "/tracer/time" : "/tracer/injectionTime"
  if f[p] == nothing
    return nothing
  end

  if typeof(f[p]) == String
    return [DateTime(f[p])]
  else
    return [DateTime(y) for y in f[p]]
  end
end
#tracerInjectionTime(f::MDFFileV2) = DateTime( f["/tracer/injectionTime"] )
tracerVendor(f::MDFFileV1)::Vector{String} = [f["/tracer/vendor"]]
tracerVendor(f::MDFFileV2)::Vector{String} = _makeStringArray(f["/tracer/vendor"])

# scanner parameters
scannerFacility(f::MDFFile)::String = f["/scanner/facility"]
scannerOperator(f::MDFFile)::String = f["/scanner/operator"]
scannerManufacturer(f::MDFFile)::String = f["/scanner/manufacturer"]
scannerName(f::MDFFileV1)::String = f["/scanner/model"]
scannerName(f::MDFFileV2)::String = f["/scanner/name", ""]
scannerTopology(f::MDFFile)::String = f["/scanner/topology"]

# acquisition parameters
acqStartTime(f::MDFFileV1)::DateTime = DateTime( f["/acquisition/time"] )
acqStartTime(f::MDFFileV2)::DateTime = DateTime( f["/acquisition/startTime"] )
acqNumAverages(f::MDFFileV1)::Int = f["/acquisition/drivefield/averages"]
acqNumAverages(f::MDFFileV2)::Int = f["/acquisition/numAverages",1]
function acqNumFrames(f::MDFFileV1)::Int
  if experimentIsCalibration(f)
    if f.mmap_measData == nothing
      h5open(f.filename,"r") do file
        f.mmap_measData = readmmap(file["/calibration/dataFD"])
      end
    end
    return size(f.mmap_measData,2)
  else
    return f["/acquisition/numFrames"]
  end
end
acqNumFrames(f::MDFFileV2)::Int = f["/acquisition/numFrames"]
acqNumPeriodsPerFrame(f::MDFFileV1)::Int = 1
acqNumPeriodsPerFrame(f::MDFFileV2)::Int = f["/acquisition/numPeriods",1]

acqGradient(f::MDFFileV1)::Array{Float64,4} = reshape(Matrix(Diagonal(f["/acquisition/gradient"])), 3,3,1,1)
function acqGradient(f::MDFFileV2)::Array{Float64,4}
  g = f["/acquisition/gradient"]
  if ndims(g) == 2 # compatibility with V2 pre versions
    g_ = zeros(3,3,1,size(g,2))
    g_[1,1,1,:] .= g[1,:]
    return g_
  else
    return g
  end
end
acqOffsetField(f::MDFFileV1)::Array{Float64,3} = f["/acquisition/offsetField", reshape([0.0,0.0,0.0],3,1,1)  ]
function acqOffsetField(f::MDFFileV2)::Array{Float64,3}
  off = f["/acquisition/offsetField", reshape([0.0,0.0,0.0],3,1,1)  ]
  if ndims(off) == 2 # compatibility with V2 pre versions
    return reshape(off,3,1,:)
  else
    return off
  end
end

# drive-field parameters
dfNumChannels(f::MDFFile)::Int = f["/acquisition/drivefield/numChannels"]
dfStrength(f::MDFFileV1)::Array{Float64,3} = addTrailingSingleton( addLeadingSingleton(
         f["/acquisition/drivefield/strength"], 2), 3)
dfStrength(f::MDFFileV2)::Array{Float64,3} = f["/acquisition/drivefield/strength"]
dfPhase(f::MDFFileV1) = dfStrength(f) .*0 .+  1.5707963267948966 # Bruker specific!
dfPhase(f::MDFFileV2) = f["/acquisition/drivefield/phase"]
dfBaseFrequency(f::MDFFile) = f["/acquisition/drivefield/baseFrequency"]
dfCustomWaveform(f::MDFFileV2) = f["/acquisition/drivefield/customWaveform"]
dfDivider(f::MDFFileV1) = addTrailingSingleton(
                f["/acquisition/drivefield/divider"],2)
dfDivider(f::MDFFileV2) = f["/acquisition/drivefield/divider"]
dfWaveform(f::MDFFileV1) = "sine"
dfWaveform(f::MDFFileV2) = f["/acquisition/drivefield/waveform"]
function dfCycle(f::MDFFile)
  if exists(f.file, "/acquisition/drivefield/cycle")
    return f["/acquisition/drivefield/cycle"]
  else  # pre V2 version
    return f["/acquisition/drivefield/period"]
  end
end

# receiver parameters
rxNumChannels(f::MDFFile) = f["/acquisition/receiver/numChannels"]
rxBandwidth(f::MDFFile) = f["/acquisition/receiver/bandwidth"]
rxNumSamplingPoints(f::MDFFile) = f["/acquisition/receiver/numSamplingPoints"]
function rxTransferFunction(f::MDFFile)
  parameter = "/acquisition/receiver/transferFunction"
  if exists(f.file, parameter)
    return readComplexArray(f.filename, parameter)
  else
    return nothing
  end
end
rxInductionFactor(f::MDFFileV1) = nothing
rxInductionFactor(f::MDFFileV2) = f["/acquisition/receiver/inductionFactor"]

rxUnit(f::MDFFileV1) = "a.u."
rxUnit(f::MDFFileV2) = f["/acquisition/receiver/unit"]
rxDataConversionFactor(f::MDFFileV1) = repeat([1.0, 0.0], outer=(1,rxNumChannels(f)))
rxDataConversionFactor(f::MDFFileV2) = f["/acquisition/receiver/dataConversionFactor"]

# measurements
function measData(f::MDFFileV1, frames=1:acqNumFrames(f), periods=1:acqNumPeriodsPerFrame(f),
                  receivers=1:rxNumChannels(f))
  if !exists(f.file, "/measurement")
    # the V1 file is a calibration
    data = f["/calibration/dataFD"]
    if ndims(data) == 4
      return reshape(reinterpret(Complex{eltype(data)}, vec(data)), (size(data,2),size(data,3),size(data,4),1))
    else
      return reshape(reinterpret(Complex{eltype(data)}, vec(data)), (size(data,2),size(data,3),size(data,4),size(data,5)))
    end
  end
  tdExists = exists(f.file, "/measurement/dataTD")

  if tdExists
    if f.mmap_measData == nothing
      f.mmap_measData = readmmap(f.file["/measurement/dataTD"])
    end
    data = zeros(Float64, rxNumSamplingPoints(f), length(receivers), length(frames))
    for (i,fr) in enumerate(frames)
      data[:,:,:,i] = f.mmap_measData[:, receivers, fr]
    end
    return reshape(data,size(data,1),size(data,2),1,size(data,3))
  else
    if f.mmap_measData == nothing
      f.mmap_measData = readmmap(f.file["/measurement/dataFD"])
    end
    data = zeros(Float64, 2, rxNumFrequencies(f), length(receivers), length(frames))
    for (i,fr) in enumerate(frames)
      data[:,:,:,i] = f.mmap_measData[:,:,receivers, fr]
    end

    dataFD = reshape(reinterpret(Complex{eltype(data)}, vec(data)), (size(data,2),size(data,3),size(data,4)))
    dataTD = irfft(dataFD, 2*(size(data,2)-1), 1)
    return reshape(dataTD,size(dataTD,1),size(dataTD,2),1,size(dataTD,3))
  end
end

function measData(f::MDFFileV2, frames=1:acqNumFrames(f), periods=1:acqNumPeriodsPerFrame(f),
                  receivers=1:rxNumChannels(f))

  if measIsTransposed(f)
    data = f.mmap_measData[frames, :, receivers, periods]
    data = reshape(data, length(frames), size(f.mmap_measData,2), length(receivers), length(periods))
  else
    data = f.mmap_measData[:, receivers, periods, frames]
    data = reshape(data, size(f.mmap_measData,1), length(receivers), length(periods), length(frames))
  end
  return data
end


function measDataTDPeriods(f::MDFFileV1, periods=1:acqNumPeriods(f),
                  receivers=1:rxNumChannels(f))
  tdExists = exists(f.file, "/measurement/dataTD")

  if tdExists
    if f.mmap_measData == nothing
      f.mmap_measData = readmmap(f.file["/measurement/dataTD"])
    end
    data = f.mmap_measData[:, receivers, periods]
    return data
  else
    if f.mmap_measData == nothing
      f.mmap_measData = readmmap(f.file["/measurement/dataFD"])
    end
    data = f.mmap_measData[:, :, receivers, periods]

    dataFD = reshape(reinterpret(Complex{eltype(data)}, vec(data)), (size(data,2),size(data,3),size(data,4)))
    dataTD = irfft(dataFD, 2*(size(data,2)-1), 1)
    return dataTD
  end
end


function measDataTDPeriods(f::MDFFileV2, periods=1:acqNumPeriods(f),
                  receivers=1:rxNumChannels(f))
  if measIsTransposed(f)
    error("measDataTDPeriods can currently not handle transposed data!")
  end

  data = reshape(f.mmap_measData,Val(3))[:, receivers, periods]

  return data
end

function systemMatrix(f::MDFFileV1, rows, bgCorrection=true)
  if !experimentIsCalibration(f)
    return nothing
  end
  if f.mmap_measData == nothing
    f.mmap_measData = readmmap(f.file["/calibration/dataFD"])
  end

  data = reshape(f.mmap_measData,Val(3))[:, :, rows]
  return reshape(reinterpret(Complex{eltype(data)}, vec(data)), (size(data,2),size(data,3)))
end

function systemMatrix(f::MDFFileV2, rows, bgCorrection=true)
  if !exists(f.file, "/measurement") || !measIsTransposed(f) ||
    !measIsFourierTransformed(f)
    return nothing
  end

  if measIsFrequencySelection(f)
    # In this case we need to convert indices
    tmp = zeros(Int64, rxNumFrequencies(f), rxNumChannels(f) )
    idxAvailable = measFrequencySelection(f)
    for d=1:rxNumChannels(f)
      tmp[idxAvailable, d] = (1:length(idxAvailable)) .+ (d-1)*length(idxAvailable)
    end
    rows_ = vec(tmp)[rows]
    if findfirst(x -> x == 0, rows_) != nothing
      @error "Indices applied to systemMatrix are not available in the file"
    end
  else
    rows_ = rows
  end

  data_ = reshape(f.mmap_measData, size(f.mmap_measData,1),
                                   size(f.mmap_measData,2)*size(f.mmap_measData,3),
                                   size(f.mmap_measData,4))[:, rows_, :]
  data = reshape(data_, Val(2))

  fgdata = data[measFGFrameIdx(f),:]

  if measIsBasisTransformed(f)
    dataBackTrafo = similar(fgdata, prod(calibSize(f)), size(fgdata,2))
    B = linearOperator(f["/measurement/basisTransformation"], calibSize(f))

    tmp = f["/measurement/basisIndices"]
    basisIndices_ = reshape(tmp, size(tmp,1),
                                     size(tmp,2)*size(tmp,3),
                                     size(tmp,4))[:, rows_, :]
    basisIndices = reshape(basisIndices_, Val(2))

    for l=1:size(fgdata,2)
      dataBackTrafo[:,l] .= 0.0
      dataBackTrafo[basisIndices[:,l],l] .= fgdata[:,l]
      dataBackTrafo[:,l] .= adjoint(B) * vec(dataBackTrafo[:,l])
    end
    fgdata = dataBackTrafo
  end

  if bgCorrection # this assumes equidistent bg frames
    @debug "Applying bg correction on system matrix (MDF)"
    bgdata = data[measBGFrameIdx(f),:]
    blockLen = measBGFrameBlockLengths( invpermute!(measIsBGFrame(f), measFramePermutation(f)) )
    st = 1
    for j=1:length(blockLen)
      bgdata[st:st+blockLen[j]-1,:] .=
           mean(bgdata[st:st+blockLen[j]-1,:], dims=1)
      st += blockLen[j]
    end

    bgdataInterp = interpolate(bgdata, (BSpline(Linear()), NoInterp()))
    # Cubic does not work for complex numbers
    origIndex = measFramePermutation(f)
    M = size(fgdata,1)
    K = size(bgdata,1)
    N = M + K
    for m=1:M
      alpha = (origIndex[m]-1)/(N-1)*(K-1)+1
      for k=1:size(fgdata,2)
        fgdata[m,k] -= bgdataInterp(alpha,k)
      end
    end
  end
  return fgdata
end

function systemMatrixWithBG(f::MDFFileV2)
  if !exists(f.file, "/measurement") || !measIsTransposed(f) ||
      !measIsFourierTransformed(f)
      return nothing
  end

  data = f.mmap_measData[:, :, :, :]
  return data
end

# This is a special variant used for matrix compression
function systemMatrixWithBG(f::MDFFileV2, freq)
  if !exists(f.file, "/measurement") || !measIsTransposed(f) ||
    !measIsFourierTransformed(f)
    return nothing
  end

  data = f.mmap_measData[:, freq, :, :]
  return data
end

function measIsFourierTransformed(f::MDFFileV1)
  if !experimentIsCalibration(f)
    return false
  else
    return true
  end
end
measIsFourierTransformed(f::MDFFileV2) = Bool(f["/measurement/isFourierTransformed"])

measIsTFCorrected(f::MDFFileV1) = false
measIsTFCorrected(f::MDFFileV2) = Bool(f["/measurement/isTransferFunctionCorrected"])

measIsSpectralLeakageCorrected(f::MDFFileV1) = false
measIsSpectralLeakageCorrected(f::MDFFileV2) = Bool(f["/measurement/isSpectralLeakageCorrected"])

function measIsBGCorrected(f::MDFFileV1)
  if !experimentIsCalibration(f)
    return false
  else
    return true
  end
end
measIsBGCorrected(f::MDFFileV2) = Bool(f["/measurement/isBackgroundCorrected"])

measIsFrequencySelection(f::MDFFileV1) = false
measIsFrequencySelection(f::MDFFileV2) = Bool(f["/measurement/isFrequencySelection"])
measFrequencySelection(f::MDFFileV2) = f["/measurement/frequencySelection"]

measIsBasisTransformed(f::MDFFileV1) = false
function measIsBasisTransformed(f::MDFFileV2)
  if exists(f.file, "/measurement/isBasisTransformed")
    Bool(f["/measurement/isBasisTransformed"])
  else
    return false
  end
end

function measIsTransposed(f::MDFFileV1)
  if !experimentIsCalibration(f)
    return false
  else
    return true
  end
end

function measIsTransposed(f::MDFFileV2)
  if exists(f.file, "/measurement/isFastFrameAxis")
    return Bool(f["/measurement/isFastFrameAxis"])
  else
    return Bool(f["/measurement/isTransposed"])
  end
end

function measIsFramePermutation(f::MDFFileV1)
  if !experimentIsCalibration(f)
    return false
  else
    return true
  end
end
measIsFramePermutation(f::MDFFileV2) = f["/measurement/isFramePermutation"]
measIsBGFrame(f::MDFFileV1) = zeros(Bool, acqNumFrames(f))
measIsBGFrame(f::MDFFileV2) = convert(Array{Bool},f["/measurement/isBackgroundFrame"])
measFramePermutation(f::MDFFileV1) = nothing
measFramePermutation(f::MDFFileV2) = f["/measurement/framePermutation"]
fullFramePermutation(f::MDFFile) = fullFramePermutation(f, calibIsMeanderingGrid(f))

#calibrations
calibSNR(f::MDFFileV1) = addTrailingSingleton(f["/calibration/snrFD"],3)
calibSNR(f::MDFFileV2) = f["/calibration/snr"]
calibFov(f::MDFFile) = f["/calibration/fieldOfView"]
calibFovCenter(f::MDFFile) = f["/calibration/fieldOfViewCenter"]
calibSize(f::MDFFile) = f["/calibration/size"]
calibOrder(f::MDFFile) = f["/calibration/order"]
calibOffsetField(f::MDFFile) = f["/calibration/offsetField"]
calibDeltaSampleSize(f::MDFFile) = f["/calibration/deltaSampleSize",[0.0,0.0,0.0]]
calibMethod(f::MDFFile) = f["/calibration/method"]
calibIsMeanderingGrid(f::MDFFile) = Bool(f["/calibration/isMeanderingGrid", 0])
calibPositions(f::MDFFile) = f["/calibration/positions"]

# reconstruction results
recoData(f::MDFFileV1) = addLeadingSingleton(
         f[ "/reconstruction/data"], 3)
recoData(f::MDFFileV2) = f["/reconstruction/data"]
recoFov(f::MDFFile) = f["/reconstruction/fieldOfView"]
recoFovCenter(f::MDFFile) = f["/reconstruction/fieldOfViewCenter"]
recoSize(f::MDFFile) = f["/reconstruction/size"]
recoOrder(f::MDFFile) = f["/reconstruction/order"]
recoPositions(f::MDFFile) = f["/reconstruction/positions"]

# this is non-standard
function recoParameters(f::MDFFile)
  if !exists(f.file, "/reconstruction/parameters")
    return nothing
  end
  return loadParams(f.file, "/reconstruction/parameters")
end

# additional functions that should be implemented by an MPIFile
filepath(f::MDFFile) = f.filename


# Helper functions
function addLeadingSingleton(a::Array,dim)
  if ndims(a) == dim
    return a
  else
    return reshape(a,1,size(a)...)
  end
end

function addTrailingSingleton(a::Array,dim)
  if ndims(a) == dim
    return a
  else
    return reshape(a,size(a)...,1)
  end
end
