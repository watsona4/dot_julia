const Tup = Union{Tuple, NamedTuple}

struct Automatic; end
const automatic = Automatic()
Base.string(::Automatic) = "automatic"

apply(f::Function, a::Automatic) = a
apply(f::Function, val) = f(val)
apply(f::Tup, val::Tup) = map(apply, f, val)
apply(f::Function, val::Tup) = map(f, val)
_all(f::Function, tup::Tup) = all(f, tup)
_all(f::Function, t) = f(t)

isfinitevalue(::Missing) = false
isfinitevalue(x::Number) = isfinite(x)

statpost(m::OnlineStat) = m => value
statpost(sp::Pair{<:OnlineStat}) = sp

initstat(m::OnlineStat; kwargs...) = initstat(m => value; kwargs...)
function initstat(sp::Pair{<:OnlineStat}; filter = isfinitevalue, transform = identity)
    stat, func = sp
    FTSeries(stat; filter = filter, transform = transform) => t -> func(first(t.stats))
end

function initstat(stats::Tuple; filter = isfinitevalue, transform = identity)
    statsfuncs = map(statpost, stats)
    stats = map(first, statsfuncs)
    funcs = map(last, statsfuncs)
    FTSeries(stats...; filter = filter, transform = transform) => t -> apply(funcs, t.stats)
end

const summary = (Mean(), Variance() => t -> sqrt(value(t)/nobs(t)))

function lazy_summary(keys::AbstractVector, cols; perm = sortperm(keys), min_nobs = 2, stats = summary, kwargs...)
    stat, func = initstat(stats; kwargs...)
    function process(idxs)
        apply(cols) do col
            init = copy(stat)
            for i in idxs
                val = col[perm[i]]
                fit!(init, val)
            end
            return init
        end
    end
    iter = (keys[perm[first(idxs)]] => process(idxs) for idxs in GroupPerm(keys, perm))
    return (key => apply(func, vals) for (key, vals) in iter if _all(t -> nobs(t) >= min_nobs, vals))
end

compute_summary(keys::AbstractVector, cols::AbstractVector; kwargs...) = compute_summary(keys, (cols,); kwargs...)
function compute_summary(keys::AbstractVector, cols::Tup; kwargs...)
    collect_columns(val for (_, val) in lazy_summary(keys, cols; kwargs...))
end

function compute_summary(f::FunctionOrAnalysis, keys::AbstractVector, cols::AbstractVector; kwargs...)
    compute_summary(f, keys, (cols,); kwargs...)
end

function compute_summary(f::FunctionOrAnalysis, keys::AbstractVector, cols::Tup;
    min_nobs = 2, perm = sortperm(keys), stats = summary, kwargs...)

    stat, func = initstat(stats; kwargs...)
    analysis = compute_axis(f, cols...)
    axis = get_axis(analysis)
    summaries = [copy(stat) for _ in axis]
    data = StructVector(cols)
    _compute_summary!(axis, summaries, analysis, keys, perm, data)
    return collect_columns((ax, func(s)) for (ax, s) in zip(axis, summaries) if nobs(s) >= min_nobs)
end

_first(t) = t
_first(t::Union{Tuple, NamedTuple}) = first(t)

function fititer!(axis, summaries, iter)
    lo, hi = extrema(axes(axis, 1))
    for (key, val) in iter
        ind = searchsortedfirst(axis, key, lo, hi, Base.Order.Forward)
        lo = ind + 1
        ind > hi && break
        fit!(summaries[ind], _first(val))
    end
end

function _compute_summary!(axis, summaries, analysis, keys, perm, data)
    for (_, idxs) in finduniquesorted(keys, perm)
        res = analysis(tupleofarrays(view(data, idxs))...)
        fititer!(axis, summaries, res)
    end
end

compute_summary(::Nothing, args...; kwargs...) = compute_summary(args...; kwargs...)

compute_summary(t::IndexedTable, ::Automatic; select, kwargs...) =
    compute_summary(t; select = select, kwargs...)

function compute_summary(t::IndexedTable; select, kwargs...)
    rows(t, select)
end

function compute_summary(t::IndexedTable, keys; select, kwargs...)
    perm, keys = sortpermby(t, keys, return_keys=true)
    compute_summary(keys, columntuple(t, select); perm=perm, kwargs...)
end

function compute_summary(f::FunctionOrAnalysis, t::IndexedTable, keys; select, kwargs...)
    perm, keys = sortpermby(t, keys, return_keys=true)
    compute_summary(f, keys, columntuple(t, select); perm=perm, kwargs...)
end

function compute_summary(f::FunctionOrAnalysis, t::IndexedTable; select, kwargs...)
    args = columntuple(t, select)
    has_error(f, args...) && (f = f(; kwargs...))
    collect_columns(f(args...))
end

compute_summary(f::FunctionOrAnalysis, t::IndexedTable, ::Automatic; select, kwargs...) =
    compute_summary(f, t; select=select, kwargs...)

tupleofarrays(s::Tup) = Tuple(s)
tupleofarrays(s::StructVector) = Tuple(fieldarrays(s))

to_tuple(s::Tup) = s
to_tuple(v) = (v,)
columntuple(t, cols) = to_tuple(columns(t, cols))
columntuple(t) = to_tuple(columns(t))
