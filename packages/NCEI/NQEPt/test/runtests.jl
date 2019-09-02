using NCEI
using Test: @test, @test_throws, @testset

const cdo_token = "ijrAfEVJJAefHdruUsTkjRyWLqSZpBhY" # Dedicated CDO token for testing

@testset "Testing NCEI" begin
    @testset "Endpoint: Data Categories" begin
    all_datacategories = cdo_datacategories(cdo_token)
    @test size(all_datacategories) == (42, 2)
    one_data_category = cdo_datacategories(cdo_token, "ANNAGR")
    @test size(one_data_category) == (1, 2)
    datacategory_location = cdo_datacategories(cdo_token, locations = "CITY:US390029")
    @test size(datacategory_location) == (38, 2)
    @test_throws ArgumentError("N7 is not a valid data category. For a complete list of valid data categories run `cdo_datacategories(CDO_token::AbstractString)`.") cdo_datacategories(cdo_token, "N7")
    end
    @testset "Endpoint: Datasets" begin
        all_datasets = cdo_datasets(cdo_token)
        @test size(all_datasets) == (11, 6)
        one_dataset = cdo_datasets(cdo_token, "GSOY")
        @test size(one_dataset) == (1, 5)
        one_datatype = cdo_datasets(cdo_token, datatypes = "TOBS")
        @test size(one_datatype) == (1, 6)
        station = cdo_datasets(cdo_token, stations = "GHCND:USC00010008")
        @test size(station) == (6, 6)
        @test_throws ArgumentError("N7 is not a valid dataset. For a complete list of valid datasets run `cdo_datasets(CDO_token::AbstractString)`.") cdo_datasets(cdo_token, "N7")
    end
    @testset "Endpoint: Data Types" begin
        all_datatypes = cdo_datatypes(cdo_token)
        @test size(all_datatypes) == (1527, 5)
        one_datatype = cdo_datatypes(cdo_token, "ACMH")
        @test size(one_datatype) == (1, 4)
        datacategory = cdo_datatypes(cdo_token, datacategories = "TEMP")
        @test size(datacategory) == (59, 5)
        datacategories = cdo_datatypes(cdo_token,
                                       stations = ["COOP:310090", "COOP:310184", "COOP:310212"])
        @test size(datacategories) == (21, 5)
        @test_throws ArgumentError("N7 is not a valid data type. For a complete list of valid data types run `cdo_datatypes(CDO_token::AbstractString)`.") cdo_datatypes(cdo_token, "N7")
    end
    @testset "Endpoint: Location Categories" begin
        all_locationcategories = cdo_locationcategories(cdo_token)
        @test size(all_locationcategories) == (12, 2)
        one_locationcategory = cdo_locationcategories(cdo_token, "CLIM_REG")
        @test size(one_locationcategory) == (1, 2)
        @test_throws ArgumentError("N7 is not a valid location category. For a complete list of valid location categories run `cdo_locationcategories(CDO_token::AbstractString)`.") cdo_locationcategories(cdo_token, "N7")
    end
    @testset "Endpoint: Locations" begin
        all_locations = cdo_locations(cdo_token,
                                      datasets = "GHCND",
                                      locationcategories = "ST")
        @test size(all_locations) == (51, 5)
        one_location = cdo_locations(cdo_token, "FIPS:37")
        @test size(one_location) == (1, 5)
        @test_throws ArgumentError("N7 is not a valid location. For a complete list of valid locations run `cdo_locations(CDO_token::AbstractString)`.") cdo_locations(cdo_token, "N7")
    end
    @testset "Endpoint: Stations" begin
        station = cdo_stations(cdo_token, "COOP:010008")
        @test size(station) == (1, 9)
        location = cdo_stations(cdo_token,
                                locations = "FIPS:37",
                                startdate = Date(2000, 1, 1),
                                enddate = Date(2000, 1, 1))
        @test size(location) == (417, 9)
        @test_throws ArgumentError("N7 is not a valid weather station. For a complete list of valid stations run `cdo_stations(CDO_token::AbstractString)`.") cdo_stations(cdo_token, "N7")
    end
    @testset "Endpoint: Data" begin
        GHCND = cdo_data(cdo_token,
                         "GHCND",
                         Date(2010, 5, 1),
                         Date(2010, 5, 1),
                         locations = "ZIP:28801")
        @test size(GHCND) == (8, 5)
        station = cdo_data(cdo_token,
                           "PRECIP_15",
                           Date(2010, 5, 1),
                           Date(2010, 5, 31),
                           stations = "COOP:010008")
        @test size(station) == (63, 5)
        GSOM = cdo_data(cdo_token,
                        "GSOM",
                        Date(2010, 5, 1),
                        Date(2010, 5, 31),
                        stations = "GHCND:USC00010008")
        @test size(GSOM) == (10, 5)
        Yearly = cdo_data(cdo_token,
                          "GHCND",
                          Date(2000, 1, 1),
                          Date(2002, 12, 31),
                          datatypes = "TAVG",
                          locations = "ZIP:91711")
        @test size(Yearly) == (1093, 5)
        Decade = cdo_data(cdo_token,
                          "GSOY",
                          Date(1990, 1, 1),
                          Date(2001, 12, 31),
                          datatypes = "TAVG",
                          locations = "ZIP:91711")
        @test size(Decade) == (3, 5)
    end
    @testset "Are these valid arguments?" begin
        @test_throws ArgumentError cdo_datacategories(cdo_token, locations = "California")
        @test_throws ArgumentError cdo_datasets(cdo_token, stations = "USC00010008")
        @test_throws ArgumentError cdo_datatypes(cdo_token, datacategories = "temp")
    end
end
