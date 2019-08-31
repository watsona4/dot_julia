using Documenter, VegaLite

makedocs(
  modules=[VegaLite],
  sitename = "VegaLite.jl",
  pages = [
    "Home" => "index.md",
    "Getting Started" => Any[
        "Installation" => "gettingstarted/installation.md",
        "Tutorial" => "gettingstarted/tutorial.md"
    ],
    "User Guide" => Any[
        "Vega-lite specifications" => "userguide/vlspec.md",
        "The @vlplot command" => "userguide/vlplotmacro.md",
        "Data sources" => "userguide/data.md",
        "Using Vega" => "userguide/vega.md"
    ],
    "Examples" => Any[
        "Simple Charts" => "examples/examples_simplecharts.md",
        "Single-View Plots" => Any[
            "Bar Charts & Histograms" => "examples/examples_barchartshistograms.md",
            "Scatter & Strip Plots" => "examples/examples_scatter_strip_plots.md",
            "Line Charts" => "examples/examples_line_charts.md",
            "Area Charts & Streamgraphs" => "examples/examples_area_Charts_streamgraphs.md",
            "Table-based Plots" => "examples/examples_table_based_plots.md"
        ],
        "Composite Mark" => Any[
            "Error Bars & Error Bands" => "examples/examples_error_bars_bands.md",
            "Box Plots" => "examples/examples_box_plots.md"
        ],
        "Multi-View Displays" => Any[
            "Faceting (Trellis Plot / Small Multiples)" => "examples/examples_faceting.md",
            "Repeat & Concatenation" => "examples/examples_repeat_concatenation.md"
        ],
        "Maps (Geographic Displays)" => "examples/examples_maps.md"
    ],
    "Reference Manual" => [
        "Global settings" => "referencemanual/global.md",
        "Outputs" => "referencemanual/output.md"]
  ]
)

deploydocs(
    repo = "github.com/queryverse/VegaLite.jl.git",
)
