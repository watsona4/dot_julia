export acqNumFGFrames, acqNumBGFrames, acqOffsetFieldShift, acqFramePeriod,
       acqNumPeriods, acqNumPatches, acqNumPeriodsPerPatch, acqFov,
       acqGradientDiag,
       rxNumFrequencies, rxFrequencies, rxTimePoints,
       measFGFrameIdx, measBGFrameIdx, measBGFrameBlockLengths

rxNumFrequencies(f::MPIFile) = floor(Int,rxNumSamplingPoints(f) ./ 2 .+ 1)

function rxFrequencies(f::MPIFile)
  numFreq = rxNumFrequencies(f)
  a = collect(0:(numFreq-1))./(numFreq-1).*rxBandwidth(f)
  return a
end

function rxTimePoints(f::MPIFile)
  numTP = rxNumSamplingPoints(f)
  a = collect(0:(numTP-1))./(numTP).*dfCycle(f)
  return a
end

function acqGradientDiag(f::MPIFile)
  g = acqGradient(f)
  g_ = reshape(g,9,size(g,3),size(g,4))
  return g_[[1,5,9],:,:]
end

function acqFov(f::MPIFile)
  if size(dfStrength(f)[1,:,:],1) == 3
    return  2*dfStrength(f)[1,:,:] ./ abs.( acqGradientDiag(f)[:,1,:] )
  else
    return  2*dfStrength(f)[1,:,:] ./ abs.( acqGradientDiag(f)[1,1,1] )
  end
end

acqFramePeriod(b::MPIFile) = dfCycle(b) * acqNumAverages(b) * acqNumPeriodsPerFrame(b)

# numPeriods is the total number of DF periods in a measurement.
acqNumPeriods(f::MPIFile) = acqNumFrames(f)*acqNumPeriodsPerFrame(f)

function acqOffsetFieldShift(f::MPIFile)
    return acqOffsetField(f) ./ reshape( acqGradient(f),9,1,:)[[1,5,9],:,:]
end

acqNumFGFrames(f::MPIFile) = acqNumFrames(f) - acqNumBGFrames(f)
acqNumBGFrames(f::MPIFile) = sum(measIsBGFrame(f))

function measBGFrameIdx(f::MPIFile)
  idx = zeros(Int64, acqNumBGFrames(f))
  j = 1
  mask = measIsBGFrame(f)
  for i=1:acqNumFrames(f)
    if mask[i]
      idx[j] = i
      j += 1
    end
  end
  return idx
end

function measFGFrameIdx(f::MPIFile)
  mask = measIsBGFrame(f)
  if !any(mask)
    #shortcut
    return 1:acqNumFrames(f)
  end
  idx = zeros(Int64, acqNumFGFrames(f))
  j = 1
  for i=1:acqNumFrames(f)
    if !mask[i]
      idx[j] = i
      j += 1
    end
  end
  return idx
end


function measBGFrameBlockLengths(mask)
  len = Vector{Int}(undef,0)

  groupIdxStart = -1
  for i=1:(length(mask)+1)
    if i <= length(mask) && mask[i] && groupIdxStart == -1
      groupIdxStart = i
    end
    if groupIdxStart != -1 && ((i == length(mask)+1) || !mask[i])
      push!(len, i-groupIdxStart)
      groupIdxStart = - 1
    end
  end
  return len
end


function acqNumPatches(f::MPIFile)
  # not valid for varying gradients / multi gradient
  shifts = acqOffsetFieldShift(f)
  return size(unique(shifts,dims=3),3)
end

function acqNumPeriodsPerPatch(f::MPIFile)
  return div(acqNumPeriodsPerFrame(f), acqNumPatches(f))
end

export unflattenOffsetFieldShift

unflattenOffsetFieldShift(f::MPIFile) = unflattenOffsetFieldShift(acqOffsetFieldShift(f))
function unflattenOffsetFieldShift(shifts::Array)
  # not valid for varying gradients / multi gradient
  uniqueShifts = unique(shifts, dims=2)
  numPeriodsPerFrame = size(shifts,2)
  numUniquePatch = size(uniqueShifts,2)

  allPeriods = 1:numPeriodsPerFrame

  flatIndices = Vector{Vector{Int64}}()

  for i=1:numUniquePatch
    temp = allPeriods[vec(sum(shifts .== uniqueShifts[:,i],dims=1)).==3]
    push!(flatIndices, temp)
  end
  return flatIndices
end

# We assume that systemMatrixWithBG has already reordered the BG data
# to the end
systemMatrix(f::MPIFile) = systemMatrixWithBG(f)[1:acqNumFGFrames(f),:,:,:]

function measDataTD(f, frames=1:acqNumFrames(f), periods=1:acqNumPeriodsPerFrame(f),
                  receivers=1:rxNumChannels(f))

  data1 = measData(f,frames,periods,receivers)

  if measIsTransposed(f)
    data2 = permutedims(data1, invperm([4,1,2,3]))
  else
    data2 = data1
  end

  if measIsFourierTransformed(f)
    dataTD = irfft(data2,2*size(data2,1)-1, 1)
  else
    dataTD = data2
  end
  return dataTD
end
