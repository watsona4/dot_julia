import Base: push!
import SimilaritySearch: search
export InvIndex, prune, search
using SimilaritySearch

"""
Inverted index search structure

"""
mutable struct InvIndex <: Index
    lists::Dict{Symbol, Vector{SparseVectorEntry}}
    n::Int
    InvIndex() = new(Dict{Symbol, Vector{SparseVectorEntry}}(), 0)
    InvIndex(lists, n) = new(lists, n)
end

# useful constant for searching
const EMPTY_SPARSE_VECTOR = SparseVectorEntry[]

"""
    update!(a::InvIndex, b::InvIndex)

Updates inverted index `a` with `b`.
"""
function update!(a::InvIndex, b::InvIndex)
    for (sym, list) in b.lists
        if haskey(a.lists, sym)
            append!(a.lists[sym], list)
        else
            a.lists[sym] = list
        end
    end

    a.n += b.n
    a
end

"""
    save(f::IO, invindex::InvIndex)

Writes `invindex` to the given stream
"""
function save(f::IO, invindex::InvIndex)
    write(f, invindex.n)
    write(f, length(invindex.lists))
    for (sym, lst) in invindex.lists
        println(f, string(sym))
        write(f, length(lst))
        for p in lst
            write(f, p.id, p.weight)
        end
    end
end

"""
    load(f::IO, ::Type{InvIndex})

Reads an inverted index from the given file
"""
function load(f::IO, ::Type{InvIndex})
    invindex = InvIndex()
    invindex.n = read(f, Int)
    m = read(f, Int)
    for i in 1:m
        sym = Symbol(readline(f))
        l = read(f, Int)
        lst = Vector{SparseVectorEntry}(undef, l)
        invindex.lists[sym] = lst
        for j in 1:l
            id = read(f, Int)
            weight = read(f, Float64)
            lst[j] = SparseVectorEntry(id, weight)
        end
    end

    invindex
end

"""
    push!(index::InvIndex, objID::UInt64, bow::Dict{Symbol,Float64})

Inserts a weighted bag of words (BOW) into the index.

See [compute_bow](@ref) to compute a BOW from a text
"""
function push!(index::InvIndex, objID::Integer, bow::Dict{Symbol,Float64})
    index.n += 1
    for (sym, weight) in bow
        if haskey(index.lists, sym)
            push!(index.lists[sym], SparseVectorEntry(objID, weight))
        else
            index.lists[sym] = [SparseVectorEntry(objID, weight)]
        end
    end
end

function fit(::Type{InvIndex}, db::AbstractVector{Dict{Symbol,Float64}})
    invindex = InvIndex()
    for (i, bow) in enumerate(db)
        push!(invindex, i, bow)
    end

    invindex
end

"""
    prune(invindex::InvIndex, k)

Creates a new inverted index using the given `invindex` discarding many entries with low weight.
It keeps at most `k` entries for each posting list; it keeps those entries with more wight values.
"""
function prune(invindex::InvIndex, k)
    I = InvIndex()
    I.n = invindex.n
    sizehint!(I.lists, length(invindex.lists))

    for (t, list) in invindex.lists
        I.lists[t] = l = deepcopy(list)
        sort!(l, by=x -> -x.weight)
        if length(list) > k
            resize!(l, k)
        end
    end

    # normalizing prunned vectors
    _norm_pruned!(I)
end

function _norm_pruned!(I::InvIndex)
    D = Dict{Int,Float64}()
    
    for (t, list) in I.lists
        for p in list
            D[p.id] = get(D, p.id, 0.0) + p.weight * p.weight
        end
    end

    for (k, v) in D
        D[k] = 1.0 / sqrt(v)
    end

    for (t, list) in I.lists
        for p in list
            p.weight *= D[p.id]
        end
    end

    I
end

"""
    search(invindex::InvIndex, dist::Function, q::Dict{Symbol, R}, res::KnnResult) where R <: Real

Seaches for the k-nearest neighbors of `q` inside the index `invindex`. The number of nearest
neighbors is specified in `res`; it is also used to collect the results. Returns the object `res`.
If `dist` is set to `angle_distance` then the angle is reported; otherwise the
`cosine_distance` (i.e., 1 - cos) is computed.
"""
function search(invindex::InvIndex, dist::Function, q::Dict{Symbol, R}, res::KnnResult) where R <: Real
    D = Dict{Int, Float64}()
    # normalize!(q) # we expect a normalized q 
    for (sym, weight) in q
        lst = get(invindex.lists, sym, EMPTY_SPARSE_VECTOR)
        if length(lst) > 0
            for e in lst
                D[e.id] = get(D, e.id, 0.0) + weight * e.weight
            end
        end
    end

    for (i, w) in D
        if dist == angle_distance
            w = max(-1.0, w)
            w = min(1.0, w)
            w = acos(w)
            push!(res, i, w)
        else
            push!(res, i, 1.0 - w)  # cosine distance
        end
    end

    res
end
