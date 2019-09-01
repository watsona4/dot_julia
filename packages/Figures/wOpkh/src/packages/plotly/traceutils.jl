module TraceUtilities

using ..Utilities, ..JSON

export TraceValue, TraceType, Trace, diff,
        ChartType, Visible, HoverInfo, Stream, GroupNorm, StackGaps, Mode, 
        HoverOn, Shape, Line, Fill, MarkerSymbol, SizeMode, 
        ThicknessMode, LenMode, ColorBar, GradientType, Marker, Selected, 
        Unselected, TextPosition, ErrorType, Error, ConstrainText, BoxPoints,
        BoxMean, CoordinateType, ZSmooth, HistFunc, HistNorm, Direction,
        CurrentBin, Cumulative, Bins, Attributes

abstract type TraceValue <: ComponentValue end
abstract type TraceType <: ComponentType end
abstract type Trace <: Component end

function Utilities.diff(ref::ComponentType,obj::ComponentType,dict=Dict())
    names = propertynames(ref)
    for name in names
        refval = getproperty(ref,name)
        objval = getproperty(obj,name)
        d = Utilities.diff(refval,objval)
        if d != nothing && !isempty(d)
            dict[name] = d
        end
    end
    if typeof(obj) <: Trace && obj.type.value != "scatter"
        dict[:type] = obj.type.value
    end
    if haskey(dict,:attributes)
        return merge(dict[:attributes],delete!(dict,:attributes))
    end
    return dict
end

JSON.lower(t::TraceValue) = t.value

charttypes = (:scatter,:bar,:box,:heatmap,:histogram,:histogram2d,:histogram2dcontour,:pie,:contour,:scatterternary,:violin,:scatter3d,:surface,:mesh3d,:cone,:streamtube,:scattergeo,:choropleth,:scattergl,:splom,:pointcloud,:heatmapgl,:parcoords,:parcats,:scattermapbox,:sankey,:table,:carpet,:scattercarpet,:contourcarpet,:ohlc,:candlestick,:scatterpolar,:scatterpolargl,:barpolar)
const ChartType = Enumerated{:charttype,charttypes}

const Visible = Enumerated{:Visible,(true,false,:legendonly)}

const HoverInfo = FlagList{(:x,:y,:z,:text,:name),(:all,:none,:skip)}

struct Stream <: TraceType
    token::String
    maxpoints::RangeValue{Int,(0,10000),(true,true)}

    Stream(token="",maxpts::Int=500) = new(token,RangeValue((0,10000),maxpts))
end

const GroupNorm = Enumerated{:GroupNorm,(:fraction,:percent,Symbol(""))}

const StackGaps = Enumerated{:StackGaps,(Symbol("infer zero"),:interpolate)}

const Mode = FlagList{(:lines,:markers,:text),(:none,)}

const HoverOn = FlagList{(:points,:fills),()}

const Shape = Enumerated{:Shape,(:linear,:spline,:hv,:vh,:hvh,:vhv)}

struct Line <: TraceType
    color::Color
    width::Size{Int}
    shape::Shape
    smoothing::RangeValue{Float64,(0.0,1.3),(true,true)}
    dash::Dash
    simplify::Bool
    cauto::Bool
    cmin::Float64
    cmax::Float64
    cmid::Float64
    colorscale::Union{ColorScale,ColorScaleSet}
    autocolorscale::Bool
    reversescale::Bool

    function Line(;
        color::String = "#444",
        width::Int = 2,
        shape::String = "linear",
        smoothing::Float64 = 1.0,
        dash::String = "solid",
        simplify::Bool = true,
        cauto::Bool = true,
        cmin::Float64 = 0.0,
        cmax::Float64 = 0.0,
        cmid::Float64 = 0.0,
        colorscale::Union{Vector{Tuple{Float64,String}},String} = "RdBu",
        autocolorscale::Bool = true,
        reversescale::Bool = false)
    return new(
        Color(color),
        Size{Int}(width),
        Shape(shape),
        RangeValue((0.0,1.3),smoothing),
        Dash(dash),
        simplify,
        cauto,
        cmin,
        cmax,
        cmid,
        typeof(colorscale) == String ? ColorScaleSet(colorscale) :
            ColorScale([(Normalized(Float64(n)),Color(s)) for (n,s) in colorscale]),
        autocolorscale,
        reversescale)
    end
end

const Fill = Enumerated{:Fill,(:none,:tozeroy,:tozerox,:tonexty,:tonextx,:toself)}

symbols = Symbol.(("circle","circle-open","circle-dot","circle-open-dot","square","square-open","square-dot","square-open-dot","diamond","diamond-open","diamond-dot","diamond-open-dot","cross","cross-open","cross-dot","cross-open-dot","x","x-open","x-dot","x-open-dot","triangle-up","triangle-up-open","triangle-up-dot","triangle-up-open-dot","triangle-down","triangle-down-open","triangle-down-dot","triangle-down-open-dot","triangle-left","triangle-left-open","triangle-left-dot","triangle-left-open-dot","triangle-right","triangle-right-open","triangle-right-dot","triangle-right-open-dot","triangle-ne","triangle-ne-open","triangle-ne-dot","triangle-ne-open-dot","triangle-se","triangle-se-open","triangle-se-dot","triangle-se-open-dot","triangle-sw","triangle-sw-open","triangle-sw-dot","triangle-sw-open-dot","triangle-nw","triangle-nw-open","triangle-nw-dot","triangle-nw-open-dot","pentagon","pentagon-open","pentagon-dot","pentagon-open-dot","hexagon","hexagon-open","hexagon-dot","hexagon-open-dot","hexagon2","hexagon2-open","hexagon2-dot","hexagon2-open-dot","octagon","octagon-open","octagon-dot","octagon-open-dot","star","star-open","star-dot","star-open-dot","hexagram","hexagram-open","hexagram-dot","hexagram-open-dot","star-triangle-up","star-triangle-up-open","star-triangle-up-dot","star-triangle-up-open-dot","star-triangle-down","star-triangle-down-open","star-triangle-down-dot","star-triangle-down-open-dot","star-square","star-square-open","star-square-dot","star-square-open-dot","star-diamond","star-diamond-open","star-diamond-dot","star-diamond-open-dot","diamond-tall","diamond-tall-open","diamond-tall-dot","diamond-tall-open-dot","diamond-wide","diamond-wide-open","diamond-wide-dot","diamond-wide-open-dot","hourglass","hourglass-open","bowtie","bowtie-open","circle-cross","circle-cross-open","circle-x","circle-x-open","square-cross","square-cross-open","square-x","square-x-open","diamond-cross","diamond-cross-open","diamond-x","diamond-x-open","cross-thin","cross-thin-open","x-thin","x-thin-open","asterisk","asterisk-open","hash","hash-open","hash-dot","hash-open-dot","y-up","y-up-open","y-down","y-down-open","y-left","y-left-open","y-right","y-right-open","line-ew","line-ew-open","line-ns","line-ns-open","line-ne","line-ne-open","line-nw","line-nw-open"))
const MarkerSymbol = Enumerated{:MarkerSymbol,symbols}

const SizeMode = Enumerated{:SizeMode,(:diameter,:area)}

const ThicknessMode = Enumerated{:ThicknessMode,(:fraction,:pixels)}

const LenMode = Enumerated{:LenMode,(:fraction,:pixels)}

struct ColorBar <: TraceType
    thicknessmode::ThicknessMode
    thickness::Size{Int}
    lenmode::LenMode
    len::Size{Int}
    x::RangeValue{Float64,(-2,3),(true,true)}
    xanchor::XAnchor
    xpad::Size{Int}
    y::RangeValue{Float64,(-2,3),(true,true)}
    yanchor::YAnchor
    ypad::Size{Int}
    outlinecolor::Color
    outlinewidth::Size{Int}
    bordercolor::Color
    borderwidth::Size{Int}
    bgcolor::Color
    # =================================================================
    # TODO: Make sure this gets written at the correct level from `diff`
    ticks::Ticks # See also LayoutUtilities.Axis
    # =================================================================
    title::Title

    function ColorBar(;
        thicknessmode::String = "pixels",
        thickness::Int = 30,
        lenmode::String = "fraction",
        len::Int = 1,
        x::Float64 = 1.02,
        xanchor::String = "left",
        xpad::Int = 10,
        y::Float64 = 0.5,
        yanchor::String = "middle",
        ypad::Int = 10,
        outlinecolor::String = "#444",
        outlinewidth::Int = 1,
        bordercolor::String = "#444",
        borderwidth::Int = 0,
        bgcolor::String = "rgba(0,0,0,0)",
        # Ticks child component. Should at the same level.
        tickmode::String = "auto",
        nticks::Int = 0,
        tick0::Any = "",
        dtick::Any = "",
        tickvals::Vector{Float64} = Float64[],
        ticktext::Vector{String} = String[],
        ticks::String = "inside",
        ticklen::Int = 5,
        tickwidth::Int = 1,
        tickcolor::String = "#444",
        showticklabels::Bool = true,
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
        tickformatstops::TickFormatStops = TickFormatStops(),
        # ===================================================
        title::Union{String,Title} = "")
        return new(
            ThicknessMode(thicknessmode),
            Size{Int}(thickness),
            LenMode(lenmode),
            Size{Int}(len),
            RangeValue((-2,3),x),
            XAnchor(xanchor),
            Size{Int}(xpad),
            RangeValue((-2,3),y),
            YAnchor(yanchor),
            Size{Int}(ypad),
            Color(outlinecolor),
            Size{Int}(outlinewidth),
            Color(bordercolor),
            Size{Int}(borderwidth),
            Color(bgcolor),
            Ticks(
                tickmode=tickmode,
                nticks=nticks,
                tick0=tick0,
                dtick=dtick,
                tickvals=tickvals,
                ticktext=ticktext,
                ticks=ticks,
                ticklen=ticklen,
                tickwidth=tickwidth,
                tickcolor=tickcolor,
                showticklabels=showticklabels,
                tickfont=tickfont,
                tickangle=tickangle,
                tickprefix=tickprefix,
                showtickprefix=showtickprefix,
                ticksuffix=ticksuffix,
                showticksuffix=showticksuffix,
                exponentformat=exponentformat,
                showexponent=showexponent,
                separatethousands=separatethousands,
                tickformat=tickformat,
                tickformatstops=tickformatstops),
            typeof(title) == String ? Title(text=title) : title
        )
    end
end

const GradientType = Enumerated{:GradientType,(:radial,:horizontal,:vertical,:none)}

struct Gradient <: TraceType
    type::GradientType
    color::Color

    function Gradient(;
        type::String = "none",
        color::String = "#000"
        )
        return new(
            GradientType(type),
            Color(color))
    end
end

struct Marker <: TraceType
    symbol::Union{MarkerSymbol,Vector{MarkerSymbol}}
    opacity::Union{Float64,Vector{Float64}}
    size::Union{Size{Int},Vector{Size{Int}}}
    maxdisplayed::Size{Int}
    sizeref::Float64
    sizemin::Size
    sizemode::SizeMode
    colorbar::ColorBar
    line::Line
    gradient::Gradient
    color::Union{Color,Vector{Color}}
    cauto::Bool
    cmin::Float64
    cmax::Float64
    cmid::Float64
    colorscale::Union{ColorScale,ColorScaleSet}
    autocolorscale::Bool
    reversescale::Bool

    function Marker(;
        symbol::Union{String,Vector{String}} = "circle",
        opacity::Union{Float64,Vector{Float64}} = 1.0,
        size::Union{Int,Vector{Int}} = 6,
        maxdisplayed::Int = 0,
        sizeref = 1.,
        sizemin::Int = 0,
        sizemode::String = "diameter",
        colorbar::ColorBar = ColorBar(),
        line::Line = Line(width=1),
        gradient::Gradient = Gradient(),
        color::Union{String,Vector{String}} = "#444",
        cauto::Bool = true,
        cmin::Float64 = 0.0,
        cmax::Float64 = 0.0,
        cmid::Float64 = 0.0,
        colorscale::Union{Vector{Tuple{Float64,String}},String} = "RdBu",
        autocolorscale::Bool = true,
        reversescale::Bool = false)
        return new(
            MarkerSymbol.(symbol),
            opacity,
            Size{Int}.(size),
            Size{Int}(maxdisplayed),
            sizeref,
            Size{Int}(sizemin),
            SizeMode(sizemode),
            colorbar,
            line,
            gradient,
            Color.(color),
            cauto,
            cmin,
            cmax,
            cmid,
            typeof(colorscale) == String ? ColorScaleSet(colorscale) :
                ColorScale([(Normalized(Float64(n)),Color(s)) for (n,s) in colorscale]),
            autocolorscale,
            reversescale)
    end
end

struct Selected <: TraceType
    marker::Marker
    textfont::Font

    function Selected(;
        marker::Marker = Marker(),
        textfont::Font = Font())
        return new(
            marker,
            textfont)
    end
end

struct Unselected <: TraceType
    marker::Marker
    textfont::Font

    function Unselected(;
        marker::Marker = Marker(),
        textfont::Font = Font())
        return new(
            marker,
            textfont)
    end
end

const TextPosition = Enumerated{:TextPosition,Symbol.((
    "top left","top center","top right","middle left","middle center","middle right",
    "bottom left","bottom center","bottom right"))}

const ErrorType = Enumerated{:ErrorType,(:percent,:constant,:sqrt,:data)}

struct Error <: TraceType
    visible::Bool
    type::ErrorType
    symmetric::Bool
    array::Vector{Float64}
    arrayminus::Vector{Float64}
    value::Size{Float64}
    valueminus::Size{Float64}
    traceref::Size{Int}
    tracerefminus::Size{Int}
    copy_ystyle::Bool
    color::Color
    thickness::Size{Int}
    width::Size{Int}

    function Error(;
        visible::Bool = false,
        type::String = "constant",
        symmetric::Bool = true,
        array::Vector{Float64} = Float64[],
        arrayminus::Vector{Float64} = Float64[],
        value::Float64 = 10.,
        valueminus::Float64 = 10.,
        traceref::Int = 0,
        tracerefminus::Int = 0,
        copy_ystyle::Bool = false,
        color::String = "#000",
        thickness::Int = 2,
        width::Int = 1)
        return new(
            visible,
            ErrorType(type),
            symmetric,
            array,
            arrayminus,
            Size{Float64}(value),
            Size{Float64}(valueminus),
            Size{Int}(traceref),
            Size{Int}(tracerefminus),
            copy_ystyle,
            Color(color),
            Size{Int}(thickness),
            Size{Int}(width)
            )
    end
end

const ConstrainText = Enumerated{:ConstrainText,(:inside,:outside,:both,:none)}

const BoxPoints = Enumerated{:BoxPoints,(:all,:outliers,:suspectedoutliers,false)}

const BoxMean = Enumerated{:BoxMean,(true,:sd,false)}

const CoordinateType = Enumerated{:CoordinateType,(:array,:scaled)}

const ZSmooth = Enumerated{:ZSmooth,(:fast,:best,false)}

const HistFunc = Enumerated{:HistFunc,(:count,:sum,:avg,:min,:max)}

const HistNorm = Enumerated{:HistNorm,(:percent,:probability,:density,:probabilitydensity)}

const Direction = Enumerated{:Direction,(:increasing,:decreasing)}

const CurrentBin = Enumerated{:CurrentBin,(:include,:exclude,:half)}

struct Cumulative <: TraceType
    enabled::Bool
    direction::Direction
    currentbin::CurrentBin

    function Cumulative(;
        enabled::Bool = false,
        direction::String = "increasing",
        currentbin::String = "include")
        return new(
            enabled,
            Direction(direction),
            CurrentBin(currentbin))
    end
end

struct Bins <: TraceType
    start::Any
    stop::Any # plotly.js uses `end`
    size::Any

    function Bins(;
        start = "",
        stop = "",
        size = 0)
        return new(start,stop,size)
    end
end

mutable struct Attributes <: TraceType
    # ====================================
    # Attributes common across trace types
    # ====================================
    x::Vector{X} where X<:Union{String,Number}
    x0::Float64
    dx::Float64
    y::Vector{Y} where Y<:Union{String,Number}
    y0::Float64
    dy::Float64
    orientation::Orientation
    text::Union{String,Vector{String}}
    hovertext::Union{String,Vector{String}}
    hovertemplate::Union{String,Vector{String}}
    marker::Marker
    selected::Selected
    unselected::Unselected
    xcalendar::Calendar
    ycalendar::Calendar
    xaxis::String
    yaxis::String
    # ============================================
    # Attributes contained in the plotly.js object
    # ============================================
    customdata::Vector{Any}
    hoverinfo::HoverInfo
    hoverlabel::HoverLabel
    ids::Vector{String}
    legendgroup::String
    name::String
    opacity::Float64
    selectedpoints::Vector{Int}
    showlegend::Bool
    stream::Stream
    # transforms
    # type
    # uid
    # uirevision::Float64
    visible::Visible

    function Attributes(;
        # ====================================
        # Attributes common across trace types
        # ====================================
        x = Float64[],
        x0 = 0.0,
        dx = 1.0,
        y = Float64[],
        y0 = 0.0,
        dy = 1.0,
        orientation::String = "v",
        text::Union{String,Vector{String}} = "",
        hovertext::Union{String,Vector{String}} = "",
        hovertemplate::Union{String,Vector{String}} = "",
        marker::Marker = Marker(),
        selected::Selected = Selected(),
        unselected::Unselected = Unselected(),
        xcalendar::String = "gregorian",
        ycalendar::String = "gregorian",
        xaxis::String = "x",
        yaxis::String = "y",
        # ============================================
        # Attributes contained in the plotly.js object
        # ============================================
        customdata::Vector{Any} = [],
        hoverinfo::String = "all",
        hoverlabel::HoverLabel = HoverLabel(),
        ids::Vector{String} = String[],
        legendgroup::String = "",
        name::String = "",
        opacity::Float64 = 1.0,
        selectedpoints::Vector{Int} = Int[],
        showlegend::Bool = true,
        stream::Stream = Stream(),
        visible::Union{Bool,String,Symbol} = true)

        return new(
            # ====================================
            # Attributes common across trace types
            # ====================================
            collect(x),
            Float64(x0),
            Float64(dx),
            collect(y),
            Float64(y0),
            Float64(dy),
            Orientation(orientation),
            text,
            hovertext,
            hovertemplate,
            marker,
            selected,
            unselected,
            Calendar(xcalendar),
            Calendar(ycalendar),
            xaxis,
            yaxis,
            # ============================================
            # Attributes contained in the plotly.js object
            # ============================================
            customdata,
            HoverInfo(hoverinfo),
            hoverlabel,
            ids,
            legendgroup,
            name,
            opacity,
            selectedpoints,
            showlegend,
            stream,
            Visible(visible))
    end
end

end
