#Test code
#-------------------------------------------------------------------------------

using PSFWrite
using LibPSF #To test validity
using Test


#==Input data
===============================================================================#
filepath = "testfile.psf"
freq = 1e9
t = collect(0:.01e-9:10e-9)
y1 = sin.(t*(2π*freq))
y2 = cos.(t*(2π*freq))


#==Tests
===============================================================================#
@testset "Writing time-domain data to PSF file" begin
	@info("Writing out data with PSFWrite...")
	data = PSFWrite.dataset(t, "time")
	push!(data, y1, "y1")
	push!(data, y2, "y2")

	PSFWrite._open(filepath) do writer
		write(writer, data)
	end

	@info("Reading data back in with LibPSF...")
	reader = LibPSF._open(filepath)
	#display(reader.props)

	_t = readsweep(reader)
	#_t[3] = 2 * _t[3] #Inject error
	@test _t == t
	_y1 = read(reader, "y1")
	@test _y1 == y1
	_y2 = read(reader, "y2")
	@test _y2 == y2
	close(reader)
end

:Test_Complete
