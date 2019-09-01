using GoogleMaps
using Dates
using Test

if haskey(ENV, "GOOGLE_MAPS_KEY")

    @testset "Geocode" begin
        response = geocode("1600+Amphitheatre+Parkway,+Mountain+View,+CA")
        @test response["status"] == "OK"
        @test response["results"][1]["formatted_address"] == "1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA"
        @test response["results"][1]["geometry"]["location"] == Dict{String,Any}("lat" => 37.4226128, "lng" => -122.0854158)
    end

    @testset "Timezone" begin
        location = (37.4226128, -122.0854158)
        timestamp = DateTime("2018-10-30T21:50:31.673")
        response = timezone(location, timestamp)
        @test response["status"] == "OK"
        @test response["timeZoneId"] == "America/Los_Angeles"
    end

else
    @info "Google Maps API key was not found in environment variables, skipping tests..."
end
