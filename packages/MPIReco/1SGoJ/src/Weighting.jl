export getWeights, WeightingType, setFreqToZero

baremodule WeightingType
  None = 0
  Norm = 1
  MixingFactors = 2
  BGVariance = 3
  VarMeanThresh = 4
  Channel = 5
end

function getWeights(weightType, freq, S; weightingLimit=0.0, emptyMeas = nothing,
                 bgFrames=1:10, bMeas = nothing, fgFrames = 1:10, bSF=nothing,
                 channelWeights=[1.0,1.0,1.0])

  if weightType == WeightingType.None
    return nothing
  elseif weightType == WeightingType.Norm
    reciprocalWeights = rowEnergy(S)
  elseif weightType == WeightingType.MixingFactors
    error("This weighting mode has to be implemented")
  elseif weightType == WeightingType.Channel
    nFreq = rxNumFrequencies(bMeas)
    nReceivers = rxNumChannels(bMeas)
    weights = zeros(nFreq, nReceivers)

    if length(channelWeights) != nReceivers
      @error "channelWeights has wrong length"
    end

    for d=1:nReceivers
      weights[:,d] .= channelWeights[d]
    end
    return vec(weights)[freq]
  elseif weightType == WeightingType.BGVariance
    if bEmpty == nothing
      stdDevU = sqrt(vec(getBV(bSF)))
    else
      uEmpty = getMeasurementsFT(bEmpty,frames=bgFrames)
      stdDevU = sqrt(abs(var(uEmpty,3 )))
    end
    reciprocalWeights = stdDevU[freq]
  elseif weightType == WeightingType.VarMeanThresh

    nFreq = numFreq(bMeas)
    nReceivers = numReceivers(bMeas)
    freqMask = zeros(nFreq, nReceivers)

    u = getMeasurementsFT(bMeas,frames=fgFrames, spectralCleaning=true)
    uEmpty = getMeasurementsFT(bEmpty,frames=bgFrames, spectralCleaning=true)

    stdDevU = sqrt(abs(var(u,3 )))
    stdDevUEmpty = sqrt(abs(var(uEmpty,3 )))
    meanU = abs(mean(u,dims=3).-mean(uEmpty,dims=3))
    meanUEmpty = abs(mean(uEmpty, dims=3))

    for k=1:nFreq
      for r=1:nReceivers
        if stdDevU[k,r]/meanU[k,r] < 0.5
          freqMask[k,r] = 1
        else
          freqMask[k,r] = 1000
        end
      end
    end

    reciprocalWeights = vec(freqMask)[freq]
  end

  if weightingLimit>0

     m = maximum(reciprocalWeights)

     # The idea here is to only normalize those rows which have enough energy
     reciprocalWeights[ reciprocalWeights .< m*weightingLimit ] = m*weightingLimit
  end

  weights = copy(reciprocalWeights)

  for l=1:length(weights)
    weights[l] = 1 / reciprocalWeights[l].^2
  end

  return weights
end


function setNoiseFreqToZero(uMeas, freq, noiseFreqThresh; bEmpty = nothing, bgFrames=1:10, bMeas = nothing, fgFrames = 1:10)
  @debug "Setting noise frequencies to zero"

  nFreq = numFreq(bMeas)
  nReceivers = numReceivers(bMeas)
  freqMask = zeros(nFreq, nReceivers)

  u = getMeasurementsFT(bMeas,frames=fgFrames)
  uEmpty = getMeasurementsFT(bEmpty,frames=bgFrames)

  stdDevU = sqrt(abs(var(u,3 )))
  meanU = abs(mean(u,dims=3).-mean(uEmpty,dims=3))
  meanUEmpty = abs(mean(uEmpty,dims=3))

  for k=1:nFreq
    for r=1:nReceivers
      if stdDevU[k,r]/meanU[k,r] < noiseFreqThresh
        freqMask[k,r] = 1
      else
        freqMask[k,r] = 0
      end
    end
  end

  uMeas[:,:] .*=  vec(freqMask)[freq]
end
