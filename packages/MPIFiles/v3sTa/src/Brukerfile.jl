include("Jcampdx.jl")

export BrukerFile, BrukerFileMeas, BrukerFileCalib, BrukerFileFast, latin1toutf8, 
       sfPath, rawDataLengthConsistent

function latin1toutf8(str::AbstractString)
  buff = Char[]
  for c in Vector{UInt8}(str)
    push!(buff,c)
  end
  string(buff...)
end

function latin1toutf8(str::Nothing)
  error("Can not convert noting to UTF8!")
end

abstract type BrukerFile <: MPIFile end

mutable struct BrukerFileMeas <: BrukerFile
  path::String
  params::JcampdxFile
  paramsProc::JcampdxFile
  methodRead
  acqpRead
  visupars_globalRead
  recoRead
  methrecoRead
  visuparsRead
  mpiParRead
  maxEntriesAcqp
end

mutable struct BrukerFileCalib <: BrukerFile
  path::String
  params::JcampdxFile
  paramsProc::JcampdxFile
  methodRead
  acqpRead
  visupars_globalRead
  recoRead
  methrecoRead
  visuparsRead
  mpiParRead
  maxEntriesAcqp
end

function _iscalib(path::AbstractString)
    calib = false
    acqpPath = joinpath(path,"acqp")
    if isfile(acqpPath)
        open(acqpPath, "r") do io
            for line in eachline(io)
                if !isnothing(findfirst("MPICalibration",line))
                    calib = true
                    break
                end
            end
        end
    end
    return calib
end

function BrukerFile(path::String; isCalib=_iscalib(path), maxEntriesAcqp=2000)
  params = JcampdxFile()
  paramsProc = JcampdxFile()

  if isCalib
    return BrukerFileCalib(path, params, paramsProc, false, false, false,
               false, false, false, false, maxEntriesAcqp)
  else
    return BrukerFileMeas(path, params, paramsProc, false, false, false,
               false, false, false, false, maxEntriesAcqp)
  end
end

function BrukerFile()
  params = JcampdxFile()
  paramsProc = JcampdxFile()
  return BrukerFileMeas("", params, paramsProc, false, false, false,
             false, false, false, false, 1)
end

BrukerFileFast(path) = BrukerFile(path, maxEntriesAcqp=400)

function getindex(b::BrukerFile, parameter)#::String
  if !b.acqpRead && ( parameter=="NA" || parameter[1:3] == "ACQ" )
    acqppath = joinpath(b.path, "acqp")
    read(b.params, acqppath, maxEntries=b.maxEntriesAcqp)
    b.acqpRead = true
  elseif !b.methodRead && length(parameter) >= 3 &&
         (parameter[1:3] == "PVM" || parameter[1:3] == "MPI")
    methodpath = joinpath(b.path, "method")
    read(b.params, methodpath)
    b.methodRead = true
  elseif !b.visupars_globalRead && length(parameter) >= 4 &&
         parameter[1:4] == "Visu"
    visupath = joinpath(b.path, "visu_pars")
    if isfile(visupath)
      keylist = ["VisuStudyId","VisuStudyNumber","VisuExperimentNumber",
		 "VisuSubjectId","VisuSubjectName","VisuStudyDate", "VisuUid","VisuStudyUid"]
      read(b.params, visupath,keylist)
      b.visupars_globalRead = true
    end
  elseif !b.mpiParRead && length(parameter) >= 6 &&
         parameter[1:6] == "CONFIG"
    mpiParPath = joinpath(b.path, "mpi.par")
    if isfile(mpiParPath)
      read(b.params, mpiParPath)
      b.mpiParRead = true
    end
  end

  if haskey(b.params, parameter)
    return b.params[parameter]
  else
    return ""
  end
end

function getindex(b::BrukerFile, parameter, procno::Int64)#::String
  if !b.recoRead && lowercase( parameter[1:4] ) == "reco"
    recopath = joinpath(b.path, "pdata", string(procno), "reco")
    read(b.paramsProc, recopath, maxEntries=13)
    b.recoRead = true
  elseif !b.methrecoRead && parameter[1:3] == "PVM"
    methrecopath = joinpath(b.path, "pdata", string(procno), "methreco")
    read(b.paramsProc, methrecopath)
    b.methrecoRead = true
  elseif !b.visuparsRead && parameter[1:4] == "Visu"
    visuparspath = joinpath(b.path, "pdata", string(procno), "visu_pars")
    if isfile(visuparspath)
      read(b.paramsProc, visuparspath)
      b.visuparsRead = true
    end
  end

  return b.paramsProc[parameter]
end

function Base.show(io::IO, b::BrukerFile)
  print(io, "BrukerFile: ", b.path)
end

# Helper
activeChannels(b::BrukerFile) = [parse(Int64,s) for s=b["PVM_MPI_ActiveChannels"]]
selectedChannels(b::BrukerFile) = b["PVM_MPI_ChannelSelect"] .== "Yes"
selectedReceivers(b::BrukerFile) = b["ACQ_ReceiverSelect"] .== "Yes"

# general parameters
version(b::BrukerFile) = nothing
uuid(b::BrukerFile) = nothing
time(b::BrukerFile) = nothing

# study parameters
studyName(b::BrukerFile) = latin1toutf8(b["VisuStudyId"])
# old study name
studyNameOld(b::BrukerFile) = string(latin1toutf8(b["VisuSubjectId"])*latin1toutf8(b["VisuSubjectName"]),"_",
                                  latin1toutf8(b["VisuStudyId"]),"_",
                                  b["VisuStudyNumber"])
studyNumber(b::BrukerFile) = parse(Int64,b["VisuStudyNumber"])
function studyUuid(b::BrukerFile)
  rng = MersenneTwister(hash(b["VisuStudyUid"])) # use VisuStudyUid as seed to generate uuid4
  return uuid4(rng)	
end
studyDescription(b::BrukerFile) = "n.a."
function studyTime(b::BrukerFile)
  m = match(r"<(.+)\+",b["VisuStudyDate"])
  timeString = replace(m.captures[1],"," => ".")
  return DateTime( timeString )
end

# study parameters
experimentName(b::BrukerFile) = latin1toutf8(b["ACQ_scan_name"])
experimentNumber(b::BrukerFile) = parse(Int64,b["VisuExperimentNumber"])
function experimentUuid(b::BrukerFile)
  rng = MersenneTwister(hash(b["VisuUid"])) # use VisuUid as seed to generate uuid4
  return uuid4(rng)	
end
experimentDescription(b::BrukerFile) = latin1toutf8(b["ACQ_scan_name"])
function experimentSubject(b::BrukerFile) 
  id = latin1toutf8(b["VisuSubjectId"])
  name = latin1toutf8(b["VisuSubjectName"])
  if id == name
    return id
  else
    return id*name
  end
end
experimentIsSimulation(b::BrukerFile) = false
experimentIsCalibration(b::BrukerFile) = _iscalib(b.path)
experimentHasProcessing(b::BrukerFile) = experimentIsCalibration(b)
experimentHasReconstruction(b::BrukerFile) = false # fixme later
experimentHasMeasurement(b::BrukerFile) = true

# tracer parameters
tracerName(b::BrukerFile) = [b["PVM_MPI_Tracer"]]
tracerBatch(b::BrukerFile) = [b["PVM_MPI_TracerBatch"]]
tracerVolume(b::BrukerFile) = [parse(Float64,b["PVM_MPI_TracerVolume"])*1e-6]
tracerConcentration(b::BrukerFile) = [parse(Float64,b["PVM_MPI_TracerConcentration"])]
tracerSolute(b::BrukerFile) = ["Fe"]
function tracerInjectionTime(b::BrukerFile)
  initialFrames = b["MPI_InitialFrames"]
  if initialFrames == ""
    return [acqStartTime(b)]
  else
    return [acqStartTime(b) + Dates.Millisecond(
       round(Int64,parse(Int64, initialFrames)*dfCycle(b)*1000 ) )]
  end
end
tracerVendor(b::BrukerFile) = ["n.a."]

# scanner parameters
scannerFacility(b::BrukerFile) = latin1toutf8(b["ACQ_institution"])
scannerOperator(b::BrukerFile) = latin1toutf8(b["ACQ_operator"])
scannerManufacturer(b::BrukerFile) = "Bruker/Philips"
scannerName(b::BrukerFile) = b["ACQ_station"]
scannerTopology(b::BrukerFile) = "FFP"

# acquisition parameters
function acqStartTime(b::BrukerFile)
  if b["ACQ_time"]==""
    m = match(r"<(.+)\+","<0000-01-01T00:00:00,000+000>")
    timeString = replace(m.captures[1],"," => ".")
    return DateTime( timeString )
  else
    m = match(r"<(.+)\+",b["ACQ_time"])
    timeString = replace(m.captures[1],"," => ".")
    return DateTime( timeString )
  end
end
function acqNumFrames(b::BrukerFileMeas)
  M = Int64(b["ACQ_jobs"][1][8])
  return div(M,acqNumPeriodsPerFrame(b))
end

function acqNumFrames(b::BrukerFileCalib)
  M = parse(Int64,b["PVM_MPI_NrCalibrationScans"])
  A_ = b["PVM_MPI_NrBackgroundMeasurementCalibrationAdditionalScans"]
  A = (A_ == "") ? 0 : parse(Int64, A_)
  return div(M-A,acqNumPeriodsPerFrame(b))
end

function acqNumPatches(b::BrukerFile)
  M = b["MPI_NSteps"]
  return (M == "") ? 1 : parse(Int64,M)
end
function acqNumPeriodsPerFrame(b::BrukerFile)
  M = b["MPI_RepetitionsPerStep"]
  N = acqNumPatches(b)
  return (M == "") ? N : N*parse(Int64,M)
end

acqNumAverages(b::BrukerFileMeas) = parse(Int,b["NA"])
acqNumAverages(b::BrukerFileCalib) = parse(Int,b["NA"])*numSubPeriods(b)


function acqNumBGFrames(b::BrukerFile)
  n = b["PVM_MPI_NrBackgroundMeasurementCalibrationAllScans"]
  a = b["PVM_MPI_NrBackgroundMeasurementCalibrationAdditionalScans"]
  if n == ""
    n = "0"
  end
  if a == ""
    a = "0"
  end
    
  return parse(Int64,n)-parse(Int64,a)
end

function acqGradient(b::BrukerFile)
  G1::Float64 = parse(Float64,b["ACQ_MPI_selection_field_gradient"])
  G2 = Matrix(Diagonal([-0.5;-0.5;1.0])) .* G1

  G = zeros(3,3,1,acqNumPeriodsPerFrame(b))
  G[:,:,1,:] .= G2
  return G
end

function acqOffsetField(b::BrukerFile) #TODO NOT correct
  if b["MPI_FocusFieldX"] != ""
    off = repeat(1e-3 * cat([parse(Float64,a) for a in b["MPI_FocusFieldX"]],
                 [parse(Float64,a) for a in b["MPI_FocusFieldY"]],
                 [parse(Float64,a) for a in b["MPI_FocusFieldZ"]],dims=2)',inner=(1,acqNumPeriodsPerPatch(b)))
  elseif b["CONFIG_MPI_FF_calibration"] != ""
    voltage = [parse(Float64,s) for s in b["ACQ_MPI_frame_list"]]
    voltage = reshape(voltage,4,:)
    voltage = repeat(voltage,inner=(1,acqNumPeriodsPerPatch(b)))
    calibFac = 1.0 / 100000 ./ parse.(Float64,b["CONFIG_MPI_FF_calibration"])
    off = Float64[voltage[d,j]*calibFac[d-1] for d=2:4, j=1:acqNumPeriodsPerFrame(b)]
  else # legacy
    voltage = [parse(Float64,s) for s in b["ACQ_MPI_frame_list"]]
    voltage = reshape(voltage,4,:)
    voltage = repeat(voltage,inner=(1,acqNumPeriodsPerPatch(b)))
    calibFac = [2.5 / 49.45, 0.5 * (-2.5)*0.008/22.73, 0.5*2.5*0.008/22.73, -1.5*0.0094/13.2963]
    off = Float64[voltage[d,j]*calibFac[d] for d=2:4, j=1:acqNumPeriodsPerFrame(b)]
  end
  return reshape(off, 3, 1, :)
end


# drive-field parameters
dfNumChannels(b::BrukerFile) = sum( selectedReceivers(b)[1:3] .== true )
   #sum( dfStrength(b)[1,:,1] .> 0) #TODO Not sure about this
function dfStrength(b::BrukerFile)
  str::Vector{String} = b["ACQ_MPI_drive_field_strength"]
  df = parse.(Float64,str) * 1e-3
  dfr = zeros(1,length(df),acqNumPeriodsPerFrame(b))
  dfr[1,:,:] .= df
  return dfr
end
dfPhase(b::BrukerFile) = dfStrength(b) .*0 .+  1.5707963267948966 # Bruker specific!
dfBaseFrequency(b::BrukerFile) = 2.5e6
dfCustomWaveform(b::BrukerFile) = nothing
dfDivider(b::BrukerFile) = reshape([102; 96; 99],:,1)
dfWaveform(b::BrukerFile) = "sine"
dfCycle(b::BrukerFile) = parse(Float64,b["PVM_MPI_DriveFieldCycle"]) / 1000 / numSubPeriods(b)

# receiver parameters
rxNumChannels(b::BrukerFile) = sum( selectedReceivers(b)[1:3] .== true )
rxBandwidth(b::BrukerFile) = parse(Float64,b["PVM_MPI_Bandwidth"])*1e6
rxNumSamplingPoints(b::BrukerFile) = div(parse(Int64,b["ACQ_size"][1]),numSubPeriods(b))
rxTransferFunction(b::BrukerFile) = nothing
rxInductionFactor(b::BrukerFile) = nothing
rxUnit(b::BrukerFile) = "a.u."
rxDataConversionFactor(b::BrukerFileMeas) =
                 repeat([1.0/acqNumAverages(b), 0.0], outer=(1,rxNumChannels(b)))
rxDataConversionFactor(b::BrukerFileCalib) =
                 repeat([1.0, 0.0], outer=(1,rxNumChannels(b)))

function rawDataLengthConsistent(b::BrukerFile)
  dataFilename = joinpath(b.path,"rawdata.job0")
  dType = acqNumAverages(b) == 1 ? Int16 : Int32

  # We derive numFrames from ACQ_jobs, since calibration files
  # are a bit longer than our acqNumFrames function reports
  # Bruker is padding the file for later processing
  numFrames = Int64(b["ACQ_jobs"][1][8])

  N = rxNumSamplingPoints(b)*numSubPeriods(b)*rxNumChannels(b)*
      acqNumPeriodsPerFrame(b)*numFrames*sizeof(dType)

  M = filesize(dataFilename)
  if N != M
    @show N M
  end
  return N == M
end

function measData(b::BrukerFileMeas, frames=1:acqNumFrames(b), periods=1:acqNumPeriodsPerFrame(b),
                  receivers=1:rxNumChannels(b))

  dataFilename = joinpath(b.path,"rawdata.job0")
  dType = acqNumAverages(b) == 1 ? Int16 : Int32

  s = open(dataFilename)

  if numSubPeriods(b) == 1
    raw = Mmap.mmap(s, Array{dType,4},
             (rxNumSamplingPoints(b),rxNumChannels(b),acqNumPeriodsPerFrame(b),acqNumFrames(b)))
  else
    raw = Mmap.mmap(s, Array{dType,5},
             (rxNumSamplingPoints(b),numSubPeriods(b),rxNumChannels(b),acqNumPeriodsPerFrame(b),acqNumFrames(b)))
    raw = dropdims(sum(raw,dims=2),dims=2)
  end
  data = raw[:,receivers,periods,frames]
  close(s)

  return reshape(data, rxNumSamplingPoints(b), length(receivers),length(periods),length(frames))
end

function measData(b::BrukerFileCalib, frames=1:acqNumFrames(b), periods=1:acqNumPeriodsPerFrame(b),
                  receivers=1:rxNumChannels(b))

  sfFilename = joinpath(b.path,"pdata", "1", "systemMatrix")
  nFreq = div(rxNumSamplingPoints(b)*numSubPeriods(b),2)+1

  s = open(sfFilename)
  data = Mmap.mmap(s, Array{ComplexF64,4}, (prod(calibSize(b)),nFreq,rxNumChannels(b),1))
  #S = data[:,:,:,:]
  S = map(ComplexF32, data)
  close(s)
  rmul!(S,1.0/acqNumAverages(b))

  bgFilename = joinpath(b.path,"pdata", "1", "background")

  s = open(bgFilename)
  data = Mmap.mmap(s, Array{ComplexF64,4}, (acqNumBGFrames(b),nFreq,rxNumChannels(b),1))
  #bgdata = data[:,:,:,:]
  bgdata = map(ComplexF32, data)
  close(s)
  rmul!(bgdata,1.0/acqNumAverages(b))
  S_ = cat(S,bgdata,dims=1)
  if numSubPeriods(b) == 1
    return S_
  else
    return S_[:,1:numSubPeriods(b):end,:,:]
  end
end


function measDataTDPeriods(b::BrukerFile, periods=1:acqNumPeriods(b),
                  receivers=1:rxNumChannels(b))

  dataFilename = joinpath(b.path,"rawdata.job0")
  dType = acqNumAverages(b) == 1 ? Int16 : Int32

  s = open(dataFilename)
  if numSubPeriods(b) == 1
    raw = Mmap.mmap(s, Array{dType,3},
    (rxNumSamplingPoints(b),rxNumChannels(b),acqNumPeriods(b)))
  else
    raw = Mmap.mmap(s, Array{dType,4},
    (rxNumSamplingPoints(b),numSubPeriods(b),rxNumChannels(b),acqNumPeriods(b)))
    raw = dropdims(sum(raw,2),dims=2)
  end
  data = raw[:,receivers,periods]
  close(s)

  return reshape(data, rxNumSamplingPoints(b), length(receivers),length(periods))
end

systemMatrixWithBG(b::BrukerFileCalib) = measData(b)

# This is a special variant used for matrix compression
function systemMatrixWithBG(b::BrukerFileCalib, freq)
  sfFilename = joinpath(b.path,"pdata", "1", "systemMatrix")
  nFreq = div(rxNumSamplingPoints(b)*numSubPeriods(b),2)+1

  s = open(sfFilename)
  data = Mmap.mmap(s, Array{ComplexF64,4}, (prod(calibSize(b)),nFreq,rxNumChannels(b),1))
  #S = data[:,:,:,:]
  S = map(ComplexF32, data[:,freq,:,:])
  close(s)
  rmul!(S,1.0/acqNumAverages(b))

  bgFilename = joinpath(b.path,"pdata", "1", "background")

  s = open(bgFilename)
  data = Mmap.mmap(s, Array{ComplexF64,4}, (acqNumBGFrames(b),nFreq,rxNumChannels(b),1))
  #bgdata = data[:,:,:,:]
  bgdata = map(ComplexF32, data[:,freq,:,:])
  close(s)
  rmul!(bgdata,1.0/acqNumAverages(b))
  S_ = cat(S,bgdata,dims=1)
  if numSubPeriods(b) == 1
    return S_
  else
    return S_[:,1:numSubPeriods(b):end,:,:]
  end
end

function systemMatrix(b::BrukerFileCalib, rows, bgCorrection=true)

  localSFFilename = bgCorrection ? "systemMatrixBG" : "systemMatrix"
  sfFilename = joinpath(b.path,"pdata", "1", localSFFilename)
  nFreq = div(rxNumSamplingPoints(b)*numSubPeriods(b),2)+1

  if numSubPeriods(b) > 1
    rows_ = collect(rows)
    NFreq = rxNumFrequencies(b)
    NRx = rxNumChannels(b)
    stepsize = numSubPeriods(b)
    for k=1:length(rows)
      freq = mod1(rows[k],NFreq)
      rec = div(rows[k]-1,NFreq)
      rows_[k] = (freq-1)*stepsize+1 + rec*nFreq
    end
  else
    rows_ = rows
  end

  s = open(sfFilename)
  data = Mmap.mmap(s, Array{ComplexF64,2}, (prod(calibSize(b)),nFreq*rxNumChannels(b)))
  S = data[:,rows_]
  close(s)
  rmul!(S, 1.0/acqNumAverages(b))
  return S
end

measIsFourierTransformed(b::BrukerFileMeas) = false
measIsFourierTransformed(b::BrukerFileCalib) = true
measIsTFCorrected(b::BrukerFile) = false
measIsBGCorrected(b::BrukerFileMeas) = false
# We have it, but by default we pretend that it is not applied
measIsBGCorrected(b::BrukerFileCalib) = false

measIsTransposed(b::BrukerFileMeas) = false
measIsTransposed(b::BrukerFileCalib) = true

measIsFramePermutation(b::BrukerFileMeas) = false
measIsFramePermutation(b::BrukerFileCalib) = true

function measIsBGFrame(b::BrukerFileMeas)
  if !experimentIsCalibration(b)
    # If the file is not a calibration file we cannot say if any particular scans
    # were BG scans
    return zeros(Bool, acqNumFrames(b))
  else
    # In case of a calibration file we know the particular indices corresponding
    # to BG measurements
    isBG = zeros(Bool, acqNumFrames(b))
    increment = parse(Int,b["PVM_MPI_BackgroundMeasurementCalibrationIncrement"])+1
    isBG[1:increment:end] .= true

    return isBG
  end
end

# If the file is considered to be a calibration file, we will load
# the measurement in a processed form. In that case the BG measurements
# will be put at the end of the frame dimension.
measIsBGFrame(b::BrukerFileCalib) =
   cat(zeros(Bool,acqNumFGFrames(b)),ones(Bool,acqNumBGFrames(b)),dims=1)

# measurements are not permuted
measFramePermutation(b::BrukerFileMeas) = nothing
# calibration scans are permuted
function measFramePermutation(b::BrukerFileCalib)
  # The following is a trick to obtain the permutation applied to the measurements
  # in a calibration measurement.
  bMeas = BrukerFile(b.path, isCalib=false)

  return fullFramePermutation(bMeas)
end

fullFramePermutation(f::BrukerFile) = fullFramePermutation(f, true)

measIsSpectralLeakageCorrected(b::BrukerFile) = get(b.params, "ACQ_MPI_spectral_cleaningl", "No") != "No"
measIsFrequencySelection(b::BrukerFile) = false
measIsBasisTransformed(b::BrukerFile) = false

# calibrations
function calibSNR(b::BrukerFile)
  snrFilename = joinpath(b.path,"pdata", "1", "snr")
  nFreq = div(rxNumSamplingPoints(b)*numSubPeriods(b),2)+1
  s = open(snrFilename)
  data = Mmap.mmap(s, Array{Float64,3}, (nFreq,rxNumChannels(b),1))
  snr = data[:,:,:]
  close(s)

  if numSubPeriods(b) == 1
    return snr
  else
    return snr[1:numSubPeriods(b):end,:,:]
  end
end
calibFov(b::BrukerFile) = [parse(Float64,s) for s = b["PVM_Fov"] ] * 1e-3
calibFovCenter(b::BrukerFile) =
          [parse(Float64,s) for s = b["PVM_MPI_FovCenter"] ] * 1e-3
calibSize(b::BrukerFile) = [parse(Int64,s) for s in b["PVM_Matrix"]]
calibOrder(b::BrukerFile) = "xyz"
calibPositions(b::BrukerFile) = nothing
calibOffsetField(b::BrukerFile) = nothing
calibDeltaSampleSize(b::BrukerFile) = [0.0, 0.0, 0.0] #TODO
calibMethod(b::BrukerFile) = "robot"
calibIsMeanderingGrid(b::BrukerFile) = true


# additional functions that should be implemented by an MPIFile
filepath(b::BrukerFile) = b.path



# special additional methods
function sfPath(b::BrukerFile)
  tmp = b["PVM_MPI_FilenameSystemMatrix",1]
  m = match(r"^(.+)\/pdata",tmp)
  return string(m.captures[1])
end

### The following is for field measurements from Alex Webers method
numCurrentSettings(b::BrukerFile) = parse(Int64,b["MPI_NrCurrentSettings"])
function currentSetting(b::BrukerFile)
  c = Float64[]
  for s in b["MPI_CurrentSetting"]
    append!(c,s)
  end
  return reshape(c,4,div(length(c),4))
end
ballRadius(b::BrukerFile) = parse(Float64,b["MPI_BallRadius"])
numLatitude(b::BrukerFile) = parse(Int64,b["MPI_NrLatitude"])
numMeridian(b::BrukerFile) = parse(Int64,b["MPI_NrMeridian"])

"""
This function is used as a workaround that no 1D and 2D sequences
were functional. Therefore we acquired 3D data and set the corresponding
drive-field amplitude to zero. Stepsize is then the number of period that
fit into the full 3D sequence.
"""
function numSubPeriods(f::BrukerFile)
  df = dfStrength(f)
  active_divider = copy(dfDivider(f))
  selected_channels = selectedChannels(f)

  for d=1:3
    active_divider[d] = (df[d] >= 0.0000001 && selected_channels[d]) ?
                         active_divider[d] : 1
  end
  floor(Int,(lcm(dfDivider(f)[selected_channels]) / lcm(active_divider)))
end

##### Reco





function recoData(f::BrukerFile)
  recoFilename = joinpath(f.path,"pdata", "1", "2dseq")
  N = recoSize(f)

  #if f["RECO_wordtype",1] != "_16BIT_SGN_INT"
  #  @error "Not yet implemented!"
  #end

  I = open(recoFilename,"r") do fd
    read!(fd,Array{Int16,3}(undef,1,prod(N),1))
  end
  return map(Float32,I)
end

recoResolution(f::BrukerFile) = push!(parse.(Float64,f["PVM_SpatResol"])./1000,
                                parse(Float64,f["ACQ_slice_thick"])./1000)

recoFov(f::BrukerFile) = recoResolution(f).*recoSize(f)

recoFovCenter(f::BrukerFile) = zeros(3)
recoSize(f::BrukerFile) = push!(parse.(Int,f["RECO_size",1]),
                                parse(Int,f["RecoObjectsPerRepetition",1]))
#recoOrder(f::BrukerFile) = f["/reconstruction/order"]
#recoPositions(f::BrukerFile) = f["/reconstruction/positions"]

###############################
# delta sample functions
###############################

export deltaSampleConcentration, deltaSampleVolume

function deltaSampleConcentration(b::BrukerFile)
 tmp = b["PVM_MPI_TracerConcentration"]
 if tmp != nothing
   return parse(Float64, tmp)
 else
   return 1.0
 end
end

deltaSampleConcentration(b::Array{T,1}) where {T<:BrukerFile} =
    map(deltaSampleConcentration, b)

function deltaSampleVolume(b::BrukerFile)
 V = parse(Float64, b["PVM_MPI_TracerVolume"] )*1e-6 # mu l
 return V
end
