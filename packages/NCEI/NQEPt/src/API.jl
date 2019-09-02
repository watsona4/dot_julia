# Data
"""
    cdo_data(CDO_token::AbstractString, dataset::AbstractString, startdate::Date, enddate::Date;
             datatypes::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
             locations::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
             stations::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
             metric::Bool = true)

For obtaining a CDO_token: [Request Web Services Token](https://www.ncdc.noaa.gov/cdo-web/token)

For additional information visit the [NCDC's Climate Data Online (CDO) Web Services v2 Documentation](https://www.ncdc.noaa.gov/cdo-web/webservices/v2#data)
"""
function cdo_data(CDO_token::AbstractString, dataset::AbstractString,
                  startdate::TimeType, enddate::TimeType;
                  datatypes::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                  locations::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                  stations::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                  metric::Bool = true)
    isvalid_cdotoken(CDO_token) || throw(CDO_NonValidToken)
    isempty(datatypes) || isvalid_datatypes(datatypes) || throw(CDO_NonValidDataTypes)
    isempty(locations) || isvalid_locations(locations) || throw(CDO_NonValidLocations)
    isempty(stations) || isvalid_stations(stations) || throw(CDO_NonValidStations)
    parse(CDO_Data(CDO_token, dataset, startdate, enddate, datatypes, locations, stations, metric))
end

# Data Categories
"""
    cdo_datacategories(CDO_token::AbstractString, datacategory::AbstractString)
    cdo_datacategories(CDO_token::AbstractString;
                       datasets::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                       locations::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                       stations::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                       startdate::Date = Date(1, 1, 1),
                       enddate::Date = today())

For obtaining a CDO_token: [Request Web Services Token](https://www.ncdc.noaa.gov/cdo-web/token)

For additional information visit the [NCDC's Climate Data Online (CDO) Web Services v2 Documentation](https://www.ncdc.noaa.gov/cdo-web/webservices/v2#dataCategories)
"""
function cdo_datacategories(CDO_token::AbstractString, datacategory::AbstractString)
    isvalid_cdotoken(CDO_token) || throw(CDO_NonValidToken)
    output = parse(CDO_DataCategory(CDO_token, datacategory))
    isa(output, Exception) && throw(output)
    output
end
function cdo_datacategories(CDO_token::AbstractString;
                            datasets::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                            locations::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                            stations::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                            startdate::Date = Date(1, 1, 1),
                            enddate::Date = today())
    isvalid_cdotoken(CDO_token) || throw(CDO_NonValidToken)
    isempty(datasets) || isvalid_datatypes(datasets) || throw(CDO_NonValidDatasets)
    isempty(locations) || isvalid_locations(locations) || throw(CDO_NonValidLocations)
    isempty(stations) || isvalid_stations(stations) || throw(CDO_NonValidStations)
    parse(CDO_DataCategories(CDO_token, datasets, locations, stations, startdate, enddate))
end

# Datasets
"""
    cdo_datasets(CDO_token::AbstractString, dataset::AbstractString)
    cdo_datasets(CDO_token::AbstractString;
                datatypes::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                locations::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                stations::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                startdate::Date = Date(1, 1, 1),
                enddate::Date = today())

For obtaining a CDO_token: [Request Web Services Token](https://www.ncdc.noaa.gov/cdo-web/token)

For additional information visit the [NCDC's Climate Data Online (CDO) Web Services v2 Documentation](https://www.ncdc.noaa.gov/cdo-web/webservices/v2#datasets)
"""
function cdo_datasets(CDO_token::AbstractString, dataset::AbstractString)
    isvalid_cdotoken(CDO_token) || throw(CDO_NonValidToken)
    output = parse(CDO_Dataset(CDO_token, dataset))
    isa(output, Exception) && throw(output)
    output
end
function cdo_datasets(CDO_token::AbstractString;
                      datatypes::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                      locations::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                      stations::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                      startdate::Date = Date(1, 1, 1),
                      enddate::Date = today())
    isvalid_cdotoken(CDO_token) || throw(CDO_NonValidToken)
    isempty(datatypes) || isvalid_datatypes(datatypes) || throw(CDO_NonValidDataTypes)
    isempty(locations) || isvalid_locations(locations) || throw(CDO_NonValidLocations)
    isempty(stations) || isvalid_stations(stations) || throw(CDO_NonValidStations)
    parse(CDO_Datasets(CDO_token, datatypes, locations, stations, startdate, enddate))
end

# Data Types
"""
    cdo_datatypes(CDO_token::AbstractString, datatype::AbstractString)
    cdo_datatypes(CDO_token::AbstractString;
                  datasets::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                  datacategories::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                  locations::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                  stations::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                  startdate::Date = Date(1, 1, 1),
                  enddate::Date = today())

For obtaining a CDO_token: [Request Web Services Token](https://www.ncdc.noaa.gov/cdo-web/token)

For additional information visit the [NCDC's Climate Data Online (CDO) Web Services v2 Documentation](https://www.ncdc.noaa.gov/cdo-web/webservices/v2#dataTypes)
"""
function cdo_datatypes(CDO_token::AbstractString, datatype::AbstractString)
    isvalid_cdotoken(CDO_token) || throw(CDO_NonValidToken)
    output = parse(CDO_DataType(CDO_token, datatype))
    isa(output, Exception) && throw(output)
    output
end
function cdo_datatypes(CDO_token::AbstractString;
                       datasets::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                       datacategories::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                       locations::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                       stations::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                       startdate::Date = Date(1, 1, 1),
                       enddate::Date = today())
    isvalid_cdotoken(CDO_token) || throw(CDO_NonValidToken)
    isempty(datasets) || isvalid_datatypes(datasets) || throw(CDO_NonValidDatasets)
    isempty(datacategories) || isvalid_datacategories(datacategories) || throw(CDO_NonValidDataCategories)
    isempty(locations) || isvalid_locations(locations) || throw(CDO_NonValidLocations)
    isempty(stations) || isvalid_stations(stations) || throw(CDO_NonValidStations)
    parse(CDO_DataTypes(CDO_token, datasets, datacategories, locations, stations, startdate, enddate))
end

# Location Categories
"""
    cdo_locationcategories(CDO_token::AbstractString, locationcategory::AbstractString)
    cdo_locationcategories(CDO_token::AbstractString;
                           datasets::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                           startdate::Date = Date(1, 1, 1),
                           enddate::Date = today())

For obtaining a CDO_token: [Request Web Services Token](https://www.ncdc.noaa.gov/cdo-web/token)

For additional information visit the [NCDC's Climate Data Online (CDO) Web Services v2 Documentation](https://www.ncdc.noaa.gov/cdo-web/webservices/v2#locationCategories)
"""
function cdo_locationcategories(CDO_token::AbstractString, locationcategory::AbstractString)
    isvalid_cdotoken(CDO_token) || throw(CDO_NonValidToken)
    output = parse(CDO_LocationCategory(CDO_token, locationcategory))
    isa(output, Exception) && throw(output)
    output
end
function cdo_locationcategories(CDO_token::AbstractString;
                                datasets::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                                startdate::Date = Date(1, 1, 1),
                                enddate::Date = today())
    isvalid_cdotoken(CDO_token) || throw(CDO_NonValidToken)
    isempty(datasets) || isvalid_datatypes(datasets) || throw(CDO_NonValidDatasets)
    parse(CDO_LocationCategories(CDO_token, datasets, startdate, enddate))
end

# Locations
"""
    cdo_locations(CDO_token::AbstractString, location::AbstractString)
    cdo_locations(CDO_token::AbstractString;
                  datasets::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                  locationcategories::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                  datacategories::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                  startdate::Date = Date(1, 1, 1),
                  enddate::Date = today())

For obtaining a CDO_token: [Request Web Services Token](https://www.ncdc.noaa.gov/cdo-web/token)

For additional information visit the [NCDC's Climate Data Online (CDO) Web Services v2 Documentation](https://www.ncdc.noaa.gov/cdo-web/webservices/v2#locations)
"""
function cdo_locations(CDO_token::AbstractString, location::AbstractString)
    isvalid_cdotoken(CDO_token) || throw(CDO_NonValidToken)
    output = parse(CDO_Location(CDO_token, location))
    isa(output, Exception) && throw(output)
    output
end
function cdo_locations(CDO_token::AbstractString;
                       datasets::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                       locationcategories::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                       datacategories::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                       startdate::Date = Date(1, 1, 1),
                       enddate::Date = today())
    isvalid_cdotoken(CDO_token) || throw(CDO_NonValidToken)
    isempty(locationcategories) || isvalid_locationcategories(locationcategories) || throw(CDO_NonValidLocationCategories)
    parse(CDO_Locations(CDO_token, datasets, locationcategories, datacategories, startdate, enddate))
end

# Stations
"""
    cdo_stations(CDO_token::AbstractString, station::AbstractString)
    cdo_stations(CDO_token::AbstractString;
                 datasets::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                 locations::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                 datacategories::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                 datatypes::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                 extent::Union{AbstractVector{<:AbstractFloat}} = Vector{Float64}(),
                 startdate::Date = Date(1, 1, 1),
                 enddate::Date = today())

For obtaining a CDO_token: [Request Web Services Token](https://www.ncdc.noaa.gov/cdo-web/token)

For additional information visit the [NCDC's Climate Data Online (CDO) Web Services v2 Documentation](https://www.ncdc.noaa.gov/cdo-web/webservices/v2#stations)
"""
function cdo_stations(CDO_token::AbstractString, station::AbstractString)
    isvalid_cdotoken(CDO_token) || throw(CDO_NonValidToken)
    output = parse(CDO_Station(CDO_token, station))
    isa(output, Exception) && throw(output)
    output
end
function cdo_stations(CDO_token::AbstractString;
                      datasets::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                      locations::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                      datacategories::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                      datatypes::Union{AbstractString, AbstractVector{<:AbstractString}} = "",
                      extent::AbstractVector{<:AbstractFloat} = Vector{Float64}(),
                      startdate::Date = Date(1, 1, 1),
                      enddate::Date = today())
    isvalid_cdotoken(CDO_token) || throw(CDO_NonValidToken)
    isempty(datasets) || isvalid_datsets(datasets) || throw(CDO_NonValidDatasets)
    isempty(locations) || isvalid_locations(locations) || throw(CDO_NonValidLocations)
    isempty(datacategories) || isvalid_datacategories(datacategories) || throw(CDO_NonValidDataCategories)
    isempty(datatypes) || isvalid_datatypes(datatypes) || throw(CDO_NonValidDataTypes)
    isvalid_extent(extent) || throw(CDO_NonValidExtent)
    parse(CDO_Stations(CDO_token, datasets, locations, datacategories, datatypes, extent, startdate, enddate))
end
