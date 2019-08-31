using BritishNationalGrid
using Test

const BNG = BritishNationalGrid

bngp_type(::BNGPoint{T}) where {T} = T

function check_bng_to_lonlat(easting, northing, lon, lat, tol)
    p = BNGPoint(easting, northing)
    plon, plat = lonlat(p)
    isapprox(plon, lon, atol=tol) && isapprox(plat, lat, atol=tol)
end
function check_lonlat_to_bng(lon, lat, easting, northing, tol)
    p = BNGPoint(lon=lon, lat=lat)
    isapprox(easting, p.e, atol=tol) && isapprox(northing, p.n, atol=tol)
end

## Construction
@testset "Construction" begin
    @test BNGPoint(500_000., 1_000_000).e == 500_000.
    @test BNGPoint(500_000., 1_000_000).n == 1_000_000.
    @test bngp_type(BNGPoint(0, 0)) == Int
    @test bngp_type(BNGPoint(0, Float64(0))) == Float64
    # Outside grid
    @test_throws ArgumentError BNGPoint(0, 1_300_001)
    @test_throws ArgumentError BNGPoint(700_001, 0)
    @test_throws ArgumentError BNGPoint(0, -1)
    @test_throws ArgumentError BNGPoint(-1, 0.)
    # Incorrect type
    @test_throws MethodError BNGPoint(1im, 1)
    # With squares
    @test_throws ArgumentError BNGPoint(0, 100_001, "SV")
    @test_throws ArgumentError BNGPoint(-1, 0, "SV")
    @test_throws ArgumentError BNGPoint(0, 0, "ZZ")
    @test BNGPoint(0, 0, "SV").e == 0
    @test BNGPoint(0, 0, "SV").n == 0
    @test BNGPoint(0, 0, "TV") == BNGPoint(500_000, 0)
    @test BNGPoint(1000, 1000, "TV") == BNGPoint(501_000, 1000)
end

## Conversion lonlat ↔ BNG
const lonlattol = 1e-6
const gridtol = 1 # Because the online calculator rounds of course

# Points taken from BGS converter at:
#   http://www.bgs.ac.uk/data/webservices/convertForm.cfm
@testset "Conversion" begin
    @test check_bng_to_lonlat(429157, 623009, -1.54000791003, 55.4999996103, lonlattol)
    @test check_bng_to_lonlat(0, 0, -7.55716018087, 49.766807227, lonlattol)
    @test check_lonlat_to_bng(-1.54000791003, 55.4999996103, 429157, 623009, gridtol)
    @test check_lonlat_to_bng(0, 60, 511648, 1125592, gridtol)
end


## Square identification
@testset "Square ID" begin
    @test BNG.SQUARE_NAMES[1,1] == "SV"
    @test BNG.SQUARE_NAMES[end,end] == "JM"
    @test square(BNGPoint(429157, 623009)) == "NU"
end


## Grid reference formatting
@testset "Gridref format" begin
    @test_throws ArgumentError gridref(BNGPoint(0, 0), 1)
    @test_throws ArgumentError gridref(BNGPoint(0, 0), 0)
    @test_throws ArgumentError gridref(BNGPoint(0, 0), 12, true)
    @test_throws ArgumentError gridref(BNGPoint(0, 0), 14)
    @test gridref(BNGPoint(429157, 623009), 8, true) == "NU 2915 2300"
    @test gridref(BNGPoint(429157, 623009)) == "4291 6230"
    @test gridref(BNGPoint(429157, 623009), 2) == "4 6"
    @test gridref(BNGPoint(429157, 623009), 2, true) == "NU 2 2"
    @test gridref(BNGPoint(429157, 623009), 4) == "42 62"
    @test gridref(BNGPoint(429157, 623009), 4, true) == "NU 29 23"
    @test gridref(BNGPoint(429157, 623009), 10, true, "") == "NU2915723009"
    @test gridref(BNGPoint(429157, 623009), 10, true, "_∘") == "NU_∘29157_∘23009"
end
