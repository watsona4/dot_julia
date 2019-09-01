#**************************************************************************************
# test_Physics_Model.jl
# ====================== part of the GeoEfficiency.jl package.
# 
#   
# ToDO: clean up some remaining isapple 
#**************************************************************************************


@debug("Point")	
@testset "Point" begin
	@test G.id(Point(5,3)) == "Point[Height=5.0, Rho=3.0]"
	@test show(Point(5,3)) == nothing


	local pnt11 = Point(1, 1)
	local pnt5 = Point(5.0, 0.0)	
	local pnt51 = Point(5.0, 1.0)	
		
	@test Point(5).Height === 5.0
	@test Point(5).Rho    === 0.0
	@test Point(-5).Height === -5.0
	@test Point(-5).Rho    === 0.0
	@test Point(-5,-1).Height === -5.0
	@test Point(-5,-1).Rho    === -1.0
	@test_throws MethodError     Point(1+0im,4)
	@test_throws MethodError     Point(4, 1+0im)
	@test_throws MethodError     Point(1+0im, 1+0im)
	@test_throws ErrorException  Point(5.0, 0.0).Height = 1.0
	@test_throws ErrorException  Point(5.0, 0.0).Rho    = 1.0
		
	@test Point(5)      === pnt5 
	@test Point(5//1)   === pnt5
	@test Point(5.0)    === pnt5
		
	@test Point(5, 0)   === pnt5
	@test Point(5, 0//1)=== pnt5
	@test Point(5, 0.0) === pnt5

	@test Point(5//1, 0)    === pnt5
	@test Point(5//1, 0//1) === pnt5
	@test Point(5//1, 0.0)  === pnt5

	@test Point(5.0, 0)    === pnt5
	@test Point(5.0, 0//1) === pnt5
	@test Point(5.0, 0.0)  === pnt5
	

	@test Point(5, 1)   === pnt51
	@test Point(5, 1//1)=== pnt51
	@test Point(5, 1.0) === pnt51

	@test Point(5//1, 1)    === pnt51
	@test Point(5//1, 1//1) === pnt51
	@test Point(5//1, 1.0)  === pnt51

	@test Point(5.0, 1)    === pnt51
	@test Point(5.0, 1//1) === pnt51
	@test Point(5.0, 1.0)  === pnt51	
		
	local pnt6 = Point(pnt5, 5)
	@test pnt6.Height == pnt5.Height 
	@test pnt6.Rho == 5.0

	pnt6 = Point(5, pnt5)
	@test pnt6.Height == 5.0
	@test pnt6.Rho == pnt5.Rho 
		
	@test H.exec_console_unattended(Point, [5, 1]) == pnt51
	@test H.exec_console_unattended(Point, [5, 0]) == pnt5
end #testset_Point


@debug("CylDetector")			
@testset "CylDetector" begin 
  
	@test G.id(CylDetector(5, 3)) == "CylDetector[CryRadius=5.0, CryLength=3.0]"
	@test show(CylDetector(5, 3)) == nothing
	
	let cyl0 = CylDetector(5), cyl1 = Detector(5)
	
		@test_throws ErrorException  cyl0.CryRadius = 1
		@test_throws ErrorException  cyl0.CryLength = 1
		@test_throws MethodError     CylDetector(1+0im)
		@test_throws MethodError     CylDetector(1+0im,4)
		@test_throws MethodError     CylDetector(4, 1+0im)
		@test_throws MethodError     CylDetector(1+0im, 1+0im)
		@test_throws G.InValidDetectorDim  CylDetector(0)
		@test_throws G.InValidDetectorDim  CylDetector(-5)
		@test_throws G.InValidDetectorDim  CylDetector(5, -1)
		@test isa(cyl1, Detector)
		@test isa(cyl1, CylDetector)
		@test cyl1.CryRadius === 5.0
		@test cyl1.CryLength === 0.0
	end #let
	
	let cyl0 = CylDetector(5),
		cyl1 = Detector(5),
		cyl2 = Detector(5, 0),
		cyl3 = Detector(5, 0.0),
		cyl4 = Detector(5.0, 0),
		cyl5 = Detector(5.0, 0.0),
		cyl6 = Detector(5, 0, 0),
		cyl7 = Detector(5, 0, 0, 0),
		cyl8 = Detector(5//1, 0, 0, 0),
		cyl9 = Detector(5//1)
			
		@test cyl0 === cyl1 
		@test cyl1 === cyl2 
		@test cyl2 === cyl3
		@test cyl3 === cyl4
		@test cyl4 === cyl5
		@test cyl5 === cyl6
		@test cyl6 === cyl7
		@test cyl7 === cyl8
		@test cyl8 === cyl9
		@test G.volume(CylDetector(5.0,1))  <=   G.volume(CylDetector(15.0,1))
		@test G.volume(CylDetector(10.0,1)) <=   G.volume(CylDetector(15.0,1)) 
		@test G.volume(CylDetector(15.0))   <=   G.volume(CylDetector(10.0)) 
		@test CylDetector(5.0,1) < CylDetector(15.0,1)
	end #let
	
	let detectors = [Detector(6,2),Detector(5,1), Detector(7,10)]

		@test eltype(Vector{Detector}(detectors)) === Detector
		@test Vector{Detector}(detectors) == detectors
	end #let

	@debug("CylDetector()")
	@test H.exec_console_unattended(CylDetector, [5, 1]) == CylDetector(5, 1)
	@test H.exec_console_unattended(CylDetector, [5, 0])  == CylDetector(5)
end #testset_CylDetector


@debug("BoreDetector")	
@testset "BoreDetector" begin 
	
		@test G.id(BoreDetector(5,3,2)) == "BoreDetector[CryRadius=5.0, CryLength=3.0, HoleRadius=2.0]"
  		@test show(BoreDetector(5,3,2)) == nothing  
    
	let bore0 = BoreDetector(5,4,3), 
		bore1 = Detector(5,4,3)

		@test_throws ErrorException  bore0.CryRadius = 1
		@test_throws ErrorException  bore0.CryLength = 1
		@test_throws ErrorException  bore0.HoleRadius= 1
		@test_throws MethodError     BoreDetector(1+1im,4,3)
		@test_throws MethodError     BoreDetector(5+1im,4,3)	
		@test isa(bore1, Detector)
		@test isa(bore1, BoreDetector)
		@test 5.0 == bore1.CryRadius
		@test 4.0 == bore1.CryLength
		@test 3.0 == bore1.HoleRadius
	end #let

	let bore0 = BoreDetector(5,4,3), 
		bore1 = Detector(5,4,3),
		bore2 = Detector(5.0,4,3),
		bore3 = Detector(5,4,3,0),
		bore4 = Detector(5,4.0,3),
		bore5 = Detector(5.0,4,3.0),
		bore6 = Detector(5.0,4.0,3.0),
		bore7 = Detector(5.0,4.0,3.0, 0),
		bore8 = Detector(5//1,4.0,3.0, 0)

		@test bore0 === bore1
		@test bore1 === bore2
		@test bore2 === bore3
		@test bore3 === bore4
		@test bore4 === bore5
		@test bore5 === bore6
		@test bore6 === bore7
		@test bore7 === bore8
		@test G.volume(Detector(5.0,1,.1))  <=   G.volume(Detector(15.0,1,0.1))
		@test G.volume(Detector(10.0,1,.0)) <=   G.volume(Detector(15.0,1,0.1)) 
		@test Detector(5.0,1,0.1) < Detector(15.0,1,0.1)
	end #let

	let	detectors = [Detector(6,2,1), Detector(5,1,.2), Detector(7,10,5)]

		@test eltype(Vector{Detector}(detectors)) === Detector
		@test Vector{Detector}(detectors) == detectors
	end #let

	@debug("BoreDetector()")
	let bore0 = BoreDetector(5,4,3)

		@test H.exec_console_unattended(BoreDetector, [5, 4, 3]) === bore0
		@test H.exec_console_unattended(BoreDetector, [5, 4, 6, 3]) === bore0
	end #let

end #testset_BoreDetector


@debug("WellDetector")	
@testset "WellDetector" begin 
	@test G.id(WellDetector(5, 3, 2, 1)) == "WellDetector[CryRadius=5.0, CryLength=3.0, HoleRadius=2.0, HoleDepth=1.0]"
	@test show(WellDetector(5, 3, 2, 1)) == nothing  

	let	Well0 = WellDetector(5,4,3,2), 
		Well1 = Detector(5,4,3,2),
		Well2 = Detector(5.0,4,3,2),
		Well3 = Detector(5,4.0,3,2),
		Well4 = Detector(5,4,3.0,2),
		Well5 = Detector(5,4,3,2.0),
		Well6 = Detector(5.0,4,3.0,2),
		Well7 = Detector(5,4.0,3,2.0),
		Well8 = Detector(5//1,4,3,2)

		@test_throws ErrorException  Well0.CryRadius = 1
		@test_throws ErrorException  Well0.CryLength = 1
		@test_throws ErrorException  Well0.HoleRadius= 1
		@test_throws ErrorException  Well0.HoleDepth = 1
		@test_throws MethodError     WellDetector(1+1im,4,3,2)
		@test_throws MethodError     WellDetector(5+1im,4,3,2)
		@test isa(Well1, Detector)
		@test isa(Well1, WellDetector)
		@test 5.0 == Well1.CryRadius
		@test 4.0 == Well1.CryLength
		@test 3.0 == Well1.HoleRadius
		@test 2.0 == Well1.HoleDepth


		@test Well0 === Well1 
		@test Well1 === Well2 
		@test Well2 === Well3
		@test Well3 === Well4
		@test Well4 === Well5
		@test Well5 === Well6
		@test Well6 === Well7
		@test Well7 === Well8
	end #let

	@test G.volume(Detector(5.0, 2, 0.1, 1))  <=   G.volume(Detector(15.0, 2, 0.1, 1))
	@test G.volume(Detector(10.0, 2, 0.1, 1)) <=   G.volume(Detector(15.0, 2, 0.1, 1)) 
	@test Detector(5.0, 2, 0.1, 1) < Detector(15.0, 2, 0.1, 1)

	let	detectors = [Detector(6, 2, 1, 0.1), Detector(5, 1, 0.2, 0.1), Detector(7, 10, 5, 0.1)]

		@test eltype(Vector{Detector}(detectors)) === Detector
		@test Vector{Detector}(detectors) == detectors
	end #let

	@debug("WellDetector()")
	let Well0 = WellDetector(5, 4, 3, 2)

		@test H.exec_console_unattended(WellDetector, [5, 4, 3, 2])    == Well0
		@test H.exec_console_unattended(WellDetector, [5, 4, 3, 6, 2]) == Well0
	end #let
end #testset_WellDetector

		
@debug("Detector")    
@testset "Detector" begin 
	
	@test_throws MethodError  Detector(1+1im)
	@test_throws MethodError  Detector(5+1im, 0)
	@test_throws MethodError  Detector(1+1im, 1)
	@test_throws MethodError  Detector(5+1im, 4, 3)
	@test_throws MethodError  Detector(1+1im, 4, 3, 2)
	@test_throws MethodError  Detector(5+1im, 4, 3, 2)
	@test_throws MethodError  Detector(1+1im, 4, 3, 2)
	@test_throws MethodError  Detector(4, 1+1im, 3, 2)
	@test_throws MethodError  Detector(4, 3, 2+1im, 1)
	@test_throws MethodError  Detector(4, 3, 2, 1+1im)
		
	@test Detector(5)       === CylDetector(5)
	@test Detector(5,0)     === CylDetector(5)
	@test Detector(5,0,0,0) === CylDetector(5)
	@test Detector(5,1)     === CylDetector(5,1)
	@test Detector(5,1,0)   === CylDetector(5,1)
	@test Detector(5,1,0,0) === CylDetector(5,1)
	@test Detector(5,2,1)   === BoreDetector(5,2, 1)
	@test Detector(5,2,1,0) === BoreDetector(5,2, 1)
	@test Detector(5,4,3,2) === WellDetector(5,4,3,2)
		
	let cyl0 = CylDetector(5),
		bore0 = BoreDetector(5, 4, 3),
		Well0 = WellDetector(5, 4, 3, 2)

    	@test Detector(cyl0)   === cyl0
		@test Detector(bore0)  === bore0
		@test Detector(Well0)  === Well0
	end #let
	for i=1:1000
		let det1 = Detector(rand()),
			det2 = Detector(rand(2)...),
			det3 = Detector(rand(15:20), rand(10:14), rand(1:13)),
			det4 = Detector(rand(15:20), rand(10:14), rand(9:13), rand(1:9))

			@test Detector(det1)   === det1
			@test Detector(det2)   === det2
			@test Detector(det3)   === det3
			@test Detector(det4)   === det4
		end #let
	end #for
		
	@test G.id(Detector(5,3,2,1)) == "WellDetector[CryRadius=5.0, CryLength=3.0, HoleRadius=2.0, HoleDepth=1.0]"
	@test G.id(Detector(5,3,2)) == "BoreDetector[CryRadius=5.0, CryLength=3.0, HoleRadius=2.0]"
	@test G.id(Detector(5,3)) == "CylDetector[CryRadius=5.0, CryLength=3.0]"
	@test G.id(Detector(5)) == "CylDetector[CryRadius=5.0, CryLength=0.0]"
	
	@debug("Detector(detectors::Vector{<:Detector})")
	@testset "Detector(detectors::Vector{<:Detector})" begin
	mix_detectors = [Detector(6,2), Detector(5,1,.2), Detector(7,10,5,.1)]
	cyl_detectors = [CylDetector(2,6), Detector(6,2), CylDetector(2), Detector(6)]

		@test eltype(Vector{Detector}(mix_detectors)) 	=== Detector
		@test eltype(Vector{Detector}(cyl_detectors)) 	=== Detector

		@test Vector{Detector}(mix_detectors) == mix_detectors
		@test Vector{Detector}(cyl_detectors) == cyl_detectors


		@test eltype(Detector(mix_detectors)) 	=== Detector
		@test eltype(Detector(cyl_detectors)) 	=== Detector

		@test Detector(mix_detectors) == mix_detectors
		@test Detector(cyl_detectors) == cyl_detectors
	end #Detector(detectors::Vector{<:Detector})

	@debug("Detector()")
	@test H.exec_console_unattended(Detector, [5, 4, 3, 6, 2]) 		== Detector(5, 4, 3, 2)
	@test H.exec_console_unattended(Detector, [5, 4, 0])				== Detector(5, 4)
	@test H.exec_console_unattended(Detector, "5\n" * "4\n" * "0\n") 	== Detector(5, 4)
	@test H.exec_console_unattended(Detector, [5, 4, 33, 3, 22, 2]) 		== Detector(5, 4, 3, 2)
end #testset_Detector	


@debug("source")   
@testset "source" begin
	setSrcToPoint(true)
	let	pnt1 = Point(5)

		@test source(pnt1) == (pnt1, 0.0, 0.0)
	end #let
			
	setSrcToPoint(false)
	write(stdin.buffer, 
		"1\n" * "0\n" * #=axial point=#
		"2\n" * "3\n" #=SrcRadius=2 SrcHeight=3=#)
	@test  source() == (Point(1.0, 0.0), 2.0, 3.0)
			
	setSrcToPoint(false)
	write(stdin.buffer, 
		"1\n" * "5\n" * #=non-axial point=#
		"2\n" * "3\n" #=SrcRadius=2 SrcHeight=3=#)
	@test  source() == (Point(1.0, 0.0), 2.0, 3.0) # axial anchor point
			
	setSrcToPoint(false)
	write(stdin.buffer, 
		"1\n" * "5\n" * #=non-axial point=#
		"0\n" 			#=SrcRadius=2=# )
	@test  source() == (Point(1.0, 5.0), 0.0, 0.0) # non-axial  point source

	setSrcToPoint(true)
	write(stdin.buffer,	"1\n" * "5\n") # non-axial point
	@test  source() == (Point(1.0, 5.0), 0.0, 0.0)
end #testset_source


@debug("Invalid Detector Dimensions")
@testset "Invalid Detector Dimensions $dim"  for dim =  
Number[0, -1, 0//1, -1//1, -e, 0.0, -1.0, -Inf, Inf,]

	@test_throws G.InValidDetectorDim	CylDetector(dim)  
	@test_throws G.InValidDetectorDim	CylDetector(dim, 0)
	@test_throws G.InValidDetectorDim	CylDetector(dim, 1)
	@test_throws G.InValidDetectorDim	BoreDetector(dim, 1, 0.2)
	@test_throws G.InValidDetectorDim	BoreDetector(dim, 1, 0)
	@test_throws G.InValidDetectorDim	WellDetector(dim, 2, 1, 0)

	@test_throws G.InValidDetectorDim	Detector(dim)
	@test_throws G.InValidDetectorDim	Detector(dim, 0)
	@test_throws G.InValidDetectorDim	Detector(dim, 1)
	@test_throws G.InValidDetectorDim	Detector(dim, 0, 0)

	dim == 0.0 && break
	@test_throws G.InValidDetectorDim	CylDetector(5, dim)
	@test_throws G.InValidDetectorDim  	BoreDetector(5, dim, 0)
	@test_throws G.InValidDetectorDim	CylDetector(5, dim)
	@test_throws G.InValidDetectorDim	BoreDetector(5, dim, 0)
	@test_throws G.InValidDetectorDim	BoreDetector(5,dim, 1)
	@test_throws G.InValidDetectorDim	WellDetector(5,dim, 1, 0.1)
end #testset_Invalid_Detector_Dimensions
