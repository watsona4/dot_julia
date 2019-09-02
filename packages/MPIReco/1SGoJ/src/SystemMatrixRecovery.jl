# @everywhere using RegularizedLeastSquares, LinearOperators, TensorDecompositions, LinearAlgebra
#@everywhere using RegularizedLeastSquares, LinearOperators, LinearAlgebra
export smRecovery

###################################################################
# System Matrix recovery using DCT-sparsity and low-rank constraing
###################################################################
function smRecovery(y::Matrix{T}, samplingIdx::Array{Int64}, params::Dict) where T
  # constrain number of threads for distributed computation
  BLAS.set_num_threads(1)

  shape = params[:shape]

  # sampling operator
  P = SamplingOp(samplingIdx, shape)

  # sparsifying transformation and regularization
  if !haskey(params, :sparseTrafo)
    params[:sparseTrafo] = DCTOp(ComplexF64,params[:shape],2)
  end
  reg1Name = get(params, :reg1, "L1")
  reg1 = Regularization(reg1Name, 1.0/params[:λ]; params...)

  # low rank regularization
  lrProx = get(params, :reg2, "Nothing")
  λ_lr = get(params, :λ_lr, 1.0)
  reg2 = lrReg(lrProx, λ_lr, params)

  # precalculate inverse for split Bregman iteration
  precon = invPrecon(samplingIdx, prod(shape); params...)
  params[:precon] = precon
  params[:iterationsCG] = 1

  # normalized measurement
  y2, y_norm = getNormalizedMeasurement(y)

  # reconstruction
  sf = map(x->splitBregman(P,x,[reg1,reg2]; params...),y2)

  sfMat = zeros(ComplexF64,prod(shape),size(y,2))
  for i=1:size(y,2)
    # undo normalization
    sfMat[:,i] .= y_norm[i]*sf[i]
  end

  return sfMat
end

#########################
# low rank regularization
#########################
function lrReg(lrProx::AbstractString, λ::AbstractFloat, params::Dict{Symbol,Any})
  if lrProx == "LR"
    proxMap = (x,y;kargs...)->proxLR!(x,y,params[:shape];kargs...)
    reg = Regularization(prox! = proxMap, λ=λ, params=params)
  elseif lrProx == "FR"
    proxMap = (x,y;kargs...)->proxFR!(x,y,params[:shape];kargs...)
    reg = Regularization(prox! = proxMap, λ=λ, params=params)
  elseif lrProx == "Nothing"
    reg = Regularization(prox! = x->x, λ=λ, params=params)
  else
    error("proximal map $(lrProx) is not supported")
  end
  return reg
end

# low rank regularization for 3d (using HOSVD)
function proxLR!(x, λ::Real, shape::NTuple{3,Int64}; kargs...)
  guvw_r = hosvd(reshape(real.(x), shape),shape)
  guvw_i = hosvd(reshape(imag.(x), shape),shape)
  proxL1!(guvw_r.core,λ)
  proxL1!(guvw_i.core,λ)
  x[:] .= vec(compose(guvw_r)+1im*compose(guvw_i))
end

# low rank regularization for 2d (using SVD)
function proxLR!(x, λ::Real, shape::NTuple{2,Int64}; kargs...)
  U,S,V = svd(reshape(x,shape))
  proxL1!(S,λ)
  x[:] .= vec(U*Matrix(Diagonal(S))*V')
end

# fixed rank constraing for 3d (using HOSVD)
function proxFR!(x, λ::Real, shape::NTuple{3,Int64}; rank::NTuple{3,Int64}=(1,1,1), kargs...)
  guvw_r = hosvd(reshape(real.(x), shape),rank)
  guvw_i = hosvd(reshape(imag.(x), shape),rank)
  x[:] = vec(compose(guvw_r)+1im*compose(guvw_i))
end

# fixed rank constraing for 3d (using SVD)
function proxFR!(x, λ::Real, shape::NTuple{2,Int64}; rank::Int64=1, kargs...)
  U,S,V = svd(reshape(x, shape))
  S[rank+1:end] .= 0.0
  x[:] .= vec(U*Matrix(Diagonal(S))*V')
end

##########################
# inverse of normal matrix
##########################
function invPrecon(samplingIdx, ncol; μ::Float64 = 1.e-2, λ::Float64 = 1.e2, ρ::Float64=1.0, kargs...)
  normalP = normalPDiag(samplingIdx, ncol)
  diag = [μ*normalP[i]+λ+ρ for i=1:length(normalP)]
  diag = diag.^-1
  return LinearOperators.LinearOperator(length(normalP),length(normalP),true,false
          , x->diag .* x
          , nothing
          , nothing)
end

function normalPDiag(samplingIdx, ncol)
  normalP = zeros(ncol)
  for i=1:length(samplingIdx)
    normalP[samplingIdx[i]] = 1.0
  end
  return normalP
end

function getNormalizedMeasurement(y::Matrix{T}) where T
  y_norm = [norm(y[:,k]) for k=1:size(y,2)]
  y2 = @DArray [ComplexF64.(y[:,k]/y_norm[k]) for k=1:size(y,2)]
  return y2, y_norm
end
