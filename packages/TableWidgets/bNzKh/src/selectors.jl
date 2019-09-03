lazymap(f, v) = (f(i) for i in v)

# To be replaced by the equivalent operations in TableOperators
_filter(t) = t
function _filter(t, args...)
    mask = [all(i) for i in zip(args...)]
    map(x -> x[mask], Tables.columntable(t))
end

@enum ColumnType categorical numerical arbitrary

const selectordict = Dict(
    categorical => categoricalselector,
    numerical => rangeselector,
    arbitrary => selector,
)

const selectortypes = [:categoricalselector, :rangeselector, :selector]

function hasdistinct(col, n)
    itr = IterTools.distinct(col)
    for (i, _) in enumerate(itr)
        i >= n && return true
    end
    return false
end

struct DefaultType
    threshold::Int
end

(d::DefaultType)(col::AbstractVector{<:Union{Missing, Real}}) = hasdistinct(col, d.threshold) ? numerical : categorical
(d::DefaultType)(col::AbstractVector) = hasdistinct(col, d.threshold) ? arbitrary : categorical

function selectors(t, obs::AbstractObservable; types = Dict(), threshold = 10, default_type = DefaultType(threshold))
    t isa AbstractObservable || (t = Observable{Any}(t))
    cols = map(Tables.columntable, t)
    output = map(x -> Tables.materializer(t[])(x), cols)

    sel_dict = OrderedDict(sym => Observable{Any}(Widget[]) for sym in selectortypes)

    function update_sels!(x)
        for sym in selectortypes
            empty!(sel_dict[sym][])
        end
        for (name, col) in pairs(x)
            sel_func = selectordict[get(types, name, default_type(col))]
            sel = sel_func(col, lazymap)
            push!(sel_dict[widgettype(sel)][], toggled(sel; label = string(name), readout = false))
        end
        for sym in selectortypes
            sel_dict[sym][] = sel_dict[sym][]
        end
    end

    update_sels!(cols[])
    on(update_sels!, cols)

    wdg = Widget{:selectors}(sel_dict; output = output)

    on(obs) do _
        selwdgs = Iterators.flatten(wdg[seltyp][] for seltyp in selectortypes)
        sels = (i[] for i in selwdgs if i[:toggle][])
        output[] = Tables.materializer(t[])(_filter(cols[], sels...))
    end

    layout!(wdg) do x
        sel_cols = [node(
            :div,
            className = "column",
            string(typ),
            @map(node(:div, &x[typ]...))
        ) for typ in selectortypes]
        filters = node(:div, className = "columns", sel_cols...)
    end
end

function selectors(t; kwargs...)
    btn = button("Filter")
    wdg = selectors(t, btn; kwargs...)
    wdg[:filter] = btn
    Widgets.layout(wdg) do x
        node(:div, wdg[:filter], x)
    end
end
