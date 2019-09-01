#**************************************************************************************
# test_Output_Interface.jl
# ======================== part of the GeoEfficiency.jl package.
# 
# 
# 
#**************************************************************************************

using Compat
using Compat: occursin, @error


@testset "GeoEfficiecny.checkResultsDirs" begin 
	@test G.checkResultsDirs() == nothing
end #testset_checkResultsDirs


@debug("max_batch")
@testset "max_batch" begin
	@test max_batch(-1) 	== G._max_batch
	@test max_batch(100) 	== G._max_batch
	@test max_batch() 		== G.max_display
end


@debug("calc - CylDetector, WellDetector")
let pnt::Point = Point(1),
	cylDet::CylDetector = Detector(5, 10),
	wellDet::WellDetector = Detector(5, 4, 3.2, 2)
	
	@testset "calc - CylDetector, WellDetector" for 
	SrcRadius = Real[1, 1//2, e, pi, 1.0], 
	SrcLength = Real[1, 1//2, e, pi, 1.0]

		@test calc(cylDet,  (pnt, SrcRadius , SrcLength))    == nothing
		@test calc(wellDet, (pnt, SrcRadius , SrcLength))    == nothing
	
		@test_throws 	G.NotImplementedError  	H.@console(calc(cylDet), 0, 15, 0)
		@test_throws 	G.InValidGeometry  		H.@console(calc(cylDet), -1, 0, 0)
	end #testset_calc
end #let


@debug("calcN")
@testset "calcN - $consol_input" for 
consol_input = ["4 0 1 2 Q", 
				"4 0 1 3 " * "d " * "4 0 1 4 Q", 
				"4 0 1 5 " * "n " * "11 6 0 " * "4 0 1 6 Q"]

	@test H.exec_console_unattended(calcN, consol_input, Fn_ARGs =[Detector(5, 10)])  == nothing
	@test H.exec_console_unattended(calcN,  consol_input, Fn_ARGs =[Detector(eps())])  == nothing
	@test H.exec_console_unattended(calcN, "13 7 0 " * consol_input)      == nothing
	@test H.exec_console_unattended(calcN, "13 7 0 Q " * consol_input)      == nothing
	#@test H.exec_consol_unattended(calcN, "-13 -7 0 Q " * consol_input)      == nothing
end #testset_calcN



@debug("writecsv_head")    
@testset "writecsv_head" begin
	# `writecsv_head` tests in the `reading_from _CSV` testset in test_Output_Interface.
end #testset_writecsv_head


@debug("GeoEfficiecny._batch")
@testset "_batch, point is $isSrcPoint" for	isSrcPoint = [true, false]

	rtrn = G._batch(Val(isSrcPoint),  CylDetector(eps(0.1)), [0.0], [0.0], [0.0], [0.0])
	@test typeof(rtrn) <: Tuple{Detector, Matrix{Float64}, String}
	@test rtrn[2][end] ≈ 0.5
	rm(rtrn[end]; force=true)

	rtrn = G._batch(Val(isSrcPoint), CylDetector(eps(0.1)), [0.0], [1.0], [0.0],[0.0])
	@test typeof(rtrn) <: Tuple{Detector, Matrix{Float64}, String}
	@test rtrn[2][end] |> isnan
	rm(rtrn[end]; force=true)

end #testset_GeoEfficiecny._batch


@debug("batch")    
@testset "batch" begin

local paths::Vector{String} = String[]
local every_path::Vector{String} = String[]
max_batch(-1)		# display the batch calculation results on the console

	@testset "batch(<:Detector)" begin
		acylDetector1::CylDetector = CylDetector(eps(0.1))

		path::String = batch(acylDetector1, [0.0])
		@test occursin( G.id(acylDetector1), path)
		@test readdlm(path,',')[2,end] ≈ 0.5
		push!(every_path, path)

		path = batch(acylDetector1, [0.0], [0.0], [0.0],[0.0],false)
		@test occursin(G.id(acylDetector1), path)
		@test readdlm(path,',')[2,end] ≈ 0.5
		push!(every_path, path)
	end #testset_batch(<:Detector)

max_batch(Inf)		# prevent the display of batch calculation results on the console
	let acylDetector2::CylDetector = CylDetector(eps(0.2))
	
		paths = batch([acylDetector2], [0.0]) # in fact `paths` is a one element vector
		@test occursin.(G.id(acylDetector2), paths) |> any
		append!(every_path, paths)

		paths = batch([acylDetector2], [0.0], [0.0], [0.0],[0.0],false)
		@test occursin.(G.id(acylDetector2), paths) |> any
		append!(every_path, paths)
	end #let

	let aBDetector = BoreDetector(eps(0.5), eps(0.4), eps(0.2))
	
		paths = batch([aBDetector], [0.0])
		@test occursin.(G.id(aBDetector), paths) |> any
		append!(every_path, paths)
	end #let

	let aWDetector = WellDetector(eps(0.5), eps(0.4), eps(0.2), eps(0.1))

		paths = batch([aWDetector], [0.0])
		@test occursin.(G.id(aWDetector), paths) |> any
		append!(every_path, paths)

		paths = batch([aWDetector], [0.0], [0.0], [0.0],[0.0],false)
		@test occursin.(G.id(aWDetector), paths) |> any
		append!(every_path, paths)
	end #let

	let acylDetector3::CylDetector 	= CylDetector(eps(0.3)),
		aBDetector::BoreDetector	= BoreDetector(6, eps(), eps(0.5)),
		aWDetector::WellDetector 	= WellDetector(eps(), eps(0.4), eps(0.1), eps(0.1))

		paths = batch([acylDetector3, aWDetector], [0.0])
		@test occursin.(G.id(aWDetector), paths) |> any
		append!(every_path, paths)

		paths = batch([acylDetector3, aWDetector], [0.0], [0.0], [0.0],[0.0],false)
		@test occursin.(G.id(acylDetector3), paths) |> any
		@test occursin.(G.id(aWDetector)  , paths) |> any
		append!(every_path, paths)

		paths = batch([acylDetector3, aBDetector], [0.0])
		@test occursin.(G.id(acylDetector3), paths) |> any
		append!(every_path, paths)

		paths = batch([acylDetector3, aBDetector], [0.0], [0.0], [0.0],[0.0],false)
		@test occursin.(G.id(acylDetector3), paths) |> any
		@test occursin.(G.id(aBDetector)  , paths) |> any
		append!(every_path, paths)
	end #let
	
	let aBDetector::BoreDetector = BoreDetector(eps(0.5), eps(0.4), eps(0.1)),
		aWDetector::WellDetector = WellDetector(eps(0.5), eps(0.4), eps(0.1), eps(0.1))

		paths = batch([aBDetector, aWDetector], [0.0])
		@test occursin.(G.id(aBDetector), paths) |> any
		@test occursin.(G.id(aWDetector), paths) |> any
		append!(every_path, paths)

		paths = batch([aBDetector, aWDetector], [0.0], [0.0], [0.0],[0.0],false)
		@test occursin.(G.id(aBDetector), paths) |> any
		@test occursin.(G.id(aWDetector), paths) |> any
		append!(every_path, paths)
	end #let

	let acylDetector = CylDetector(6, eps(0.65)),
		aBDetector::BoreDetector  = BoreDetector(7, eps(), eps(0.5)),
		aWDetector::WellDetector  = WellDetector(8, eps(), eps(0.5), eps(0.1))
	
		temppaths::Vector{String} = batch([acylDetector, aBDetector, aWDetector], [0.0]) 
		@test occursin.(G.id(acylDetector), temppaths) |> any
		@test occursin.(G.id(aBDetector), temppaths) |> any
		@test occursin.(G.id(aWDetector), temppaths) |> any
	chmod.(temppaths, 0o100444)		#make path read only

		paths = batch([acylDetector, aBDetector, aWDetector], [0.0])
		@test occursin.("_" * G.id(acylDetector), paths) |> any
		@test occursin.("_" * G.id(aBDetector)  , paths) |> any
		@test occursin.("_" * G.id(aWDetector)  , paths) |> any
	append!(every_path, paths)
	try
		append!(every_path, chmod.(temppaths, 0o777))   #
	catch err
		append!(every_path, temppaths)
		chmod.(temppaths, 0o777)
	end


		temppaths = batch([acylDetector, aBDetector, aWDetector], [0.0], [0.0], [0.0],[0.0], false)
		@test occursin.(G.id(acylDetector), temppaths) |> any
		@test occursin.(G.id(aBDetector)  , temppaths) |> any
		@test occursin.(G.id(aWDetector)  , temppaths) |> any
	chmod.(temppaths, 0o100444)

		paths = batch([acylDetector, aBDetector, aWDetector], [0.0], [0.0], [0.0],[0.0], false)
		@test occursin.("_" * G.id(acylDetector), paths) |> any
		@test occursin.("_" * G.id(aBDetector)  , paths) |> any
		@test occursin.("_" * G.id(aWDetector)  , paths) |> any
	append!(every_path, paths)
	try
		append!(every_path, chmod.(temppaths, 0o777))   #
	catch err
		append!(every_path, temppaths)
		chmod.(temppaths, 0o777)
	end
	end #let

	let acylDetector::CylDetector = CylDetector(5, eps()),
		aBDetector::BoreDetector  = BoreDetector(5, eps(), eps(0.5)),
		aWDetector::WellDetector  = WellDetector(5, eps(), eps(0.5), eps(0.1))

		@test append!(every_path, batch([eps() 0], [0.0]))|> eltype === String
		@test append!(every_path, batch([eps() 0], [0.0], [0.0], [0.0], [0.0], false)) |> eltype === String
		@test append!(every_path, batch([1.0 eps()], [0.0]))|> eltype === String
		@test append!(every_path, batch([1.0 eps()], [0.0], [0.0], [0.0], [0.0], false)) |> eltype === String
		@test append!(every_path, batch([1//2 eps()], [0.0]))|> eltype === String
		@test append!(every_path, batch([1//2 eps()], [0.0], [0.0], [0.0], [0.0], false)) |> eltype === String
		@test append!(every_path, batch([1//2 eps(0.5)], [0.0]))|> eltype === String
		@test append!(every_path, batch([1//2 eps(0.5)], [0.0], [0.0], [0.0], [0.0], false)) |> eltype === String
		@test append!(every_path, batch([e pi], [0.0]))|> eltype === String
		@test append!(every_path, batch([e pi], [0.0], [0.0], [0.0], [0.0], false)) |> eltype === String

		@test append!(every_path, batch([5.0 4 3.1], [0.0]))|> eltype === String
		@test append!(every_path, batch([5.0 4 3.1], [0.0], [0.0],[0.0],[0.0],false)) |> eltype === String
		@test append!(every_path, batch([5.0 4 3//1], [0.0]))|> eltype === String
		@test append!(every_path, batch([5.0 4 3//1], [0.0], [0.0],[0.0],[0.0],false)) |> eltype === String
		@test append!(every_path, batch([5.0 4 pi], [0.0]))|> eltype === String
		@test append!(every_path, batch([5.0 4 pi], [0.0], [0.0],[0.0], [0.0], false)) |> eltype === String

		@test append!(every_path, batch([5.0 4 3 2], [0.0]))|> eltype === String
		@test append!(every_path, batch([5.0 4 3 2], [0.0], [0.0], [0.0],[0.0],false))|> eltype === String

		#=@test append!(every_path, batch([acylDetector, aWDetector], [0.0]))|> eltype === String
		@test append!(every_path, batch([acylDetector, aWDetector], [0.0], [0.0], [0.0],[0.0],false))|> eltype === String

		@test append!(every_path, batch([acylDetector, aBDetector], [0.0]))|> eltype === String
		@test append!(every_path, batch([acylDetector, aBDetector], [0.0], [0.0], [0.0],[0.0],false))|> eltype === String

		@test append!(every_path, batch([aBDetector, aWDetector], [0.0]))|> eltype === String
		@test append!(every_path, batch([aBDetector, aWDetector], [0.0], [0.0], [0.0],[0.0],false))|> eltype === String
		=#
		@test append!(every_path, batch([acylDetector, aBDetector, aWDetector], [0.0]))|> eltype === String
		@test append!(every_path, batch([acylDetector, aBDetector, aWDetector], [0.0], [0.0], [0.0],[0.0],false))|> eltype === String
	end #let

	G.detector_info_from_csvFile()
	if  [0.0] != G.read_from_csvFile(G.srcHeights, G.dataDir)
		setSrcToPoint(true);  
		@test_skip append!(every_path, batch())|> eltype === String
			
		if [0.0] != G.read_from_csvFile(G.srcRadii, G.dataDir) 
			setSrcToPoint(false); 
			@test_skip append!(every_path, batch())|> eltype === String
		end #if
	end	#if


	#rm.(batch([aWDetector], [0.0]))
	#rm.(batch([aWDetector], [0.0], [0.0], [0.0],[0.0],false))
	#=for cr = 0.2:0.1:0.7	
		@test append!(every_path, batch([Detector(11, eps(cr))], [0.0], [0.0], [0.0],[0.0],false))|> eltype === String
		@test append!(every_path, batch([Detector(22, eps(cr))], collect(0.0:0.1:10), [0.0], [0.0],[0.0],false))|> eltype === String
		@test append!(every_path, batch([Detector(33, eps(cr))], [0.0]))|> eltype === String
	end #for
	=#
try 
	rm.(every_path, force=true)
catch err
	@error err
end #try
end #testset_batch
