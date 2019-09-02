export filterFrequencies

"""
  filterFrequencies(f; kargs...) => Vector{Int64}

Supported keyword arguments:
* SNRThresh
* minFreq
* maxFreq
* recChannels
* sortBySNR
* numUsedFreqs
* stepsize
* maxMixingOrder
* sortByMixFactors
"""
function filterFrequencies(f::MPIFile; SNRThresh=-1, minFreq=0,
               maxFreq=rxBandwidth(f), recChannels=1:rxNumChannels(f),
               sortBySNR=false, numUsedFreqs=-1, stepsize=1, maxMixingOrder=-1,
               sortByMixFactors=false)

  nFreq = rxNumFrequencies(f)
  nReceivers = rxNumChannels(f)
  nPeriods = 1 #acqNumPeriodsPerFrame(f)

  minIdx = floor(Int, minFreq / rxBandwidth(f) * (nFreq-1) ) + 1
  maxIdx = ceil(Int, maxFreq / rxBandwidth(f) * (nFreq-1) ) + 1

  freqMask = zeros(Bool,nFreq,nReceivers,nPeriods)

  freqMask[:,recChannels,:] .= true

  if measIsFrequencySelection(f)
    freqMask[:,recChannels,:] .= false
    idx = measFrequencySelection(f)
    freqMask[idx,recChannels,:] .= true
  else
    freqMask[:,recChannels,:] .= true
  end

  if minFreq > 0
    freqMask[1:(minIdx),:,:] .= false
  end

  if maxFreq < nFreq
    freqMask[(maxIdx):end,:,:] .= false
  end



  if maxMixingOrder > 0
      mf = mixingFactors(f)
      for l=1:size(mf,1)
        if mf[l,4] > maxMixingOrder || mf[l,4] > maxMixingOrder
          freqMask[(l-1)+1,recChannels] = false
        end
      end
  end

  if SNRThresh > 0 || numUsedFreqs > 0 || sortBySNR
    SNR = zeros(nFreq, nReceivers)
    idx = measIsFrequencySelection(f) ? measFrequencySelection(f) : idx = 1:nFreq

    SNR[idx,:] = calibSNR(f)[:,:,1]
  end

  if SNRThresh > 0 && numUsedFreqs > 0
    error("It is not possible to use SNRThresh and SNRFactorUsedFreq similtaneously")
  end

  if SNRThresh > 0
    freqMask[ findall(vec(SNR) .< SNRThresh) ] .= false
  end

  if numUsedFreqs > 0
    numFreqsAlreadyFalse = sum(!freqMask)
    numFreqsFalse = round(Int,length(freqMask)* (1-numUsedFreqs))
    S = sortperm(vec(SNR))

    l = 1
    j = 1
    while j<  (numFreqsFalse-numFreqsAlreadyFalse)
      if freqMask[S[l]] == true
        freqMask[S[l]] = false
        j += 1
      end
      l += 1
    end

  end


  if stepsize > 1
    freqStepsizeMask = zeros(Bool,nFreq, nReceivers, nPatches)
    freqStepsizeMask[1:stepsize:nFreq,:,:] = freqMask[1:stepsize:nFreq,:,:]
    freqMask = freqStepsizeMask
  end

  freq = findall( vec(freqMask) )

  if sortBySNR && !sortByMixFactors
    SNR = vec(SNR[1:stepsize:nFreq,:,:])

    freq = freq[reverse(sortperm(SNR[freq]),dims=1)]
  end

  if !sortBySNR && sortByMixFactors
    mfNorm = zeros(nFreq,nReceivers,nPeriods)
    mf = mixingFactors(f)
    for k=1:nFreq
      mfNorm[k,:,:] = norm(mf[k,1:3])
    end

    freq = freq[sortperm(mfNorm[freq])]
  end

  freq
end
