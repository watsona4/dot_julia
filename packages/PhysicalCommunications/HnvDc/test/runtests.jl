using Test, PhysicalCommunications

testfiles = [ "prbs.jl", "eyediag.jl"]

for testfile in testfiles
	include(testfile)
end
