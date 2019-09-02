#=
    InterpolatedRejectionSampling
    Copyright © 2019 Mark Wells <mwellsa@gmail.com>

    Distributed under terms of the AGPL-3.0 license.
=#

module InterpolatedRejectionSampling

using Base.Iterators
using Interpolations
using Interpolations: Extrapolation
using StatsBase: sample, Weights

export irsample, irsample!

@inline function midpoints(x::AbstractVector{Float64})
    length(x) == 1 && return x
    retval = Vector{Float64}(undef, length(x)-1)
    @fastmath @inbounds @simd for i in eachindex(retval)
        retval[i] = (x[i  ] +
                     x[i+1])/2
    end
    return retval
end

@inline function midpoints(x::AbstractRange{Float64})
    length(x) == 1 && return x
    Δx = 0.5*step(x)
    return range(first(x)+Δx, stop=last(x)-Δx, length=length(x)-1)
end

@inline get_interp(interp::AbstractExtrapolation{Float64,N,ITPT,IT}, val::NTuple{N,Float64}) where {N,ITPT,IT} = interp(val...)

#@inline get_knots(interp::Extrapolation{Float64,1,ITPT,BSpline{Linear},ET}) where {ITPT,ET} = first(interp.itp.ranges)
#@inline get_knots(interp::Extrapolation{Float64,1,ITPT,Gridded{Linear},ET}) where {ITPT,ET} = first(interp.itp.knots)

@inline get_knots(interp::Extrapolation{Float64,N,ITPT,BSpline{Linear},ET}) where {N,ITPT,ET} = interp.itp.ranges
@inline get_knots(interp::Extrapolation{Float64,N,ITPT,Gridded{Linear},ET}) where {N,ITPT,ET} = interp.itp.knots

@inline get_coefs(interp::Extrapolation{Float64,N,ITPT,BSpline{Linear},ET}) where {N,ITPT,ET} = interp.itp.itp.coefs
@inline get_coefs(interp::Extrapolation{Float64,N,ITPT,Gridded{Linear},ET}) where {N,ITPT,ET} = interp.itp.coefs

@inline get_Δ(x::AbstractVector) = length(x) > 1 ? diff(x) : 1

@inline integrate(interp::AbstractExtrapolation{Float64,N,ITPT,IT}, (x, Δx)::NTuple{2,NTuple{N,Float64}}
                  ) where {N,ITPT,IT} = prod(Δx)*get_interp(interp, x)

function integrate(knots::NTuple{N,AbstractVector{Float64}},
                   interp::AbstractExtrapolation{Float64,N,ITPT,IT}
                  ) where {N,ITPT,IT}
    midknots = map(midpoints, knots)
    Δknots = map(get_Δ, knots)
    return sum(x -> integrate(interp, x), zip(product(midknots...), product(Δknots...)))
end

@inline integrate(interp::AbstractExtrapolation{Float64,N,ITPT,IT}
                 ) where {N,ITPT,IT} = integrate(get_knots(interp), interp)

@inline is_normalized(interp::AbstractExtrapolation{Float64,N,ITPT,IT}
                     ) where {N,ITPT,IT} = isapprox(integrate(interp), one(Float64))

function normalize_interp(interp::AbstractExtrapolation{Float64,N,ITPT,IT}) where {N,ITPT,IT}
    knots = get_knots(interp)
    coefs = get_coefs(interp)
    A = integrate(interp)
    coefs ./= A
    return LinearInterpolation(knots, coefs)
end

@inline sliced_knots(k::AbstractVector{Float64}, s::T
                    ) where T<:Union{Missing,Float64} = ismissing(s) ? k : [s]

@inline sliced_knots(knots::NTuple{N,AbstractVector}, slice::AbstractVector{Union{Missing,Float64}}
                    ) where N = ntuple(i -> sliced_knots(knots[i], slice[i]), Val(N))

struct Cells{Float64,N,ITPT,IT,ET}
    knots::NTuple{N,Vector}
    pmass::Array{Float64,N}
    cinds::CartesianIndices{N,NTuple{N,Base.OneTo{Int}}}
    interp::Extrapolation{Float64,N,ITPT,IT,ET}

    function Cells(interp::Extrapolation{Float64,N,ITPT,IT,ET},
                   knots::NTuple{N,AbstractVector} = get_knots(interp)
                  ) where {T<:Union{Missing,Float64},N,ITPT,IT,ET}

        ksz = map(length, knots)
        midpnt = map(midpoints, knots)
        msz = map(length, midpnt)

        pmass = Array{Float64,N}(undef,msz)
        for (i,k) in enumerate(product(midpnt...))
            pmass[i] = get_interp(interp, k)
        end
        pmass ./= sum(pmass)

        new{Float64,N,ITPT,IT,ET}(knots, pmass, CartesianIndices(msz), interp)
    end

    function Cells(interp::Extrapolation{Float64,N,ITPT,IT,ET},
                   slice::AbstractVector{Union{Missing,Float64}}
                  ) where {N,ITPT,IT,ET}
        knots = get_knots(interp)
        sknots = sliced_knots(knots, slice)
        return Cells(interp, sknots)
    end
end

@inline get_interp(C::Cells{Float64,N,ITPT,IT,ET}, val::NTuple{N,Float64}
                  ) where {N,ITPT,IT,ET} = get_interp(C.interp, val)

import StatsBase.sample
@inline sample(C::Cells) = sample(CartesianIndices(C.cinds), Weights(vec(C.pmass)))

@inline _get_xmin(x::AbstractVector{Float64}, i::Int)::Float64 = x[i]
@inline _get_span(x::AbstractVector{Float64}, i::Int)::Float64 = length(x) == 1 ? zero(Float64) : x[i+1] - x[i]

struct Support{Float64,N}
    xmin::NTuple{N,Float64}
    span::NTuple{N,Float64}

    function Support(C::Cells{Float64,N}, cind::CartesianIndex{N}) where {N}
        xmin = ntuple(i -> _get_xmin(C.knots[i], cind.I[i])::Float64, Val(N))
        span = ntuple(i -> _get_span(C.knots[i], cind.I[i])::Float64, Val(N))
        new{Float64,N}(xmin,span)
    end
end

@inline Base.getindex(S::Support{Float64,N}, i::Int) where N = (S.xmin[i], S.span[i])

Base.iterate(S::Support{Float64,N}, state::Int=1) where N = state > N ? nothing : (S[state], state+1)

@inline propose_sample(S::Support{Float64,N}
                      ) where N = ntuple(i -> iszero(last(S[i])) ?
                                         first(S[i]) :
                                         first(S[i]) + rand()*last(S[i]),
                                         Val(N)
                                        )

@inline get_extrema(S::Support{Float64,N}
                   ) where N = product(ntuple(i -> (first(S[i]), first(S[i]) + last(S[i])),
                                              Val(N)
                                             )...
                                      )

@inline maxmapreduce(f,a) = mapreduce(f, max, a)

struct Envelope{Float64,N,ITPT,IT,ET}
    support::Support{Float64,N}
    maxvalue::Float64
    interp::Extrapolation{Float64,N,ITPT,IT,ET}
    function Envelope(C::Cells{Float64,N,ITPT,IT,ET},
                      cind::CartesianIndex{N}
                     ) where {N,ITPT,IT,ET}
        support = Support(C, cind)
        spnts = get_extrema(support)
        maxvalue = maxmapreduce(x -> get_interp(C,x), spnts)
        new{Float64,N,ITPT,IT,ET}(support, maxvalue, C.interp)
    end
end

@inline get_interp(E::Envelope{Float64,N,ITPT,IT,ET},
                   val::NTuple{N,Float64}
                  ) where {N,ITPT,IT,ET} = get_interp(E.interp, val)

@inline propose_sample(E::Envelope) = propose_sample(E.support)

function rsample(E::Envelope{Float64,N,ITPT,IT,ET}) where {N,ITPT,IT,ET}
    while true
        samp = propose_sample(E)
        if rand()*E.maxvalue ≤ get_interp(E, samp)
            return samp
        end
    end
    error("unable to draw a sample after $maxruns runs")
end

function rsample(C::Cells)
    cind = sample(C)
    E = Envelope(C,cind)
    return rsample(E)
end

function rsample(interp::Extrapolation)
    C = Cells(interp)
    return rsample(C)
end

function irsample(knots::NTuple{N,AbstractVector{Float64}},
                  probs::AbstractArray{Float64,N}
                 ) where N
    interp = LinearInterpolation(knots, probs)
    return rsample(interp)
end

function irsample(knots::NTuple{N,AbstractVector{Float64}},
                  probs::AbstractArray{Float64,N},
                  n::Int
                 ) where N
    interp = LinearInterpolation(knots, probs)
    retval = Matrix{Float64}(undef, N, n)
    for s in eachcol(retval)
        s .= rsample(interp)
    end
    return retval
end

function rsample(interp::Extrapolation, slice::AbstractVector{Union{Missing,Float64}})
    C = Cells(interp, slice)
    return rsample(C)
end

function irsample!(slices::AbstractMatrix{Union{Missing,Float64}},
                   knots::NTuple{N,AbstractVector{Float64}},
                   probs::AbstractArray{Float64,N}
                  ) where N
    interp = LinearInterpolation(knots, probs)
    for s in eachcol(slices)
        s .= rsample(interp, s)
    end
end

end
