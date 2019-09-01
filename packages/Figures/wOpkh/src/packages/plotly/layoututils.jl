module LayoutUtilities

using ..Utilities

export LayoutValue, LayoutType,
        LayoutColorScale, ModeBar, ClickMode, DragMode, HoverMode,
        HoverDistance, SpikeDistance, SelectDirection, RowOrder, CounterRegex,
        SubPlot, GridXAxis, GridYAxis, Pattern, Domain, XSide, YSide, Grid,
        AxisType, AutoRange, AutoRangeMode, ScaleAnchor, Constrain, ConstrainToward,
        Axis

abstract type LayoutValue <: ComponentValue end
abstract type LayoutType <: ComponentType end

struct LayoutColorScale
    squential::Union{ColorScale,ColorScaleSet}
    sequentialminus::Union{ColorScale,ColorScaleSet}
    diverging::Union{ColorScale,ColorScaleSet}

    function LayoutColorScale(;
        sequential::Union{Tuple{Float64,String},String} = "Reds",
        sequentialminus::Union{Tuple{Float64,String},String} = "Blues",
        diverging::Union{Tuple{Float64,String},String} = "RdBu"
        )
        return new(
            typeof(sequential) == String ? ColorScaleSet(sequential) :
                ColorScale(
                [(Normalized(Float64(n)),
                    Color(s)) for (n,s) in sequential]),
            typeof(sequentialminus) == String ? ColorScaleSet(sequentialminus) :
                ColorScale(
                [(Normalized(Float64(n)),
                    Color(s)) for (n,s) in sequentialminus]),
            typeof(diverging) == String ? ColorScaleSet(diverging) :
                ColorScale(
                [(Normalized(Float64(n)),Color(s)) for (n,s) in diverging]))
    end
end

struct ModeBar
    orientation::Orientation
    bgcolor::Color
    color::Color
    activecolor::Color

    function ModeBar(;
        orientation::String = "h",
        bgcolor::String = "#fff",
        color::String = "rgba(68, 68, 68, 0.3)",
        activecolor::String = "rgb(105, 115, 138)")
        return new(
            Orientation(orientation),
            Color(bgcolor),
            Color(color),
            Color(activecolor))
    end
end

const ClickMode = FlagList{(:event,:select),(:none,)}

const DragMode = Enumerated{:DragMode,(:zoom,:pan,:select,:lasso,:orbit)}

const HoverMode = Enumerated{:HoverMode,(:x,:y,:closest,:false)}

const HoverDistance = RangeValue{Int,(-1,Inf),(true,false)}

const SpikeDistance = RangeValue{Int,(-1,Inf),(true,false)}

const SelectDirection = Enumerated{:SelectDirection,(:h,:v,:d,:any)}

const RowOrder = Enumerated{:RowOrder,
                    Symbol.(("top to bottom","bottom to top"))}

struct CounterRegex{H,T,O,B} <: LayoutValue
    value::String

    function CounterRegex{H,T,O,B}(s::String) where {H,T,O,B}
        tail = string(T,O ? "" : "\$")
        prefix = B ? "^" : ""
        id = "([2-9]|[1-9][0-9]+)?"
        if isequal(H,:xy)
            occursin(Regex("$(prefix)(x$(id)y$(id))?$(tail)"),s) &&
                return new(s)
            error("Not a valid id, e.g. \"\",\"xy\",\"x2y2\", etc.")
        elseif isequal(H,:xory)
            occursin(Regex("$(prefix)([xy]$(id))?$(tail)"),s) &&
                return new(s)
            error("Not a valid id, e.g. \"\",\"x\",\"y\",\"x2\",\"y2\", etc.")
        else
            occursin(Regex("$(prefix)($(H)$(id))?$(tail)"),s) &&
                return new(s)
            error("Not a valid id, e.g. \"\",\"$(H)\",\"$(H)2\", etc.")
        end
    end
end

const SubPlot = CounterRegex{:xy,Symbol(""),false,true}

const GridXAxis = CounterRegex{:x,Symbol(""),false,true}

const GridYAxis = CounterRegex{:y,Symbol(""),false,true}

const Pattern = Enumerated{:Pattern,(:independent,:coupled)}

struct Domain <: LayoutType
    x::NTuple{2,Float64}
    y::NTuple{2,Float64}

    function Domain(;
        x::Vector{Float64} = [0.,1.],
        y::Vector{Float64} = [0.,1.])
        length(x) != 2 && error("`x` domain must be a 2-element vector")
        length(y) != 2 && error("`y` domain must be a 2-element vector")
        return new(Float64.((x[1],x[2])),Float64.((y[1],y[2])))
    end
end

const XSide = Enumerated{:XSide,
                Symbol.(("bottom","bottom plot","top plot","top"))}

const YSide = Enumerated{:YSide,
                Symbol.(("left","left plot","right plot","right"))}

struct Grid <: LayoutType
    rows::Count
    roworder::RowOrder
    columns::Count
    subplots::Vector{SubPlot}
    xaxes::Vector{GridXAxis}
    yaxes::Vector{GridYAxis}
    pattern::Pattern
    xgap::Normalized
    ygap::Normalized
    domain::Domain
    xside::XSide
    yside::YSide
    function Grid(;
            rows::Int = 1,
            roworder::String = "top to bottom",
            columns::Int = 1,
            subplots::Vector{String} = String[],
            xaxes::Vector{String} = String[],
            yaxes::Vector{String} = String[],
            pattern::String = "coupled",
            xgap::Float64 = 0.0,
            ygap::Float64 = 0.0,
            domain::Domain = Domain(),
            xside::String = "bottom plot",
            yside::String = "left plot")
        return new(
        Count(rows),
        RowOrder(roworder),
        Count(columns),
        SubPlot.(subplots),
        GridXAxis.(xaxes),
        GridYAxis.(yaxes),
        Pattern(pattern),
        Normalized(xgap),
        Normalized(ygap),
        domain,
        XSide(xside),
        YSide(yside))
    end
end

const AxisType = Enumerated{:AxisType,
    Symbol.(("-","linear","log","date","category","multicategory"))}

const AutoRange = Enumerated{:AutoRange,(true,false,:reversed)}

const AutoRangeMode = Enumerated{:AutoRangeMode,(:normal,:tozero,:nonnegative)}

const ScaleAnchor = CounterRegex{:xory,Symbol(""),false,true}

const Constrain = Enumerated{:Constrain,(:range,:domain)}

const ConstrainToward = Enumerated{:ConstrainToward,
                            (:left,:center,:right,:top,:middle,:bottom)}

const Matches = CounterRegex{:xory,Symbol(""),false,true}

const SpikeMode = FlagList{(:toaxis,:across,:marker),()}

const SpikeSnap = Enumerated{:SpikeSnap,(:data,:cursor)}

struct AxisId <: LayoutValue
    value::String

    function AxisId(s::String)
        isequal(s,"free") && return new(s)
        c = CounterRegex{:xory,Symbol(""),false,true}
        return new(c.value)
    end
end

const Layer = Enumerated{:Layer,Symbol.(("above traces","below traces"))}

const CategoryOrder = Enumerated{:CategoryOrder,
        Symbol.(("trace","category ascending","category descending","array"))}

const RangeMode = Enumerated{:RangeMode,(:auto,:fixed,:match)}

struct RangeYAxis
    rangemode::RangeMode
    range::NTuple{2}

    function RangeYAxis(;
        rangemode::String = "match",
        range::Vector = [0.,1.]
        )
        return new(
            RangeMode(rangemode),
            (Float64(range[1]),Float64(range[2]))
        )
    end
end

struct RangeSlider
    bgcolor::Color
    bordercolor::Color
    borderwidth::Size{Int}
    autorange::Bool
    range::NTuple{2}
    thickness::Normalized
    visible::Bool
    yaxis::RangeYAxis
    function RangeSlider(;
        bgcolor::String = "#444",
        bordercolor::String = "#444",
        borderwidth::Int = 0,
        autorange::Bool = true,
        range = [0.,1.],
        thickness = 0.15,
        visible::Bool = true,
        yaxis::RangeYAxis = RangeYAxis())
        return new(
            Color(bgcolor),
            Color(bordercolor),
            Size{Int}(borderwidth),
            autorange,
            (Float64(range[1]),Float64(range[2])),
            Normalized(Float64(thickness)),
            visible,
            yaxis)
    end
end

const RangeStep = Enumerated{:RangeStep,
                    (:month,:year,:day,:hour,:minute,:second,:all)}

const RangeStepMode = Enumerated{:RangeStepMode,(:backward,:todate)}

struct RangeButton
    visible::Bool 
    step::RangeStep
    stepmode::RangeStepMode
    count::Size{Int}
    label::String
    name::String
    templateitemname::String
    function RangeButton(;
        visible::Bool = true,
        step::String = "month",
        stepmode::String = "backward",
        count::Int = 1,
        label::String = "")
        return new(
            visible,
            RangeStep(step),
            RangeStepMode(stepmode),
            Size{Int}(count),
            label)
    end
end

struct RangeSelector
    visible::Bool
    buttons::RangeButton
    x::RangeValue{Float64,(-2,3),(true,true)}
    xanchor::XAnchor
    y::RangeValue{Float64,(-2,3),(true,true)}
    yanchor::YAnchor
    font::Font
    bgcolor::Color
    activecolor::Color
    bordercolor::Color
    borderwidth::Size{Int}

    function RangeSelector(;
        visible::Bool = true,
        buttons::RangeButton = RangeButton(),
        x = 0.,
        xanchor::String = "auto",
        y = 0.,
        yanchor::String = "auto",
        font::Font = Font(),
        bgcolor::String = "#eee",
        activecolor::String = "",
        bordercolor::String = "#444",
        borderwidth::Int = 0)
        return new(
            visible,
            buttons,
            RangeValue((-2,3),Float64(x)),
            XAnchor(xanchor),
            RangeValue((-2,3),Float64(y)),
            YAnchor(yanchor),
            font,
            Color(bgcolor),
            Color(activecolor),
            Color(bordercolor),
            Size{Int}(borderwidth))
    end
end

struct Axis <: LayoutType
    visible::Bool
    color::Color
    title::Title
    type::AxisType
    autorange::AutoRange
    rangemode::AutoRangeMode
    range::Union{NTuple{2,String},NTuple{2,Int},NTuple{2,Float64}}
    fixedrange::Bool
    scaleanchor::ScaleAnchor
    scaleratio::Size{Float64}
    constrain::Constrain
    constraintoward::ConstrainToward
    matches::Matches
    # =================================================================
    # TODO: Make sure this gets written at the correct level from `diff`
    ticks::Ticks # See also TraceUtilities.ColorBar
    # =================================================================
    showspikes::Bool
    spikecolor::Color
    spikethickness::Size{Int}
    spikedash::Dash
    spikemode::SpikeMode
    spikesnap::SpikeSnap
    hoverformat::String
    showline::Bool
    linecolor::Color
    linewidth::Size{Int}
    showgrid::Bool
    gridcolor::Color
    gridwidth::Size{Int}
    zeroline::Bool
    zerolinecolor::Color
    zerolinewidth::Size{Int}
    showdividers::Bool
    dividercolor::Color
    dividerwidth::Size{Int}
    anchor::AxisId
    side::Side
    overlaying::AxisId
    layer::Layer
    domain::NTuple{2,Float64}
    position::Normalized
    categoryorder::CategoryOrder
    categoryarray::Vector
    rangeslide::RangeSlider
    rangeselector::RangeSelector
    calendar::Calendar
    function Axis(;
        visible::Bool = true,
        color::String = "#444",
        title::Title = Title(),
        type::String = "multicategory",
        autorange::Union{String,Bool} = true,
        rangemode::String = "normal",
        range = [0.,1.],
        fixedrange::Bool = false,
        scaleanchor::String = "x", # Requires input, e.g. "x" for xaxis.
        scaleratio = 1.0,
        constrain::String = "range",
        constraintoward::String = "center",
        matches::String = "",
        ticks::Ticks = Ticks(),
        showspikes::Bool = false,
        spikecolor::String = "",
        spikethickness::Int = 3,
        spikedash::String = "dash",
        spikemode::String = "toaxis",
        spikesnap::String = "data",
        hoverformat::String = "",
        showline::Bool = false,
        linecolor::String = "",
        linewidth::Int = 1,
        showgrid::Bool = true,
        gridcolor::String = "#444",
        gridwidth::Int = 1,
        zeroline::Bool = false,
        zerolinecolor::String = "#444",
        zerolinewidth::Int = 1,
        showdividers::Bool = true,
        dividercolor::String = "#444",
        dividerwidth::Int = 1,
        anchor::String = "free",
        side::String = "bottom",
        overlaying::String = "free",
        layer::String = "above traces",
        domain::Vector = [0.,1.],
        position = 0.,
        categoryorder::String = "trace",
        categoryarray::Vector = [],
        rangeslider::RangeSlider = RangeSlider(),
        rangeselector::RangeSelector = RangeSelector(),
        calendar::String = "gregorian")
        return new(
            visible,
            Color(color),
            title,
            AxisType(type),
            AutoRange(autorange),
            AutoRangeMode(rangemode),
            (range[1],range[2]),
            fixedrange,
            ScaleAnchor(scaleanchor),
            Size{Float64}(Float64(scaleratio)),
            Constrain(constrain),
            ConstrainToward(constraintoward),
            Matches(matches),
            ticks,
            showspikes,
            Color(spikecolor),
            Size{Int}(spikethickness),
            Dash(spikedash),
            SpikeMode(spikemode),
            SpikeSnap(spikesnap),
            hoverformat,
            showline,
            Color(linecolor),
            Size{Int}(linewidth),
            showgrid,
            Color(gridcolor),
            Size{Int}(gridwidth),
            zeroline,
            Color(zerolinecolor),
            Size{Int}(zerolinewidth),
            showdividers,
            Color(dividercolor),
            Size{Int}(dividerwidth),
            AxisId(anchor),
            Side(side),
            AxisId(overlaying),
            Layer(layer),
            Float64.((domain[1],domain[2])),
            Normalized(position),
            CategoryOrder(categoryorder),
            categoryarray,
            rangeslider,
            rangeselector,
            Calendar(calendar))
    end
end

end
