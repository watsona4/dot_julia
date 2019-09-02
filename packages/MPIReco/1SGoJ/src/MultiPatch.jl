import Base: size
import RegularizedLeastSquares: initkaczmarz, dot_with_matrix_row, kaczmarz_update!

export reconstructionMultiPatch, MultiPatchOperator


# Necessary for Multi-System-Matrix FF reconstruction
voxelSize(bSF::MultiMPIFile) = voxelSize(bSF[1])
sfGradient(bSF::MultiMPIFile,dim) = sfGradient(bSF[1],dim)
generateHeaderDict(bSF::MultiMPIFile,bMeas::MPIFile) =
   generateHeaderDict(bSF[1],bMeas)


function reconstructionMultiPatch(bSF, bMeas::MPIFile;
  minFreq=0, maxFreq=1.25e6, SNRThresh=-1,maxMixingOrder=-1, numUsedFreqs=-1, sortBySNR=false, recChannels=1:numReceivers(bMeas), kargs...)

  freq = filterFrequencies(bSF,minFreq=minFreq, maxFreq=maxFreq,recChannels=recChannels, SNRThresh=SNRThresh, numUsedFreqs=numUsedFreqs, sortBySNR=sortBySNR)

  @debug "selecting $(length(freq)) frequencies"

  return reconstructionMultiPatch(bSF, bMeas, freq; kargs...)
end

function reconstructionMultiPatch(bSF, bMeas::MPIFile, freq;
            frames=nothing, bEmpty=nothing, nAverages=1, numAverages=nAverages,
	    spectralLeakageCorrection=true, kargs...)

  bgCorrection = (bEmpty != nothing)

  FFOp = MultiPatchOperatorHighLevel(bSF, bMeas, freq, bgCorrection;
                    kargs... )

  L = acqNumFGFrames(bMeas)
  (frames==nothing) && (frames=collect(1:L))
  nFrames=length(frames)

  uTotal_ = getMeasurementsFD(bMeas,frequencies=freq, frames=frames, numAverages=numAverages,
                             spectralLeakageCorrection=spectralLeakageCorrection)

  periodsSortedbyFFPos = unflattenOffsetFieldShift(ffPos(bMeas))
  uTotal = similar(uTotal_,size(uTotal_,1),length(periodsSortedbyFFPos),size(uTotal_,3))

  for k=1:length(periodsSortedbyFFPos)
      uTotal[:,k,:] = mean(uTotal_[:,periodsSortedbyFFPos[k],:], dims=2)
  end

  # Here we call a regular reconstruction function
  c_ = reconstruction(FFOp, uTotal; kargs...)
  c = reshape(c_, shape(FFOp.grid)..., :)

  # calculate axis
  shp = size(c)
  pixspacing = (voxelSize(bSF) ./ sfGradient(bMeas,3) .* sfGradient(bSF,3)) * 1000u"mm"
  offset = (fieldOfViewCenter(FFOp.grid) .- 0.5.*fieldOfView(FFOp.grid) .+ 0.5.*spacing(FFOp.grid)) * 1000u"mm"
  # TODO does this provide the correct value in the multi-patch case?
  dtframes = acqNumAverages(bMeas)*dfCycle(bMeas)*numAverages*1u"s"
  # create image
  c = reshape(c,1,size(c)...)
  im = makeAxisArray(c, pixspacing, offset, dtframes)
  imMeta = ImageMeta(im,generateHeaderDict(bSF,bMeas))
  return imMeta
end

# MultiPatchOperator is a type that acts as the MPI system matrix but exploits
# its sparse structure.
# Its very important to keep this type typestable
mutable struct MultiPatchOperator{V<:AbstractMatrix, U<:Positions}
  S::Vector{V}
  grid::U
  N::Int
  M::Int
  RowToPatch::Vector{Int}
  xcc::Vector{Vector{Int}}
  xss::Vector{Vector{Int}}
  sign::Matrix{Int}
  nPatches::Int
  patchToSMIdx::Vector{Int}
end

function MultiPatchOperatorHighLevel(SF::MPIFile, bMeas, freq, bgCorrection::Bool; kargs...)
  return MultiPatchOperatorHighLevel(MultiMPIFile([SF]), bMeas, freq, bgCorrection; kargs...)
end

function MultiPatchOperatorHighLevel(bSF::MultiMPIFile, bMeas, freq, bgCorrection::Bool;
        FFPos = zeros(0,0), FFPosSF = zeros(0,0), kargs...)

  FFPos_ = ffPos(bMeas)

  periodsSortedbyFFPos = unflattenOffsetFieldShift(FFPos_)
  idxFirstPeriod = getindex.(periodsSortedbyFFPos,1)
  FFPos_ = FFPos_[:,idxFirstPeriod]

  if length(FFPos) > 0
    FFPos_[:] = FFPos
  end

  if length(FFPosSF) == 0
    L = length(ffPos(bSF[1]))
    FFPosSF_ = [vec(ffPos(SF))[l] for l=1:L, SF in bSF] #[vec(ffPos(SF)) for SF in bSF]
  else
    FFPosSF_ = FFPosSF #[vec(FFPosSF[:,l]) for l=1:size(FFPosSF,2)]
  end

  gradient = acqGradient(bMeas)[:,:,1,idxFirstPeriod]

  FFOp = MultiPatchOperator(bSF, bMeas, freq, bgCorrection,
                  FFPos = FFPos_,
                  gradient = gradient,
                  FFPosSF = FFPosSF_; kargs...)
  return FFOp
end


function MultiPatchOperator(SF::MPIFile, bMeas, freq, bgCorrection::Bool; kargs...)
  return MultiPatchOperator(MultiMPIFile([SF]), bMeas, freq, bgCorrection; kargs...)
end

function findNearestPatch(ffPosSF, FFPos, gradientSF, gradient)
  idx = -1
  minDist = 1e20
  for l = 1:size(ffPosSF,2)
    if gradientSF[l][:,:,1,1] == gradient
      dist = norm(ffPosSF[:,l].-FFPos)
      if dist < minDist
        minDist = dist
        idx = l
      end
    end
  end
  if idx < 0
    error("Something went wrong")
  end
  return idx
end

function MultiPatchOperator(SFs::MultiMPIFile, bMeas, freq, bgCorrection::Bool;
        mapping=zeros(0), kargs...)
  if length(mapping) > 0
    return MultiPatchOperatorExpliciteMapping(SFs,bMeas,freq,bgCorrection; mapping=mapping, kargs...)
  else
    return MultiPatchOperatorRegular(SFs,bMeas,freq,bgCorrection; kargs...)
  end
end

function MultiPatchOperatorExpliciteMapping(SFs::MultiMPIFile, bMeas, freq, bgCorrection::Bool;
                    denoiseWeight=0, FFPos=zeros(0,0), FFPosSF=zeros(0,0),
                    gradient=zeros(0,0,0),
                    roundPatches = false,
                    SFGridCenter = zeros(0,0),
                    systemMatrices = nothing,
                    mapping=zeros(0),
                    grid = nothing, kargs...)

  @debug "Loading System matrix"
  numPatches = size(FFPos,2)
  M = length(freq)
  RowToPatch = kron(collect(1:numPatches), ones(Int,M))

  if systemMatrices == nothing
    S = [getSF(SF,freq,nothing,"kaczmarz", bgCorrection=bgCorrection)[1] for SF in SFs]
  else
    S = systemMatrices
  end

  if length(SFGridCenter) == 0
    SFGridCenter = zeros(3,length(SFs))
    for l=1:length(SFs)
      SFGridCenter[:,l] = calibFovCenter(SFs[l])
    end
  end

  gradientSF = [acqGradient(SF) for SF in SFs]

  grids = RegularGridPositions[]
  patchToSMIdx = mapping


  sign = ones(Int, M, numPatches)

  # We first check which system matrix fits best to each patch. Here we use only
  # those system matrices where the gradient matches. If the gradient matches, we take
  # the system matrix with the closes focus field shift
  for k=1:numPatches
    idx = mapping[k]
    SF = SFs[idx]

    diffFFPos = FFPosSF[:,idx] .- FFPos[:,k]

    push!(grids, RegularGridPositions(calibSize(SF),calibFov(SF),SFGridCenter[:,idx].-diffFFPos))
  end

  # We now know all the subgrids for each patch, if the corresponding system matrix would be taken as is
  # and if a possible focus field missmatch has been taken into account (by changing the center)
  @debug "Calculate Reconstruction Grid"
  if grid == nothing
    recoGrid = RegularGridPositions(grids)
  else
    recoGrid = grid
  end


  # Within the next loop we will refine our grid since we now know our reconstruction grid
  for k=1:numPatches
    idx = mapping[k]
    SF = SFs[idx]

    issubgrid = isSubgrid(recoGrid,grids[k])
    if !issubgrid
      grids[k] = deriveSubgrid(recoGrid, grids[k])
    end
  end
  @debug "Use $(length(S)) patches"

  @debug "Calculate LUT"
  # now that we have all grids we can calculate the indices within the recoGrid
  xcc, xss = calculateLUT(grids, recoGrid)

  return MultiPatchOperator(S, recoGrid, length(recoGrid), M*numPatches,
             RowToPatch, xcc, xss, sign, numPatches, patchToSMIdx)
end

function MultiPatchOperatorRegular(SFs::MultiMPIFile, bMeas, freq, bgCorrection::Bool;
                    denoiseWeight=0, gradient=zeros(0,0,0),
                    roundPatches = false, FFPos=zeros(0,0), FFPosSF=zeros(0,0),
                    kargs...)

  @debug "Loading System matrix"
  numPatches = size(FFPos,2)
  M = length(freq)
  RowToPatch = kron(collect(1:numPatches), ones(Int,M))

  S = AbstractMatrix[]
  SOrigIdx = Int[]
  SIsPlain = Bool[]

  gradientSF = [acqGradient(SF) for SF in SFs]

  grids = RegularGridPositions[]
  matchingSMIdx = zeros(Int,numPatches)
  patchToSMIdx = zeros(Int,numPatches)

  # We first check which system matrix fits best to each patch. Here we use only
  # those system matrices where the gradient matches. If the gradient matches, we take
  # the system matrix with the closes focus field shift
  for k=1:numPatches
    idx = findNearestPatch(FFPosSF, FFPos[:,k], gradientSF, gradient[:,:,k])

    SF = SFs[idx]

    if isapprox(FFPosSF[:,idx],FFPos[:,k])
      diffFFPos = zeros(3)
    else
      diffFFPos = FFPosSF[:,idx] .- FFPos[:,k]
    end
    push!(grids, RegularGridPositions(calibSize(SF),calibFov(SF),calibFovCenter(SF).-diffFFPos))
    matchingSMIdx[k] = idx
  end

  # We now know all the subgrids for each patch, if the corresponding system matrix would be taken as is
  # and if a possible focus field missmatch has been taken into account (by changing the center)
  @debug "Calculate Reconstruction Grid"
  recoGrid = RegularGridPositions(grids)


  # Within the next loop we will refine our grid since we now know our reconstruction grid
  for k=1:numPatches
    idx = matchingSMIdx[k]
    SF = SFs[idx]

    issubgrid = isSubgrid(recoGrid,grids[k])
    if !issubgrid &&
       roundPatches &&
       spacing(recoGrid) == spacing(grids[k])

      issubgrid = true
      grids[k] = deriveSubgrid(recoGrid, grids[k])

    end

    # if the patch is a true subgrid we don't need to apply interpolation and can load the
    # matrix as is.
    if issubgrid
      # we first check if the matrix is already in memory
      u = -1
      for l=1:length(SOrigIdx)
        if SOrigIdx[l] == idx && SIsPlain[l]
          u = l
          break
        end
      end
      if u > 0 # its already in memory
        patchToSMIdx[k] = u
      else     # not yet in memory  -> load it
        S_, grid = getSF(SF,freq,nothing,"kaczmarz", bgCorrection=bgCorrection)
        push!(S,S_)
        push!(SOrigIdx,idx)
        push!(SIsPlain,true) # mark this as a plain system matrix (without interpolation)
        patchToSMIdx[k] = length(S)
      end
    else
      # in this case the patch grid does not fit onto the reco grid. Lets derive a subgrid
      # that is very similar to grids[k]
      newGrid = deriveSubgrid(recoGrid, grids[k])

      # load the matrix on the new subgrid
      S_, grid = getSF(SF,freq,nothing,"kaczmarz", bgCorrection=bgCorrection,
                   gridsize=shape(newGrid),
                   fov=fieldOfView(newGrid),
                   center=fieldOfViewCenter(newGrid).-fieldOfViewCenter(grids[k]))
                   # @TODO: I don't know the sign of aboves statement

      grids[k] = newGrid # we need to change the stored Grid since we now have a true subgrid
      push!(S,S_)
      push!(SOrigIdx,idx)
      push!(SIsPlain,false)
      patchToSMIdx[k] = length(S)
    end
  end
  @debug "Use $(length(S)) patches"

  @debug "Calculate LUT"
  # now that we have all grids we can calculate the indices within the recoGrid
  xcc, xss = calculateLUT(grids, recoGrid)

  sign = ones(Int, M, numPatches)

  return MultiPatchOperator(S, recoGrid, length(recoGrid), M*numPatches,
             RowToPatch, xcc, xss, sign, numPatches, patchToSMIdx)
end


function calculateLUT(grids, recoGrid)
  xss = Vector{Int}[]
  xcc = Vector{Int}[]
  for k=1:length(grids)
    N = length(grids[k])
    push!(xss, collect(1:N))
    xc = zeros(Int64,N)
    for n=1:N
      xc[n] = posToLinIdx(recoGrid,grids[k][n])
    end
    push!(xcc, xc)
  end
  return xcc, xss
end

function size(FFOp::MultiPatchOperator,i::Int)
  if i==2
    return FFOp.N
  elseif i==1
    return FFOp.M
  else
    error("bounds error")
  end
end

length(FFOp::MultiPatchOperator) = size(FFOp,1)*size(FFOp,2)

### The following is intended to use the standard kaczmarz method ###

function calculateTraceOfNormalMatrix(Op::MultiPatchOperator, weights)
  if length(Op.S) == 1
    trace = calculateTraceOfNormalMatrix(Op.S[1],weights)
    trace *= Op.nPatches #*prod(Op.PixelSizeSF)/prod(Op.PixelSizeC)
  else
    trace = sum([calculateTraceOfNormalMatrix(S,weights) for S in Op.S])
    #trace *= prod(Op.PixelSizeSF)/prod(Op.PixelSizeC)
  end
  return trace
end

setlambda(::MultiPatchOperator, ::Any) = nothing

function dot_with_matrix_row(Op::MultiPatchOperator, x::AbstractArray{T}, k::Integer) where T
  p = Op.RowToPatch[k]
  xs = Op.xss[p]
  xc = Op.xcc[p]

  j = mod1(k,div(Op.M,Op.nPatches))
  A = Op.S[Op.patchToSMIdx[p]]
  sign = Op.sign[j,Op.patchToSMIdx[p]]

  return dot_with_matrix_row_(A,x,xs,xc,j,sign)
end

function dot_with_matrix_row_(A::AbstractArray{T},x,xs,xc,j,sign) where T
  tmp = zero(T)
  @simd  for i = 1:length(xs)
     @inbounds tmp += sign*A[j,xs[i]]*x[xc[i]]
  end
  tmp
end

function kaczmarz_update!(Op::MultiPatchOperator, x::AbstractArray, k::Integer, beta)
  p = Op.RowToPatch[k]
  xs = Op.xss[p]
  xc = Op.xcc[p]

  j = mod1(k,div(Op.M,Op.nPatches))
  A = Op.S[Op.patchToSMIdx[p]]
  sign = Op.sign[j,Op.patchToSMIdx[p]]

  kaczmarz_update_!(A,x,beta,xs,xc,j,sign)
end

function kaczmarz_update_!(A,x,beta,xs,xc,j,sign)
  @simd for i = 1:length(xs)
    @inbounds x[xc[i]] += beta* conj(sign*A[j,xs[i]])
  end
end

function initkaczmarz(Op::MultiPatchOperator,λ,weights::Vector)
  T = typeof(real(Op.S[1][1]))
  denom = zeros(T,Op.M)
  rowindex = zeros(Int64,Op.M)

  MSub = div(Op.M,Op.nPatches)

  if length(Op.S) == 1
    for i=1:MSub
      s² = rownorm²(Op.S[1],i)*weights[i]^2
      if s²>0
        for l=1:Op.nPatches
          k = i+MSub*(l-1)
          denom[k] = weights[i]^2/(s²+λ)
          rowindex[k] = k
        end
      end
    end
  else
    for l=1:Op.nPatches
      for i=1:MSub
        s² = rownorm²(Op.S[Op.patchToSMIdx[l]],i)*weights[i]^2
        if s²>0
          k = i+MSub*(l-1)
          denom[k] = weights[i]^2/(s²+λ)
          rowindex[k] = k
        end
      end
    end
  end

  denom, rowindex
end
