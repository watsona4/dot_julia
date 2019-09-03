"""
`addfilter(t; readout = true)`

Create selectors (`categoricalselector`, `rangeselector`, `selector` are supported) and delete them for various
columns of table `t`. `readout` denotes whether the table will be displayed initially. Outputs the filtered table.
"""
function addfilter(t, r = 6; readout = true)
    t isa AbstractObservable || (t = Observable{Any}(t))

    wdg = Widget{:addfilter}(output = Observable{Any}(t[]))
    cols = map(Tables.columntable, t)

    wdg[:cols] = dropdown(map(collect∘propertynames, cols), placeholder = "Column to filter", value = nothing)

    selectoptions = OrderedDict(
        "categorical" => categoricalselector,
        "range" => rangeselector,
        "predicate" => selector
    )

    wdg[:selectortype] = dropdown(selectoptions, placeholder = "Selector type", value = nothing)
    wdg[:button] = button("Add selector")
    wdg[:filter] = button("Filter")

    wrap = Widgets.div(className = "column")
    container = Widgets.div(className = "columns is-multiline is-mobile")
    wdg[:selectors] = notifications([], wrap = wrap, container = container)

    @on begin
        &wdg[:button]
        push!(wdg[:selectors][], wdg[:selectortype][](cols[], wdg[:cols][], lazymap))
        wdg[:selectors][] = wdg[:selectors][]
    end

    on(wdg[:filter]) do x
        sels = (observe(i)[] for i in observe(wdg[:selectors])[])
        wdg.output[] = _filter(cols[], sels...)
    end

    @layout! wdg Widgets.div(
        Widgets.div(className = "level is-mobile", map(Widgets.div(className="level-item"), [:cols, :selectortype, :button, :filter])...),
        :selectors,
        toggled(head(_.output, r), readout = true),
        className = "interact-widget"
    )
    on(t) do x
        observe(wdg, :selectors)[] = []
        observe(wdg)[] = x
    end
    wdg
end

addfilter(t::Widgets.AbstractWidget; kwargs...) = addfilter(observe(t); kwargs...)
