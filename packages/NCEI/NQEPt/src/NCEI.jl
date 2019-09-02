"""
    NCEI

The `NCEI` module provides an interface to the National Centers of Environmental
Information API. The Climate Data Online API is fully supported.

Please see the documentation for more information.
"""
module NCEI

using Dates: Day, Date, DateTime, TimeType, today, Year
using DataFrames: DataFrame
using HTTP: request
using LazyJSON: value
using LazyJSON.PropertyDicts: get

import Base: parse

foreach(include, ["Endpoint.jl", "API.jl"])

export
    Date,
    DateTime,
    cdo_datasets,
    cdo_datacategories,
    cdo_datatypes,
    cdo_locationcategories,
    cdo_locations,
    cdo_stations,
    cdo_data
end
