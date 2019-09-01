module Configs

using ..Utilities

export Config

abstract type ConfigValue <: ComponentValue end
abstract type ConfigType <: ComponentType end

struct Edits <: ConfigType
    annotationPosition::Bool
    annotationTail::Bool
    annotationText::Bool
    axisTitleText::Bool
    colorbarPosition::Bool
    legendPosition::Bool
    legendText::Bool
    shapePosition::Bool
    titleText::Bool

    function Edits(;
        annotationPosition::Bool = false,
        annotationTail::Bool = false,
        annotationText::Bool = false,
        axisTitleText::Bool = false,
        colorbarPosition::Bool = false,
        legendPosition::Bool = false,
        legendText::Bool = false,
        shapePosition::Bool = false,
        titleText::Bool = false)
        return new(
            annotationPosition,
            annotationTail,
            annotationText,
            axisTitleText,
            colorbarPosition,
            legendPosition,
            legendText,
            shapePosition,
            titleText)
    end
end

const FrameMargins = RangeValue{Float64,(0.,0.5),(true,true)}

const ScrollZoom = FlagList{(:cartesian,:gl3d,:geo,:mapbox),(true,false)}

const DoubleClick = Enumerated{:DoubleClick,
                        (false,:reset,:autosize,Symbol("reset+autosize"))}

const DisplayModeBar = Enumerated{:DisplayModeBar,(:hover,true,false)}

struct Config <: Component
    staticPlot::Bool
    plotlyServerURL::String
    editable::Bool
    edits::Edits
    autosizable::Bool
    responsive::Bool
    fillFrame::Bool
    frameMargins::FrameMargins
    scrollZoom::ScrollZoom
    doubleClick::DoubleClick
    showAxisDraghandles::Bool
    showAxisRangeEntryBoxes::Bool
    showTips::Bool
    showLink::Bool
    linkText::String
    sendData::Bool
    showSources::Any
    displayModeBar::DisplayModeBar
    showSendToCloud::Bool
    modeBarButtonsToRemove::Any
    modeBarButtonsToAdd::Any
    modeBarButtons::Any
    toImageButtonOptions::Any
    displaylogo::Bool
    watermark::Bool
    plotGlPixelRatio::RangeValue{Float64,(1,4),(true,true)}
    setBackground::Any
    topojsonURL::String
    mapboxAccessToken::String
    logging::Bool
    queueLength::Size{Int}
    globalTransforms::Any
    locale::String
    locales::Any

    function Config(;
        staticPlot::Bool = false,
        plotlyServerURL::String = "https://plot.ly",
        editable::Bool = false,
        edits::Edits = Edits(),
        autosizable::Bool = false,
        responsive::Bool = false,
        fillFrame::Bool = false,
        frameMargins = 0.,
        scrollZoom::Union{String,Bool} = "gl3d+geo+mapbox",
        doubleClick::String = "reset+autosize",
        showAxisDraghandles::Bool = true,
        showAxisRangeEntryBoxes::Bool = true,
        showTips::Bool = true,
        showLink::Bool = false,
        linkText::String = "Edit chart",
        sendData::Bool = true,
        showSources::Any = false,
        displayModeBar::Union{String,Bool} = "hover",
        showSendToCloud::Bool = false,
        modeBarButtonsToRemove::Any = [],
        modeBarButtonsToAdd::Any = [],
        modeBarButtons::Any = false,
        toImageButtonOptions::Any = Dict(),
        displaylogo::Bool = true,
        watermark::Bool = false,
        plotGlPixelRatio = 2,
        setBackground::Any = "transparent",
        topojsonURL::String = "https://cdn.plot.ly/",
        mapboxAccessToken::String = "",
        logging::Bool = true,
        queueLength::Int = 0,
        globalTransforms::Any = [],
        locale::String = "en-US",
        locales::Any = Dict())
        return new(
            staticPlot,
            plotlyServerURL,
            editable,
            edits,
            autosizable,
            responsive,
            fillFrame,
            FrameMargins(frameMargins),
            ScrollZoom(scrollZoom),
            DoubleClick(doubleClick),
            showAxisDraghandles,
            showAxisRangeEntryBoxes,
            showTips,
            showLink,
            linkText,
            sendData,
            showSources,
            DisplayModeBar(displayModeBar),
            showSendToCloud,
            modeBarButtonsToRemove,
            modeBarButtonsToAdd,
            modeBarButtons,
            toImageButtonOptions,
            displaylogo,
            watermark,
            RangeValue((1,4),Float64(plotGlPixelRatio)),
            setBackground,
            topojsonURL,
            mapboxAccessToken,
            logging,
            Size{Int}(queueLength),
            globalTransforms,
            locale,
            locales)
    end
end
default["config"] = Config()

end