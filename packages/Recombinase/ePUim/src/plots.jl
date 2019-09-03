struct Group{NT}
    kwargs::NT
    function Group(; kwargs...)
        nt = values(kwargs)
        NT = typeof(nt)
        return new{NT}(nt)
    end
end

Group(s) = Group(color = s)
apply(f::Function, g::Group) = Group(; map(t -> apply(f, t), g.kwargs)...)

to_string(t::Tuple) = join(t, ", ")
to_string(t::Any) = string(t)
to_string(nt::NamedTuple) = join(("$a = $b" for (a, b) in pairs(nt)), ", ")

struct Observations; end
const observations = Observations()
Base.string(::Observations) = "observations"

function sortpermby(t::IndexedTable, ::Observations; return_keys = false)
    perm = Base.OneTo(length(t))
    return return_keys ? (perm, perm) : perm
end

function apply_postprocess(t::IndexedTable, res; select, postprocess)
    cols = Tuple(fieldarrays(res))
    colinds = to_tuple(lowerselection(t, select))
    N = length(colinds)
    cols_trimmed = cols[1:N]
    res = map(cols_trimmed, colinds) do col, ind
        isa(ind, Integer) && ind > 0 || return col 
        name = colnames(t)[ind]
        haskey(postprocess, name) || return col
        f = postprocess[name]
        return collect_columns(apply(f, el) for el in col)
    end
    StructArray((res..., cols[N+1:end]...))
end

function series2D(s::StructVector; ribbon = false)
    kwargs = Dict{Symbol, Any}()
    xcols, ycols = map(columntuple, fieldarrays(s))
    x, y = xcols[1], ycols[1]
    yerr = ifelse(ribbon, :ribbon, :yerr)
    length(xcols) == 2 && (kwargs[:xerr] = xcols[2])
    length(ycols) == 2 && (kwargs[yerr] = ycols[2])
    return (x, y), kwargs
end

series2D(t, g = Group(); kwargs...) = series2D(nothing, t, g; kwargs...)

function series2D(f::Union{Nothing, FunctionOrAnalysis}, t, g = Group();
                  select, error = automatic, kwargs...)
    isa(g, Group) || (g = Group(g)) 
    by = _flatten(g.kwargs)
    err_cols = error === automatic ? () : to_tuple(error)
    sel_cols = (to_tuple(by)..., to_tuple(select)..., err_cols...)
    coltable = Tables.columntable(Tables.select(t, sel_cols...))
    coldict = Dict(zip(sel_cols, keys(coltable)))
    to_symbol = i -> coldict[i]
    t = table(coltable, copy=false)
    return series2D(f, t, apply(to_symbol, g);
                    select = apply(to_symbol, select),
                    error = apply(to_symbol, error),
                    kwargs...)
end

function series2D(f::Union{Nothing, FunctionOrAnalysis}, t′::IndexedTable, g = Group(); select, postprocess = NamedTuple(),
    error = automatic, ribbon=false, stats=summary, filter=isfinitevalue, transform=identity, min_nobs=2, kwargs...)

    t = dropmissing(t′, select)
    isa(g, Group) || (g = Group(g)) 
    group = g.kwargs
    if isempty(group)
        itr = ("" => :,)
    else
        by = _flatten(group)
        perm, group_rows = sortpermby(t, by, return_keys = true)
        itr = finduniquesorted(group_rows, perm)
    end
    data = collect_columns_flattened(
        key => compute_summary(
            f,
            view(t, idxs),
            error;
            min_nobs=min_nobs,
            select=select,
            stats=stats,
            filter=filter,
            transform=transform,
        ) for (key, idxs) in itr
    )
    res = apply_postprocess(t, data.second; select = select, postprocess = postprocess)
    plot_args, plot_kwargs = series2D(res; ribbon = ribbon)
    plot_kwargs[:group] = columns(data.first)
    grpd = collect_columns(key for (key, _) in itr)
    style_kwargs = Dict(kwargs)
    for (key, val) in pairs(group)
        col = rows(grpd, val)
        s = unique(sort(col))
        d = Dict(zip(s, 1:length(s)))
        style = get(style_kwargs, key) do
            style_dict[key]
        end
        plot_kwargs[key] = permutedims(access_style(style, getindex.(Ref(d), col)))
    end
    get!(plot_kwargs, :color, "black")
    plot_args, plot_kwargs
end

function access_style(st, n::AbstractArray)
    [access_style(st, i) for i in n]
end

function access_style(st, n::Integer)
    v = vec(st)
    m = ((n-1) % length(v))+1
    v[m]
end

_flatten(t) = IterTools.imap(to_tuple, t) |>
    Iterators.flatten |>
    IterTools.distinct |>
    Tuple
