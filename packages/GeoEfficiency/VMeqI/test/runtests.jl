#
# Correctness Tests
#

using Compat, Compat.Test , Compat.DelimitedFiles, Compat.MathConstants
using Compat: @error, @debug, @warn, @info, stdin
using GeoEfficiency
const G = GeoEfficiency
#logging(IOBuffer(), G)


include("Helper.jl")

const SourceFiles = [
					"Helper",
					"Error",
					"Input_Console",
					"Physics_Model",
					"Input_Batch",
    				"Calculations",
					"Output_Interface"
					]

@testset "GeoEfficiency" begin
	@test G.srcType === G.srcUnknown  		# the initial program condition
	@test typeofSrc() === G.srcUnknown  	# the initial program condition
	@test setSrcToPoint() === false      	# not defined, set to not point
	println("\n")
	
	@testset "$SourceFile" for SourceFile = SourceFiles
		@debug("Begin test", SourceFile)   
		include("test_$SourceFile.jl")
		println("\n")
	end #testset_SourceFile

	@test about() == nothing

end #testset_GeoEfficiency
