# Using Vega

Basic support for Vega graphics is supported as part of VegaLite.jl.  Vega specifications are more verbose than
VegaLite specifications, but with that verbosity comes more control/options - see the [Vega documentation](https://vega.github.io/vega/docs/)
for details on creating Vega plots.

VegaLite.jl supports rendering Vega JSON specification graphics with interactivity via the REPL (launching a browser if available)
or JupyterLab.  There are two methods to do this: the `vg_str` macro or directly creating a `VGSpec` with parsed JSON.

## The `vg` string macro

Similar to the `vl` string macro, the `vg` string macro takes the Vega spec as a JSON string and returns and renders a `VGSpec`.

```julia
using VegaLite

spec = vg"""
  {
  "$schema": "https://vega.github.io/schema/vega/v4.4.json",
  "width": 400,
  "height": 200,
  "padding": 5,

  "data": [
    {
      "name": "table",
      "values": [
        {"category": "A", "amount": 28},
        {"category": "B", "amount": 55},
        {"category": "C", "amount": 43},
        {"category": "D", "amount": 91},
        {"category": "E", "amount": 81},
        {"category": "F", "amount": 53},
        {"category": "G", "amount": 19},
        {"category": "H", "amount": 87}
      ]
    }
  ],

  "signals": [
    {
      "name": "tooltip",
      "value": {},
      "on": [
        {"events": "rect:mouseover", "update": "datum"},
        {"events": "rect:mouseout",  "update": "{}"}
      ]
    }
  ],

  "scales": [
    {
      "name": "xscale",
      "type": "band",
      "domain": {"data": "table", "field": "category"},
      "range": "width",
      "padding": 0.05,
      "round": true
    },
    {
      "name": "yscale",
      "domain": {"data": "table", "field": "amount"},
      "nice": true,
      "range": "height"
    }
  ],

  "axes": [
    { "orient": "bottom", "scale": "xscale" },
    { "orient": "left", "scale": "yscale" }
  ],

  "marks": [
    {
      "type": "rect",
      "from": {"data":"table"},
      "encode": {
        "enter": {
          "x": {"scale": "xscale", "field": "category"},
          "width": {"scale": "xscale", "band": 1},
          "y": {"scale": "yscale", "field": "amount"},
          "y2": {"scale": "yscale", "value": 0}
        },
        "update": {
          "fill": {"value": "steelblue"}
        },
        "hover": {
          "fill": {"value": "red"}
        }
      }
    },
    {
      "type": "text",
      "encode": {
        "enter": {
          "align": {"value": "center"},
          "baseline": {"value": "bottom"},
          "fill": {"value": "#333"}
        },
        "update": {
          "x": {"scale": "xscale", "signal": "tooltip.category", "band": 0.5},
          "y": {"scale": "yscale", "signal": "tooltip.amount", "offset": -2},
          "text": {"signal": "tooltip.amount"},
          "fillOpacity": [
            {"test": "datum === tooltip", "value": 0},
            {"value": 1}
          ]
        }
      }
    }
  ]
  }
  """
```

## VGSpec

When parameterizing a Vega spec via a function, it is often simpler to construct a `VGSpec` structure directly.

```julia
using VegaLite
using JSON

function bar_plot(data)
  json_data = json(data)

  spec = """
    {
    "$schema": "https://vega.github.io/schema/vega/v4.4.json",
    "width": 400,
    "height": 200,
    "padding": 5,

    "data": [
      {
        "name": "table",
        "values": $(json_data)
      }
    ],

    "signals": [
      {
        "name": "tooltip",
        "value": {},
        "on": [
          {"events": "rect:mouseover", "update": "datum"},
          {"events": "rect:mouseout",  "update": "{}"}
        ]
      }
    ],

    "scales": [
      {
        "name": "xscale",
        "type": "band",
        "domain": {"data": "table", "field": "category"},
        "range": "width",
        "padding": 0.05,
        "round": true
      },
      {
        "name": "yscale",
        "domain": {"data": "table", "field": "amount"},
        "nice": true,
        "range": "height"
      }
    ],

    "axes": [
      { "orient": "bottom", "scale": "xscale" },
      { "orient": "left", "scale": "yscale" }
    ],

    "marks": [
      {
        "type": "rect",
        "from": {"data":"table"},
        "encode": {
          "enter": {
            "x": {"scale": "xscale", "field": "category"},
            "width": {"scale": "xscale", "band": 1},
            "y": {"scale": "yscale", "field": "amount"},
            "y2": {"scale": "yscale", "value": 0}
          },
          "update": {
            "fill": {"value": "steelblue"}
          },
          "hover": {
            "fill": {"value": "red"}
          }
        }
      },
      {
        "type": "text",
        "encode": {
          "enter": {
            "align": {"value": "center"},
            "baseline": {"value": "bottom"},
            "fill": {"value": "#333"}
          },
          "update": {
            "x": {"scale": "xscale", "signal": "tooltip.category", "band": 0.5},
            "y": {"scale": "yscale", "signal": "tooltip.amount", "offset": -2},
            "text": {"signal": "tooltip.amount"},
            "fillOpacity": [
              {"test": "datum === tooltip", "value": 0},
              {"value": 1}
            ]
          }
        }
      }
    ]
    }
  """

  return VegaLite.VGSpec(JSON.parse(spec))
end

d = [(category="A", amount=28),
    category="B", amount=55),
    category="C", amount=43),
    category="D", amount=91),
    category="E", amount=81),
    category="F", amount=53),
    category="G", amount=19),
    category="H", amount=87)]

bar_plot(d)
```


## Loading and saving vega specifications

The `load` and `save` functions can be used to load and save vega specifications to and from disc. The following example loads a vega specification from a file named `myfigure.vega`:

```julia
using VegaLite

spec = loadvgspec("myfigure.vega")
```

To save a `VGSpec` to a file on disc, use the `save` function:

```julia
using VegaLite

spec = ... # Aquire a spec from somewhere

savespec("myfigure.vega", spec)
```

!!! note

    Using the `load` and `save` function will be enabled in a future release. For now you should use `loadvgspec` and `savespec` instead (both of these functions will be deprecated once `load` and `save` are enabled).
