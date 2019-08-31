# Repeat & Concatenation

## Repeat and layer to show different weather measures

```@example
using VegaLite, VegaDatasets

dataset("weather.csv") |>
@vlplot(repeat={column=[:temp_max,:precipitation,:wind]}) +
(
    @vlplot() +
    @vlplot(
        :line,
        y={field={repeat=:column},aggregate=:mean,typ=:quantitative},
        x="month(date):o",
        detail="year(date):t",
        color=:location,
        opacity={value=0.2}
    ) +
    @vlplot(
        :line,
        y={field={repeat=:column},aggregate=:mean,typ=:quantitative},
        x="month(date):o",
        color=:location
    )
)
```

## Vertically concatenated charts that show precipitation in Seattle

```@example
using VegaLite, VegaDatasets

dataset("weather.csv") |>
@vlplot(transform=[{filter="datum.location === 'Seattle'"}]) +
[
    @vlplot(:bar,x="month(date):o",y="mean(precipitation)");
    @vlplot(:point,x={:temp_min, bin=true}, y={:temp_max, bin=true}, size="count()")
]
```

## Horizontally repeated charts

```@example
using VegaLite, VegaDatasets

dataset("cars") |>
@vlplot(repeat={column=[:Horsepower, :Miles_per_Gallon, :Acceleration]}) +
@vlplot(
    :bar,
    x={field={repeat=:column},bin=true,typ=:quantitative},
    y="count()",
    color=:Origin
)
```

## Interactive Scatterplot Matrix

```@example
using VegaLite, VegaDatasets

dataset("cars") |> 
@vlplot(
    repeat={
        row=[:Horsepower, :Acceleration, :Miles_per_Gallon],
        column=[:Miles_per_Gallon, :Acceleration, :Horsepower]
    }
) +
@vlplot(
    :point,
    selection={
        brush={
            typ=:interval,
            resolve=:union,
            on="[mousedown[event.shiftKey], window:mouseup] > window:mousemove!",
            translate="[mousedown[event.shiftKey], window:mouseup] > window:mousemove!",
            zoom="wheel![event.shiftKey]"
        },
        grid={
            typ=:interval,
            resolve=:global,
            bind=:scales,
            translate="[mousedown[!event.shiftKey], window:mouseup] > window:mousemove!",
            zoom="wheel![!event.shiftKey]"
        }
    },
    x={field={repeat=:column}, typ=:quantitative},
    y={field={repeat=:row}, typ=:quantitative},
    color={
        condition={
            selection=:brush,
            field=:Origin,
            typ=:nominal
        },
        value=:grey
    }
)
```

