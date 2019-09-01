#**************************************************************************************
# test_Calculations.jl
# =============== part of the GeoEfficiency.jl package.
# 
# this file contains all the required function to test calculate the Geometrical efficiency.
#
#**************************************************************************************

const absoluteTol1 = 1.0e-14 #1.0e-16
const absoluteTol2 = 1.0e-11 #1.0e-13

let poly1(z::Float64) = @evalpoly(z, 1.0, 2.0),
	poly2(z::Float64) = @evalpoly(z, 1.0, 2.0, 3.0)
	
	@testset "integrate start=$str, end=$nd" for 
	str = -20.0:2.0:30.0, 
	nd  = -20.0:2.0:30.0
	#str === nd &&  continue

		#@test G.integrate(poly0, str, nd)[1] ≈ @evalpoly(nd, 0.0, 1.0) - @evalpoly(str, 0.0, 1.0) atol=absoluteTol2
		@test G.integrate(poly1, str, nd)[1] ≈ @evalpoly(nd, 0.0, 1.0, 1.0) - @evalpoly(str, 0.0, 1.0, 1.0) atol=absoluteTol2
		@test G.integrate(poly2, str, nd)[1] ≈ @evalpoly(nd, 0.0, 1.0, 1.0, 1.0) - @evalpoly(str, 0.0, 1.0, 1.0, 1.0) atol=absoluteTol2	
	end #testset_integrate
end #let


@testset "special cases" begin

	@debug("special case - point at the surface of cylindrical detector; very restrict test")
	@testset "cylindrical detector of cryRadius $cryRadius" for 
	cryRadius    = 1.0:0.5:11.0
	
	local acylDetector = CylDetector(cryRadius)

		@test geoEff(acylDetector, Point(0)) ≈ 0.5
		@test geoEff(acylDetector, Point(0, prevfloat(cryRadius)))  ≈ 0.5
		@test geoEff(acylDetector, Point(0, nextfloat(-cryRadius))) ≈ 0.5
		@test geoEff(acylDetector, Point(0,         cryRadius/2.0)) ≈ 0.5
		@test geoEff(acylDetector, Point(0,        -cryRadius/2.0)) ≈ 0.5

		@test geoEff(acylDetector, Point(eps())) ≈ 0.5
		@test 0.0 < geoEff(acylDetector, Point(eps(), prevfloat(cryRadius)))  <= 0.5
		@test 0.0 < geoEff(acylDetector, Point(eps(), nextfloat(-cryRadius))) <= 0.5
		@test geoEff(acylDetector, Point(eps(),          cryRadius/2.0)) ≈ 0.5
		@test geoEff(acylDetector, Point(eps(),         -cryRadius/2.0)) ≈ 0.5

		@test geoEff(acylDetector, Point(eps(cryRadius), cryRadius))  ≈ 0.25
		@test 0.0 < geoEff(acylDetector, Point(cryRadius, cryRadius)) < 0.25		
	
		@test_throws G.NotImplementedError	geoEff(acylDetector, Point(eps(cryRadius), nextfloat(cryRadius)))
		@test_throws G.NotImplementedError	geoEff(acylDetector, Point(nextfloat(cryRadius), nextfloat(cryRadius)))
		@test_throws G.InValidGeometry		geoEff(acylDetector, Point(-1, 0))
	end #testset_cylindrical_detector


	@debug("special case - point at the surface of Borehole detector")
	@testset "Borehole detector of cryRadius $cryRadius and height $height, k $k" for 
	cryRadius = 1.0:0.5:11.0, 
	height    = 1.0:0.5:11.0, 
	k         = 1.1:0.5:11.0

	local holeradius::Float64 = cryRadius/k		# k > 1
	local aboreDetector = BoreDetector(cryRadius, height, holeradius)
	
		@test  0.0 < geoEff(aboreDetector, Point(0.0))        < 1.0 
		@test  0.0 < geoEff(aboreDetector, Point(-0.1))       < 1.0 ### invert Detector
		@test_skip  0.0 < geoEff(aboreDetector, Point(height/2.0))  < 1.0 # StackOverflowError
		@test_skip  0.0 < geoEff(aboreDetector, Point(-height/2.0)) < 1.0
		@test_skip  geoEff(aboreDetector, Point(height/2.0)) ≈ geoEff(aboreDetector, Point(-height/2.0))

		@test_skip   0.0 < geoEff(aboreDetector, Point(height))  < 1.0
		@test_skip   0.0 < geoEff(aboreDetector, Point(-height)) < 1.0
		@test_skip   geoEff(aboreDetector, Point(height)) ≈ geoEff(aboreDetector, Point(-height))
		
		@test_skip   0.0 < geoEff(aboreDetector, Point(1.5*height))   < 1.0
		@test_skip   0.0 < geoEff(aboreDetector, Point(-1.5*height))  < 1.0
		@test_skip   geoEff(aboreDetector, Point(1.5*height)) ≈ geoEff(aboreDetector, Point(-1.5*height))
	end #testset_Borehole_detector


	@debug("special case - point at the surface of well detector")
	@testset "Well detectors of cryRadius $cryRadius and height $height, k $k" for 
	cryRadius = 1.0:0.5:11.0, 
	height    = 1.0:0.5:11.0, 
	k         = 1.1:0.5:11.0
		
	local holeradius::Float64 = cryRadius/k		# k > 1
	local welldepth::Float64 = height/k		# k > 1
	local awellDetector = WellDetector(cryRadius, height, holeradius, welldepth)

		@test geoEff(awellDetector, Point(welldepth)) ≈ 0.5
		@test geoEff(awellDetector, Point(welldepth, prevfloat(holeradius))) ≈ 0.5
		@test geoEff(awellDetector, Point(welldepth, nextfloat(-holeradius))) ≈ 0.5
		@test geoEff(awellDetector, Point(welldepth, holeradius/2.0)) ≈ 0.5
		@test geoEff(awellDetector, Point(welldepth, -holeradius/2.0)) ≈ 0.5

		@test geoEff(awellDetector, Point(nextfloat(welldepth))) ≈ 0.5
		@test geoEff(awellDetector, Point(nextfloat(welldepth), prevfloat(holeradius))) ≈ 0.5
		@test geoEff(awellDetector, Point(nextfloat(welldepth), prevfloat(-holeradius))) ≈ 0.5
		@test geoEff(awellDetector, Point(nextfloat(welldepth),  holeradius/2.0)) ≈ 0.5
		@test geoEff(awellDetector, Point(nextfloat(welldepth), -holeradius/2.0)) ≈ 0.5

	end #testset_Well_detector
end #testset_spectial_cases


@testset "scaling" begin

	@debug("scaling test - cylindrical detector with point source")
	@testset "[J=$j] test, Scaling $k at cryRadius=$cryRadius" for 
	cryRadius = [1,2,3,4,5,6,7,8,9,10.1,10.5,10.6],
	j=2:5:100, 	# j > 1
	k=2:5:100
		
		acylDetector  = CylDetector(  cryRadius)
		acylDetectork = CylDetector(k*cryRadius)
		axPnt  = Point(  cryRadius/j); naxPnt  = Point(  cryRadius/j,   cryRadius/j)
		axPntk = Point(k*cryRadius/j); naxPntk = Point(k*cryRadius/j, k*cryRadius/j)
		
		@test geoEff(acylDetector, axPnt)  ≈ geoEff(acylDetectork, axPntk)		# axial point
		@test geoEff(acylDetector, naxPnt) ≈ geoEff(acylDetectork, naxPntk)		# non-axial point
	end #testset_cylindrical_detector
	
	@debug("scaling test - Borehole detector with point source")
	@testset "cryRadius=$cryRadius, holeRadius=$holeRadius" for 
	cryRadius  = [1,2,3,4,5,6,7,8,9,10.1,10.5,10.6],
	holeRadius = [1,2,3,4,5,6,7,8,9,10.1,10.5,10.6]/2.2
	holeRadius > cryRadius && continue	
		
		for j=2:100, k=2:100
		aboreDetector  = BoreDetector(  cryRadius,   j,   holeRadius)
		aboreDetectork = BoreDetector(k*cryRadius, k*j, k*holeRadius)
		axPnt  = Point(  cryRadius/j); naxPnt  = Point(  cryRadius/j,   holeRadius/j)
		axPntk = Point(k*cryRadius/j); naxPntk = Point(k*cryRadius/j, k*holeRadius/j)
		
			@test geoEff(aboreDetector , axPnt)  ≈ geoEff(aboreDetectork, axPntk) atol= absoluteTol1	# axial point
			@test geoEff(aboreDetector , naxPnt) ≈ geoEff(aboreDetectork, naxPntk) atol= absoluteTol1	# non-axial point
		end #for
	end #testset_Borehole_detector


	@debug("scaling test - Well-type detector with point source")
	@testset "cryRadius=$cryRadius, holeRadius=$holeRadius" for 
	cryRadius  = [1,2,3,4,5,6,7,8,9,10.1,10.5,10.6],
	holeRadius = [1,2,3,4,5,6,7,8,9,10.1,10.5,10.6]/2.2
	holeRadius > cryRadius && continue	
		
		for j=2:5:100, k=2:5:100
			awellDetector  = WellDetector(  cryRadius,   j,   holeRadius,   j/2.0)
			awellDetectork = WellDetector(k*cryRadius, k*j, k*holeRadius, k*j/2.0)		
			axPnt  = Point(  cryRadius/j); naxPnt  = Point(  cryRadius/j,   holeRadius/j)
			axPntk = Point(k*cryRadius/j); naxPntk = Point(k*cryRadius/j, k*holeRadius/j)

			@test geoEff(awellDetector , axPnt)  ≈ geoEff(awellDetectork, axPntk) atol= absoluteTol2	# axial point
			@test geoEff(awellDetector , naxPnt) ≈ geoEff(awellDetectork, naxPntk) atol= absoluteTol2	# non-axial point
		end #for
	end #testset_Well-type_detector
end #tesset_scalling


@testset "geoEff-relaxed`" begin

	@testset "geoEff on CylDetector(5,$cryLength)" for 
	cryLength=[0,1,5,10]
	
		@test 0.0 < geoEff(Detector(5,cryLength),(Point(1),1, 1))    < 0.5
		@test 0.0 < geoEff(Detector(5,cryLength),(Point(1),1, 1//2)) < 0.5
		@test 0.0 < geoEff(Detector(5,cryLength),(Point(1),1, pi))   < 0.5
		@test 0.0 < geoEff(Detector(5,cryLength),(Point(1),1, 1.0))  < 0.5

		@test 0.0 < geoEff(Detector(5,cryLength),(Point(1),1//2, 1))    < 0.5
		@test 0.0 < geoEff(Detector(5,cryLength),(Point(1),1//2, 1//2)) < 0.5
		@test 0.0 < geoEff(Detector(5,cryLength),(Point(1),1//2, pi))   < 0.5
		@test 0.0 < geoEff(Detector(5,cryLength),(Point(1),1//2, 1.0))  < 0.5

		@test 0.0 < geoEff(Detector(5,cryLength),(Point(1),e, 1))    < 0.5
		@test 0.0 < geoEff(Detector(5,cryLength),(Point(1),e, 1//2)) < 0.5
		@test 0.0 < geoEff(Detector(5,cryLength),(Point(1),e, pi))   < 0.5 #
		@test 0.0 < geoEff(Detector(5,cryLength),(Point(1),e, 1.0))  < 0.5

		@test 0.0 < geoEff(Detector(5,cryLength),(Point(1),1.0, 1))    < 0.5
		@test 0.0 < geoEff(Detector(5,cryLength),(Point(1),1.0, 1//2)) < 0.5
		@test 0.0 < geoEff(Detector(5,cryLength),(Point(1),1.0, pi))   < 0.5
		@test 0.0 < geoEff(Detector(5,cryLength),(Point(1),1.0, 1.0))  < 0.5
     end #testset_CylDetector


	@testset "geoEff on WellDetector(5, 4, $holeRadius, $holeDepth)" for 
	holeRadius = 3:0.5:4, 
	holeDepth  = 0.1:1.0:3.1

	local (mim, mam) = holeDepth >= 1 ? (0.5, 1.0) : (0.0, 0.5)

		@test geoEff(Detector(5, 4, holeRadius, 1),(Point(1),0, 0)) ≈ 0.5 atol= absoluteTol1
		@test mim < geoEff(Detector(5, 4, holeRadius, holeDepth),(Point(1),0, 0))    < mam

		@test 0.0 < geoEff(Detector(5, 4, holeRadius, holeDepth),(Point(1),1, 1))    < 1.0
		@test 0.0 < geoEff(Detector(5, 4, holeRadius, holeDepth),(Point(1),1, 1//2)) < 1.0
		@test 0.0 < geoEff(Detector(5, 4, holeRadius, holeDepth),(Point(1),1, pi))   < 1.0
		@test 0.0 < geoEff(Detector(5, 4, holeRadius, holeDepth),(Point(1),1, 1.0))  < 1.0

		@test 0.0 < geoEff(Detector(5, 4, holeRadius, holeDepth),(Point(1),1//2, 1))    < 1.0
		@test 0.0 < geoEff(Detector(5, 4, holeRadius, holeDepth),(Point(1),1//2, 1//2)) < 1.0
		@test 0.0 < geoEff(Detector(5, 4, holeRadius, holeDepth),(Point(1),1//2, pi))   < 1.0
		@test 0.0 < geoEff(Detector(5, 4, holeRadius, holeDepth),(Point(1),1//2, 1.0))  < 1.0

		@test 0.0 < geoEff(Detector(5, 4, holeRadius, holeDepth),(Point(1),e, 1))    < 1.0
		@test 0.0 < geoEff(Detector(5, 4, holeRadius, holeDepth),(Point(1),e, 1//2)) < 1.0
		@test 0.0 < geoEff(Detector(5, 4, holeRadius, holeDepth),(Point(1),e, pi))   < 1.0
		@test 0.0 < geoEff(Detector(5, 4, holeRadius, holeDepth),(Point(1),e, 1.0))  < 1.0

		@test 0.0 < geoEff(Detector(5, 4, holeRadius, holeDepth),(Point(1),1.0, 1))    < 1.0
		@test 0.0 < geoEff(Detector(5, 4, holeRadius, holeDepth),(Point(1),1.0, 1//2)) < 1.0
		@test 0.0 < geoEff(Detector(5, 4, holeRadius, holeDepth),(Point(1),1.0, pi))   < 1.0
		@test 0.0 < geoEff(Detector(5, 4, holeRadius, holeDepth),(Point(1),1.0, 1.0))  < 1.0
	end #testset_WellDetector
end #testset_geoEff_relaxed
