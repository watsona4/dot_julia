## Choropleth of unemployment rate per county

```@example
using VegaLite, VegaDatasets

us10m = dataset("us-10m").path
unemployment = dataset("unemployment.tsv").path

@vlplot(
    :geoshape,
    width=500, height=300,
    data={
        url=us10m,
        format={
            typ=:topojson,
            feature=:counties
        }
    },
    transform=[{
        lookup=:id,
        from={
            data=unemployment,
            key=:id,
            fields=["rate"]
        }
    }],
    projection={
        typ=:albersUsa
    },
    color="rate:q"
)
```

## One dot per zipcode in the U.S.

```@example
using VegaLite, VegaDatasets

dataset("zipcodes").path |>
@vlplot(
    :circle,
    width=500, height=300,
    transform=[{calculate="substring(datum.zip_code, 0, 1)", as=:digit}],
    projection={typ=:albersUsa},
    longitude="longitude:q",
    latitude="latitude:q",
    size={value=1},
    color="digit:n"
)

VegaLite.MimeWrapper{MIME"image/png"}(dataset("zipcodes").path |> @vlplot(:circle,width=500,height=300,transform=[{calculate="substring(datum.zip_code, 0, 1)", as=:digit}],projection={typ=:albersUsa},longitude="longitude:q",latitude="latitude:q",size={value=1},color="digit:n")) # hide
```

## One dot per airport in the US overlayed on geoshape

```@example
using VegaLite, VegaDatasets

us10m = dataset("us-10m").path
airports = dataset("airports")

@vlplot(width=500, height=300) +
@vlplot(
    mark={
        :geoshape,
        fill=:lightgray,
        stroke=:white
    },
    data={
        url=us10m,
        format={typ=:topojson, feature=:states}
    },
    projection={typ=:albersUsa},
) +
@vlplot(
    :circle,
    data=airports,
    projection={typ=:albersUsa},
    longitude="longitude:q",
    latitude="latitude:q",
    size={value=10},
    color={value=:steelblue}
)
```

## Rules (line segments) connecting SEA to every airport reachable via direct flight

TODO

## Three choropleths representing disjoint data from the same table

TODO

## U.S. state capitals overlayed on a map of the U.S

```@example
using VegaLite, VegaDatasets

us10m = dataset("us-10m").path
usstatecapitals = dataset("us-state-capitals").path

p = @vlplot(width=800, height=500, projection={typ=:albersUsa}) +
@vlplot(
    data={
        url=us10m,
        format={
            typ=:topojson,
            feature=:states
        }
    },
    mark={
        :geoshape,
        fill=:lightgray,
        stroke=:white
    }
) +
(
    @vlplot(
        data={url=usstatecapitals},
        enc={
            longitude="lon:q",
            latitude="lat:q"
        }
    ) +
    @vlplot(mark={:circle, color=:orange}) +
    @vlplot(mark={:text, dy=-6}, text="city:n")
)
```

## Line drawn between airports in the U.S. simulating a flight itinerary

TODO

## Income in the U.S. by state, faceted over income brackets

TODO

## London Tube Lines

```@example
using VegaLite, VegaDatasets

@vlplot(
    width=700, height=500,
    config={
        view={
            stroke=:transparent
        }
    }
) +
@vlplot(
    data={
        url=dataset("londonBoroughs").path,
        format={
            typ=:topojson,
            feature=:boroughs
        }
    },
    mark={
        :geoshape,
        stroke=:white,
        strokeWidth=2
    },
    color={value="#eee"}
) +
@vlplot(
    data={
        url=dataset("londonCentroids").path,
        format={
            typ=:json
        }
    },
    transform=[{
        calculate="indexof (datum.name,' ') > 0  ? substring(datum.name,0,indexof(datum.name, ' ')) : datum.name",
        as=:bLabel
    }],
    mark=:text,
    longitude="cx:q",
    latitude="cy:q",
    text="bLabel:n",
    size={value=8},
    opacity={value=0.6}
) +
@vlplot(
    data={
        url=dataset("londonTubeLines").path,
        format={
            typ=:topojson,
            feature=:line
        }
    },
    mark={
        :geoshape,
        filled=false,
        strokeWidth=2
    },
    color={
        "id:n",
        legend={
            title=nothing,
            orient="bottom-right",
            offset=0
        },
        scale={
            domain=[
                "Bakerloo",
                "Central",
                "Circle",
                "District",
                "DLR",
                "Hammersmith & City",
                "Jubilee",
                "Metropolitan",
                "Northern",
                "Piccadilly",
                "Victoria",
                "Waterloo & City"
            ],
            range=[
                "rgb(137,78,36)",
                "rgb(220,36,30)",
                "rgb(255,206,0)",
                "rgb(1,114,41)",
                "rgb(0,175,173)",
                "rgb(215,153,175)",
                "rgb(106,114,120)",
                "rgb(114,17,84)",
                "rgb(0,0,0)",
                "rgb(0,24,168)",
                "rgb(0,160,226)",
                "rgb(106,187,170)"
            ]
        }
    }
)
```
