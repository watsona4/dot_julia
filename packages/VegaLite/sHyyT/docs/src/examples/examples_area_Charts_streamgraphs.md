# Area Charts & Streamgraphs

## Area Chart

```@example
using VegaLite, VegaDatasets

dataset("unemployment-across-industries") |>
@vlplot(
    :area,
    width=300, height=200,
    x={
        "yearmonth(date):t",
        axis={format="%Y"}
    },
    y={
        "sum(count)",
        axis={title="count"}
    }    
)
```

## Area Chart with Overlaying Lines and Point Markers

```@example
using VegaLite, VegaDatasets

dataset("stocks") |>
@vlplot(
    transform=[{filter="datum.symbol==='GOOG'"}],
    mark={
        :area,
        line=true,
        point=true
    },
    x="date:t",
    y=:price
)
```

## Stacked Area Chart

```@example
using VegaLite, VegaDatasets

dataset("unemployment-across-industries") |>
@vlplot(
    :area,
    width=300, hieght=200,
    x={
        "yearmonth(date):t",
        axis={format="%Y"}
    },
    y="sum(count)",
    color={
        :series,
        scale={scheme="category20b"}
    }
)
```

## Normalized Stacked Area Chart

```@example
using VegaLite, VegaDatasets

dataset("unemployment-across-industries") |>
@vlplot(
    :area,
    width=300, height=200,
    x={
        "yearmonth(date)",
        axis={
            domain=false,
            format="%Y"
        }
    },
    y={
        "sum(count)",
        axis=nothing,
        stack=:normalize
    },
    color={
        :series,
        scale={scheme="category20b"}
    }
)
```

## Streamgraph

```@example
using VegaLite, VegaDatasets

dataset("unemployment-across-industries") |>
@vlplot(
    :area,
    width=300, height=200,
    x={
        "yearmonth(date)",
        axis={
            domain=false,
            format="%Y",
            tickSize=0
        }
    },
    y={
        "sum(count)",
        axis=nothing,
        stack=:center
    },
    color={
        :series,
        scale={scheme="category20b"}
    }
)
```

## Horizon Graph

```@example
using VegaLite, DataFrames

data = DataFrame(
    x=1:20,
    y=[28,55,43,91,81,53,19,87,52,48,24,49,87,66,17,27,68,16,49,15]
)

data |>
@vlplot(width=300, height=50, config={area={interpolate=:monotone}}) +
@vlplot(
    mark={
        :area,
        clip=true,
        orient=:vertical
    },
    x={:x, scale={zero=false, nice=false}},
    y={:y, scale={domain=[0,50]}},
    opacity={value=0.6}
) +
@vlplot(
    transform=[{calculate="datum.y-50", as=:ny}],
    mark={
        :area,
        clip=true,
        orient=:vertical
    },
    x=:x,
    y={
        "ny:q",
        scale={domain=[0,50]},
        axis={title="y"}
    },
    opacity={value=0.3}
)
```
