
export maxcol, myround, clip, clip!, trim, trim!, MINWEIGHT, MINPROB, sortcols

const MINWEIGHT = 1e-10 ## trim() deletes prior points with less than this weight.
const MINPROB = 1e-100  ## clip() sets to zero entries smaller than this.
const DIGITS = 5 ## digits to round off to when calling unique(), by default

using Statistics

"""
    mean(x::Weighted)
Takes the mean along `dims=ndims(x)` taking `weights(x)` into account. Now returns a Weighted.
"""
function Statistics.mean(x::Weighted)
    arr = sum( x.array .* reshape(weights(x), Iterators.repeated(1,ndims(x)-1)...,:) ; dims=ndims(x))
    Weighted(arr, [1.0], x.opt)
end

"""
    maxcol(x)
    maxcol(x, weights)
Returns the column of `x` with the largest weight, as the same type.
If `x::Weighted{Matrix}` then weights need not be given.
"""
function maxcol(x::Weighted{<:AbsMat}, λ=x.weights)
    (m,i) = findmax(λ)
    Weighted(x.array[:, i:i], [x.weights[i]], unnormalise(x.opt))
end
maxcol(x::AbsMat, λ::AbsVec) = begin (m,i) = findmax(λ); x[:, i:i] end


"""    sort(x::Weighted)
Sorts according to `weights(x)`, with `rev=true` thus biggest first by default. See `sortcols()` to sort by `array(x)` instead. """
function Base.sort(x::Weighted; rev=true)
    ind = sortperm(weights(x), rev=rev)
    ndims(x)==1 && return Weighted(x.array[ind], x.weights[ind], x.opt)
    ndims(x)==2 && return Weighted(x.array[:,ind], x.weights[ind], x.opt)
    ndims(x)==3 && return Weighted(x.array[:,:,ind], x.weights[ind], x.opt)
    error("sort doesn't understand >=4-index Weighted yet, sorry")
end

"""    sortcols(x::WeightedMatrix)
Sorts according to `θ₁`, i.e. the first row of `array(x)`."""
function sortcols(x::WeightedMatrix; kw...)
    perm = sortperm(x.array[1,:]; kw...)
    Weighted( x.array[:,perm], x.weights[perm], x.opt)
end

"""
    round(x::Weighted; digits)
Rounds off θ `x.array`... digits need not be an integer. Always rounds -0.0 to 0.0, too.
    myround(x, digits)
Works without keywords!
"""
Base.round(x::Weighted; digits::Real=DIGITS) =
    Weighted( myround.(x.array, digits), x.weights, x.opt )

myround(x::Weighted, digits::Real=DIGITS) = round(x; digits=digits)

function myround(num::Real, dig::Real=DIGITS) ## this allows me to round(π, 1.5)
    factor = 10^(dig-floor(dig))
    round(num*factor; digits=Int(floor(dig)))/factor |> flipzero
end
myround(num::Real, dig::Int) = round(num; digits=dig) |> flipzero

flipzero(x::Real) = ifelse(x==-0.0, zero(x), x)

using .GroupSlices
using EllipsisNotation

uniquedoc = """
    unique!(x::Weighted)
    unique!(f, x) = unique!(x, f) = unique!(x, f(x))
Removes duplicate points while combining their weights. Decided up to `digits=$DIGITS` digits,
and after applying function `f` if given. Now works for any `ndims(x)`.

    unique(x) = unique!(copy(x))
    unique(f, x)
Non-mutating version.

Note BTW that both of these return `x` partially sorted, done so that among nearly co-incident points,
the position of the heaviest is kept. But the result is not sure to be completely sorted.
"""
@doc uniquedoc
Base.unique!(x::Weighted, y::Weighted=x; digits=DIGITS) = begin x.array, x.weights = unique_(x,y;digits=digits); x end
Base.unique!(x::Weighted, f::Function; kw...) = unique!(x, f(x); kw...)
Base.unique!(f::Function, x::Weighted; kw...) = unique!(x, f(x); kw...) ## matching built-in order now

@doc uniquedoc
Base.unique(x::Weighted, y::Weighted=x; digits=DIGITS) = Weighted(unique_(x,y;digits=digits)..., x.opt)
Base.unique(x::Weighted, f::Function; kw...) = unique(x, f(x); kw...)
Base.unique(f::Function, x::Weighted; kw...) = unique(x, f(x); kw...)

@inline function unique_(x::Weighted, y::Weighted=x; digits=DIGITS)

    if ndims(x)==2 && size(x.array,1)==0 && size(y.array,1)==0 ## special case: cannot alter order
        return x.array, x.weights
    end

    perm = sortperm(y.weights, rev=true)

    ind = groupslices( myround.(y.array, digits)[..,perm] ,ndims(x))

    k = size(x, ndims(x))
    w = zeros(eltype(x.weights), k)

    if ndims(x)==2 && size(x,1)==0 && size(y,1)>0 ## special case: cannot alter order, but can move weight around
        for i=1:k
            w[perm[ind[i]]] += x.weights[perm[i]]
        end
        return x.array, w
    end

    for i=1:k
        w[ind[i]] += x.weights[perm[i]]
    end

    uind = unique(ind)

    x.array[..,perm[uind]], w[uind] ## .. is EllipsisNotation
end


"""
    trim(x::Weighted)
    trim!(x::Weighted)
Removes points with weight less than cutoff `cut=$MINWEIGHT`, either copying or mutating.

    trim!(Π::Weighted, L::Weighted)
Removes the same columns from both, using the first one's weights. Mutates both arguments! Returns tuple `(Π,L)`.
"""
trim(x::AbstractArray) = x
trim!(x::AbstractArray) = x

trim(x::Weighted; kw...) = Weighted(trim_(x; kw...)..., x.opt)

@doc @doc(trim)
trim!(x::Weighted; kw...) = begin x.array, x.weights = trim_(x; kw...); x end

@inline function trim_(x::Weighted; cut=MINWEIGHT)
    keep = weights(x) .> cut
    if size(x,1)==0 ## special case used for MultiModel... do not move or delete things.
        keep[:] .= true
    end
    x.array[.., keep], x.weights[keep] ## .. is EllipsisNotation
end

function trim!(x::Weighted, y::Weighted; cut=MINWEIGHT)
    keep = weights(x) .> cut
    x.array = x.array[..,keep]
    x.weights = x.weights[keep]
    y.array = y.array[..,keep]
    y.weights = y.weights[keep]
    x,y
end

"""
    clip(x, ϵ=$MINPROB)
    clip!(x)
Sets to zero all entries `abs(x[i]) < ϵ`. When `x::Weighted` this acts on `x.array` only; see also `trim()`.
"""
clip(x::Real, ϵ::Real=MINPROB) = ifelse(abs(x)<ϵ, zero(x), x)

@doc @doc(clip)
function clip!(x::Array, ϵ::Real=MINPROB)
    for i in eachindex(x)
        x[i] = clip(x[i], ϵ)
    end
end

clip(x::Weighted, ϵ::Real=MINPROB) = clip.(x, ϵ)
clip!(x::Weighted, ϵ::Real=MINPROB) = begin clip!(x.array, ϵ); x end

"""
    mapslices(f, x::Weighted)
If no dimensions are given, then `f` acts on slices `x.array[:,...:, c]` for `c=1:lastlength(x)`.
`x.weights` are untouched.
"""
function Base.mapslices(f::Function, x::Weighted; dims=collect(1:ndims(x)-1))
    array = mapslices(f, x.array; dims=dims)
    @assert size(array, ndims(array)) == length(x.weights) "mapslices must preserve lastlength(array)"
    Weighted(array, x.weights, addlname(Π.opt, "map-") |> unclamp)
end

using SliceMap

slicedoc = """
    MapCols(f, x::Weighted)
    MapCols{d}(f, x::Weighted)
    ThreadMapCols{d}(f, x::Weighted)
Like `mapslices(f,x)` but for SVector column slices, each of length `d`.
`x.weights` are untouched.
"""
@doc slicedoc
SliceMap.MapCols(f::Function, M::WeightedMatrix, args...)  =
    MapCols{size(M,1)}(f, M, args...)

SliceMap.MapCols{d}(f::Function, M::WeightedMatrix, args...) where {d} =
    Weighted(MapCols{d}(f, M.array, args...), M.weights, addlname(Π.opt, "map-") |> unclamp)

@doc slicedoc
SliceMap.ThreadMapCols{d}(f::Function, M::WeightedMatrix, args...) where {d} =
    Weighted(ThreadMapCols{d}(f, M.array, args...), M.weights, addlname(Π.opt, "map-") |> unclamp)

@doc slicedoc
SliceMap.mapcols(f::Function, M::WeightedMatrix, args...) =
    Weighted(mapcols(map, f, M.array, args...), M.weights, addlname(Π.opt, "map-") |> unclamp)



"""    log(Π)
Log all entries, approximately `== log.(Π)` but with nice labels etc. """
function Base.log(Π::Weighted)
    if Π.opt.clamp==false || Π.opt.lo <0
        @warn "taking log of Weighted Array which isn't clamped to positive numbers" maxlog=3
    end
    Weighted(log.(Π.array), Π.weights, addlname(Π.opt, "log-") |> unclamp)
end

"""    sqrt(Π)
Sqrt all entries, approximately `== sqrt.(Π)` but with nice labels etc. """
function Base.sqrt(Π::Weighted)
    hi = sqrt(Π.opt.hi)
    if Π.opt.clamp==false || Π.opt.lo <0
        @warn "taking sqrt of Weighted Array which isn't clamped to positive numbers"  maxlog=3
        hi = Inf
    end
    Weighted(sqrt.(Π.array), Π.weights, clamp(addlname(Π.opt, "sqrt-"),0,hi))
end

"""    tanh(Π)
Compactifies all entries to [-1,1], approximately `== tanh.(Π)` but with nice labels etc. """
Base.tanh(Π::Weighted) = Weighted(tanh.(Π.array), Π.weights, clamp(addlname(Π.opt, "tanh-"),-1,1) )

"""    sigmoid(Π)
Compactifies all entries to [0,1], approximately `== sigmoid.(Π)` but with nice labels etc. """
sigmoid(x::Number) = 1 / (1 + exp(-x))
sigmoid(Π::Weighted) = Weighted(sigmoid.(Π.array), Π.weights, clamp(addlname(Π.opt, "sigmoid-"),0,1))
