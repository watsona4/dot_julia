_hbox(args...) = Widgets.div(args...; style = Dict("display" => "flex", "flex-direction"=>"row"))
_vbox(args...) = Widgets.div(args...; style = Dict("display" => "flex", "flex-direction"=>"column"))

get_kwargs(; kwargs...) = kwargs
string2kwargs(s::AbstractString) = eval(Meta.parse("get_kwargs($s)"))

const analysis_options = OrderedDict(
    "" => nothing,
    "Cumulative" => Recombinase.cumulative,
    "Density" => Recombinase.density,
    "Hazard" => Recombinase.hazard,
    "Prediction" => Recombinase.prediction,
)

function is_small(col, n = 100)
    for (ind, _) in enumerate(IterTools.distinct(col))
        ind > n && return false
    end
    return true
end

function take_small(t, vec::AbstractVector{Symbol}, n = 100)
    filter(vec) do sym
        col = get(columns(t), sym, ())
        return is_small(col, n)
    end
end


"""
`gui(data, plotters; postprocess = NamedTuple())`

Create a gui around `data::IndexedTable` given a list of plotting
functions plotters.

## Examples

```julia
using StatsPlots, Recombinase, JuliaDB, Interact
school = loadtable(joinpath(Recombinase.datafolder, "school.csv"))
plotters = [plot, scatter, groupedbar]
Recombinase.gui(school, plotters)
```
"""
function gui(data′, plotters; postprocess = NamedTuple())
    (data′ isa AbstractObservable) || (data′ = Observable{Any}(data′))
    data = @map table(&data′, copy = false, presorted = true)
    ns = @map collect(colnames(&data))
    maybens = @map vcat(Symbol(), &ns)
    xaxis = dropdown(ns,label = "X")
    yaxis = dropdown(maybens,label = "Y")
    an_opt = dropdown(analysis_options, label = "Analysis")
    axis_type = dropdown([:automatic, :continuous, :discrete, :vectorial], label = "Axis type")
    error = dropdown(@map(vcat(automatic, &ns)), label="Error")
    styles = collect(keys(style_dict))
    sort!(styles)
    smallns = map(take_small, data, maybens)
    splitters = [dropdown(smallns, label = string(style)) for style in styles]
    plotter = dropdown(plotters, label = "Plotter")
    ribbon = toggle("Ribbon", value = false)
    btn = button("Plot")
    output = Observable{Any}("Set the dropdown menus and press plot to get started.")
    plot_kwargs = Widgets.textbox("Insert optional plot attributes")
    @map! output begin
        &btn
        select = yaxis[] == Symbol() ? xaxis[] : (xaxis[], yaxis[])
        grps = Dict(key => val[] for (key, val) in zip(styles, splitters) if val[] != Symbol())
        an = an_opt[]
        an_inf = isnothing(an) ? nothing : Analysis{axis_type[]}(an)
        args, kwargs = series2D(
                                an_inf, 
                                &data,
                                Group(; grps...);
                                postprocess = postprocess,
                                select = select,
                                error = error[],
                                ribbon = ribbon[]
                               )
        plotter[](args...; kwargs..., string2kwargs(plot_kwargs[])...)
    end
    ui = Widget(
        OrderedDict(
            :xaxis => xaxis,
            :yaxis => yaxis,
            :analysis => an_opt,
            :axis_type => axis_type,
            :error => error,
            :plotter => plotter,
            :plot_button => btn,
            :plot_kwargs => plot_kwargs,
            :ribbon => ribbon,
            :splitters => splitters,
        ),
        output = output
    )
    Widgets.@layout! ui Widgets.div(
                                    _hbox(
                                          :xaxis,
                                          :yaxis,
                                          :analysis,
                                          :axis_type,
                                          :error,
                                          :plotter
                                         ),
                                    :ribbon,
                                    :plot_button,
                                    _hbox(
                                          _vbox(:splitters...),
                                          _vbox(output, :plot_kwargs)
                                         )
                                   )
end
