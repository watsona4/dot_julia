export AvgCutPruningAlgo, AvgCutPruner

"""
    AvgCutPruningAlgo <: AbstractCutPruningAlgo

Removes the cuts with lower trust where the trust is: nused / nwith + bonus
where the cut has been used `nused` times amoung `nwith` optimization done with it.
We say that the cut was used if its dual value is nonzero.
It has a bonus equal to `mycutbonus` if the cut was generated using a trial given by the problem using this cut.
If `nwidth` is zero, `nused/nwith` is replaced by `newcuttrust`.
"""
struct AvgCutPruningAlgo <: AbstractCutPruningAlgo
    # maximum number of cuts
    maxncuts::Int
    newcuttrust::Float64
    mycutbonus::Float64
    function AvgCutPruningAlgo(maxncuts::Int, newcuttrust=3/4, mycutbonus=1/4)
        new(maxncuts, newcuttrust, mycutbonus)
    end
end

mutable struct AvgCutPruner{N, T} <: AbstractCutPruner{N, T}
    # used to generate cuts
    isfun::Bool
    islb::Bool
    lazy_minus::Bool
    A::AbstractMatrix{T}
    b::AbstractVector{T}

    # maximum number of cuts
    maxncuts::Int

    # number of optimization performed
    nwith::Vector{Int}
    # number of times where the cuts have been used
    nused::Vector{Int}
    mycut::Vector{Bool}
    trust::Union{Vector{Float64}, Nothing}
    ids::Vector{Int} # small id means old
    id::Int # current id

    newcuttrust::Float64
    mycutbonus::Float64

    # check redundancy with old cuts when adding new cuts
    excheck::Bool

    # tolerance to check redundancy between two cuts
    TOL_EPS::Float64


    function (::Type{AvgCutPruner{N, T}})(sense::Symbol, maxncuts::Int, newcuttrust=3/4, mycutbonus=1/4, lazy_minus::Bool=false, tol=1e-6, excheck::Bool=false) where {N, T}
        isfun, islb = gettype(sense)
        new{N, T}(isfun, islb, lazy_minus, spzeros(T, 0, N), T[], maxncuts, Int[], Int[], Bool[], nothing, Int[], 0, newcuttrust, mycutbonus, excheck, tol)
    end
end

(::Type{CutPruner{N, T}})(algo::AvgCutPruningAlgo, sense::Symbol, lazy_minus::Bool=false) where {N, T} = AvgCutPruner{N, T}(sense, algo.maxncuts, algo.newcuttrust, algo.mycutbonus, lazy_minus)

# COMPARISON
"""Update cuts relevantness after a solver's call returning dual vector `σρ`."""
function addusage!(man::AvgCutPruner, σρ)
    if ncuts(man) > 0
        man.nwith .+= 1
        # TODO: dry 1e-6 in CutPruner?
        man.nused[σρ .> 1e-6] .+= 1
        man.trust = nothing # need to be recomputed
    end
end

function gettrustof(man::AvgCutPruner, nwith, nused, mycut)
    (nwith == 0 ? man.newcuttrust : nused / nwith) + (mycut ? man.mycutbonus : 0)
end
function initialtrust(man::AvgCutPruner, mycut)
    gettrustof(man, 0, 0, mycut)
end
function hastrust(man::AvgCutPruner)
    man.trust !== nothing
end
function gettrust(man::AvgCutPruner)
    if !hastrust(man)
        trust = man.nused ./ man.nwith
        trust[man.nwith .== 0] .= man.newcuttrust
        trust[man.mycut] .+= man.mycutbonus
        man.trust = trust
    end
    man.trust
end

# CHANGE

function keeponlycuts!(man::AvgCutPruner, K::AbstractVector{Int})
    man.nwith = man.nwith[K]
    man.nused = man.nused[K]
    man.mycut = man.mycut[K]
    _keeponlycuts!(man, K)
end

function replacecuts!(man::AvgCutPruner, K::AbstractVector{Int}, A, b, mycut::AbstractVector{Bool})
    man.nwith[K] .= 0
    man.nused[K] .= 0
    man.mycut[K] .= mycut
    _replacecuts!(man, K, A, b)
    if hastrust(man)
        man.trust[K] .= initialtrusts(man, mycut)
    end
end

function appendcuts!(man::AvgCutPruner, A, b, mycut::AbstractVector{Bool})
    n = length(mycut)
    append!(man.nwith, zeros(n))
    append!(man.nused, zeros(n))
    append!(man.mycut, mycut)
    _appendcuts!(man, A, b)
    if hastrust(man)
        append!(man.trust, initialtrusts(man, mycut))
    end
end
