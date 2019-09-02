export MultiContrastFile
import Base: getindex, length, iterate

struct MultiContrastFile <: MPIFile
  files::Vector{MPIFile}

  function MultiContrastFile(filenames::Vector{String})
    return new([MPIFile(f) for f in filenames])
  end

  function MultiContrastFile(f::Vector{T}) where T<:MPIFile
    return new(f)
  end
end

getindex(f::MultiContrastFile, index::Integer) = f.files[index]
length(f::MultiContrastFile) = length(f.files)
start_(f::MultiContrastFile) = 1
next_(f::MultiContrastFile, state) = (f[state],state+1)
done_(f::MultiContrastFile, state) = state > length(f.files)
iterate(f::MultiContrastFile, s=start_(f)) = done_(f, s) ? nothing : next_(f, s)


function Base.show(io::IO, f::MultiContrastFile)
  print(io, "Multi Contrast File: ", f.files)
end

for op in [:filepath, :version, :uuid, :time, :studyName, :studyNumber, :studyUuid, :studyDescription,
            :experimentName, :experimentNumber, :experimentUuid, :experimentDescription,
            :experimentSubject, :experimentHasMeasurement,
            :experimentIsSimulation, :experimentIsCalibration, :experimentHasProcessing,
            :tracerName, :tracerBatch, :tracerVendor, :tracerVolume, :tracerConcentration,
            :tracerSolute, :tracerInjectionTime,
            :scannerFacility, :scannerOperator, :scannerManufacturer, :scannerName,
            :scannerTopology, :acqNumBGFrames, :acqGradient,
            :acqStartTime, :acqNumFrames, :acqNumPeriodsPerFrame,
            :dfNumChannels, :dfBaseFrequency, :dfDivider, :dfStrength, :dfPhase,
            :dfCycle, :dfWaveform, :rxNumChannels, :acqNumAverages, :rxBandwidth,
            :rxNumSamplingPoints, :rxTransferFunction, :rxInductionFactor, :rxUnit,
            :rxDataConversionFactor,
            :calibSNR, :calibFov, :calibFovCenter, #:calibSize,
            :calibOrder, :calibPositions, :calibOffsetField,
            :calibDeltaSampleSize, :calibMethod]
  @eval MPIFiles.$op(f::MultiContrastFile) = MPIFiles.$op(f.files[1])
end

measPath(bs::MultiContrastFile) = [measPath(b) for b in bs]
gridSize(bs::MultiContrastFile) = [gridSize(b) for b in bs]
calibSize(bs::MultiContrastFile) = [calibSize(b) for b in bs]
gridSizeCommon(bs::MultiContrastFile) = gridSize(bs[1])
fov(b::MultiContrastFile) = fov(b[1])

function filterFrequencies(bSFs::MultiContrastFile; kargs...) where {T<:MPIFile}
  return intersect([filterFrequencies(bSF; kargs...) for bSF in bSFs]...)
end


### deprecated ###
measPath(bs::Vector{T}) where {T<:MPIFile} = [measPath(b) for b in bs]
gridSize(bs::Vector{T}) where {T<:MPIFile} = [gridSize(b) for b in bs]
calibSize(bs::Vector{T}) where {T<:MPIFile} = [calibSize(b) for b in bs]
gridSizeCommon(bs::Vector{T}) where {T<:MPIFile} = gridSize(bs[1])
fov(b::Vector{T}) where {T<:MPIFile} = fov(b[1])
calibFov(b::Vector{T}) where {T<:MPIFile} = calibFov(b[1])

function filterFrequencies(bSFs::Vector{T}; kargs...) where {T<:MPIFile}
  return intersect([filterFrequencies(bSF; kargs...) for bSF in bSFs]...)
end
