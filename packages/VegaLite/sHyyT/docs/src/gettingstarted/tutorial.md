# Tutorial

This tutorial will show you how to create plots with [VegaLite.jl](https://github.com/queryverse/VegaLite.jl).

## Data

Plots are a way to visualize data, and therefore every plot starts with some dataset. [VegaLite.jl](https://github.com/queryverse/VegaLite.jl) expects data to be in tabular form, and it works best if you pass it [tidy data](https://en.wikipedia.org/wiki/Tidy_data).

The definition of tabular data we are using here is very simple: think of a table that has a header and consists of a number of columns and rows. The header gives each column a name. The rows correspond to the actual data. Columns don't have to be of the same data type, i.e. you can have one column that contains `String`s, and another that contains `Float64` values.

[VegaLite.jl](https://github.com/queryverse/VegaLite.jl) can digest many different julia types that store tabular data. You can, for example, plot data that is stored in a `DataFrame`, [JuliaDB.jl](https://github.com/JuliaComputing/JuliaDB.jl) or loaded from disc with [CSVFiles.jl](https://github.com/queryverse/CSVFiles.jl). In this tutorial we will plot data that ships in the package [VegaDatasets.jl](https://github.com/queryverse/VegaDatasets.jl).

The dataset we will use for this tutorial is the `cars` dataset from the [VegaDatasets.jl](https://github.com/queryverse/VegaDatasets.jl). The dataset contains information about a couple hundred cars. We can load the dataset with the `dataset` function:

```@example
using VegaDatasets

data = dataset("cars")
```

We are storing the dataset in the variable `data`, so that we can access it more easily in the following examples.

## Simple Scatter Plot

We will start out with a very simple scatter plot. The minimum steps for creating a plot are to 1) pass the data we want to plot to the plot macro, and 2) specify what kind of visual shape, or "mark" in Vega-Lite terminology, we want to use to visualize our data. We "pipe" the data into the plot macro using the pipe operator `|>`. The actual plot is created by a call to the `@vlplot` macro. The first argument to the `@vlplot` macro specifies what kind of mark we want to use for our plot. We pass the name of the mark as a symbol. In our example we want to use points for our plot. The following code shows this minimal plot:

```@example
using VegaLite, VegaDatasets

data = dataset("cars")

data |> @vlplot(:point)
```

While this code produces a plot, it is not a very useful plot. Vega-Lite is actually drawing a point for every row in our input dataset. But it is drawing all these points on top of each other, which makes the plot so uninteresting.

By the way, the code above is based on the premise that it is executed in the Julia command line (REPL). When the code is executed from within a script (or a function), the plot needs to be explicitly displayed as

```@example
using VegaLite, VegaDatasets

data = dataset("cars")

data |> @vlplot(:point) |> display
```

To create a more interesting plot, we next need to specify how Vega-Lite should connect key properties of the points (for example their position) with the data that we passed it. These connections are called "encodings" in Vega-Lite. We will start out by specifying how both the x and y position encoding channel for the points should take values from the data we passed:

```@example
using VegaLite, VegaDatasets

data = dataset("cars")

data |> @vlplot(:point, x=:Miles_per_Gallon, y=:Horsepower)
```

This code now produces a nice scatter plot. We specify these encodings by using keyword arguments inside the `@vlplot` macro that correspond to the names of the encoding channels, in our example the `x` and `y` channel. We pass the names of the columns in our dataset that we want to use for these channels as symbols, e.g. as `:Miles_per_Gallon` and `:Horsepower`.

## Encoding

Vega-Lite provides many different encoding channels beyond the `x` and `y` channel we saw in the previous section. This section will introduce a few more encoding channels and how you can configure their details. You can read about the full list of encoding channels in the original [Vega-Lite documentation](https://vega.github.io/vega-lite/docs/encoding.html).

### Channels

As our next step we will encode the `color` channel. The following code will use the `Origin` column in our dataset for the `color` channel, so that the points in our plot use a different color for each unique value in the `Origin` column:

```@example
using VegaLite, VegaDatasets

data = dataset("cars")

data |> @vlplot(:point, x=:Miles_per_Gallon, y=:Horsepower, color=:Origin)
```

If we want to produce a separate plot for each of the three unique `Origin` values, we can instead encode the `columns` channel so that we create a facet plot:

```@example
using VegaLite, VegaDatasets

data = dataset("cars")

data |> @vlplot(:point, x=:Miles_per_Gallon, y=:Horsepower, column=:Origin)
```

We can now use the `color` channel to visualize yet another column from our dataset. The following code uses the `color` encoding channel to visualize the `Cylinders` column in our dataset:

```@example
using VegaLite, VegaDatasets

data = dataset("cars")

data |>
@vlplot(:point, x=:Miles_per_Gallon, y=:Horsepower, column=:Origin, color=:Cylinders)
```

### Channel types

Before we introduce channel types, we will go back to a more simple plot without faceting.

```@example
using VegaLite, VegaDatasets

data = dataset("cars")

data |>
@vlplot(:point, x=:Miles_per_Gallon, y=:Horsepower, color="Cylinders")
```

We are still encoding the `color` channel, but note that we are now passing the name of the column as a `String`, not as a `Symbol` (i.e. we are writing `color="Cylinders"` instead of `color=:Cylinders`). This is a general pattern in [VegaLite.jl](https://github.com/queryverse/VegaLite.jl): you can generally use `Symbol`s and `String`s interchangeably. Using a `Symbol` saves you one extra character (the closing `"`), so we tend to use those when possible, but sometimes you need to use characters that can't be used in Julia's literal Symbolsyntax, and then we use `String`s.

The legend that was automatically generated for the color channel in the previous plot uses a continuous scale, i.e. it shows a smooth range of colors. [VegaLite.jl](https://github.com/queryverse/VegaLite.jl) automatically encodes any numeric column in the source data as such a "quantitative" channel. Sometimes that is not a good automatic default, though. For example, in our example case there are only a handful of distinct integer values used in the Cylinders column, and in such a case we might prefer a more discrete legend.

We can tell [VegaLite.jl](https://github.com/queryverse/VegaLite.jl) to change the type of a channel from say the default `quantitative` type to an `ordinal` channel by slightly changing the channel encoding to `color="Cylinders:ordinal"`. In this case we specify the type of the encoding as a second argument in the string that is separated from the column name by a `:`. We can further shorten this by writing `color="Cylinders:o"`, i.e. we can only use the first character of the type of encoding we want to use.

Using this new syntax we can generate the following plot:

```@example
using VegaLite, VegaDatasets

data = dataset("cars")

data |>
@vlplot(:point, x=:Miles_per_Gallon, y=:Horsepower, color="Cylinders:o")
```

Values in an ordinal channel are still ordered, so Vega-Lite automatically picks a color scheme that can showcase such an order.

What if we don't want to use a color scheme that signals any order? In that case we can change the type of the encoding to `nominal` by using the syntax `color="Cylinders:n"`, generating the following plot:

```@example
using VegaLite, VegaDatasets

data = dataset("cars")

data |>
@vlplot(:point, x=:Miles_per_Gallon, y=:Horsepower, color="Cylinders:n")
```

You can also use the same encoding type specification for any other encoding channel. The following example puts the Cylinders column on the x axis of the plot and specifies it as an ordinal encoding:

```@example
using VegaLite, VegaDatasets

data = dataset("cars")

data |> @vlplot(:point, x="Cylinders:o", y=:Miles_per_Gallon)
```

### Channel properties

Our previous plots looked quite decent, but in many cases we probably still want to customize a whole range of features of our plots. One simple example in the previous plots might be the label of the axis that encoded the `Miles_per_Gallon` column. The axis automatically got labeled by the column name, and we might want to remove the underscores from the actual axis label.

Whenever we want to specify more properties for a channel than just the name or type, we have to assign a composite value to the name of the channel by using curly brackets `{}`. Note that this use of `{}` is specific to the `@vlplot` macro, i.e. it is not a generic Julia language feature. For example, to specify an alternative title for an axis, we would write `x={:Miles_per_Gallon, title="MPG"}`. Note that within the composite value we can still pass the name of the field to be encoded as a first positional argument, followed by arbitrary many named arguments. We can use similar syntax to also adjust the title of the legend, as shown in the following code example:

```@example
using VegaLite, VegaDatasets

data = dataset("cars")

data |>
@vlplot(
    :point,
    x={
        :Miles_per_Gallon,
        title="MPG"
    },
    y=:Horsepower,
    color={
        "Cylinders:n",
        legend={title="No of Cylinders"}
    }
)
```

Channels have a large number of properties that you can customize in this way, they are all explained in the original [Vega-Lite documentation](https://vega.github.io/vega-lite/docs/encoding.html).

## Marks

Our examples all used a `point` mark so far, but Vega-Lite supports many more types of [marks](https://vega.github.io/vega-lite/docs/mark.html). The following example uses a `line` mark instead of the `point` mark we have used so far:

```@example
using VegaLite, VegaDatasets, Query

dataset("stocks") |>
@filter(_.symbol=="GOOG") |>
@vlplot(:line, x={"date:t", axis={format="%Y"}}, y=:price)
```

Note how we specify the `line` mark type as the first positional argument to the `@vlplot` macro call. This examples also showcases a number of other features. First, it uses [Query.jl](https://github.com/queryverse/Query.jl) to filter the dataset before we plot it (we only want to plot the stock price for Google). The example also introduces a encoding channel type we haven't seen before: we are using a `temporal` channel type here (configured with the `:t` part in `"date:t"`). The `temporal` type is specifically designed for date and time information. We are also changing how the values of the x axis are displayed in the plot by specifying a custom format string for the x axis.

Sometimes we will need to configure more aspects of the mark than just the type of mark. In that case we can pass additional properties by using the composite syntax we have seen before. In the following example we are using a `line` mark, and we are customizing the color of the line and are also configuring it to show points on top of the line itself:

```@example
using VegaLite, VegaDatasets, Query

dataset("stocks") |>
@filter(_.symbol=="GOOG") |>
@vlplot(
    mark={
        :line,
        point=true,
        color=:red
    },
    x={
        "date:t",
        axis={
            format="%Y"
        }
    },
    y=:price
)
```

Note how we have to use the more explicit named keyword syntax `mark={}` when we want to specify more mark properties inside the `@vlplot` macro call. We can still pass the mark type as a positional first argument inside the value we assign to `mark`, though.

There are many different mark types in Vega-Lite, with many different options to customize their appearance. The original [Vega-Lite documentation](https://vega.github.io/vega-lite/docs/mark.html) describes all these options in detail.

## Aggregations

The following graph shows many individual data points for each x axis value:

```@example
using VegaLite, VegaDatasets

dataset("cars") |> @vlplot(:point, x=:Origin, y=:Miles_per_Gallon)
```

In such situations it can often be more interesting to compute an aggregate value for each x axis value, for example the mean miles per gallon number for each region:

```@example
using VegaLite, VegaDatasets

dataset("cars") |> @vlplot(:point, x=:Origin, y="average(Miles_per_Gallon)")
```

Here we are making use of another shorthand syntax option in [VegaLite.jl](https://github.com/queryverse/VegaLite.jl). We can specify an aggregation operation in the form of a function call (e.g. `average(...)`) and then pass the name of the column for which we want to compute the aggregation as an argument (e.g. `average(Miles_per_Gallon)`). Vega-Lite supports many different [aggregations](https://vega.github.io/vega-lite/docs/aggregate.html#ops). For example the next plot shows the minimum miles per gallon per region:

```@example
using VegaLite, VegaDatasets

dataset("cars") |> @vlplot(:bar, x=:Origin, y="min(Miles_per_Gallon)")
```

This example also uses a different mark, namely the `bar` mark to create a bar plot.

There is one aggregation operator that works slightly different, namely the `count` aggregation. It simply counts the number of rows in each group, so one does not have to specify a column to be aggregated:

```@example
using VegaLite, VegaDatasets

dataset("cars") |> @vlplot(:bar, x=:Origin, y="count()")
```

Aggregations can of course be used for any encoding channel, we can for example easily create a horizontal bar chart:


```@example
using VegaLite, VegaDatasets

dataset("cars") |> @vlplot(:bar, x="count()", y=:Origin)
```

## Config

Almost all aspects of a Vega-Lite plot can be configured and customized. Many of these choices can be set by using the `config` keyword in the `@vlplot` macro call. For example, the following plot adds a title to the plot and the configures the title to use a red font:

```@example
using VegaLite, VegaDatasets

dataset("cars") |>
@vlplot(
    :point,
    x=:Miles_per_Gallon,
    y=:Acceleration,
    title="Cars",
    config={
        title={
            color=:red
        }
    }
)
```

The original [Vega-Lite documentation](https://vega.github.io/vega-lite/docs/config.html) describes all config options in great detail.

## File IO

Plots that are created with [VegaLite.jl](https://github.com/queryverse/VegaLite.jl) can be saved to disc in a number of formats (PNG, SVG, PDF, ESP). To save a plot, simply call the `save` function:

```@example
using VegaLite, VegaDatasets

p = dataset("cars") |> @vlplot(:bar, x="count()", y=:Origin)

save("myplot.png", p)
```

You can also pipe a plot into the `save` function:

```@example
using VegaLite, VegaDatasets

dataset("cars") |>
@vlplot(:bar, x="count()", y=:Origin) |>
save("myplot.pdf")
```

## Next steps

There are two main sources of information if you want to learn more about plotting with [VegaLite.jl](https://github.com/queryverse/VegaLite.jl). The first is the excellent [Vega-Lite documentation](https://vega.github.io/vega-lite/). The documentation describes the JSON original Vega-Lite version, but it should be fairly easy to understand how those examples translate into the Julia equivalent. The second source is are the remaining sections in this documentation of [VegaLite.jl](https://github.com/queryverse/VegaLite.jl). The section about the `@vlplot` macro should be especially useful for understanding how the JSON Vega-Lite syntax can be translated into the equivalent julia version.
