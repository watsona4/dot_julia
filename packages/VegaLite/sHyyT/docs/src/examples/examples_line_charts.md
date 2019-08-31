# Line Charts

## Line Chart

```@example
using VegaLite, VegaDatasets

dataset("stocks") |>
@vlplot(
    :line,
    transform=[
        {filter="datum.symbol=='GOOG'"}
    ],
    x="date:t",
    y=:price
)
```

## Line Chart with Point Markers

```@example
using VegaLite, VegaDatasets

dataset("stocks") |>
@vlplot(
    transform=[{filter="datum.symbol==='GOOG'"}],
    mark={
        :line,
        point=true
    },
    x="year(date)",
    y="mean(price)",
    color=:symbol
)
```

## Line Chart with Stroked Point Markers

```@example
using VegaLite, VegaDatasets

dataset("stocks") |>
@vlplot(
    transform=[{filter="datum.symbol==='GOOG'"}],
    mark={
        :line,
        point={filled=false, fill=:white}
    },
    x="year(date)",
    y="mean(price)",
    color=:symbol
)
```

## Multi Series Line Chart

```@example
using VegaLite, VegaDatasets

dataset("stocks") |>
@vlplot(
    :line,
    x="date:t",
    y=:price,
    color=:symbol
)
```

## Slope Graph

```@example
using VegaLite, VegaDatasets

dataset("barley") |>
@vlplot(
    :line,
    x={
        "year:o",
        scale={
            rangeStep=50,
            padding=0.5
        }
    },
    y="median(yield)",
    color=:site
)
```

## Step Chart

```@example
using VegaLite, VegaDatasets

dataset("stocks") |>
@vlplot(
    transform=[{filter="datum.symbol==='GOOG'"}],
    mark={
        :line,
        interpolate="step-after"
    },
    x="date:t",
    y=:price
)
```

## Line Chart with Monotone Interpolation

```@example
using VegaLite, VegaDatasets

dataset("stocks") |>
@vlplot(
    transform=[{filter="datum.symbol==='GOOG'"}],
    mark={
        :line,
        interpolate="monotone"
    },
    x="date:t",
    y=:price
)
```

## Connected Scatterplot (Lines with Custom Paths)

```@example
using VegaLite, VegaDatasets

dataset("driving") |>
@vlplot(
    mark={
        :line,
        point=true
    },
    x={
        :miles,
        scale={zero=false}
    },
    y={
        :gas,
        scale={zero=false}
    },
    order="year:t"
)
```

## Line Chart with Varying Size (using the trail mark)

```@example
using VegaLite, VegaDatasets

dataset("stocks") |>
@vlplot(
    :trail,
    x={
        "date:t",
        axis={format="%Y"}
    },
    y=:price,
    size=:price,
    color=:symbol
)
```

## Line Chart with Markers and Invalid Values

```@example
using VegaLite, DataFrames

data = DataFrame(
    x=[1,2,3,4,5,6,7],
    y=[10,30,missing,15,missing,40,20]
)

data |>
@vlplot(
    mark={
        :line,
        point=true
    },
    x=:x,
    y=:y
)
```

## Carbon Dioxide in the Atmosphere

```@example
using VegaLite, VegaDatasets

@vlplot(
    data={
        url=dataset("co2-concentration").path,
        format={
            parse={Date="utc:'%Y-%m-%d'"}
        }
    },
    width=800,
    height=500,
    transform=[
        {
            calculate="year(datum.Date)",
            as=:year
        },
        {
            calculate="month(datum.Date)",
            as=:month
        },
        {
            calculate="floor(datum.year / 10) + 'x'",
            as=:decade
        },
        {
            calculate="(datum.year % 10) + (datum.month/12)",
            as=:scaled_date
        }
    ]
) +
@vlplot(
    :line,
    x={
        "scaled_date:q",
        axis={
            title="Year into Decade",
            tickCount=11
        }
    },
    y={
        "CO2:q",
        axis={title="CO2 concentration in ppm"},
        scale={zero=false}
    },
    detail="decade:o",
    color={"decade:n", legend={offset=40}}
) +
(
    @vlplot(
        transform=[
            {
                aggregate=[{
                    op="argmin",
                    field="scaled_date",
                    as="start"
                }, {
                    op="argmax",
                    field="scaled_date",
                    as="end"
                }],
                groupby=["decade"]
            },
            {
                calculate="datum.start.scaled_date",
                as="scaled_date_start"
            },
            {
                calculate="datum.start.CO2",
                as="CO2_start"
            },
            {
                calculate="datum.start.year",
                as="year_start"
            },
            {
                calculate="datum.end.scaled_date",
                as="scaled_date_end"
            },
            {
                calculate="datum.end.CO2",
                as="CO2_end"
            },
            {
                calculate="datum.end.year",
                as="year_end"
            }
        ]
    ) +
    @vlplot(
        mark={
            :text,
            aligh=:left,
            baseline=:top,
            dx=3,
            dy=1
        },
        x="scaled_date_start:q",
        y="CO2_start:q",
        text="year_start:n"
    ) +
    @vlplot(
        mark={
            :text,
            align=:left,
            baseline=:bottom,
            dx=3,
            dy=1
        },
        x="scaled_date_end:q",
        y="CO2_end:q",
        text="year_end:n"
    )
)
```

## Line Charts Showing Ranks Over Time

```@example
using VegaLite, DataFrames

data = DataFrame(
    team=["Man Utd", "Chelsea", "Man City", "Spurs", "Man Utd", "Chelsea",
        "Man City", "Spurs", "Man Utd", "Chelsea", "Man City", "Spurs"],
    matchday=[1,1,1,1,2,2,2,2,3,3,3,3],
    point=[3,1,1,0,6,1,0,3,9,1,0,6]
)

data |>
@vlplot(
    transform=[{
        sort=[{field="point", order="descending"}],
        window=[{
            op="rank",
            as="rank"
        }],
        groupby=["matchday"]
    }],
    mark={
        :line,
        orient="vertical"
    },
    x="matchday:o",
    y="rank:o",
    color={
        :team,
        scale={
            domain=["Man Utd", "Chelsea", "Man City", "Spurs"],
            range=["#cc2613", "#125dc7", "#8bcdfc", "#d1d1d1"]
        }
    }
)
```
