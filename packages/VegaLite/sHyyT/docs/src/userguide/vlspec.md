# Vega-lite specifications

A [Vega-Lite](https://vega.github.io/vega-lite/) plot specification is represented as a `VLSpec` object in julia. There are multiple ways to create a `VLSpec` object:
1. The `@vlplot` macro is the main way to create `VLSpec` instances in code.
2. Using the `vl` string macro, you can write [Vega-Lite](https://vega.github.io/vega-lite/) specifications as JSON in your julia code.
3. You can load [Vega-Lite](https://vega.github.io/vega-lite/) specifications from disc with the `load` function.
4. The [DataVoyager.jl](https://github.com/queryverse/DataVoyager.jl) package provides a graphical user interface that you can use to create [Vega-Lite](https://vega.github.io/vega-lite/) specification.

There are two main things one can do with a `VLSpec` object:
1. One can display it in various front ends.
2. One can save the plot to disc in various formats using the `save` function.

This section will give a brief overview of these options. Other sections will describe each option in more detail.

## The `@vlplot` macro

The `@vlplot` macro is the main way to specify plots in [VegaLite.jl](https://github.com/queryverse/VegaLite.jl). The macro uses a syntax that is closely aligned with the JSON format of the original [Vega-Lite](https://vega.github.io/vega-lite/) specification. It is very simple to take a vega-lite specification and "translate" it into a corresponding `@vlplot` macro call. In addition, the macro provides a number of convenient syntax features that allow for a concise expression of common vega-lite patterns. These shorthand give [VegaLite.jl](https://github.com/queryverse/VegaLite.jl) a syntax that can be used in a productive way for exploratory data analysis.

A very simple [Vega-Lite](https://vega.github.io/vega-lite/) JSON specification looks like this:

```json
{
  "data": {
    "values": [
      {"a": "A","b": 28}, {"a": "B","b": 55}, {"a": "C","b": 43},
      {"a": "D","b": 91}, {"a": "E","b": 81}, {"a": "F","b": 53},
      {"a": "G","b": 19}, {"a": "H","b": 87}, {"a": "I","b": 52}
    ]
  },
  "mark": "bar",
  "encoding": {
    "x": {"field": "a", "type": "ordinal"},
    "y": {"field": "b", "type": "quantitative"}
  }
}
```

This can be directly translated into the following `@vlplot` macro call:

```julia
using VegaLite

@vlplot(
    data={
        values=[
            {a="A",b=28},{a="B",b=55},{a="C",b=43},
            {a="D",b=91},{a="E",b=81},{a="F",b=53},
            {a="G",b=19},{a="H",b=87},{a="I",b=52}
        ]
    },
    mark="bar",
    encoding={
        x={field="a", typ="ordinal"},
        y={field="b", typ="quantitative"}
    }
)
```

The main difference between JSON and the `@vlplot` macro is that keys are not surrounded by quotation marks in the macro, and key-value pairs are separate by a `=` (instead of a `:`). The second important change is that whenever a key is named `type` in the JSON version, one has to translate that into `typ` in the macro (`type` is a reserved keyword in julia and therefore can't be used in this context).

While these literal translations of JSON work, they are also quite verbose. The `@vlplot` macro provides a number of shorthands so that the same plot can be expressed in a much more concise manner. The following example creates the same plot, but uses a number of alternative syntaxes provided by the `@vlplot` macro:

```julia
using VegaLite, DataFrames

data = DataFrame(
    a=["A","B","C","D","E","F","G","H","I"],
    b=[28,55,43,91,81,53,19,87,52]
)

data |> @vlplot(:bar, x=:a, y=:b)
```

Typically you should use these shorthands so that you can express your plots in a concise way. The various shorthands are described in more detail in a different chapter.

## The `vl` string macro

One can embed a JSON vega-lite specification directly in julia code by using the `vl` string macro:

```julia
using VegaLite

spec = vl"""
{
  "$schema": "https://vega.github.io/schema/vega-lite/v2.json",
  "description": "A simple bar chart with embedded data.",
  "data": {
    "values": [
      {"a": "A","b": 28}, {"a": "B","b": 55}, {"a": "C","b": 43},
      {"a": "D","b": 91}, {"a": "E","b": 81}, {"a": "F","b": 53},
      {"a": "G","b": 19}, {"a": "H","b": 87}, {"a": "I","b": 52}
    ]
  },
  "mark": "bar",
  "encoding": {
    "x": {"field": "a", "type": "ordinal"},
    "y": {"field": "b", "type": "quantitative"}
  }
}
"""
```

The resulting `VLSpec` object is indistinguishable from one that is created via the `@vlplot` macro.

The main benefit of this approach is that one can directly leverage JSON vega-lite examples and code.

## Loading and saving vega-lite specifications

The `load` and `save` functions can be used to load and save vega-lite specifications to and from disc. The following example loads a vega-lite specification from a file named `myfigure.vegalite`:

```julia
using VegaLite

spec = load("myfigure.vegalite")
```

To save a `VLSpec` to a file on disc, use the `save` function:

```julia
using VegaLite

spec = ... # Aquire a spec from somewhere

savespec("myfigure.vegalite", spec)
```

!!! note

    Using the `load` and `save` function will be enabled in a future release. For now you should use `loadspec` and `savespec` instead (both of these functions will be deprecated once `load` and `save` are enabled).

## [DataVoyager.jl](https://github.com/queryverse/DataVoyager.jl)

The [DataVoyager.jl](https://github.com/queryverse/DataVoyager.jl) package provides a graphical UI for data exploration that is based on vega-lite. One can use that tool to create a figure in the UI, and then export the corresponding vega-lite specification for use with this package here.

## Displaying plots

[VegaLite.jl](https://github.com/queryverse/VegaLite.jl) integrates into the default julia multimedia system for viewing plots. This means that in order to show a plot `p` you would simply call the `display(p)` function. Most interactive julia environments (REPL, IJulia, Jupyter Lab, nteract etc.) automatically call `display` on the value of the last interactive command for you.

Simply viewing plots should work out of the box in all known julia environments. If you plan to use the interactive features of [VegaLite.jl](https://github.com/queryverse/VegaLite.jl) the story becomes slightly more nuanced: while many environments (REPL, [Jupyter Lab](https://github.com/jupyterlab/jupyterlab), [nteract](https://github.com/nteract/nteract), [ElectronDisplay.jl](https://github.com/queryverse/ElectronDisplay.jl)) support interactive [VegaLite.jl](https://github.com/queryverse/VegaLite.jl) plots by default, there are others that either need some extra configuration work ([Jupyter Notebook](http://jupyter.org/)), or don't support interactive plots.

## Saving plots

[VegaLite.jl](https://github.com/queryverse/VegaLite.jl) plots can be saved as [PNG](https://en.wikipedia.org/wiki/Portable_Network_Graphics), [SVG](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics), [PDF](https://en.wikipedia.org/wiki/PDF) and [EPS](https://en.wikipedia.org/wiki/Encapsulated_PostScript) files. You can save a plot by calling the `save` function:

```julia
using VegaLite, VegaDatasets

p = dataset("cars") |> @vlplot(:point, x=:Horsepower, y=:Miles_per_Gallon)

# Save as PNG file
save("figure.png", p)

# Save as SVG file
save("figure.svg", p)

# Save as PDF file
save("figure.pdf", p)

# Save EPS PNG file
save("figure.eps", p)
```

You can also use the `|>` operator with the `save` function:

```julia
using VegaLite, VegaDatasets

dataset("cars") |>
    @vlplot(:point, x=:Horsepower, y=:Miles_per_Gallon) |>
    save("figure.png")
```
