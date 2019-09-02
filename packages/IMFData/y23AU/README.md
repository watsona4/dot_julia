# IMFData

*A Julia interface for retrieving data from the International Monetary Fund (IMF).*

| **Repo Status** | **Build Status** | **Coverage** |
|:---------------:|:----------------:|:------------:|
|[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.][repo-img]][repo-url] | [![Travis][travis-img]][travis-url] [![AppVeyor][appveyor-img]][appveyor-url] | [![Coveralls][coveralls-img]][coveralls-url] [![codecov.io][codecov-img]][codecov-url] |

## Installation

```julia
    (v1.0) pkg> add https://github.com/stephenbnicar/IMFData.jl
```

## Usage

**Get a list of datasets accessible from the API:**

```julia
    get_imf_datasets()
```
> **Note:** While this function returns a list of all available datasets, currently the module only supports data requests from the International Financial Statistics (IFS) dataset.


**Get the list of parameters ("dimensions") for a dataset and their values:**

```julia
    get_imf_datastructure(database_id::String)
```

Example:
```julia
    julia> ifs_structure = get_imf_datastructure("IFS")
    Dict{String,Any} with 2 entries:
      "Parameter Names"  => 5×2 DataFrames.DataFrame
      "Parameter Values" => Dict Any → Any with 5 entries
```

**Retrieve data from the IFS dataset**
```julia
    get_ifs_data(area, indicator, frequency, startyear, endyear)
```
* `area` and `indicator` must be `String`s or `Array`s of `String`s (to request multiple series with one call).
* `frequency` is limited to annual ("A"), quarterly ("Q"), or monthly ("M").
* `startyear` and `endyear` must be `Int`s.

The function returns an `IfsSeries` object; the data (if available) is in the `series` field.

Example:
```julia
    julia> us_gdp = get_ifs_data("US", "NGDP_SA_XDC", "Q", 2015, 2016)
    IMF Data Series
    Database: IFS
    Area: US
    Indicator: NGDP_SA_XDC
    Description:
    Frequency: Q
    Time Period: 2015 to 2016
    Data: 8 x 2 DataFrame

    julia> us_gdp.series
    8×2 DataFrames.DataFrame
    │ Row │ date       │ value     │
    ├─────┼────────────┼───────────┤
    │ 1   │ 2015-03-01 │ 1.78747e7 │
    │ 2   │ 2015-06-01 │ 1.80932e7 │
    │ 3   │ 2015-09-01 │ 1.82277e7 │
    │ 4   │ 2015-12-01 │ 1.82872e7 │
    │ 5   │ 2016-03-01 │ 1.83252e7 │
    │ 6   │ 2016-06-01 │ 1.8538e7  │
    │ 7   │ 2016-09-01 │ 1.87291e7 │
    │ 8   │ 2016-12-01 │ 1.89055e7 │
```
With multiple requests:
```julia
    julia> us_ca_gdp = get_ifs_data(["US","CA"], "NGDP_SA_XDC", "Q", 2015, 2016)
    2-element Array{IMFData.IMFSeries,1}:
     IMF Data Series
    Database: IFS
    Area: US
    Indicator: NGDP_SA_XDC
    Description:
    Frequency: Q
    Time Period: 2015 to 2016
    Data: 8 x 2 DataFrame

     IMF Data Series
    Database: IFS
    Area: CA
    Indicator: NGDP_SA_XDC
    Description:
    Frequency: Q
    Time Period: 2015 to 2016
    Data: 8 x 2 DataFrame
```
## Disclaimer
IMFData.jl is not affiliated with, officially maintained, or otherwise supported by the International Monetary Fund.

[travis-img]: https://travis-ci.org/stephenbnicar/IMFData.jl.svg?branch=master
[travis-url]: https://travis-ci.org/stephenbnicar/IMFData.jl

[appveyor-img]: https://ci.appveyor.com/api/projects/status/x3qvtuuodo24pam3/branch/master?svg=true
[appveyor-url]: https://ci.appveyor.com/project/stephenbnicar/imfdata-jl/branch/master

[coveralls-img]: https://coveralls.io/repos/github/stephenbnicar/IMFData.jl/badge.svg?branch=master
[coveralls-url]: https://coveralls.io/github/stephenbnicar/IMFData.jl?branch=master

[codecov-img]: http://codecov.io/github/stephenbnicar/IMFData.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/stephenbnicar/IMFData.jl?branch=master

[repo-img]: http://www.repostatus.org/badges/latest/active.svg
[repo-url]: http://www.repostatus.org/#active
