using Polyline
using Test

pointCurrent = Polyline.coordinate{Float64}(38.5, -120.2)
precision = 10. ^5

@testset "Round coordinates" begin
    pointRound::Polyline.coordinate = Polyline.coordinate{Float64}(pointCurrent.Lat * precision, pointCurrent.Lng * precision)
    roundValue = Polyline.roundCoordinate(pointRound)
    @test roundValue.Lat == 3850000 && roundValue.Lng == -12020000
end

@testset "Write polyline" begin
    @test isequal(Polyline.diffCoordinate(
                  Polyline.coordinate{Int64}(3850000, -12020000),
                  Polyline.coordinate{Int64}(0, 0)),
                  Polyline.coordinate{Int64}(3850000, -12020000))

    @test isequal(Polyline.leftShiftCoordinate(
                  Polyline.coordinate{Int64}(3850000, -12020000)),
                  Polyline.coordinate{Int64}(7700000, -24040000))

    @test isequal(Polyline.encodeToChar(7700000),
                  collect("_p~iF"))

    @test isequal(Polyline.encodeToChar(-24040000),
                  collect("~ps|U"))

    conv = Polyline.convertToChar(Polyline.coordinate{Int64}(7700000, -24040000))
    @test isequal(conv.Lat, collect("_p~iF"))
    @test isequal(conv.Lng, collect("~ps|U"))

    gps_coord = [[38.5 -120.2]; [40.7 -120.95]; [43.252 -126.453]]
    @test isequal(encodePolyline(gps_coord),
                  "_p~iF~ps|U_ulLnnqC_mqNvxq`@")
end
