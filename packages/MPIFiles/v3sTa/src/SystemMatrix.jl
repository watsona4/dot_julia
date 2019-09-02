export getSystemMatrix, getSystemMatrixReshaped, calculateSystemMatrixSNR

"""
  getSystemMatrix(f, [neglectBGFrames]; kargs...) => Array{ComplexF32,4}

Load the system matrix in frequency domain

Supported keyword arguments:
* frequencies
* bgCorrection
* loadasreal
"""
function getSystemMatrix(f::MPIFile,
           frequencies=1:rxNumFrequencies(f)*rxNumChannels(f);
                         bgCorrection=false, loadasreal=false,
                         kargs...)

  data = systemMatrix(f, frequencies, bgCorrection)

  S = map(ComplexF32, data)

  if loadasreal
    return converttoreal(S)
  else
    return S
  end
end

function getSystemMatrixReshaped(f::MPIFile; kargs...)
  return reshape(getSystemMatrix(f;kargs...),:,rxNumFrequencies(f),
                            rxNumChannels(f),acqNumPeriodsPerFrame(f))
end

function calculateSystemMatrixSNR(f::MPIFile)
  data = systemMatrixWithBG(f)
  SNR = calculateSystemMatrixSNR(f, data)
  return SNR
end

function calculateSystemMatrixSNR(f::MPIFile, S::Array)
  SNR = zeros(rxNumFrequencies(f),rxNumChannels(f),acqNumPeriodsPerFrame(f))
  for j=1:acqNumPeriodsPerFrame(f)
    for r=1:rxNumChannels(f)
      for k=1:rxNumFrequencies(f)
        diffBG = diff(S[(acqNumFGFrames(f)+1):end,k,r,j])
        meanBG = mean(S[(acqNumFGFrames(f)+1):end,k,r,j])
        signal = maximum(abs.(S[1:acqNumFGFrames(f),k,r,j].-meanBG))
        #noise = mean(abs.(S[(acqNumFGFrames(f)+1):end,k,r,j].-meanBG))
        noise = mean(abs.(diffBG))
        SNR[k,r,j] = signal / noise
      end
    end
  end
  SNR[:,:,:] .= mean(SNR,dims=3)
  return SNR
end

function converttoreal(S::AbstractArray{Complex{T},2}) where {T}
  N = size(S,1)
  M = size(S,2)
  S = reshape(reinterpret(T,vec(S)),(2*N,M))
  for l=1:M
    tmp = S[:,l]
    S[1:N,l] = tmp[1:2:end]
    S[N+1:end,l] = tmp[2:2:end]
  end
  return reshape(S,(N,2*M))
end
