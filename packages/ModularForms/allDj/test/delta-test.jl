include("../src/delta.jl")

function test_delta_poly_length()
	print("delta_poly.length...")
	
	@test length(delta_poly(5)) == 5
	@test length(delta_poly(500)) == 500

	println("PASS")
end

function test_delta_poly_output()
	print("delta_poly.output...")

	R, q = PolynomialRing(ZZ, "q")
	delta_7 = 	q - 24q^2 + 252q^3 - 1472q^4 + 4830q^5 - 6048q^6
	delta_30 = 	q - 24q^2 + 252q^3 - 1472q^4 + 4830q^5 - 6048q^6 - 16744q^7 + 
			84480q^8 - 113643q^9 - 115920q^10 + 534612q^11 - 370944q^12 - 
			577738q^13 + 401856q^14 + 1217160q^15 + 987136q^16 - 6905934q^17 + 
			2727432q^18 + 10661420q^19 - 7109760q^20 - 4219488q^21 - 
			12830688q^22 + 18643272q^23 + 21288960q^24 - 25499225q^25 + 
			13865712q^26 - 73279080q^27 + 24647168q^28 + 128406630q^29
	@test delta_7 == delta_poly(7)
	@test delta_30 == delta_poly(30)

	println("PASS")
end

function test_delta_qexp_output()
	print("delta_qexp.output...")

	delta_5 = delta_qexp(5)
	S = parent(delta_5)
	q = gen(S)
  d5 = q - 24q^2 + 252q^3 - 1472q^4 + O(q^5)
	@test delta_5 - d5 == 0

	delta_45 = delta_qexp(45, "q")
	S = parent(delta_45)
	q = gen(S)
	d45 =	q - 24*q^2 + 252*q^3 - 1472*q^4 + 4830*q^5 - 6048*q^6 - 
		16744*q^7 + 84480*q^8 - 113643*q^9 - 115920*q^10 + 534612*q^11 - 
		370944*q^12 - 577738*q^13 + 401856*q^14 + 1217160*q^15 + 
		987136*q^16 - 6905934*q^17 + 2727432*q^18 + 10661420*q^19 - 
		7109760*q^20 - 4219488*q^21 - 12830688*q^22 + 18643272*q^23 + 
		21288960*q^24 - 25499225*q^25 + 13865712*q^26 - 73279080*q^27 + 
		24647168*q^28 + 128406630*q^29 - 29211840*q^30 - 52843168*q^31 - 
		196706304*q^32 + 134722224*q^33 + 165742416*q^34 - 
		80873520*q^35 + 167282496*q^36 - 182213314*q^37 - 255874080*q^38 - 
		145589976*q^39 + 408038400*q^40 + 308120442*q^41 + 
		101267712*q^42 - 17125708*q^43 - 786948864*q^44 + O(q^45)
	@test delta_45 - d45 == 0

	println("PASS")
end

function test_delta_qexp_var()
	print("delta_qexp.variable...")
	
	delta_x = delta_qexp(10, "x")
	S = parent(delta_x)
	x = gen(S)
	dx =	x - 24x^2 + 252x^3 - 1472x^4 + 4830x^5 - 6048x^6 - 
		16744x^7 + 84480x^8 - 113643x^9 + O(x^10)
	@test delta_x - dx == 0

	println("PASS")
end

function test_delta()
	test_delta_poly_length()
	test_delta_poly_output()
	test_delta_qexp_output()
	test_delta_qexp_var()

	println("")
end
