#Test DataHR manipulations
#-------------------------------------------------------------------------------

using MDDatasets
using Test


#==Input data
===============================================================================#
#Sample DataF1 leaf dataset:
d1 = DataF1([1,2,3], [4,5,6])
sweeplist1 = PSweep[
	PSweep("v1", [1,2])
	PSweep("v2", [4,5])
]
sweeplist2 = PSweep[ #2nd sweep is different variable than sweeplist1
	PSweep("v1", [1,2])
	PSweep("v4", [4,5])
]
sweeplist3 = PSweep[ #Points of 2nd sweep are different than sweeplist1
	PSweep("v1", [1,2])
	PSweep("v2", [3,4])
]

dhr1 = DataHR(sweeplist1,DataF1[d1 d1; d1 d1])
dhr2 = DataHR(sweeplist2,DataF1[d1 d1; d1 d1])
dhr3 = DataHR(sweeplist3,DataF1[d1 d1; d1 d1])


#==Tests
===============================================================================#
@testset "Broadcast operations on DataHR" begin
	s1 = dhr1 + dhr1
	@testset "Validate s1 = dhr1+dhr2" begin
		for (es1, e1) in zip(s1.elem, dhr1.elem)
			@test es1.x == e1.x
			@test es1.y == (e1.y .+ e1.y)
		end
	end
	@test_throws ArgumentError dhr1+dhr2 #Mismatched sweeps
	@test_throws ArgumentError dhr1+dhr3 #Mismatched sweeps
end

@testset "DataHR => DataRS conversion" begin
	drs1 = DataRS(dhr1)

	#Verify that the sweeps match:
	@test drs1.sweep == dhr1.sweeps[1]
	@test drs1.elem[1].sweep == dhr1.sweeps[2]
	@test drs1.elem[2].sweep == dhr1.sweeps[2]

	#Verify that each element of the two data structures match:
	a = dhr1.sweeps
	for i in 1:length(a[1]), j in 1:length(a[2])
		_drs = drs1.elem[i].elem[j]; _dhr = dhr1.elem[i,j]
		@test _drs.x == _dhr.x
		@test _drs.y == _dhr.y
	end
end

:Test_Complete
