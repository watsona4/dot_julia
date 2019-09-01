using DarkSky
using Test
using Dates

if haskey(ENV, "DARKSKY_API_KEY")
    @info("Dark Sky API key was found in your system environment variables, running tests...")
    @test isa(forecast(42.3601, -71.0589), DarkSky.DarkSkyResponse)
    @test isa(forecast(42.3601, -71.0589, exclude=["currently"], extend="hourly"), DarkSky.DarkSkyResponse)
    response = forecast(42.3601, -71.0589, DateTime(2018, 3, 7, 0, 0, 0));
    @test isa(response, DarkSky.DarkSkyResponse)
    @test latitude(response) === 42.3601
    @test longitude(response) === -71.0589
    @test timezone(response) == "America/New_York"
    @test isa(currently(response), Dict{String, Any})
    @test isa(minutely(response), Nothing)
    @test isa(daily(response), Dict{String, Any})
    @test isa(alerts(response), Array{Any, 1}) | isa(alerts(response), Nothing)
    @test isa(flags(response), Dict{String, Any})
    @test isa(print(response), Nothing)
    dict_response = forecast(42.3601, -71.0589, DateTime(2018, 3, 7, 0, 0, 0), out_type="");
    @test Dict(response) == dict_response
    @test Dict(response) == convert(Dict, response)
    @test isa(forecast(42.3601, -71.0589, DateTime(2018, 1, 1, 0, 0, 0), lang="es", units="si", exclude=["minutely"]), DarkSky.DarkSkyResponse)
else
    @warn "Dark Sky API key was not found in your system environment variables, skipping tests..."
end
