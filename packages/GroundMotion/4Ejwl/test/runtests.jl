using Test, DelimitedFiles, GroundMotion

# constants
TEST_GRID_SIZE = 17
WITH_MINPGA = 8
SIMULATION_ARRAY_SIZE = 1000
# load vs30 grid
grid = read_vs30_file("testvs30.txt")
raw_grid = readdlm("testvs30.txt")
grid_dl = read_vs30_dl_file("testvs30dl.txt")
grid_epicenter = [Point_vs30(143.04,51.92,350)]
# set earthquake location
eq_4 = Earthquake(143.04,51.92,13,4)
eq_6 = Earthquake(143.04,51.92,13,6)
eq_7 = Earthquake(143.04,51.92,13,7)
eq_85 = Earthquake(143.04,51.92,13,8.5)

## Auxilary finctions tests
include("test_auxiliary.jl")

## AS2008 GMPE tests
include("test_as2008.jl")

## Si-Midorikawa 1999 GMPE tests
include("test_simidorikawa1999.jl")

## Morikawa-Fujiwara 2013 GMPE tests
include("test_morikawafujiwara2013.jl")
