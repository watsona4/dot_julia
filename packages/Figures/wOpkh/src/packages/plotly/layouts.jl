module Layouts

using ..Utilities, ..LayoutUtilities

export Layout

const default_colorlist = ["#1f77b4","#ff7f0e","#2ca02c","#d62728","#9467bd","#8c564b","#e377c2","#7f7f7f","#bcbd22","#17becf"]

struct Layout <: Component
    font::Font
    title::Title
    autosize::Bool
    width::RangeValue{Int,(10,Inf),(true,true)}
    height::RangeValue{Int,(10,Inf),(true,true)}
    margin::Margin
    paper_bgcolor::Color
    plot_bgcolor::Color
    seperators::String
    hidesources::Bool
    showlegend::Bool
    colorway::Vector{Color}
    colorscale::LayoutColorScale
    # datarevision - Not implemented
    # uirevision - Not implemented
    # editrevision - Not implemented
    # template - Not implemented
    modebar::ModeBar
    meta::Vector{Any}
    transition::Transition
    clickmode::ClickMode
    dragmode::DragMode
    hovermode::HoverMode
    hoverdistance::HoverDistance
    spikedistance::SpikeDistance
    hoverlabel::HoverLabel
    selectdirection::SelectDirection
    grid::Grid
    calendar::Calendar
    xaxis::Axis
    yaxis::Axis
    function Layout(;
        font::Font = Font(),
        title::Title = Title(),
        autosize::Bool = true,
        width::Int = 700,
        height::Int = 450,
        margin::Margin = Margin(),
        paper_bgcolor::String = "#fff",
        plot_bgcolor::String = "#fff",
        separators::String = ".,",
        hidesources::Bool = false,
        showlegend::Bool = true,
        colorway::Vector{String} = default_colorlist,
        colorscale::LayoutColorScale = LayoutColorScale(),
        modebar::ModeBar = ModeBar(),
        meta::Vector{Any} = [],
        transition::Transition = Transition(),
        clickmode::String = "event",
        dragmode::String = "zoom",
        hovermode::String = "closest",
        hoverdistance::Int = 20,
        spikedistance::Int = 20,
        hoverlabel::HoverLabel = HoverLabel(),
        selectdirection::String = "any",
        grid::Grid = Grid(),
        calendar::String = "gregorian",
        xaxis::Axis = Axis(),
        yaxis::Axis = Axis())
        return new(
            font,
            title,
            autosize,
            RangeValue((10,Inf),width),
            RangeValue((10,Inf),height),
            margin,
            Color(paper_bgcolor),
            Color(plot_bgcolor),
            separators,
            hidesources,
            showlegend,
            Color.(colorway),
            colorscale,
            modebar,
            meta,
            transition,
            ClickMode(clickmode),
            DragMode(dragmode),
            HoverMode(hovermode),
            HoverDistance(hoverdistance),
            SpikeDistance(spikedistance),
            hoverlabel,
            SelectDirection(selectdirection),
            grid,
            Calendar(calendar),
            xaxis,
            yaxis)
    end
end
default["layout"] = Layout()

end
