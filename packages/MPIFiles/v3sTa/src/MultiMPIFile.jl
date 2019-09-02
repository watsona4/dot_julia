export MultiMPIFile

mutable struct MultiMPIFile <: MPIFile
  files::Vector{MPIFile}

  function MultiMPIFile(filenames::Vector{String})
    return new([MPIFile(f) for f in filenames])
  end

  function MultiMPIFile(f::Vector{T}) where T<:MPIFile
    return new(f)
  end

end

getindex(f::MultiMPIFile, index::Integer) = f.files[index]

length(f::MultiMPIFile) = length(f.files)

start_(f::MultiMPIFile) = 1
next_(f::MultiMPIFile,state) = (f[state],state+1)
done_(f::MultiMPIFile,state) = state > length(f.files)
iterate(f::MultiMPIFile, s=start_(f)) = done_(f, s) ? nothing : next_(f, s)


function Base.show(io::IO, f::MultiMPIFile)
  print(io, "Multi MPI File: ", f.files)
end

acqNumPeriodsPerFrame(f::MultiMPIFile) = length(f.files)*acqNumFrames(f.files[1])
acqNumFrames(f::MultiMPIFile) = 1

for op in [:filepath, :version, :uuid, :time, :studyName, :studyNumber, :studyTime, :studyUuid, :studyDescription,
            :experimentName, :experimentNumber, :experimentUuid, :experimentDescription,
            :experimentSubject, :experimentHasMeasurement,
            :experimentIsSimulation, :experimentIsCalibration, :experimentHasProcessing,
            :tracerName, :tracerBatch, :tracerVendor, :tracerVolume, :tracerConcentration,
            :tracerSolute, :tracerInjectionTime,
            :scannerFacility, :scannerOperator, :scannerManufacturer, :scannerName,
            :scannerTopology, :acqNumBGFrames,
            :acqStartTime,
            :dfNumChannels, :dfBaseFrequency, :dfDivider,
            :dfCycle, :dfWaveform, :rxNumChannels, :acqNumAverages, :rxBandwidth,
            :rxNumSamplingPoints, :rxTransferFunction, :rxInductionFactor, :rxUnit, :rxDataConversionFactor]
  @eval $op(f::MultiMPIFile) = $op(f.files[1])
end

for op in [ :dfStrength, :dfPhase ]
  @eval begin function $op(f::MultiMPIFile)
       tmp = $op(f.files[1])
       newVal = similar(tmp, size(tmp,1), size(tmp,2),
                        acqNumFrames(f.files[1]),length(f.files))
       for c=1:length(f.files)
         tmp = $op(f.files[c])
         for y=1:acqNumFrames(f.files[1])
           for a=1:size(tmp,1)
             for b=1:size(tmp,2)
               newVal[a,b,y,c] = tmp[a,b]
             end
           end
         end
       end
      return reshape(newVal,size(newVal,1),size(newVal,2),:)
    end
  end
end

function acqOffsetField(f::MultiMPIFile)
   tmp = acqOffsetField(f.files[1])
   newVal = similar(tmp, 3, acqNumFrames(f.files[1]),length(f.files))
   for c=1:length(f.files)
     tmp = acqOffsetField(f.files[c])
     for b=1:acqNumFrames(f.files[1])
       for a=1:3
           newVal[a,b,c] = tmp[a,1,1,1]
       end
     end
   end
  return reshape(newVal,3,1,:)
end

function acqGradient(f::MultiMPIFile)
   tmp = acqGradient(f.files[1])
   newVal = similar(tmp, 3, 3, acqNumFrames(f.files[1]),length(f.files))
   for c=1:length(f.files)
     tmp = acqGradient(f.files[c])
     for b=1:acqNumFrames(f.files[1])
       for a=1:3
         for d=1:3
             newVal[a,d,b,c] = tmp[a,d,1,1]
         end
       end
     end
   end
  return reshape(newVal,3,3,1,:)
end

for op in [:measIsFourierTransformed, :measIsTFCorrected,
           :measIsBGCorrected,
           :measIsTransposed, :measIsFramePermutation, :measIsFrequencySelection,
           :measIsSpectralLeakageCorrected,
           :measFramePermutation, :measIsBGFrame]
  @eval $op(f::MultiMPIFile) = $op(f.files[1])
end


experimentHasReconstruction(f::MultiMPIFile) = false

## Achtung hack in der Schleife acqNumFrames(fi) statt acqNumFrames(f)
# notwendig, da hier Sprung zwischen MultiMPIFile und MPIFile
function measData(f::MultiMPIFile, frames=1:acqNumFrames(f), periods=1:acqNumPeriodsPerFrame(f),
                  receivers=1:rxNumChannels(f))
  data = zeros(Float32, rxNumSamplingPoints(f), length(receivers),
                        length(frames),length(periods))
  #for (i,p) in enumerate(periods)
  #  data[:,:,:,i,:] = measData(f.files[p], frames, 1, receivers)
  #end
  for (i,fi) in enumerate(f.files)
    fr_fi=acqNumFrames(fi)
    data[:,:,:,fr_fi*(i-1)+1:fr_fi*i] = measData(fi, 1:fr_fi, 1, receivers)
  end
  return reshape(data,size(data,1),size(data,2),:,1)
end

function measDataTDPeriods(f::MultiMPIFile, periods=1:acqNumPeriods(f),
              receivers=1:rxNumChannels(f))

  data = zeros(Float32, rxNumSamplingPoints(f), length(receivers), length(periods))
  for (i,p) in enumerate(periods)
    l = divrem(p-1, acqNumPeriods(f.files[1]) )
    data[:,:,i] = measDataTDPeriods(f.files[l[1]+1], l[2]+1, receivers)
  end

  return data
end


# TODO: define functions for multi calibration data
#  if experimentIsCalibration(f)
#    for op in [:calibSNR, :calibFov, :calibFovCenter,
#               :calibSize, :calibOrder, :calibPositions, :calibOffsetField,
#               :calibDeltaSampleSize, :calibMethod]
#      setparam!(params, string(op), eval(op)(f))
#    end
#  end
