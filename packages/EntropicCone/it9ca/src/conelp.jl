using StructDualDynProg, CutPruners
export appendtoSDDPLattice!, updatemaxncuts!

function MathProgBase.linprog(c::DualEntropy, h::EntropyCone, cut::DualEntropy)
    cuthrep = HalfSpace(cut.h, 1)
    MathProgBase.linprog(c.h, intersect(h.poly, cuthrep))
end

function getNLDS(c::DualEntropy, W, h, T, linset, solver, newcut::Symbol, pruningalgo::AbstractCutPruningAlgo)
    K = [(:NonNeg, collect(setdiff(BitSet(1:size(W, 1)), linset))), (:Zero, collect(linset))]
    C = [(:NonNeg, collect(1:size(W, 2)))]
    StructDualDynProg.StructProg.NLDS{Float64}(W, h, T, K, C, c.h, solver, pruningalgo, newcut)
end

function extractNLDS(c, h::EntropyConeLift, id, idp, solver, newcut, pruningalgo::AbstractCutPruningAlgo)
    hr = MixedMatHRep(hrep(h.poly))
    idx  = rangefor(h, id)
    idxp = rangefor(h, idp)
    W = hr.A[:,idx]
    T = hr.A[:,idxp]
    getNLDS(c, W, hr.b, T, hr.linset, solver, newcut, pruningalgo)
end

function next_perm(arr)
    # Find non-increasing suffix
    i = length(arr)
    while i > 1 && arr[i - 1] > arr[i]
        i -= 1
    end
    if i <= 1
        false
    else
        # Find successor to pivot
        j = length(arr)
        while arr[j] < arr[i - 1]
            j -= 1
        end
        arr[i - 1], arr[j] = arr[j], arr[i - 1]

        # Reverse suffix
        arr[i:end] = arr[length(arr):-1:i]
        true
    end
end

function addchildren!(sp::StructDualDynProg.StructProg.StochasticProgram{S}, node::Int, n::Int, old::Bool, oldnodes, newnodes, solver, max_n::Int, newcut::Symbol, pruningalgo::Vector) where S
    proba = 0.0 # It will be set at once the number of children is known (i.e. at the end of the function)
    transitions = []
    N = Int(ntodim(n))
    function addchild(J::EntropyIndex, K::EntropyIndex, adh::Symbol,
                      T = SparseMatrixCSC(1.0LinearAlgebra.I, N, N))
        if (n,J,K,adh) in keys(oldnodes)
            if !old
                child = oldnodes[(n,J,K,adh)]
                StructDualDynProg.SOI.add_scenario_transition!(sp, node, child, proba, T)
            end
        else
            child = create_node(sp, oldnodes, newnodes, n, J, K, adh, node, solver, max_n, newcut, pruningalgo)
            StructDualDynProg.SOI.add_scenario_transition!(sp, node, child, proba, T)
        end
    end

    if true
        #childT = Vector{AbstractMatrix{S}}()
        dn = max_n - n
        N = Int(ntodim(n))
        for i in 1:n-1
            for j in i+1:min(n, i+dn)
                I = set(1:i)
                J = set(1:j)
                push!(transitions, addchild(J,I,:Self))
                σ = collect(1:n)
                done = [(I,J)]
                while next_perm(σ)
                    Iperm = mymap(σ, I, n)
                    Jperm = mymap(σ, J, n)
                    if !((Iperm, Jperm) in done)
                        σinv = collect(1:n)[σ]
                        σi = map(I->mymap(σinv, I, n), indset(n))
                        push!(done, (Iperm, Jperm))
                        # Why transpose ?
                        P = sparse(Vector{Int}(σi), 1:N, 1, N, N)'
                        push!(transitions, addchild(J,I,:Self,P))
                    end
                end
            end
        end
    else
        #childT = nothing
        for adh in [:Self, :Inner]
            for J in indset(n)
                for K in indset(n)
                    if J == K ||
                        (adh == :Self && !(K ⊆ J)) ||
                        #(adh == :Self && !(fullset(n) ⊆ J)) || # Don't do that, Z-Y is not found with max_n = 5 and no inner otherwise
                        (adh == :Self && (fullset(n) ⊆ J)) || # Don't do that, Z-Y is not found with max_n = 5 and no inner otherwise
                        (adh == :Inner && K ⊆ J) ||
                        (adh == :Inner && J ⊆ K) ||
                        (adh == :Inner && (K ∩ J) == 0) ||
                        (adh == :Inner && !(fullset(n) ⊆ (K ∪ J))) ||
                        (adh == :Self && n <= 3) ||
                        (adh == :Inner && n <= 4) ||
                        adh == :Inner
                        continue
                    end
                    if nadh(n, J, K, adh) <= max_n
                        push!(transitions, addchild(J,K,adh))
                    end
                end
            end
        end
    end
    # no optimality cut needed since only the root has an objective
    # so the probably only influence sampling hence equal probability is a fair choice
    for tr in transitions
        StructDualDynProg.SOI.set!(sp, StructDualDynProg.SOI.Probability(), tr, 1 / length(transitions))
    end
end

# np: n for parent
function create_node(sp::StructDualDynProg.StructProg.StochasticProgram{S}, oldnodes, newnodes, np, Jp, Kp, adhp, parent, solver, max_n, newcut, pruningalgo::Vector) where S
    @assert !((np,Jp,Kp,adhp) in keys(oldnodes))
    if !((np,Jp,Kp,adhp) in keys(newnodes))
        n = nadh(np, Jp, Kp, adhp)
        #h = polymatroidcone(np)
        # h is for the parent.
        # We do not need the constraint of the parent so we want the full polyhedron with no constraint
        Np = Int(ntodim(np))
        fullpoly = polyhedron(hrep(HalfSpace{S, SparseVector{S, Int}}[]; d = Np))
        h = EntropyCone{S}(np, fullpoly)
        lift = adhesivelift(h, Jp, Kp, adhp)
        c = constdualentropy(n, 0)
        nlds = extractNLDS(c, lift, 2, 1, solver, newcut, pruningalgo[n])
        newnodedata = StructDualDynProg.StructProg.NodeData(nlds, Np)
        newnode = StructDualDynProg.SOI.add_scenario_node!(sp, newnodedata)
        # Only the root node has a non-zero objective so no need for optimality cuts
        StructDualDynProg.SOI.set!(sp, StructDualDynProg.StructProg.CutGenerator(),
                                   newnode, StructDualDynProg.StructProg.NoOptimalityCutGenerator())
        newnodes[(np,Jp,Kp,adhp)] = newnode
        addchildren!(sp, newnode, n, false, oldnodes, newnodes, solver, max_n, newcut, pruningalgo)
    end
    newnodes[(np,Jp,Kp,adhp)]
end

function fillroot!(sp::StructDualDynProg.StructProg.StochasticProgram, c::DualEntropy, H::EntropyCone, cut::DualEntropy, newnodes, solver, max_n::Integer, newcut::Symbol, pruningalgo::Vector)
    h = MixedMatHRep(hrep(H.poly ∩ HalfSpace(cut.h, 1)))
    @assert h.A isa AbstractSparseMatrix
    T = spzeros(Float64, size(h.A, 1), 0)
    hb = sparsevec(h.b) # FIXME it was done before but not sure it is useful as it the the rhs
    nlds = getNLDS(c, h.A, hb, T, h.linset, solver, newcut, AvgCutPruningAlgo(-1))
    rootdata = StructDualDynProg.StructProg.NodeData(nlds, 0)
    root = StructDualDynProg.SOI.add_scenario_node!(sp, rootdata)
    StructDualDynProg.SOI.set!(sp, StructDualDynProg.StructProg.CutGenerator(),
                               root, StructDualDynProg.StructProg.NoOptimalityCutGenerator())
    newnodes[(H.n,emptyset(),emptyset(),:NoAdh)] = root
    oldnodes = Dict{Tuple{Int,EntropyIndex,EntropyIndex,Symbol},Int}()
    addchildren!(sp, root, H.n, false, oldnodes, newnodes, solver, max_n, newcut, pruningalgo)
end

function StructDualDynProg.SOI.stochasticprogram(num_stages::Int, c::DualEntropy, h::EntropyCone, solver, max_n, cut::DualEntropy, newcut::Symbol, pruningalgo::Vector)
    # allnodes[n][J][K]: if K ⊆ J, it is self-adhesivity, otherwise it is inner-adhesivity
    allnodes = Dict{Tuple{Int,EntropyIndex,EntropyIndex,Symbol},Int}()
    sp = StructDualDynProg.StructProg.StochasticProgram{Float64}(num_stages)
    fillroot!(sp, c, h, cut, allnodes, solver, max_n, newcut, pruningalgo)
    sp, allnodes
end
function Base.append!(sp::StructDualDynProg.StructProg.StochasticProgram, oldnodes, solver, max_n, newcut, pruningalgo::Vector)
    newnodes = Dict{Tuple{Int,EntropyIndex,EntropyIndex,Symbol},Int}()
    for ((n,J,K,adh), node) in oldnodes
        addchildren!(sp, node, nadh(n,J,K,adh), true, oldnodes, newnodes, solver, max_n, newcut, pruningalgo)
    end
    merge!(oldnodes, newnodes)
end
function updatemaxncuts!(sp::StructDualDynProg.StructProg.StochasticProgram, allnodes, maxncuts::Vector{Int})
    for ((n,J,K,adh), node) in allnodes
        StructDualDynProg.updatemaxncuts!(nodedata(sp, node).nlds, maxncuts[nadh(n,J,K,adh)])
    end
end
