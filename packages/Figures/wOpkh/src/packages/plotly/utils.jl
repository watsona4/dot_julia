module Utilities

export ComponentValue, ComponentType, Component, ComponentChild, Enumerated,
        FlagList, RangeValue, Size, Count, Normalized, Color, FontSize, Font,
        Side, AxisRef, XAnchor, YAnchor, Margin, Title, ColorScale,
        ColorScaleSet, Orientation, Easing, Ordering, Transition, NameLength,
        HoverLabel, Calendar, TickMode, Ticks, TickFormatStops, ShowTickPrefix,
        ShowTickSuffix, ExponentFormat, ShowExponent, Dash, default

abstract type ComponentValue end
abstract type ComponentType end
abstract type Component <: ComponentType end
abstract type ComponentChild <: ComponentType end

const default = Dict{String,Component}()

diff(ref::ComponentValue,obj::ComponentValue) = diff(ref.value,obj.value)

function diff(ref,obj)
    ref != obj && return obj
    return
end

struct Enumerated{E,T} <: ComponentValue
    value::Union{String,Bool}

    function Enumerated{E,T}(v) where {E,T}
        Symbol(v) in T || v in T ||
        error("$(E): \"$(v)\" not found in $(tuple([isbits(t) ? t : string(t) for t in T]...))")
        return new{E,T}(v)
    end
end

struct FlagList{S,T} <: ComponentValue
    value::Union{String,Bool}

    function FlagList{S,T}(s::Union{String,Bool}) where {S,T}
        flags = isa(s,String) ? Symbol.(split(s,'+')) : Bool[s]
        length(flags) == 1 && (Symbol(flags[1]) in T || flags[1] in T) && return new(s)
        for flag in flags
            Symbol(flag) in S || flag in S || error("$(flag) not found in $(S)")
        end
        return new(s)
    end
end

struct RangeValue{N,R,T} <: ComponentValue
    value::N

    function RangeValue{N,R,T}(v::N) where {N,R,T}
        errmsg = "$(v) is outside the range $(T[1] ? "[" : "(")$(R[1]),$(R[2])$(T[2] ? "]" : ")")"
        (v < R[1]) && error(errmsg)
        (v > R[2]) && error(errmsg)
        (!T[1] && v == R[1]) && error(errmsg)
        (!T[2] && v == R[2]) && error(errmsg)
        return new(v)
    end
end
RangeValue(range,value) = RangeValue{typeof(value),range,(true,true)}(value)

const Size{S} = RangeValue{S,(0,Inf),(true,false)}

const Count = RangeValue{Int,(1,Inf),(true,false)}

const Normalized = RangeValue{Float64,(0,1),(true,true)}

struct Color <: ComponentValue
    value::String
end

const FontSize = RangeValue{Int,(1,Inf),(true,false)}

struct Font <: ComponentType
    family::Union{String,Vector{String}}
    size::Union{FontSize,Vector{FontSize}}
    color::Union{Color,Vector{Color}}

    function Font(;
        family::Union{String,Vector{String}}="",
        size::Union{Int,Vector{Int}}=6,
        color::Union{String,Vector{String}}="#000")
        return new(family,FontSize.(size),Color.(color))
    end
end

const Side = Enumerated{:Side,(:left,:right,:top,:bottom)}

const AxisRef = Enumerated{:AxisRef,(:container,:paper)}

const XAnchor = Enumerated{:XAnchor,(:auto,:left,:center,:right)}

const YAnchor = Enumerated{:YAnchor,(:auto,:top,:middle,:bottom)}

struct Margin <: ComponentType
    t::Size{Int}
    r::Size{Int}
    b::Size{Int}
    l::Size{Int}
    pad::Size{Int}
    autoexpand::Bool

    function Margin(;
        t::Int = 0,
        r::Int = 0,
        b::Int = 0,
        l::Int = 0,
        pad::Int = 0,
        autoexpand::Bool = true)
        return new(
            Size{Int}(t),
            Size{Int}(r),
            Size{Int}(b),
            Size{Int}(l),
            Size{Int}(pad),
            autoexpand)
    end
end

struct Title <: ComponentType
    text::String
    font::Font
    side::Side
    xref::AxisRef
    yref::AxisRef
    x::Normalized
    y::Normalized
    xanchor::XAnchor
    yanchor::YAnchor
    pad::Margin

    function Title(;
        text::String = "",
        font::Font = Font(),
        side::String = "top",
        xref::String = "container",
        yref::String = "container",
        x = .5,
        y = .5,
        xanchor::String = "auto",
        yanchor::String = "auto",
        pad = Margin())
        return new(
            text,
            font,
            Side(side),
            AxisRef(xref),
            AxisRef(yref),
            Normalized(Float64(x)),
            Normalized(Float64(y)),
            XAnchor(xanchor),
            YAnchor(yanchor),
            pad)
    end
end
Title(t::Title) = t

struct ColorScale <: ComponentType
    colors::Vector{Tuple{Normalized,Color}}
end

colorscalesets = (:Greys,:YlGnBu,:Greens,:YlOrRd,:Bluered,:RdBu,:Reds,:Blues,:Picnic,:Rainbow,:Portland,:Jet,:Hot,:Blackbody,:Earth,:Electric,:Viridis,:Cividis)
const ColorScaleSet = Enumerated{:colorscaleset,colorscalesets}

const Orientation = Enumerated{:Orientation,(:v,:h)}

easings = Symbol.(("linear","quad","cubic","sin","exp","circle","elastic","back","bounce","linear-in","quad-in","cubic-in","sin-in","exp-in","circle-in","elastic-in","back-in","bounce-in","linear-out","quad-out","cubic-out","sin-out","exp-out","circle-out","elastic-out","back-out","bounce-out","linear-in-out","quad-in-out","cubic-in-out","sin-in-out","exp-in-out","circle-in-out","elastic-in-out","back-in-out","bounce-in-out"))
const Easing = Enumerated{:Easing,easings}

const Ordering = Enumerated{:Ordering,Symbol.(("layout first","traces first"))}

struct Transition
    duration::Size{Int}
    easing::Easing
    ordering::Ordering

    function Transition(;
        duration::Int = 500,
        easing::String = "cubic-in-out",
        ordering::String = "layout first")
        return new(
            Size{Int}(duration),
            Easing(easing),
            Ordering(ordering)
        )
    end
end

const NameLength = RangeValue{Int,(-1,Inf),(true,false)}

struct HoverLabel <: ComponentType
    bgcolor::Union{Color,Vector{Color}}
    bordercolor::Union{Color,Vector{Color}}
    font::Font
    namelength::Union{NameLength,Vector{NameLength}}

    function HoverLabel(;
        bgcolor::Union{String,Vector{String}} = "#fff",
        bordercolor::Union{String,Vector{String}} = "#fff",
        font = Font(),
        namelength::Union{Int,Vector{Int}} = -1)
        return new(
            Color.(bgcolor),
            Color.(bordercolor),
            font,
            NameLength.(namelength))
    end
end

const Calendar = Enumerated{:Calendar,(:gregorian,:chinese,:coptic,:discworld,:ethiopian,:hebrew,:islamic,:mayan,:nanakshahi,:nepali,:persian,:jalali,:taiwan,:thai,:ummalqura)}

const TickMode = Enumerated{:TickMode,(:auto,:linear,:array)}

const TickLocation = Enumerated{:TickLocation,(:outside,:inside,Symbol(""))}

const TicksOn = Enumerated{:TicksOn,(:labels,:boundaries)}

const Mirror = Enumerated{:Mirror,(true,:ticks,false,:all,:allticks)}

struct TickFormatStops <: ComponentType
    enable::Bool
    dtickrange::Vector{NamedTuple{(:min,:max),NTuple{2,Float64}}}
    value::String

    function TickFormatStops(;
        enable::Bool = true,
        dtickrange = Vector{NamedTuple{(:min,:max),NTuple{2,Float64}}}(),
        value::String = "")
        return new(enable,dtickrange,value)
    end
end

const ShowTickPrefix = Enumerated{:ShowTickPrefix,(:all,:first,:last,:none)}

const ShowTickSuffix = Enumerated{:ShowTickSuffix,(:all,:first,:last,:none)}

const ExponentFormat = Enumerated{:ExponentFormat,(:none,:e,:E,:power,:SI,:B)}

const ShowExponent = Enumerated{:ShowExponent,(:all,:first,:last,:none)}

struct Ticks <: ComponentChild
    tickmode::TickMode
    nticks::Size{Int}
    tick0::Any
    dtick::Any
    tickvals::Vector{Float64}
    ticktext::Vector{String}
    ticks::TickLocation
    tickson::TicksOn
    mirror::Mirror
    ticklen::Size{Int}
    tickwidth::Size{Int}
    tickcolor::Color
    showticklabels::Bool
    automargin::Bool
    tickfont::Font
    tickangle::Float64
    tickprefix::String
    showtickprefix::ShowTickPrefix
    ticksuffix::String
    showticksuffix::ShowTickSuffix
    showexponent::ShowExponent
    exponentformat::ExponentFormat
    separatethousands::Bool
    tickformat::String
    tickformatstops::TickFormatStops

    function Ticks(;
        tickmode::String = "auto",
        nticks::Int = 0,
        tick0::Any = "",
        dtick::Any = "",
        tickvals::Vector{Float64} = Float64[],
        ticktext::Vector{String} = String[],
        ticks::String = "inside",
        tickson::String = "labels",
        mirror::Union{String,Bool} = false,
        ticklen::Int = 5,
        tickwidth::Int = 1,
        tickcolor::String = "#444",
        showticklabels::Bool = true,
        automargin::Bool = false,
        tickfont::Font = Font(),
        tickangle::Float64 = 0.,
        tickprefix::String = "",
        showtickprefix::String = "all",
        ticksuffix::String = "",
        showticksuffix::String = "all",
        showexponent::String = "all",
        exponentformat::String = "B",
        separatethousands::Bool = false,
        tickformat::String = "",
        tickformatstops::TickFormatStops = TickFormatStops())
        return new(
            TickMode(tickmode),
            Size{Int}(nticks),
            tick0,
            dtick,
            tickvals,
            ticktext,
            TickLocation(ticks),
            TicksOn(tickson),
            Mirror(mirror),
            Size{Int}(ticklen),
            Size{Int}(tickwidth),
            Color(tickcolor),
            showticklabels,
            automargin,
            tickfont,
            tickangle,
            tickprefix,
            ShowTickPrefix(showtickprefix),
            ticksuffix,
            ShowTickSuffix(showticksuffix),
            ShowExponent(showexponent),
            ExponentFormat(exponentformat),
            separatethousands,
            tickformat,
            tickformatstops)
    end
end

const Dash = Enumerated{:Dash,(:solid,:dot,:dash,:longdash,:dashdot,:longdashdot)}

end
