# Table-based Plots

## Table Heatmap

```@example
using VegaLite, VegaDatasets

dataset("cars") |>
@vlplot(:rect, y=:Origin, x="Cylinders:o", color="mean(Horsepower)")
```

## Table Binned heatmap

```@example
using VegaLite, VegaDatasets

dataset("movies") |>
@vlplot(
    :rect,
    width=300, height=200,
    x={:IMDB_Rating, bin={maxbins=60}},
    y={:Rotten_Tomatoes_Rating, bin={maxbins=40}},
    color="count()",
    config={
        range={
            heatmap={
                scheme="greenblue"
            }
        },
        view={
            stroke="transparent"
        }
    }
)
```

## Table Bubble Plot (Github Punch Card)

```@example
using VegaLite, VegaDatasets

dataset("github") |>
@vlplot(
    :circle,
    y="day(time):o",
    x="hours(time):o",
    size="sum(count)"
)
```

## Layering text over heatmap


```@example
using VegaLite, VegaDatasets

cars = dataset("cars")

@vlplot(
    data=cars,
    y="Origin:o",
    x="Cylinders:o",
    config={
        scale={bandPaddingInner=0, bandPaddingOuter=0},
        text={baseline=:middle}
    }
) +
@vlplot(:rect, color="count()") +
@vlplot(
    :text,
    text="count()",
    color={
        condition={
            test="datum['count_*'] > 100",
            value=:black
        },
        value=:white
    }
)
```
