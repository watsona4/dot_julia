"""
    smssvd(X, d, stdThresholds=10 .^ range(-2,stop=0,length=100); nbrIter=10, maxSignalDim=typemax(Int)) -> (U,Σ,V,ps,signalDimensions,selectedVariables)

Computes the SubMatrix Selection Singular Value Decomposition (SMSSVD) of a matrix X.

**Inputs**

* `X`: PxN data matrix (P variables and N samples).
* `d`: Number of dimension in the result.
* `stdThresholds`: Standard deviation filtering thresholds at which the Projection Score will be evaluated. Expressed as fractions of the maximum standard deviation of a variable in X. Should be a vector of increasing values between 0 and 1.

**Outputs**

* `U`: Pxd matrix of left singular vectors (variable representation).
* `S`: d-vector of singular values.
* `V`: Nxd matrix of right singular vectors (sample representation).
* `ps`: d x length(stdThresholds) matrix with all Projection Scores. Useful for plotting.
* `signalDimensions`: Vector with the number of dimensions in each signal detected by SMSSVD.
* `selectedVariables`: For each signal, a bitmask showing the variables selected by Projection Score.
"""
function smssvd(X, d::Integer, stdThresholds=10 .^ range(-2,stop=0,length=100); nbrIter=10, maxSignalDim=typemax(Int))
    σMax = maximum(std(X,dims=2)) # Always base the variable filtering on the original σ's

    U = zeros(size(X,1),d)
    Σ = zeros(d)
    V = zeros(size(X,2),d)

    ps = zeros(d, length(stdThresholds))

    signalDimensions = Int[]
    selectedVariables = Vector{BitArray}()

    k = 1
    while k<=d
        # Filter variables and choose dimension by optimizing over Projection Score
        σ = dropdims(std(X,dims=2),dims=2) / σMax # always keep the same scale

        dmax = min(d-k+1, maxSignalDim)
        PS = projectionscorefiltered(X, 1:dmax, stdThresholds, nbrIter=nbrIter, σ=σ)
        dims,σInd = Tuple(CartesianIndices(size(PS))[argmax(PS)]) # Use projection score both to choose dimension and threshold for this signal
        σThresh = stdThresholds[σInd]

        r = k:k+dims-1
        ps[r,:] = PS[1:dims,:]
        push!(signalDimensions, dims)

        push!(selectedVariables,σ.>=σThresh)
        Y = X[selectedVariables[end],:]

        # Find the subspace Π that we are interested in.
        K = Symmetric(Y'Y)
        M = size(K,1)
        _,Π = eigen(K, M-dims+1:M) # only get the largest eigenvalues and vectors

        # Project X onto the subspace v and compute SVD. For dims=1, this is identical to uσ:=Xv.
        F = svd(X*Π) # solve for smaller matrix expressed in the basis of the subspace Π
        UΠ,ΣΠ,VΠ = F.U,F.S,F.V

        U[:,r] = UΠ
        Σ[r]   = ΣΠ
        V[:,r] = Π*VΠ # expand to original basis

        # make matrix orthogonal to previous component
        X = X - UΠ*(UΠ'X) # multiplication order avoiding big matrices

        k += dims
    end

    U,Σ,V,ps,signalDimensions,selectedVariables
end

# convenience method useful when calling smssvd from R
function smssvd(X, d::Vector{T}, stdThresholds=10 .^ range(-2,stop=0,length=100); kwargs...) where T<:Integer
    @assert length(d)==1
    smssvd(X, d[1], stdThresholds; kwargs...)
end
