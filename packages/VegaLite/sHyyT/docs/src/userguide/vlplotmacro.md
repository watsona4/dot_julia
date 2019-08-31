# The @vlplot command

The `@vlplot` macro is the main method to create Vega-Lite plots from julia. The macro accepts arguments that look almost identical to the original Vega-Lite JSON syntax. It should therefore be very easy to take any given Vega-Lite JSON example and translate it into a corresponding `@vlplot` macro call. The macro also provides a number of shorthands that make it easy to create very compact plot specifications. This section will first review the difference between the original JSON Vega-Lite syntax and the `@vlplot` macro, and then discuss the various shorthands that users will typically use.

## JSON syntax vs `@vlplot` macro

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

We had to make the following adjustments to the original JSON specification:
1. The outer pair of `{}` brackets was removed, the parenthesis `()` of the macro call instead deliminate the beginning and end of the specification.
2. The quotation marks `"` around keys like `mark` are removed.
3. The JSON key-value separator `:` was replaced with `=`.
4. Any key that is named `type` in the JSON specification has to be renamed to `typ` in the `@vlplot` macro (`type` is a reserved keyword in julia and can therefore not be used here).
5. Any `null` value in the JSON specification should be replaced with `nothing` in the `@vlplot` call.

These five rules should be sufficient to translate any valid JSON Vega-Lite specification into a corresponding `@vlplot` macro call.

## Symbols instead of Strings

A first shorthand provided by the `@vlplot` macro is that you can use a `Symbol` on the right hand side of any key-value pair instead of a `String`. For example, instead of writing `mark="bar"`, you can write `mark=:bar`.

The following example demonstrates this in the context of a full plotting example:

```julia
data |>
@vlplot(
    mark=:point, # Note how we use :point instead of "point" here
    encoding={
        x={
            field=:a, # Note how we use :a instead of "a" here
            typ=:ordinal # Note how we use :ordinal instead of "ordinal" here
        },
        y={
            field=:b, # Note how we use :b instead of "b" here
            typ=:quantitative # Note how we use :quantitative instead of "quantitative" here
        }
    }
)
```

## Shorthand string syntax for encodings

[VegaLite.jl](https://github.com/queryverse/VegaLite.jl) provides a similar string shorthand syntax for encodings as [Altair](https://altair-viz.github.io/) (the Python wrapper around Vega-Lite).

Almost any channel encoding in a specification will have the keys `field` and `typ`, as in `x={field=:a, typ=:ordinal}`. Because these patterns are so common, we provide a shorthand string syntax for this case. Using the shorthand one can write the channel encoding as `x={"a:o"}`. These string shorthands have to appear as the first positional argument inside the curly brackets `{}` for the encoding channel. The pattern inside the string is that one specifies the name of the field before the `:`, and then the first letter of the type of encoding (`o` for ordinal, `q` for quantitative etc.).

The string shorthand also extends to the `timeUnit` and `aggregate` key in encodings. Aggregation functions and time units can be specified using a function call syntax inside the string shorthand. For example, `x={"mean(foo)"}` is equivalent to `x={field=:foo, aggregate=:mean, typ=:quantitative}` (note that we don't have to specify the type explicitly when we use aggregations, the default assumption is that the result of an aggregation is quantitative). An example that uses the shorthand for a time unit is `x={"year(foo):t"}`, which is equivalent to `x={field=:foo, timeUnit=:year, typ=:quantitative}`. For aggregations that don't require a field name (e.g. the `count` aggregation), you can just write `x="count()"`.

String shorthands can be combined with any other attributes. For example, the following example shows how one can specify an axis title and still use the string shorthand notation:

```julia
x={"foo:q", axis={title="some title"}}
```

In cases where you don't want to specify any other attributes than what can be expressed in the string shorthand you don't have to use the surrounding curly brackets `{}` for the encoding: `x="foo:q"` is equivalent to `x={field=:foo, typ=:quantitative}`. If you only want to specify the field and not even the type, you can resort to using a `Symbol`: `x=:foo` is also a valid encoding.

The shorthand string syntax allows us to write the specification of the plot from the previous section in this much more concise format:

```julia
data |>
@vlplot(
    mark=:point,
    encoding={
        x="a:o",
        y=:b
    }
)
```

## Shorthands for the `encoding` element

There are two shorthands for the `encoding` element in a plot specification.

The first is to simply write `enc` instead of `encoding`. For example, the previous specification can be written as

```julia
data |>
@vlplot(
    mark=:point,
    enc={
        x="a:o",
        y=:b
    }
)
```

An even shorter notation is to just leave the level of the `encoding` element away and place the channel encodings directly into the top level specification. With that option you would write the previous example as:

```julia
data |>
@vlplot(mark=:point, x="a:o", y=:b)
```

## Mark shorthands

There are two shorthands for the `mark` attribute in a specification. The first option is to use the first positional argument in a `@vlplot` call to specify the mark type. This only works if you don't want to specify any other mark attributes. For example, the previous plot can now be written as

```julia
data |> @vlplot(:point, x="a:o", y=:b)
```

If you want to specify more mark attributes, you can reintroduce curly brackets `{}`, and then specify the type of the mark as the first positional argument inside the `mark` block. For example, the following code specifies that the mark color should be red, in addition to picking points as the mark type:

```julia
data |>
@vlplot(
    mark={:point, color=:red},
    x="a:o",
    y=:b
)
```
