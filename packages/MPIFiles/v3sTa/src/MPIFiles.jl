module MPIFiles

using AxisArrays
const axes = Base.axes
using Graphics: @mustimplement
using HDF5
using Interpolations
using RegularizedLeastSquares
using Reexport
using UUIDs

@reexport using Dates
@reexport using DelimitedFiles
@reexport using FFTW
@reexport using ImageAxes
@reexport using ImageMetadata
@reexport using LinearAlgebra
@reexport using Random
@reexport using Mmap
@reexport using Statistics
@reexport using Unitful

if VERSION < v"1.1"
  isnothing(x) = x == nothing
end

### global import list ###

import Base: convert, get, getindex, haskey, iterate, length, ndims, range, read, show, time, write
import FileIO: save
import HDF5: h5read
import Interpolations: interpolate

### export list ###

export MPIFile

# general parameters
export version, uuid

# study parameters
export studyName, studyNumber, studyUuid, studyDescription, studyTime

# experiment parameters
export experimentName, experimentNumber, experimentUuid, experimentDescription, experimentSubject,
      experimentIsSimulation, experimentIsCalibration,
      experimentHasMeasurement, experimentHasReconstruction

# tracer parameters
export tracerName, tracerBatch, tracerVolume, tracerConcentration,
       tracerSolute, tracerInjectionTime, tracerVendor

# scanner parameters
export scannerFacility, scannerOperator, scannerManufacturer, scannerName,
       scannerTopology

# acquisition parameters
export acqStartTime, acqNumFrames, acqNumAverages,
       acqGradient, acqOffsetField, acqNumPeriodsPerFrame, acqSize

# drive-field parameters
export dfNumChannels, dfStrength, dfPhase, dfBaseFrequency, dfCustomWaveform,
       dfDivider, dfWaveform, dfCycle

# receiver parameters
export rxNumChannels, rxBandwidth, rxNumSamplingPoints,
       rxTransferFunction, rxUnit, rxDataConversionFactor, rxInductionFactor

# measurements
export measData, measDataTDPeriods, measIsFourierTransformed, measIsTFCorrected,
       measIsBGCorrected, measIsTransposed,
       measIsFramePermutation, measIsFrequencySelection,
       measIsBGFrame, measIsSpectralLeakageCorrected, measFramePermutation,
       measFrequencySelection, measIsBasisTransformed

# calibrations
export calibSNR, calibFov, calibFovCenter, calibSize,
       calibOrder, calibPositions, calibOffsetField, calibDeltaSampleSize,
       calibMethod, calibIsMeanderingGrid

# reconstruction results
export recoData, recoFov, recoFovCenter, recoSize, recoOrder, recoPositions

# additional functions that should be implemented by an MPIFile
export filepath, systemMatrixWithBG, systemMatrix

export selectedChannels
### Interface of an MPIFile ###

abstract type MPIFile end

# general parameters
@mustimplement version(f::MPIFile)
@mustimplement uuid(f::MPIFile)
@mustimplement time(f::MPIFile)

# study parameters
@mustimplement studyName(f::MPIFile)
@mustimplement studyNumber(f::MPIFile)
@mustimplement studyUuid(f::MPIFile)
@mustimplement studyDescription(f::MPIFile)
@mustimplement studyTime(f::MPIFile)

# experiment parameters
@mustimplement experimentName(f::MPIFile)
@mustimplement experimentNumber(f::MPIFile)
@mustimplement experimentUuid(f::MPIFile)
@mustimplement experimentDescription(f::MPIFile)
@mustimplement experimentSubject(f::MPIFile)
@mustimplement experimentIsSimulation(f::MPIFile)
@mustimplement experimentIsCalibration(f::MPIFile)
@mustimplement experimentHasReconstruction(f::MPIFile)
@mustimplement experimentHasMeasurement(f::MPIFile)

# tracer parameters
@mustimplement tracerName(f::MPIFile)
@mustimplement tracerBatch(f::MPIFile)
@mustimplement tracerVolume(f::MPIFile)
@mustimplement tracerConcentration(f::MPIFile)
@mustimplement tracerSolute(f::MPIFile)
@mustimplement tracerInjectionTime(f::MPIFile)

# scanner parameters
@mustimplement scannerFacility(f::MPIFile)
@mustimplement scannerOperator(f::MPIFile)
@mustimplement scannerManufacturer(f::MPIFile)
@mustimplement scannerName(f::MPIFile)
@mustimplement scannerTopology(f::MPIFile)

# acquisition parameters
@mustimplement acqStartTime(f::MPIFile)
@mustimplement acqNumAverages(f::MPIFile)
@mustimplement acqNumPeriodsPerFrame(f::MPIFile)
@mustimplement acqNumFrames(f::MPIFile)
@mustimplement acqGradient(f::MPIFile)
@mustimplement acqOffsetField(f::MPIFile)

# drive-field parameters
@mustimplement dfNumChannels(f::MPIFile)
@mustimplement dfStrength(f::MPIFile)
@mustimplement dfPhase(f::MPIFile)
@mustimplement dfBaseFrequency(f::MPIFile)
@mustimplement dfCustomWaveform(f::MPIFile)
@mustimplement dfDivider(f::MPIFile)
@mustimplement dfWaveform(f::MPIFile)
@mustimplement dfCycle(f::MPIFile)

# receiver properties
@mustimplement rxNumChannels(f::MPIFile)
@mustimplement rxBandwidth(f::MPIFile)
@mustimplement rxNumSamplingPoints(f::MPIFile)
@mustimplement rxTransferFunction(f::MPIFile)
@mustimplement rxInductionFactor(f::MPIFile)
@mustimplement rxUnit(f::MPIFile)
@mustimplement rxDataConversionFactor(f::MPIFile)

# measurements
@mustimplement measData(f::MPIFile)
@mustimplement measDataTD(f::MPIFile)
@mustimplement measDataTDPeriods(f::MPIFile, periods)
@mustimplement measIsSpectralLeakageCorrected(f::MPIFile)
@mustimplement measIsFourierTransformed(f::MPIFile)
@mustimplement measIsTFCorrected(f::MPIFile)
@mustimplement measIsFrequencySelecton(f::MPIFile)
@mustimplement measIsBGCorrected(f::MPIFile)
@mustimplement measIsTransposed(f::MPIFile)
@mustimplement measIsFramePermutation(f::MPIFile)
@mustimplement measIsBGFrame(f::MPIFile)
@mustimplement measFramePermutation(f::MPIFile)
@mustimplement measIsBasisTransformed(f::MPIFile)

# calibrations
@mustimplement calibSNR(f::MPIFile)
@mustimplement calibFov(f::MPIFile)
@mustimplement calibFovCenter(f::MPIFile)
@mustimplement calibSize(f::MPIFile)
@mustimplement calibOrder(f::MPIFile)
@mustimplement calibPositions(f::MPIFile)
@mustimplement calibOffsetField(f::MPIFile)
@mustimplement calibDeltaSampleSize(f::MPIFile)
@mustimplement calibMethod(f::MPIFile)
@mustimplement calibIsMeanderingGrid(f::MPIFile)

# reconstruction results
@mustimplement recoData(f::MPIFile)
@mustimplement recoFov(f::MPIFile)
@mustimplement recoFovCenter(f::MPIFile)
@mustimplement recoSize(f::MPIFile)
@mustimplement recoOrder(f::MPIFile)
@mustimplement recoPositions(f::MPIFile)

# additional functions that should be implemented by an MPIFile
@mustimplement filepath(f::MPIFile)


include("Derived.jl")
include("Custom.jl")
include("Utils.jl")
include("FramePermutation.jl")

### Concrete implementations ###
include("MDF.jl")
include("Brukerfile.jl")
include("IMT.jl")

# This dispatches on the file extension and automatically
# generates the correct type
function MPIFile(filename::AbstractString; kargs...)
  filenamebase, ext = splitext(filename)
  if ext == ".mdf" || ext == ".hdf" || ext == ".h5"
    file = h5open(filename,"r")
    if exists(file, "/version")
      return MDFFile(filename, file) # MDFFile currently has no kargs
    else
      return IMTFile(filename, file; kargs...)
    end
  else
    if isfile(joinpath(filename,"mdf"))
      filenameMDF = readline(joinpath(filename,"mdf"))
      return MDFFile(filenameMDF)
    else
      return BrukerFile(filename; kargs...)
    end
  end
end

# Opens a set of MPIFiles
function MPIFile(filenames::Vector)
  return map(x->MPIFile(x),filenames)
end

include("MultiMPIFile.jl")
include("Measurements.jl")
include("SystemMatrix.jl")
include("FrequencyFilter.jl")
include("Conversion.jl")
include("RecoData.jl")
include("DatasetStore.jl")
include("MixingFactors.jl")
include("positions/Positions.jl")


end # module
