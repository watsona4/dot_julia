#Test code
#-------------------------------------------------------------------------------

using MDDatasets
using Test


#==List available physics constants (informative)
===============================================================================#

println("\nList of available physics constants:")
println("TODO: move to separate unit")
sepline = "---------------------------------------------------------------------"
println(sepline)
MDDatasets.Physics.Constants._show()
println()


#==Input data
===============================================================================#
xingsall = CrossType(:all)
xingsrise = CrossType(:rise)
xingsfall = CrossType(:fall)

d1 = DataF1(1:10.0)
d2 = xshift(d1, 4.5) + 12
d3 = d1 + 12
d4 = DataF1(d1.x, d1.y[end:-1:1])
d9 = xshift(d1, 100)

#Required mostly to test cross function:
y = [0,0,0,0,1,-3,4,5,6,7,-10,-5,0,0,0,-5,-10,10,-3,1,-4,0,0,0,0,0,0]
d10=DataF1(collect(1:length(y)), y)


#==Basic Tests
===============================================================================#
@testset "Basic operations on DataF1" begin
	r1 = d1+d2
	r2 = d1+d3
	#r3 = d1+d4
	@test r1.x == [1.0, 2.0, 3.0, 4.0, 5.0, 5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0, 10.5, 11.5, 12.5, 13.5, 14.5]
	@test r1.y == [1.0, 2.0, 3.0, 4.0, 5.0, 18.5, 19.5, 20.5, 21.5, 22.5, 23.5, 24.5, 25.5, 26.5, 27.5, 18.0, 19.0, 20.0, 21.0, 22.0]
	@test r2.x == d1.x
	@test r2.y == [14.0, 16.0, 18.0, 20.0, 22.0, 24.0, 26.0, 28.0, 30.0, 32.0]
	@test length(d1) == 10
	@test length(d2) == 10
	@test length(d3) == 10
	@test length(r1) == 20 #Shifted x values.
	@test length(r2) == 10
end

@testset "Functionnality of clip()" begin
	_d1 = clip(d1, xmin=1, xmax=9)
	@test _d1.x == collect(1:9.0)
	@test _d1.y == _d1.x

	_d1 = clip(d1, xmin=2, xmax=5)
	@test _d1.x == collect(2:5.0)
	@test _d1.y == _d1.x

	_d1 = clip(d1, 3:10)
	@test _d1.x == collect(3:10.0)
	@test _d1.y == _d1.x

	_d1 = clip(d1, xmin=3)
	@test _d1.x == collect(3:d1.x[end])
	@test _d1.y == _d1.x

	_d1 = clip(d1, xmax=8.5)
	@test _d1.x == [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 8.5]
	@test _d1.y == _d1.x

	_d1 = clip(d1, xmin=1.5, xmax=5.5)
	@test _d1.x == [1.5, 2.0, 3.0, 4.0, 5.0, 5.5]
	@test _d1.y == _d1.x

	_d3 = clip(d3, xmin=1.5, xmax=5.5)
	@test _d3.x == [1.5, 2.0, 3.0, 4.0, 5.0, 5.5]
	@test _d3.y == [13.5, 14.0, 15.0, 16.0, 17.0, 17.5]
end

@testset "Functionnality of x/ycross()" begin
	rtol = 1e-4

	#Test ycross:
	_x = xcross(d10, allow=xingsall)
	@test _x.y ≈ [4.0, 5.25, 6.42857, 10.4118, 14.0, 17.5, 18.7692, 19.75, 20.2, 22.0] rtol=rtol
	@test _x.x == _x.y
	_x = xcross(d10)
	@test _x.y ≈ [5.25, 6.42857, 10.4118, 17.5, 18.7692, 19.75, 20.2] rtol=rtol
	@test _x.x == _x.y
	_x = xcross(d10, allow=xingsrise)
	@test _x.y ≈ [6.42857, 17.5, 19.75] rtol=rtol
	@test _x.x == _x.y
	_x = xcross(d10, allow=xingsfall)
	@test _x.y ≈ [5.25, 10.4118, 18.7692, 20.2] rtol=rtol
	@test _x.x == _x.y
	_x = xcross(d10-.5)
	@test _x.y ≈ [4.5, 5.125, 6.5, 10.3824, 17.525, 18.7308, 19.875, 20.1] rtol=rtol
	@test _x.x == _x.y

	#Test ycross:
	_x = ycross(d10, .5, allow=xingsall)
	@test _x.x ≈ [4.5, 5.125, 6.5, 10.3824, 17.525, 18.7308, 19.875, 20.1] rtol=rtol
	@test _x.y ≈ zeros(length(_x.y)) .+ 0.5 rtol=rtol
	_x2 = ycross(d10, .5)
	@test _x.x ≈ _x2.x rtol=rtol
	@test _x.y ≈ _x2.y rtol=rtol
	_x = ycross(d10, .5, allow=xingsrise)
	@test _x.x ≈ [4.5, 6.5, 17.525, 19.875] rtol=rtol
	@test _x.y ≈ zeros(length(_x.y)) .+ 0.5 rtol=rtol
	_x = ycross(d10, .5, allow=xingsfall)
	@test _x.x ≈ [5.125, 10.3824, 18.7308, 20.1] rtol=rtol
	@test _x.y ≈ zeros(length(_x.y)) .+ 0.5 rtol=rtol

	#Test xcross1/ycross1:
	@test xcross1(d10, n=1) == 5.25
	@test xcross1(d10-.5, n=2) == 5.125
	@test ycross1(d10, .5, n=3) ≈ 0.5 rtol=rtol
end

@testset "Functionnality of meas() interface" begin
	_xref = xcross(d10, allow=xingsrise)
	_x = meas(:xcross, d10, allow=xingsrise)
	@test _x.x == _xref.x
	@test _x.y == _xref.y

	_x = meas(:xcross, Event, d10, allow=xingsrise)
	@test _x.x == collect(1:length(_x.x))
	@test _x.y == _xref.y
end

@testset "Functionnality value()" begin
	for i in 1:length(d3)
		@test d3.y[i] == value(d3, x=d3.x[i])
	end
end

@testset "Functionnality of ensure()" begin
	function fail_to_ensure()
		@warn("TODO: fix bad ensure-do syntax - sounds like body should execute when predicate is true")

		#Test ensure-do syntax:
		ensure(false) do
			#Allows user to build a more complex error object...
			ArgumentError("Predicate is false.")
		end
		return
	end

	#Simple syntax:
	@test ensure(true, "No error") == nothing
	@test_throws SystemError ensure(false, SystemError("Some system error"))
	@test_throws ArgumentError fail_to_ensure()
end


#==DataHR/DataRS Tests
===============================================================================#
include("runtests_datahr.jl")
include("runtests_datars.jl")

:Test_Complete
