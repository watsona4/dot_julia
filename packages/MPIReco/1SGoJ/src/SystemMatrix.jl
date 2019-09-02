import Base.length, Base.size

export getSF, SVD, tikhonovLU, setlambda

function converttoreal(S::AbstractArray{Complex{T}},f) where T
  N = prod(calibSize(f))
  M = div(length(S),N)
  S = reshape(S,N,M)
  S = reshape(reinterpret(T,vec(S)),(2*N,M))
  for l=1:M
    tmp = S[:,l]
    S[1:N,l] = tmp[1:2:end]
    S[N+1:end,l] = tmp[2:2:end]
  end
  return S
end

setlambda(S::AbstractMatrix, λ) = nothing

function getSF(bSF, frequencies, sparseTrafo, solver; kargs...)
  SF, grid = getSF(bSF, frequencies, sparseTrafo; kargs...)
  if solver == "kaczmarz"
    return transpose(SF), grid
  elseif solver == "pseudoinverse"
    return SVD(svd(transpose(SF))...), grid
  elseif solver == "cgnr" || solver == "lsqr" || solver == "fusedlasso"
    return copy(transpose(SF)), grid
  elseif solver == "direct"
    return RegularizedLeastSquares.tikhonovLU(copy(transpose(SF))), grid
  else
    return SF, grid
  end
end

getSF(bSF::Union{T,Vector{T}}, frequencies, sparseTrafo::Nothing; kargs...) where {T<:MPIFile} =
   getSF(bSF, frequencies; kargs...)

# TK: The following is a hack since colored and sparse trafo are currently not supported
getSF(bSF::Vector{T}, frequencies, sparseTrafo::AbstractString; kargs...) where {T<:MPIFile} =
  getSF(bSF[1], frequencies, sparseTrafo; kargs...)

getSF(bSFs::MultiContrastFile, frequencies; kargs...) =
   getSF(bSFs.files, frequencies; kargs...)

function getSF(bSFs::Vector{T}, frequencies; kargs...) where {T<:MPIFile}
  maxFov = [0.0,0.0,0.0]
  maxSize = [0,0,0]
  for l=1:length(bSFs)
    maxFov = max.(maxFov, calibFov(bSFs[l]))
    maxSize = max.(maxSize, collect(calibSize(bSFs[l])) )
  end
  data = [getSF(bSF, frequencies; gridsize=maxSize, fov=maxFov, kargs...) for bSF in bSFs]
  return cat([d[1] for d in data]..., dims=1), data[1][2] # grid of the first SF
end

getSF(f::MPIFile; recChannels=1:numReceivers(f), kargs...) = getSF(f, filterFrequencies(f, recChannels=recChannels); kargs...)

function repairDeadPixels(S, shape, deadPixels)
  shapeT = tuple(shape...)
  for k=1:size(S,2)
    for dp in deadPixels
      ix,iy,iz = ind2sub(shapeT,dp)
      if 1<ix<shape[1] && 1<iy<shape[2] && 1<iz<shape[3]
         lval = S[ sub2ind(shapeT,ix,iy+1,iz)  ,k]
         rval = S[ sub2ind(shapeT,ix,iy-1,iz)  ,k]
         S[dp,k] = 0.5*(lval+rval)
         fval = S[ sub2ind(shapeT,ix+1,iy,iz)  ,k]
         bval = S[ sub2ind(shapeT,ix-1,iy,iz)  ,k]
         S[dp,k] = 0.5*(fval+bval)
         uval = S[ sub2ind(shapeT,ix,iy,iz+1)  ,k]
         dval = S[ sub2ind(shapeT,ix,iy,iz-1)  ,k]
         S[dp,k] = 0.5*(uval+dval)
      end
    end
  end
end

function getSF(bSF::MPIFile, frequencies; returnasmatrix = true, procno::Integer=1,
               bgcorrection=false, bgCorrection=bgcorrection, loadasreal=false,
	       gridsize=collect(calibSize(bSF)),
	       fov=calibFov(bSF), center=[0.0,0.0,0.0], deadPixels=Int[], kargs...)

  nFreq = rxNumFrequencies(bSF)

  S = getSystemMatrix(bSF, frequencies, bgCorrection=bgCorrection)

  if !isempty(deadPixels)
    repairDeadPixels(S,gridsize,deadPixels)
  end

  if collect(gridsize) != collect(calibSize(bSF)) ||
    center != [0.0,0.0,0.0] ||
    fov != calibFov(bSF)
    @debug "Perform SF Interpolation..."

    origin = RegularGridPositions(calibSize(bSF),calibFov(bSF),[0.0,0.0,0.0])
    target = RegularGridPositions(gridsize,fov,center)

    SInterp = zeros(eltype(S),prod(gridsize),length(frequencies)*acqNumPeriodsPerFrame(bSF))
    for k=1:length(frequencies)*acqNumPeriodsPerFrame(bSF)
      A = MPIFiles.interpolate(reshape(S[:,k],calibSize(bSF)...), origin, target)
      SInterp[:,k] = vec(A)
    end
    S = SInterp
    grid = target
  else
    grid = RegularGridPositions(calibSize(bSF),calibFov(bSF),[0.0,0.0,0.0])
  end

  if loadasreal
    S = converttoreal(S,bSF)
    resSize = [gridsize..., 2*length(frequencies)*acqNumPeriodsPerFrame(bSF)]
  else
    resSize = [gridsize...,length(frequencies)*acqNumPeriodsPerFrame(bSF)]
  end

  if returnasmatrix
    return reshape(S,prod(resSize[1:end-1]),resSize[end]), grid
  else
    return squeeze(reshape(S,resSize...)), grid
  end
end

"""
This function reads the component belonging to the given mixing-factors und channel from the given MPIfile.\n
In the case of a 2D systemfunction, the third dimension is added.
"""
function getSF(bSF::MPIFile, mx::Int, my::Int, mz::Int, recChan::Int)
  maxFreq  = rxNumFrequencies(bSF)
  freq = mixFactorToFreq(bSF, mx, my, mz)
  freq = clamp(freq,0,maxFreq-1)
  k = freq + (recChan-1)*maxFreq
  @debug "Frequency = $k"
  SF, grid = getSF(bSF,[k+1],returnasmatrix = true, bgcorrection=true)
  N = calibSize(bSF)
  SF = reshape(SF,N[1],N[2],N[3])

  return SF
end

include("Sparse.jl")
