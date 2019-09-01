using GeohashHilbert
using Random
using Test
using CSV

const GHH = GeohashHilbert
const ALL_BITS_PER_CHAR = [2, 4, 6]

randlat() = -90 + 180 * rand()
randlon() = -180 + 360 * rand()
randprec() = rand(1:10)

# converting between int/string and back should reproduce starting values
function test_int_str_conversion()
    for _ in 1:200 # 200 independent tests
        x = rand(0:50_000)
        bpc = rand([2,4,6])
        base = 2^bpc
        chars_needed = ceil(Int, log(base, x + 1))
        nchar = rand(chars_needed : (chars_needed + 5))
        x_str = GHH.int_to_str(x, nchar, bpc)
        @test length(x_str) == nchar
        x_prime = GHH.str_to_int(x_str, bpc)
        @test x == x_prime
    end
    return nothing
end

# converting between xy and integer should be lossless
function test_int_xy_conversion()
    # many independent random tests of normal behavior
    for _ in 1:1000
        k = rand(2:20)
        n = 2^k
        int = rand(0:(n^2 - 1))
        x, y = GHH.int_to_xy(int, n)
        int_prime = GHH.xy_to_int(x, y, n)
        @test int_prime == int
    end
    # test illegal input
    @test_throws DomainError GHH.int_to_xy(-1, 8) # t too small
    @test_throws DomainError GHH.int_to_xy(100, 8) # t too large
    return nothing
end

# For lat/lons which are centers of geohash cells, encoding then decoding
# should match input coordinates.
# We can find lat/lons which are centers of cells by encoding and then decoding
# random points.
function test_cell_centers_encode_decode(bits_per_char = 2)
    for _ in 1:50
        lon, lat = randlon(), randlat()
        prec = randprec()
        geohash = GHH.encode(lon, lat, prec, bits_per_char)
        cell_center = GHH.decode(geohash, bits_per_char)
        geohash2 = GHH.encode(cell_center..., prec, bits_per_char)
        @test geohash == geohash2
        cell_center2 = GHH.decode(geohash2, bits_per_char)
        @test cell_center2 == cell_center
    end
    return nothing
end

# Make sure we match Python geohash hilbert on encoding, particularly on edges
# and corners of cells.
function test_match_python_encode(bits_per_char = 2)
    # python_hashes.csv has columns lon, lat, prec, bpc [bits per char], geohash
    typedict = Dict(
        :lon => Float64,
        :lat => Float64,
        :prec => Int,
        :bpc => Int,
        :geohash => String
    )
    python_hashes = CSV.File(joinpath(@__DIR__, "python_hashes.csv"); types = typedict)
    for row in python_hashes
        julia_hash = GHH.encode(row.lon, row.lat, row.prec, row.bpc)
        @test julia_hash == row.geohash
    end
    return nothing
end

# Illegal arguments should raise exceptions.
# This is not an exhaustive list of all kinds of illegal args.
function test_illegal_arguments()
    @test_throws Exception GHH.int_to_str(5, 5, 3) # 3 illegal bits per char
    @test_throws Exception GHH.str_to_int("hey there", 2) # illegal characters
    @test_throws Exception GHH.str_to_int("0123123", 3) # illegal bits per char
    @test_throws DomainError encode(-200, 0, 4, 4) # illegal longitude
    @test_throws DomainError encode(0, 100, 4, 4) # illegal latitude
    @test_throws DomainError encode(0, 0, 0, 4) # illegal precision
    @test_throws DomainError encode(0, 0, 11, 6) # too much precision
    @test_throws Exception encode(0, 0, 2, -1) # illegal bits per char
    @test_throws DomainError GHH.int_to_xy(16, 4) # first argument is too large
    @test_throws DomainError GHH.find_quadrant(5, GHH.ULeft) # illegal quadrant
    @test_throws DomainError GHH.xy_to_int(5, 1, 4) # x too large
    @test_throws DomainError GHH.xy_to_int(2, 0, 4) # y too small
end

println("Greetings tester; your test will now begin.")
Random.seed!(47)
test_int_str_conversion()
test_int_xy_conversion()
for bpc in ALL_BITS_PER_CHAR
    test_cell_centers_encode_decode(bpc)
end
test_match_python_encode()
test_illegal_arguments()
println("Great job, you passed!")
