# Data

[VegaLite.jl](https://github.com/queryverse/VegaLite.jl) accepts data to be plotted in a variety of different formats and provides a number of different ways to reference that data. The most typical way to plot data is that you have your data in some julia data structure, and then add this data to the Vega-Lite specification itself for plotting. As an alternative, Vega-Lite also accepts URLs that point to data sources either on disc or on the web for plotting. Data that you want to plot will typically be in a tabular form.

## Inline data

Any julia data structure data supports the iterable tables interface from the [TableTraits.jl](https://github.com/queryverse/TableTraits.jl) package can be used as an inline data source with [VegaLite.jl](https://github.com/queryverse/VegaLite.jl). In practice that covers most tabular data structures in the julia ecosystem: [DataFrames.jl](https://github.com/JuliaData/DataFrames.jl), [JuliaDB.jl](https://github.com/JuliaComputing/JuliaDB.jl), [IndexedTables.jl](https://github.com/JuliaComputing/IndexedTables.jl), various file IO packages ([CSVFiles.jl](https://github.com/queryverse/CSVFiles.jl), [FeatherFiles.jl](https://github.com/queryverse/FeatherFiles.jl), [ExcelFiles.jl](https://github.com/queryverse/ExcelFiles.jl), [StatFiles.jl](https://github.com/queryverse/StatFiles.jl), [ParquetFiles.jl](https://github.com/queryverse/ParquetFiles.jl)) and any [Query.jl](https://github.com/queryverse/Query.jl) result that has a tabular form.

There are two ways to add an inline data source to a Vega-Lite plot: 1) by piping the data source into a plot, or 2) by using the `data` keyword from within a `@vlplot` call.

### Piping inline data

Any tabular data can be piped into a plot by using the `|>` operator. For example, to create a scatter plot of a `DataFrame` called `df` you can pipe that `DataFrame` into a specification like this:

```julia
df |> @vlplot(:point, x=:a, y=:b)
```

As mentioned above, you are not restricted to piping `DataFrame`s into a plot, but can in fact plot any iterable table. The following example loads some data from a CSV file using [CSVFiles.jl](https://github.com/queryverse/CSVFiles.jl), filters it with [Query.jl](https://github.com/queryverse/Query.jl) and then plots it with [VegaLite.jl](https://github.com/queryverse/VegaLite.jl):

```julia
load("my_data.csv") |> @filter(_.a>30) |> @vlplot(:point, x=:a, y=:b)
```

### Using inline data with the `data` keyword

You can also specify the inline data for a plot by using the standard `data` keyword from the Vega-Lite language. The following example creates a plot based on a `DataFrame` named `df`:

```julia
@vlplot(:point, data=df, x=:a, y=:b)
```

This method also accepts any iterable table.

## Referencing external data

!!! note
    Note that some of the techniques described in this section are not yet implemented.

Sometimes it can be convenient to not embed the source data in the actual Vega-Lite specification, but instead just embed a link to some data in a file. Vega-Lite can read data in a variety of formats (CSV, TSV, JSON etc.), and you can again either pipe a reference into a plot or use the `data` keyword to specify an external link.

[VegaLite.jl](https://github.com/queryverse/VegaLite.jl) uses the `URI` type from the [URIParser.jl](https://github.com/JuliaWeb/URIParser.jl) package to represent URIs, and the [FilePaths.jl](https://github.com/rofinn/FilePaths.jl) package to represent filesystem paths. For example, to create a path, you can use the `p` string macro:

```julia
using FilePaths

path = p"folder/filename.csv"
```

The following example creates a `URI` instance:

```julia
using URIParser

uri = URI("https://www.foo.com/bar.csv")
```

### Piping paths and URIs

Piping either a path or a URI into a Vega-Lite specification works the same way as piping inline data into a plot. You first have to create a path or URI, and then use the pipe operator `|>`. The following code shows examples of piping both a path and a URI into a plot:

```julia
# Piping a path into a plot

p"subfolder/myfile.csv" |> @vlplot(:point, x=:a, y=:b)

# Piping a URI into a plot

URI("https://www.foo.com/bar.json") |> @vlplot(:point, x=:a, y=:b)
```

### Using paths and URIs with the `data` keyword

You can directly pass a path or URI to the `data` keyword in a `@vlplot` call, similar to how you can pass inline data:

```julia
# Plotting data from a local file
@vlplot(:point, data=p"subfolder/file.csv", x=:a, y=:b)

# Plotting data from a URI
@vlplot(:point, data=URI("https://www.foo.com/bar.json"), x=:a, y=:b)
```

Sometimes you need to specify additional configuration parameters for an external data source that are supported by the Vega-Lite specification. In that case you can also pass the path or URI instance to the `url` sub-key in the `data` part of a plot specification:

```julia
@vlplot(
    :point,
    data={
        url=p"subfolder/foo.txt",
        format={
            typ=:csv
        }
    },
    x=:a,
    y=:b
)
```