export DecayCutPruningAlgo, DecayCutPruner

"""
    DecayCutPruningAlgo <: AbstractCutPruningAlgo

Removes the cuts with lower trust where the trust is initially
`newcuttrust + bonus` and is updated using `trust -> λ * trust + used`
after each optimization done with it.
The value `used` is 1 if the cut was used and 0 otherwise.
It has a bonus equal to `mycutbonus` if the cut was generated using a trial
given by the problem using this cut.
We say that the cut was used if its dual value is nonzero.
"""
struct DecayCutPruningAlgo <: AbstractCutPruningAlgo
    maxncuts::Int
    λ::Float64
    newcuttrust::Float64
    mycutbonus::Float64
    function DecayCutPruningAlgo(maxncuts::Int, λ=0.9, newcuttrust=0.8, mycutbonus=1)#newcuttrust=(1/(1/0.9-1))/2, mycutbonus=(1/(1/0.9-1))/2)
        new(maxncuts, λ, newcuttrust, mycutbonus)
    end
end

mutable struct DecayCutPruner{N, T} <: AbstractCutPruner{N, T}
    # used to generate cuts
    isfun::Bool
    islb::Bool
    lazy_minus::Bool
    A::AbstractMatrix{T}
    b::AbstractVector{T}

    maxncuts::Int

    trust::Vector{Float64}
    ids::Vector{Int}
    id::Int

    λ::Float64
    newcuttrust::Float64
    mycutbonus::Float64

    # check redundancy with old cuts when adding new cuts
    excheck::Bool

    # tolerance to check redundancy between two cuts
    TOL_EPS::Float64


    function (::Type{DecayCutPruner{N, T}})(sense::Symbol, maxncuts::Int, λ=0.9,
            newcuttrust=0.8, mycutbonus=1, lazy_minus::Bool=false, tol=1e-6, excheck::Bool=false) where {N, T} #newcuttrust=(1/(1/0.9-1))/2, mycutbonus=(1/(1/0.9-1))/2)
        isfun, islb = gettype(sense)
        new{N, T}(isfun, islb, lazy_minus, spzeros(T, 0, N), T[], maxncuts, Float64[], Int[], 0, λ, newcuttrust, mycutbonus, excheck, tol)
    end
end

(::Type{CutPruner{N, T}})(algo::DecayCutPruningAlgo, sense::Symbol, lazy_minus::Bool=false) where {N, T} = DecayCutPruner{N, T}(sense, algo.maxncuts, algo.λ, algo.newcuttrust, algo.mycutbonus, lazy_minus)

# COMPARISON

function addusage!(man::DecayCutPruner, σρ)
    if ncuts(man) > 0
        man.trust .*= man.λ
        man.trust[σρ .> 1e-6] .+= 1
    end
end

function initialtrust(man::DecayCutPruner, mycut)
    if mycut
        man.newcuttrust + man.mycutbonus
    else
        man.newcuttrust
    end
end

function isbetter(man::DecayCutPruner, i::Int, mycut::Bool)
    if mycut
        # If the cut has been generated, that means it is useful
        false
    else
        # The new cut has initial trust initialtrust(man, false)
        # but it is a bit disadvantaged since it is new so
        # as we advantage the new cut if mycut == true,
        # we advantage this cut by taking initialtrust(man, true)
        # with true instead of false
        man.trust[i] > initialtrust(man, mycut)
    end
end
