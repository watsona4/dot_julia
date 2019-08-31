# Box Plots

## Box Plot with Min/Max Whiskers

```@example
using VegaLite, VegaDatasets

dataset("population") |>
@vlplot(
    mark={:boxplot, extent="min-max"},
    x="age:o",
    y={:people, axis={title="population"}}
)
```

## Tukey Box Plot (1.5 IQR)

```@example
using VegaLite, VegaDatasets

dataset("population") |>
@vlplot(
    mark={:boxplot, extend=1.5},
    x="age:o",
    y={:people, axis={title="population"}},
    size={value=5}
)
```
