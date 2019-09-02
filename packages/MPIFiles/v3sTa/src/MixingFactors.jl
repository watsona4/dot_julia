####### Mixing factor functions #########

export mixFactorToFreq, mixFactorToFreqIdx, mixingFactors


"""
This function returns the multiplicator `k` corresponding to the frequency
given by the mixing factors `mx`, `my`, and `mz`. I.e. the integer value, for
which k*F = mx*fx + my*fy* + mz*fz, where F is the measurement cycle frequency
and fx, fy, and fz are the excitation frequencies for the x,y, and z channel.
"""
function mixFactorToFreq(b::MPIFile,mx,my,mz=0)
  mxyz, mask, freqNumber = calcPrefactors(b)
  k = (mx*mxyz[1]+my*mxyz[2]+mz*mxyz[3])
  return k
end

"""
This function returns the index `freqidx` of the frequency given by the mixing
factors `mx`, `my`, and `mz` with respect to the frequency list
`freq = frequencies(bSF)`.
"""
function mixFactorToFreqIdx(b::MPIFile,mx,my,mz=0)
  freqidx = mixFactorToFreq(b,mx,my,mz)
  return freqidx + 1
end

function calcPrefactors(b::MPIFile)
  freqNumber = rxNumFrequencies(b)
  mask = collect((dfStrength(b)[1,:,1] .>= 0.0000001))
  divider = vec(dfDivider(b))
  #mxyz = round.(Int64,divider.*mask./gcd(divider.*mask))
  mxyz_ = 2 .*rxBandwidth(b)*dfCycle(b)./divider
  mxyz = max.(1,round.(Int64,mxyz_.*mask))

  return mxyz, mask, freqNumber
end

"""
This function returns a lookup table with columns
`freqidx` | `mx` | `my` | `mz` | `mixingOrder`
for all frequencies in `freq = frequencies(bSF)`, where only the lowest order
mixing coefficients `mx`, `my`, and `mz` are listed.
"""
function mixingFactors(b::MPIFile)
  mxyz, mask, freqNumber = calcPrefactors(b)
  MoList = zeros(Int64,freqNumber,4)
  MoList[:,4] .= -1 # set all mixing orders to -1 initially to change them later
  if length(mxyz) == 3
    Nx,Ny,Nz = round.(Int64,freqNumber./mxyz.*mask)

    return _mixingFactors(MoList, mxyz, Nx,Ny,Nz, freqNumber)
  else
    MoList[:,1] = MoList[:,4] = 0:(freqNumber-1)
    return MoList
  end
end

function _mixingFactors(MoList, mxyz, Nx,Ny,Nz, freqNumber)
  for mx = -Nx:Nx
    #for my = abs(mx)-n0:n0-abs(mx)
    for my = -Ny:Ny
      for mz = -Nz:Nz
        k = (mx*mxyz[1]+my*mxyz[2]+mz*mxyz[3])+1

          if k>=1 &&
             k<=freqNumber &&
             (MoList[k,4]<0 || MoList[k,4]>=abs(mx)+abs(my)+abs(mz))
           MoList[k,1] = mx
           MoList[k,2] = my
           MoList[k,3] = mz
           MoList[k,4] = abs(mx)+abs(my)+abs(mz)
          end
       end
    end
  end
  return MoList
end
