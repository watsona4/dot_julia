using CALCEPH
using Test


CALCEPH.disableCustomHandler()
CALCEPH.setCustomHandler(s::String->Nothing )
testpath = joinpath(dirname(pathof(CALCEPH)), "..", "test")

# NAIF ID tests

for (name,id) ∈ naifId.id
    @test name ∈ naifId.names[id]
end

for (id,names) ∈ naifId.names
    for name ∈ names
       @test naifId.id[name] == id
   end
end

@test naifId.id[:ssb] == naifId.id[:solar_system_barycenter] == 0
@test naifId.id[:sun] == 10
@test naifId.id[:mercury_barycenter] == 1
@test naifId.id[:mercury] == 199
@test naifId.id[:venus_barycenter] == 2
@test naifId.id[:venus] == 299
@test naifId.id[:emb] == naifId.id[:earth_barycenter] == 3
@test naifId.id[:moon] == 301
@test naifId.id[:earth] == 399
@test naifId.id[:mars_barycenter] == 4
@test naifId.id[:phobos] == 401
@test naifId.id[:deimos] == 402
@test naifId.id[:mars] == 499
@test naifId.id[:jupiter_barycenter] == 5
@test naifId.id[:io] == 501
@test naifId.id[:europa] == 502
@test naifId.id[:ganymede] == 503
@test naifId.id[:callisto] == 504
@test naifId.id[:jupiter] == 599
@test naifId.id[:saturn_barycenter] == 6
@test naifId.id[:titan] == 606
@test naifId.id[:saturn] == 699
@test naifId.id[:uranus_barycenter] == 7
@test naifId.id[:uranus] == 799
@test naifId.id[:neptune_barycenter] == 8
@test naifId.id[:triton] == 801
@test naifId.id[:neptune] == 899
@test naifId.id[:pluto_barycenter] == 9
@test naifId.id[:charon] == 901
@test naifId.id[:pluto] == 999

# test error case: changing name->id mapping
@test_throws CALCEPHException CALCEPH.add!(naifId,:jupiter,1)
# test error case: parsing wrongly formatted body id input file
bid = CALCEPH.BodyId()
@test_throws CALCEPHException CALCEPH.loadData!(bid,joinpath(testpath,"badIds.txt"))

# check memory management
eph1 = Ephem(joinpath(testpath,"example1.dat"))
eph2 = Ephem([joinpath(testpath,"example1.bsp"),
                     joinpath(testpath,"example1.tpc")])


@test eph1.data != C_NULL
finalize(eph1)
@test eph1.data == C_NULL

@test eph2.data != C_NULL
finalize(eph2)
@test eph2.data == C_NULL
finalize(eph2)
CALCEPH._ephemDestructor(eph2)

# Opening invalid ephemeris
@test_throws CALCEPHException Ephem(String[])

# check constants
eph1 = Ephem(joinpath(testpath,"example1.dat"))
eph2 = Ephem([joinpath(testpath,"example1.bsp"),
                     joinpath(testpath,"example1.tpc")])
eph3 = Ephem([joinpath(testpath,"checktpc_11627.tpc")])
eph4 = Ephem([joinpath(testpath,"checktpc_str.tpc")])
con1 = constants(eph1)
con2 = constants(eph2)
con3 = constants(eph3)
con4 = constants(eph4)

@test isa(con1,Dict{Symbol,Any})
@test length(con1) == 402
@test con1[:EMRAT] ≈ 81.30056
@test isa(con2,Dict{Symbol,Any})
@test length(con2) == 313
@test con2[:AU] ≈ 1.49597870696268e8
@test isa(con3,Dict{Symbol,Any})
@test length(con3) == 3
@test con3[:BODY000_GMLIST4] == [ 199.0 ; 299.0 ; 301.0 ; 399.0 ]
@test con3[:BODY000_GMLIST2] == [ 499 ; 599 ]
@test con3[:BODY000_GMLIST1] == 699
@test isa(con4,Dict{Symbol,Any})
@test length(con4) == 4
@test con4[:MESSAGE] == "You can't always get what you want."
@test con4[:DISTANCE_UNITS] == "KILOMETERS"
@test con4[:MISSION_UNITS] == [ "KILOMETERS" ; "SECONDS" ; "KILOMETERS/SECOND" ]
@test con4[:CONTINUED_STRINGS] == ["This //", "is //", "just //", "one long //", "string.", "Here's a second //", "continued //", "string."]

# Retrieving constants from closed ephemeris
finalize(eph2)
@test_throws CALCEPHException constants(eph2)

# test compute*
# test data and thresholds from CALCEPH C library tests
inpop_files = [joinpath(testpath,"example1.dat")]
spk_files = [joinpath(testpath,"example1.bsp"),
             joinpath(testpath,"example1.tpc"),
             joinpath(testpath,"example1.tf"),
             joinpath(testpath,"example1.bpc"),
             joinpath(testpath,"example1spk_time.bsp")]

testfile = joinpath(testpath,"example1_tests.dat")

test_data = [
    (inpop_files,false),
    (spk_files,false),
    (inpop_files,true),
    (spk_files,true)
]

include("testfunction1.jl")

for (ephFiles,prefetch) in test_data
    testFunction1(testfile,ephFiles,prefetch)
end

testfile2 = joinpath(testpath,"example1_tests_naifid.dat")

include("testfunction2.jl")

for (ephFiles,prefetch) in test_data
    testFunction2(testfile,testfile2,ephFiles,prefetch)
end

# test error case wrong order
eph1 = Ephem(joinpath(testpath,"example1.bsp"))
@test_throws CALCEPHException compute(eph1,0.0,0.0,1,0,0,4)
@test_throws CALCEPHException compute(eph1,0.0,0.0,1,0,0,-1)

# test error case:
@test_throws CALCEPHException compute(eph1,0.0,0.0,-144,0,0)


# Five-Point Stencil

f(x)=x^8
@test_throws ErrorException CALCEPH.fivePointStencil(f,1.5,5,0.001)
@test_throws ErrorException CALCEPH.fivePointStencil(f,1.5,-1,0.001)
@test_throws ErrorException CALCEPH.fivePointStencil(f,1.5,4,0.0)
val = CALCEPH.fivePointStencil(f,1.5,4,0.001)
ref = [25.62890625,136.6875,637.875,2551.5,8505.0]
@test ref[1] ≈ val[1] atol=1e-10
@test ref[2] ≈ val[2] atol=1e-8
@test ref[3] ≈ val[3] atol=1e-5
@test ref[4] ≈ val[4] atol=1e-2
@test ref[5] ≈ val[5] atol=1e-2


# introspection
eph = Ephem(inpop_files)
@test timeScale(eph) == 1

records = positionRecords(eph)
@test length(records) == 12

records = orientationRecords(eph)
@test length(records) == 1

@test timespan(eph) == (2.442457e6, 2.451545e6, 1)


# rotangmom
eph = Ephem(joinpath(testpath,"example2_rotangmom.dat"))
a = rotAngMom(eph,2.4515e6,0.0,399,useNaifId+unitSec)
b = rotAngMom(eph,2.4515e6,0.0,399,useNaifId+unitSec,1)
@test a == b
@test length(a) == 6
