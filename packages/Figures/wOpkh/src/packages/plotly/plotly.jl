module Plotly

using ..Figures, ..Pages, ..JSON

export Scatter, Layout, Config
export Font, Title, ColorBar, Gradient, Marker, Line, Error, Margin, Axis

include("utils.jl"); using .Utilities
include("traceutils.jl"); using .TraceUtilities
include("layoututils.jl"); using .LayoutUtilities
include("config.jl"); using .Configs

include("traces.jl");  using .Traces

include("layouts.jl"); using .Layouts

function newPlot(io::IO,id,traces;layout=default["layout"],config=default["config"])
    isa(traces,Vector) || (traces = [traces])

    data = similar(traces,Dict)
    figure(io,id, Style(
        "width" => string(layout.width.value,"px"),
        "height" => string(layout.height.value+30,"px")))
    for (i,trace) in enumerate(traces)
        data[i] = Utilities.diff(default[trace.type.value],trace)
    end
    layout = Utilities.diff(default["layout"],layout)
    config = Utilities.diff(default["config"],config)
    script = "Plotly.newPlot('$(Figures.current[])',$(json(data)),$(json(layout)),$(json(config)));"
    # println("***********************************************")
    # println(script)
    # println("***********************************************")
    print(io,script)
    return io
end

function react(id,traces)
    typeof(traces) <: Vector || (traces = [traces])

    data = similar(traces,Dict)
    figure(id)
    for (i,trace) in enumerate(traces)
        data[i] = diff(default[trace.type.value],trace)
    end
    Pages.broadcast("script",
        """Plotly.react("$(Figures.current[])",$(json(data)));""")
end

function plot(id,traces)
    typeof(traces) <: Vector || (traces = [traces])

    data = similar(traces,Dict)
    figure(id)
    for (i,trace) in enumerate(traces)
        data[i] = diff(default[trace.type.value],trace)
    end
    Pages.broadcast("script",
        """Plotly.plot("$(Figures.current[])",$(json(data)));""")
end

# function Base.display(::Figures.Display, trace::Trace)
#     println("Try to plot the trace.")
#     # id = isempty(Figures.current[]) ? p.plot.divid : Figures.current[]
#     # Pages.broadcast("script","""Plotly.newPlot("$(id)",$(p.plot.data),$(p.plot.layout),$(PlotlyJS.JSON.json(p.options)));""")
#     # println("""Plotly.newPlot("$(id)",$(p.plot.data),$(p.plot.layout),$(PlotlyJS.JSON.json(p.options)));""")
# end

end
