function α(s::Union{AbstractVector{S},S},K::Symmetric{T}) where {S<:Integer,T<:Real}
    N = size(K,2)
    s = broadcast(min,s,N) # any value s>N will get an α score of 1
    eig = reverse(eigvals(K, N-maximum(s)+1:N)) # get the largest eigenvalues (as many as we need) and sort them in decreasing order
    num = cumsum(eig)[s] # ∑ᵢ₌₁ˢ λᵢ² ∀s
    denom = tr(K) # ∑_ᵢ₌₁ⁿ λᵢ²
    broadcast(sqrt,num/denom)
end
α(s::Union{AbstractVector{S},S}, X::AbstractMatrix) where {S<:Integer} = α(s,Symmetric(X'*X))


_resamplerow(x) = rand(x,size(x))
_resamplematrix(X) = mapslices(_resamplerow, X, dims=2)

function _αbootstrap(X::AbstractMatrix, s::Union{AbstractVector{S},S}, nbrIter::Integer) where {S<:Integer}
    sum(i->α(s,_resamplematrix(X)), 1:nbrIter) # bootstrap and sum
end


function projectionscore(X::AbstractMatrix, s::Union{AbstractVector{S},S}; nbrIter::Integer=10) where {S<:Integer}
    αB = NaN
    if nprocs()==1 || nbrIter==1
        αB=_αbootstrap(X,s,nbrIter)/nbrIter # no threading needed
    else
        # try to minimize data movement by spawning once per process
        W = workers()
        nbrWorkers = min( length(W), nbrIter ) # never use more than nbrIter workers
        nbrIterPerWorker = [ ((d,r)=divrem(nbrIter,nbrWorkers); d+(r>=i)) for i=1:nbrWorkers ] # divide iterations evenly among workers

        # TODO: do with pmap instead?
        refs = Array{Any}(nbrWorkers)
        for i=1:nbrWorkers
            refs[i] = @spawnat W[i] _αbootstrap(X,s,nbrIterPerWorker[i])
        end
        αB = sum(fetch, refs)/nbrIter # take mean over all bootstrapped α's
    end
    α(s,X) - αB
end


# Assumes X is sorted by decreasing σ!
function _αfiltered(X, s, σ, σThresholds)
    αs = zeros(length(s), length(σThresholds))

    # Build Kernel Matrix gradually, starting with the variables with highest σ
    K = zeros(size(X,2),size(X,2))
    prevInd = 1
    for i = length(σThresholds):-1:1
        # get range of variables to add
        currInd = prevInd
        while currInd<length(σ) && σ[currInd] >= σThresholds[i]
            currInd += 1
        end

        varRange = prevInd:currInd-1

        if !isempty(varRange)
            X2 = X[varRange,:]
            K += X2'X2
            αs[:,i] = α(s, Symmetric(K))
        elseif i<length(σThresholds)
            αs[:,i] = αs[:,i+1]
        end
        prevInd = currInd
    end

    αs
end

function _αfilteredsum(X,s,σ,σThresholds,nbrIter) 
    sum(i->_αfiltered(_resamplematrix(X),s,σ,σThresholds), 1:nbrIter)
end


_stdnormalized(X) = (σ=squeeze(std(X,dims=2),2); σ/maximum(σ))

function projectionscorefiltered(X::AbstractMatrix, s::Union{AbstractVector{S},S}, σThresholds::AbstractVector; 
                                             nbrIter::Integer=10, σ=_stdnormalized(X)) where {S<:Integer}
    @assert all(diff(σThresholds).>=0) "σThresholds must be increasing"
    @assert length(σ) == size(X,1)

    # get rid of those variables that will not be used at any threshold
    baseFilter = σ.>=σThresholds[1]
    X = X[baseFilter,:]
    σ = σ[baseFilter]

    if length(σ)==0
        warn("No variables remain after filtering at lowest given threshold.")
        return zeros(length(s), length(σThresholds))
    end

    # sort X so that the variables are ordered by decreasing σ
    σPerm = sortperm(σ, rev=true)
    σ = σ[σPerm]
    X = X[σPerm,:]

    α = _αfiltered(X,s,σ,σThresholds)

    αB = NaN

    if nprocs()==1 || nbrIter==1  # no threading needed
        αB = _αfilteredsum(X,s,σ,σThresholds,nbrIter)
    else
        # try to minimize data movement by spawning once per process
        W = workers()
        nbrWorkers = min( length(W), nbrIter ) # never use more than nbrIter workers
        nbrIterPerWorker = [ ((d,r)=divrem(nbrIter,nbrWorkers); d+(r>=i)) for i=1:nbrWorkers ] # divide iterations evenly among workers

        refs = Array{Any}(nbrWorkers)
        for i=1:nbrWorkers
            refs[i] = @spawnat W[i] _αfilteredsum(X,s,σ,σThresholds,nbrIterPerWorker[i])
        end
        αB = sum(fetch, refs) # take mean over all bootstrapped α's
    end

    α - αB/nbrIter
end
