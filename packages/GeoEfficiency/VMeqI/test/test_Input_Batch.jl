#**************************************************************************************
# test_Input_Batch.jl
# ======================= part of the GeoEfficiency.jl package.
# 
# test all the input to the package from the CSV files.
# 
#**************************************************************************************


@debug("setSrcToPoint & typeofSrc")
@testset "setSrcToPoint & typeofSrc" begin
	@test setSrcToPoint(false) === false
	@test G.srcType == G.srcNotPoint
	@test typeofSrc() === G.srcNotPoint
	@test setSrcToPoint() === false
	@test setSrcToPoint("\n Is it a point source {Y|n} ? ") === false	# allredy set

	@test setSrcToPoint(true)
	@test G.srcType === G.srcPoint
	@test typeofSrc() === G.srcPoint
	@test setSrcToPoint()
	@test setSrcToPoint("\n Is it a point source {Y|n} ? ")				# allredy set

	@test typeofSrc(-5) === G.srcUnknown
	@test typeofSrc(-1) === G.srcUnknown
	@test setSrcToPoint() === false
		
	@test typeofSrc(1) === G.srcLine
	@test setSrcToPoint() === false
	@test setSrcToPoint("\n Is it a point source {Y|n} ? ") === false
	@test setSrcToPoint(false) === false
	@test setSrcToPoint(true)
		
	@test typeofSrc(2) === G.srcDisk
	@test setSrcToPoint() === false
	@test setSrcToPoint("\n Is it a point source {Y|n} ? ") === false
	@test setSrcToPoint(false) === false
	@test setSrcToPoint(true)
		
	@test typeofSrc(3) === G.srcVolume
	@test setSrcToPoint() === false
	@test setSrcToPoint("\n Is it a point source {Y|n} ? ") === false
	@test setSrcToPoint(false) === false
	@test setSrcToPoint(true)
		
	@test typeofSrc(4) === G.srcNotPoint
	@test setSrcToPoint() === false
	@test setSrcToPoint("\n Is it a point source {Y|n} ? ") === false
	@test setSrcToPoint(false) === false
	@test setSrcToPoint(true)
	
	@test typeofSrc(0) === G.srcPoint
	@test setSrcToPoint()
	@test setSrcToPoint("\n Is it a point source {Y|n} ? ") 	# allredy set
	@test setSrcToPoint()

	@test typeofSrc(5) === G.srcNotPoint
	@test setSrcToPoint() === false
	@test setSrcToPoint(false) === false
	@test setSrcToPoint(true)


	@testset "setSrcToPoint(::Strin)" begin
		@test typeofSrc(-1) === G.srcUnknown
		#@test H.exec_consol_unattended(setSrcToPoint, ["n"], Fn_ARGs =["\n Is it a point source {Y|n} ? "]) === false # require input
		@test false == H.@console 	setSrcToPoint("\n Is it a point source {Y|n} ? ")	"n"
		@test setSrcToPoint() === false
	
		@test typeofSrc(-1) === G.srcUnknown
		#@test H.exec_consol_unattended(setSrcToPoint, ["N"], Fn_ARGs =["\n Is it a point source {Y|n} ? "]) === false # require input
		@test false == H.@console 	setSrcToPoint("\n Is it a point source {Y|n} ? ")	"N"
		@test setSrcToPoint() === false
	
		@test typeofSrc(-1) === G.srcUnknown
		#@test H.exec_consol_unattended(setSrcToPoint, ["Y"], Fn_ARGs =["\n Is it a point source {Y|n} ? "])  	# require input
		@test H.@console 	setSrcToPoint("\n Is it a point source {Y|n} ? ")	"Y"
		@test setSrcToPoint()

		@test typeofSrc(-1) === G.srcUnknown
		#@test H.exec_consol_unattended(setSrcToPoint, ["y"], Fn_ARGs =["\n Is it a point source {Y|n} ? "]) 	# require input
		@test H.@console 	setSrcToPoint("\n Is it a point source {Y|n} ? ")	"y"
		@test setSrcToPoint()
	end #testset_setSrcToPoint(::Strin)

	@test typeofSrc(-1) === G.srcUnknown		#set back the default
end #testset


@debug("reading from CSV")	
@testset "reading from CSV" begin
	local detector_info_array = [5 0 0 0; 5 10 0 0; 5 10 2 0; 5 10 2 5]
    local detectors = [Detector(5, 0, 0, 0), Detector(5, 10, 0, 0), Detector(5, 10, 2, 0), Detector(5, 10, 2, 5)]

	local detectorfile = "detectorfile.csv"
	local hightfile    = "hightfile.csv"
	local Rhosfile     = "Rhosfile.csv"			# no file will created
	local Radiifile    = "Radiifile.csv"		# no file will created
	local Lengthsfile  = "Lengthsfile.csv"		# no file will created

	local datadirectory	= mktempdir(); isdir(datadirectory) || mkdir(datadirectory)
	local detectorpath 	= joinpath(datadirectory, detectorfile)
	local hightpath    	= joinpath(datadirectory, hightfile)

	setSrcToPoint(true) == true


	@testset "Detectors write and read - input eltype{Int}" begin	
		@test  G.writecsv_head(detectorpath, detector_info_array, ["CryRadius"	 "CryLength" "HoleRadius" "HoleDepth"])  ==  nothing
		@test  G.detector_info_from_csvFile(detectorfile, datadirectory) == sort(detectors)
	end #testset_input_type{Int}


	@testset "write and read - input eltype{Int}" begin
		@test  G.writecsv_head(hightpath, [0, 1, 2, 3, 4, 5, 10, 15, 20,], ["SrcHight"])  ==  nothing
		@test  G.read_from_csvFile(hightfile, datadirectory) == [0, 1, 2, 3, 4, 5, 10, 15, 20,]
	end #testset


	@testset "rewrite, read and sort  - input eltype{Int}" begin
		@test  G.writecsv_head(hightpath, [3, 20, 4, 0, 1, 2, 5, 10, 15,], ["SrcHight"])  ==  nothing
		@test  G.read_from_csvFile(hightfile, datadirectory) == [0, 1, 2, 3, 4, 5, 10, 15, 20,]
	end #testset


	@testset "rewrite, read and sort - input eltype{Rational-treated as any}" begin
		@test  G.writecsv_head_any(hightpath, [3//2, 20, 4, 0, 1, 2, 5, 10, 15,], ["SrcHight"])  ==  nothing
		@test  G.read_from_csvFile(hightfile, datadirectory) == [0.0]	# bad format
	end #testset


	@testset "rewrite, read and sort - input eltype{Float64}" begin
		@test  G.writecsv_head(hightpath, [3.0, 20, 4, 0, 1, 2, 5, 10, 15,], ["SrcHight"])  ==  nothing
		@test  G.read_from_csvFile(hightfile, datadirectory) == [0, 1, 2, 3, 4, 5, 10, 15, 20,]
	end #testset


	@testset "rewrite, read and sort - input eltype{Irrational}" begin
		@test  G.writecsv_head(hightpath, [pi, e, pi + e, 1, 2, 5, 10, 15,], ["SrcHight"])  ==  nothing
		@test G.read_from_csvFile(hightfile, datadirectory) == [1.0, 2.0, e, pi, 5.0, pi + e, 10.0, 15.0]	# Irrational converted to Float
	end #testset


	@testset "invalid data type {Unionall}" begin
		@test  G.writecsv_head_any(hightpath, ["3.0", 20, 4, 0, 1, 2, 5, 10, 15,], ["SrcHight"])  ==  nothing
		@test  G.read_from_csvFile(hightfile, datadirectory) ==  [0, 1, 2, 3, 4, 5, 10, 15, 20,]
	end #testset


	@testset "invalid data type {String}" begin
		@test  G.writecsv_head_any(hightpath, ["pi", "20", "4", "0", "1", "2", "5", "10", "15",], ["SrcHight"])  ==  nothing
		@test  G.read_from_csvFile(hightfile, datadirectory) == [0.0]
		
		@test  G.writecsv_head_any(hightpath, string.([pi, e, pi + e, 1, 2, 5, 10, 15,], ["SrcHight"]))  ==  nothing
		@test G.read_from_csvFile(hightfile, datadirectory) == [0.0]
	end #testset


	@testset "invalid data type {Complex}" begin
		@test  G.writecsv_head_any(hightpath, [3.0+0.0im, 20, 4, 0, 1, 2, 5, 10, 15,], ["SrcHight"])  ==  nothing
		@test  G.read_from_csvFile(hightfile, datadirectory) == [0.0]			
	end #testset


	@testset "missing file - `Hights.csv`" begin
		rm(hightpath, force=true)
		@test  G.read_from_csvFile(hightfile, datadirectory) == [0.0]
		
		setSrcToPoint(false)
		write(stdin.buffer, 
			"1\n" * "0\n" * #=axial point=#
			"2\n" * "3\n" 	#=SrcRadius SrcHeight=#)
		@test  G.read_batch_info(datadirectory, detectorfile, hightfile, Rhosfile, Radiifile, Lengthsfile) == (detectors |> sort, [1.0], [0.0], [2.0], [3.0], false)
	end #testset


	@testset "missing file - `Rhos.csv`" begin
		@test  G.writecsv_head(hightpath, [4.0,], ["SrcHight"])  ==  nothing
		@test  G.read_from_csvFile(hightfile, datadirectory) == [4.0]
		
		setSrcToPoint(false)
		write(stdin.buffer, 
			"1\n" * "0\n" * #=axial point=#
			"2\n" * "3\n" 	#=SrcRadius SrcHeight=#)
		@test  G.read_batch_info(datadirectory, detectorfile, hightfile, Rhosfile, Radiifile, Lengthsfile) == (detectors |> sort, [1.0], [0.0], [2.0], [3.0], false)
	end #testset


	@testset "GeoEfficiency.read_batch_info" begin

		try 
			@test eltype(G.detector_info_from_csvFile()) == G.Detector
			@test G.read_batch_info() isa Tuple{Vector,  Vector{Float64},  Vector{Float64}, Vector{Float64}, Vector{Float64}, Bool}
			setSrcToPoint(true);  
			@test H.@console(G.read_batch_info(tempname(),"","","","",""), "1 2 0 q 1 0") isa Tuple{Vector,  Vector{Float64},  Vector{Float64}, Vector{Float64}, Vector{Float64}, Bool}
			setSrcToPoint(false);
			@test H.@console(G.read_batch_info(tempname(),"","","","",""), "1 2 0 q 1 0 1 1") isa Tuple{Vector,  Vector{Float64},  Vector{Float64}, Vector{Float64}, Vector{Float64}, Bool}

			if  [0.0] != G.read_from_csvFile(G.srcHeights, G.datadir)
				setSrcToPoint(true);  
				@test G.read_batch_info()[end]=== true
			
				if [0.0] != G.read_from_csvFile(G.srcRadii, G.datadir) 
					setSrcToPoint(false); 
					@test G.read_batch_info()[end]=== false
				end #if
			end	#if
	
		catch err
		end #try


		setSrcToPoint(true);
		@test  G.writecsv_head(hightpath, [0, 10, 20, 3, 4, 5, 1, 15, 2,], ["SrcHight"])  ==  nothing
		@test  G.writecsv_head(detectorpath, detector_info_array, ["CryRadius"	 "CryLength" "HoleRadius" "HoleDepth"])  ==  nothing
		let batch_info = G.read_batch_info(datadirectory, detectorfile, hightfile, Rhosfile, Radiifile, Lengthsfile)
			@test  batch_info[1] == sort(detectors)
			@test  batch_info[2] == [0, 1, 2, 3, 4, 5, 10, 15, 20,]
			@test  batch_info[3] == [0.0]
			@test  batch_info[4] == [0.0]
			@test  batch_info[5] == [0.0]
			@test  batch_info[6] == ( G.srcType === G.srcPoint)
			@test  batch_info 	 == (detectors |> sort, [0.0, 1, 2, 3, 4, 5, 10, 15, 20,], [0.0], [0.0], [0.0], G.srcType === G.srcPoint)
		end #let
	end #testset_read_batch_info


	@testset "missing file - Detectors.csv" begin
		rm(detectorpath, force=true)
		@test_throws Union{ArgumentError, SystemError}  G.detector_info_from_csvFile(detectorfile, datadirectory)   # the Union{ArgumentError, SystemError} is used for compatibility in both 0.6 and 0.7-dev

		@test_throws Union{ArgumentError, SystemError}  G.detector_info_from_csvFile("jskfdsiu.uty",".fghpweuh")
	end #testset
	
	rm(datadirectory, force=true, recursive=true) # remove temp directory 
end #testset_reading_from_CSV


@testset "getDetectors" begin
	local detector_info_array = [5 0 0 0; 5 10 0 0; 5 10 2 0; 5 10 2 5]
	local detectors = [Detector(5, 0, 0, 0), Detector(5, 10, 0, 0), Detector(5, 10, 2, 0), Detector(5, 10, 2, 5)]
	detectors = detectors |> sort
    
	@test getDetectors(detector_info_array) == detectors 
	for det = detectors
		@test typeof(det) != Detector
	end
	@test eltype(detectors) != CylDetector
	@test eltype(detectors) == Detector
	local (det1, det2, det3, det4) = detectors
	@test det1 <= det2 <= det3 <= det4

	detector_info_array = [5 0; 10 0; 15 0; 20 0]
	detectors = getDetectors(detector_info_array)
	for det = detectors
		@test typeof(det) == CylDetector
		@test typeof(det) != Detector
	end
	@test eltype(detectors) != CylDetector
	@test eltype(detectors) == Detector
	(det1, det2, det3, det4) = detectors
		
	detector_info_array = [5 1; 10 1; 15 1; 20 1]
	detectors = getDetectors(detector_info_array)
	for det = detectors
		@test typeof(det) == CylDetector
		@test typeof(det) != Detector
	end
	@test eltype(detectors) != CylDetector
	@test eltype(detectors) == Detector
	(det1, det2, det3, det4) = detectors
	@test det1 <= det2 <= det3 <= det4
		
	detector_info_array = [5 1; 10 1; 15 1; 20 1//1]
	detectors = getDetectors(detector_info_array)
	for det = detectors
		@test typeof(det) == CylDetector
		@test typeof(det) != Detector
	end
	@test eltype(detectors) != CylDetector
	@test eltype(detectors) == Detector
	(det1, det2, det3, det4) = detectors
	@test det1 <= det2 <= det3 <= det4
		
	detector_info_array = [5 1; 10 1; 15 1; 20 1.0]
	detectors = getDetectors(detector_info_array)
	for det = detectors
		@test typeof(det) == CylDetector
		@test typeof(det) != Detector
	end
	@test eltype(detectors) != CylDetector
	@test eltype(detectors) == Detector
	(det1, det2, det3, det4) = detectors
	@test det1 <= det2 <= det3 <= det4

	@test  getDetectors([-2 0 ; 2 1]) ==  [CylDetector(2.0, 1.0)]	# invalid detector

	detector_info_array = ["5" "0" "0" "0"; "10" "0" "0" "0"]
	@test_throws  MethodError getDetectors(detector_info_array; console_FB=false)
	detector_info_array = [5+1im 0 0 0; 5 10 0 0; 5 10 2 0; 5 10 2 5]
	@test_throws MethodError getDetectors(detector_info_array; console_FB=false)
	detector_info_array = detector_info_array = Matrix{Int}(undef, 0, 0)
	@test_throws ErrorException getDetectors(detector_info_array; console_FB=false)


	@testset "quit = $qt, new detector = $nw" for 
		qt = ["q", "Q"] .* "\n" , 
		nw = ["", "n", "N", "anything", "qQ", "Qq"] .* "\n"

		write(stdin.buffer,"5\n" * "1\n" * "0\n" * qt)
		@test getDetectors() == [Detector(5,1)]
	
		write(stdin.buffer,"5\n" * "1\n" * "0\n" * qt)
		@test getDetectors(Matrix{Float64}(undef, 0, 0)) == [Detector(5,1)]

		#write(stdin.buffer,"5\n" * "1\n" * "0\n" * nw * "55\n" * "11\n" * "0\n" * "0\n" * qt)
		#@test getDetectors(Matrix{Float64}(undef, 0, 0)) == [Detector(5, 1), Detector(55, 11)]
	end #testset_quit
end #testset_getDetectors
