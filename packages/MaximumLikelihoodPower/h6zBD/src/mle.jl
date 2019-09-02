import Printf.@printf

"""
    (estimate, stderr) = mle(data::AbstractVector)

Return the maximum likelihood estimate and standard error of the exponent of a power law
applied to the sorted vector `data`.
"""
function mle(data::AbstractVector{T}) where {T}
    FT = float(T)
    xmin = data[1]
    acc = zero(FT)
    xlast = convert(FT, Inf)
    ncount = 0
    for x in data
        xlast == x && continue
        xlast = x
        ncount += 1
        acc += log(x / xmin)
    end
    ahat = 1 + ncount / acc
    stderr = (ahat - 1) / sqrt(convert(FT, ncount))
    return (ahat, stderr)
end

"""
    KSstatistic(data::AbstractVector, alpha)

Return the Колмогоров-Смирнов (Kolmogorov-Smirnov) statistic
comparing `data` to a power law with power `alpha`. The elements of `data` are
assumed to be unique.
"""
function KSstatistic(data::AbstractVector{T}, alpha) where {T}
    n = length(data)
    xmin = data[1]
    maxdistance = zero(xmin)
    FT = float(T)
    @inbounds for i in 0:n-1
        pl::FT = 1 - (xmin / data[i + 1])^alpha
        distance = abs(pl - i / n)
        if distance > maxdistance maxdistance = distance end
    end
    return maxdistance
end

"""
    scanKS(data, powers)

Compute the Kolmogorov Smirnov statistic for several values of α in the iterator `powers`.
Return the value of α that minimizes the KS statistic and the two neighboring values.
"""
function scanKS(data, powers)
    ks = [KSstatistic(data, x) for x in powers]
    i = argmin(ks)
    return collect(powers[(i-1):(i+1)])
end

"""
    MLEKS{T}

Container for storing results of MLE estimate and
Kolmogorov-Smirnov statistic of the exponent of a power law.
"""
struct MLEKS{T}
    alpha::T
    stderr::T
    KS::T
end

"""
    mleKS{T<:AbstractFloat}(data::AbstractVector{T})

Return the maximum likelihood estimate and standard error of the exponent of a power law
applied to the sorted vector `data`. Also return the Kolmogorov-Smirnov statistic. Results
are returned in an instance of type `MLEKS`.
"""
function mleKS(data::AbstractVector)
    (alpha, stderr) = mle(data)
    KSstat = KSstatistic(data, alpha)
    return MLEKS(alpha, stderr, KSstat)
end

"""
    MLEScan{T <: AbstractFloat}

Record best estimate of alpha and associated parameters.
"""
mutable struct MLEScan{T <: AbstractFloat}
    alpha::T
    stderr::T
    minKS::T
    xmin::T
    imin::Int
    npts::Int
    nptsall::Int
    ntrials::Int
end

# FIXME. more clever formatting needed
function Base.show(io::IO, s::MLEScan)
    @printf(io, "alpha   = %.8f\n" , s.alpha)
    @printf(io, "stderr  = %.8f\n" , s.stderr)
    println(io, "minKS   = ", s.minKS)
    println(io, "xmin    = ", s.xmin)
    println(io, "imin    = ", s.imin)
    println(io, "npts    = ", s.npts)
    println(io, "nptsall = ", s.nptsall)
    @printf(io, "pct pts = %.3f\n", (s.npts / s.nptsall))
    println(io, "ntrials = ", s.ntrials)
    return nothing
end

function MLEScan(T)
    z = zero(T)
    return MLEScan(z, z, convert(T, Inf), z, 0, 0, 0, 0)
end

"""
    comparescan(mle::MLEKS, i, data, mlescan::MLEScan)

Compare the results of MLE estimation `mle` to record results
in `mlescan` and update `mlescan`.
"""
function comparescan(mlescan::MLEScan, mle::MLEKS, data, i::Integer)
    if mle.KS < mlescan.minKS
        copy_mslescan!(mlescan, mle, data, i)
    end
    mlescan.ntrials += 1
    return nothing
end

function copy_mslescan!(mlescan::MLEScan, mle::MLEKS, data, i::Integer)
    mlescan.minKS = mle.KS
    mlescan.alpha = mle.alpha
    mlescan.stderr = mle.stderr
    mlescan.imin = i
    mlescan.npts = length(data)
    mlescan.xmin = data[1]
    return nothing
end

"""
    scanmle(data; ntrials=100, stderrcutoff=0.1, useKS=false)

Perform `mle` approximately `ntrials` times on `data`, increasing `xmin`. Stop trials
if the standard error of the estimate `alpha` is greater than `stderrcutoff`.
If `useKS` is true, then the application of `mle` giving the smallest KS statistic is
returned. Return an object containing statistics of the scan.

`scanmle` is intended to analayze the power-law behavior of the tail of data.
"""
function scanmle(data; ntrials=100, stderrcutoff=0.1, useKS=false)
    skip = convert(Int, round(length(data) / ntrials))
    if skip < 1 skip = 1 end
    return _scanmle(data, 1:skip:length(data), stderrcutoff, useKS)
end

"""
    _scanmle{T<:AbstractFloat, V <: Integer}(data::AbstractVector{T}, range::AbstractVector{V},stderrcutoff)

Inner function for scanning power-law mle for power `alpha` over `xmin`. `range` specifies which `xmin` to try.
`stderrcutoff` specifies a standard error in `alpha` at which we stop trials. `range` should be increasing.
"""
function _scanmle(data, range::AbstractVector{<: Integer}, stderrcutoff, useKS)
    mlescan = MLEScan(float(eltype(data)))
    mlescan.nptsall = length(data)
    lastind::Int = 0
    for i in range
        ndata = @view data[i:end]
        mleks = mleKS(ndata)
        lastind = i
        if mleks.stderr > stderrcutoff || i == last(range)
            if ! useKS
                copy_mslescan!(mlescan, mleks, ndata, i)
                mlescan.ntrials = i
            end
            break
        end
        if useKS
            comparescan(mlescan, mleks, ndata, i)
        end  # do we want ndata or data here ?
    end
    return mlescan
end

#  LocalWords:  Kolmogorov Smirnov
