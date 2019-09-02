# Walkthrough

- Set Up

After installing the package one can call it in a new session as any other package.
A good practice is to define the `cdo_token` one intends to use for that session.

```@example Tutorial
using NCEI
const cdo_token = ENV["cdo_token"]
# A token has form: r"[A-Za-z]{32}"
```

- Datasets

One should first inspect the datasets available to select the ones the appropriate ones.
Good information about a dataset is its ID which one needs to query data from that dataset,
the temporal coverage, and documentation that can be accessed through the uid.
For example, the daily summaries dataset (GHCND) has uid: C00861. The information for
this dataset can be accessed at: [https://data.nodc.noaa.gov/cgi-bin/iso?id=gov.noaa.ncdc:C00861](https://data.nodc.noaa.gov/cgi-bin/iso?id=gov.noaa.ncdc:C00861).

```@example Tutorial
# Fetch all available datasets
cdo_datasets(cdo_token)
```

```@example Tutorial
# Fetch all information about the GSOY dataset specifically
cdo_datasets(cdo_token, "GSOY")
```

```@example Tutorial
# Fetch all available datasets with the Temperature at the time of observation (TOBS) data type
cdo_datasets(cdo_token, datatypes = "TOBS")
```

```@example Tutorial
# Fetch all available datasets with data for a given set of stations
cdo_datasets(cdo_token, stations = "GHCND:USC00010008")
```

- Data Categories

The next step is to find the data categories one might need (e.g., temperature vs precipitation).

```@example Tutorial
# Fetch all available data categories
cdo_datacategories(cdo_token)
```

```@example Tutorial
# Fetch all information about the Annual Agricultural dataset specifically
cdo_datacategories(cdo_token, "ANNAGR")
```

```@example Tutorial
# Fetch data categories for a given set of locations
cdo_datacategories(cdo_token, locations = ["FIPS:37", "CITY:US390029"])
```

- Data Types

Now we can inspect which variables we want to query from what data set.

```@example Tutorial
# Fetch available data types
cdo_datatypes(cdo_token)
```

```@example Tutorial
# Fetch more information about the ACMH data type id
cdo_datatypes(cdo_token, "ACMH")
```

```@example Tutorial
# Fetch data types with the air temperature data category
cdo_datatypes(cdo_token, datacategories = "TEMP")
```

```@example Tutorial
# Fetch data types that support a given set of stations
cdo_datatypes(cdo_token, stations = ["COOP:310090", "COOP:310184", "COOP:310212"])
```

- Location Categories

We must identify the spatial constraints of the search and that can be accomplished
at various levels (e.g., State vs Zip code).

```@example Tutorial
# Fetch all available location categories
cdo_locationcategories(cdo_token)
```

```@example Tutorial
# Fetch more information about the climate region location category
cdo_locationcategories(cdo_token, "CLIM_REG")
```

```@example Tutorial
# Fetch available location categories that have data after 1970
cdo_locationcategories(cdo_token, startdate = Date(1970, 1, 1))
```

- Locations

Now select which locations are of interest.

```@example Tutorial
# Fetch available locations
cdo_locations(cdo_token)
```

```@example Tutorial
# Fetch more information about location id FIPS:37
cdo_locations(cdo_token, "FIPS:37")
```

```@example Tutorial
# Fetch available locations for the GHCND (Daily Summaries) dataset
cdo_locations(cdo_token, datasets = "GHCND")
```

```@example Tutorial
# Fetch all U.S. States
cdo_locations(cdo_token, locationcategories = "ST")
```

- Stations

Lastly, one can obtain the relevant stations and verify their spatial information,
temporal coverage, and data quality. To select from feasible weather stations one
can use packages such as `Distances.jl` to obtain the nearest acceptable weather station
to the desired location.

```@example Tutorial
# Fetch a list of stations that support a given set of data types
cdo_stations(cdo_token, datatypes = ["EMNT", "EMXT", "HTMN"])
```

```@example Tutorial
# Fetch all information about the Abbeville AL station specifically
cdo_stations(cdo_token, "COOP:010008")
```

```@example Tutorial
# Fetch all the stations in North Carolina, US (FIPS:37)
cdo_stations(cdo_token, locations = "FIPS:37")
```

- Data

The final step is to obtain the raw data itself. A few transformations are recommended
before proceeding with the analysis of the data (e.g., transforming the dataframe from
long to short and filling the missing records with missing values for those observations).
Read the documentation to interpret the various flags under the attributes column.

```@example Tutorial
# Fetch data from the GHCND dataset (Daily Summaries) for zip code 28801, May 1st of 2010
cdo_data(cdo_token, "GHCND", Date(2010, 5, 1), Date(2010, 5, 1), locations = "ZIP:28801")
```

```@example Tutorial
# Fetch data from the PRECIP_15 dataset (Precipitation 15 Minute) for COOP station 010008, for May of 2010 with metric units
cdo_data(cdo_token, "PRECIP_15", Date(2010, 5, 1), Date(2010, 5, 31), stations = "COOP:010008")
```

```@example Tutorial
# Fetch data from the GSOM dataset (Global Summary of the Month) for GHCND station USC00010008, for May of 2010 with standard units
cdo_data(cdo_token, "GSOM", Date(2010, 5, 1), Date(2010, 5, 31),
         stations = "GHCND:USC00010008", metric = false)
```
