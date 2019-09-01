module Traces

import ..JSON: json

using ..Utilities, ..TraceUtilities

export Scatter #, Bar, Box, HeatMap, Histogram

# Export only utiliity types that are needed in constructors
# export Font, Title, ColorBar, Gradient, Marker, Line, Error

mutable struct Scatter <: Trace
    type::ChartType
    attributes::Attributes
    stackgroup::String
    groupnorm::GroupNorm
    stackgaps::StackGaps
    mode::Mode
    hoveron::HoverOn
    line::Line
    connectgaps::Bool
    cliponaxis::Bool
    fill::Fill
    fillcolor::Color
    textposition::TextPosition
    textfont::Font
    error_x::Error
    error_y::Error

    function Scatter(;
        stackgroup::String = "",
        groupnorm::String = "",
        stackgaps::String = "infer zero",
        mode::String = "lines+markers",
        hoveron::String = "points",
        line::Line = Line(),
        connectgaps::Bool = false,
        cliponaxis::Bool = true,
        fill::String = "none",
        fillcolor::String = "#444",
        textposition::String = "middle center",
        textfont::Font = Font(),
        error_x::Error = Error(),
        error_y::Error = Error(),kwargs...)
        return new(
            ChartType("scatter"),
            Attributes(;kwargs...),
            stackgroup,
            GroupNorm(groupnorm),
            StackGaps(stackgaps),
            Mode(mode),
            HoverOn(hoveron),
            line,
            connectgaps,
            cliponaxis,
            Fill(fill),
            Color(fillcolor),
            TextPosition(textposition),
            textfont,
            error_x,
            error_y)
    end
end
default["scatter"] = Scatter()

# struct Bar <: Trace
#     type::ChartType
#     attributes::Attributes
#     cliponaxis::Bool
#     textposition::TextPosition
#     textfont::Font
#     insidetextfont::Font
#     outsidetextfont::Font
#     constraintext::ConstrainText
#     base::Float64
#     offset::Union{Float64,Vector{Float64}}
#     width::Union{Size{Float64},Vector{Size{Float64}}}
#     offsetgroup::String
#     alignmentgroup::String
#     error_x::Error
#     error_y::Error

#     function Bar(;
#         cliponaxis::Bool = true,
#         textposition::String = "none",
#         textfont::Font = Font(),

#         insidetextfont::Font = Font(),
#         outsidetextfont::Font = Font(),
#         constraintext::String = "both",
#         base::Float64,
#         offset::Union{Float64,Vector{Float64}},
#         width::Union{Size{Float64},Vector{Size{Float64}}},
#         offsetgroup::String,
#         alignmentgroup::String,
#         error_x::Error,
#         error_y::Error,


#         error_x::Error = Error(),
#         error_y::Error = Error(),kwargs...)
#         return new(
#             ChartType("bar"),
#             Attributes(;kwargs...),
#             cliponaxis,
#             TextPosition(textposition),
#             textfont,
#             )
#     end
# end

# function Base.display(::Figures.Display, scatter::Scatter)
#     println("Try to plot the scatter trace.")
#     s = diff(default["Scatter"],scatter)
#     println(json(s))
#     # id = isempty(Figures.current[]) ? p.plot.divid : Figures.current[]
#     # Pages.broadcast("script","""Plotly.newPlot("$(id)",$(p.plot.data),$(p.plot.layout),$(PlotlyJS.JSON.json(p.options)));""")
#     # println("""Plotly.newPlot("$(id)",$(p.plot.data),$(p.plot.layout),$(PlotlyJS.JSON.json(p.options)));""")
# end

# struct Box <: Trace
#     option::TraceOptions
#     whiskerwidth::RangeValue{Float64,(0,1),(true,true)}
#     notched::Bool
#     notchwidth::RangeValue{Float64,(0,.5),(true,true)}
#     boxpoints::BoxPoints
#     boxmean::BoxMean
#     jitter::RangeValue{Float64,(0,1),(true,true)}
#     pointpos::RangeValue{Float64,(-2,2),(true,true)}
#     hoveron::HoverOn
#     line::Line
#     fillcolor::String
#     width::Union{Size{Float64},Vector{Size{Float64}}}
#     offsetgroup::String
#     alignmentgroup::String
# end

# struct HeatMap <: Trace
#     options::TraceOptions
#     z::Vector{Float64}
#     transpose::Bool
#     xtype::CoordinateType
#     ytype::CoordinateType
#     zsmooth::ZSmooth
#     connectgaps::Bool
#     xgap::Size{Int}
#     ygap::Size{Int}
#     zhoverformat::Union{String,Vector{String}}
#     zauto::Bool
#     zmin::Float64
#     zmax::Float64
#     zmid::Float64
#     colorscale::ColorScale
#     autocolorscale::Bool
#     reversescale::Bool
#     showscale::Bool
#     colorbar::ColorBar
# end

# struct Histogram <: Trace
#     options::TraceOptions
#     histfunc::HistFunc
#     histnorm::Union{HistNorm,Nothing}
#     cumulative::Cumulative
#     nbinsx::Size{Int}
#     xbins::Bins
#     nbinsy::Size{Int}
#     ybins::Bins
#     autobinx::Bool
#     autobiny::Bool
#     offsetgroup::String
#     alignmentgroup::String
#     error_x::Error
#     error_y::Error
# end

end
