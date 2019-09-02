include("../src/eis_series.jl")

function test_eis_series_length()
	print("eis_series.length...")
  
  @test length(eisenstein_series_poly(4, 5)) == 5
  @test length(eisenstein_series_poly(6, 500)) == 500
  @test length(eisenstein_series_poly(12, 1)) == 1
	println("PASS")
end

function test_eis_series_normalisation()
	print("eis_series.normalisation...")
  
  e4 = eisenstein_series_qexp(4, 5, QQ, "q", "linear")
  @test coeff(e4, 1) == 1
  @test coeff(e4, 0) == 1//240
  e6 = eisenstein_series_qexp(6, 5, QQ, "q", "constant")
  @test coeff(e6, 0) == 1
  @test coeff(e6, 1) == -504
  e12 = eisenstein_series_qexp(12, 5, ZZ, "q", "integral")
  @test coeff(e12, 0) == 691
  @test coeff(e12, 1) == 65520
	println("PASS")
end

function test_eis_series_coefficients()
	print("eis_series.coefficients...")
  
  e4 = eisenstein_series_qexp(4, 11, QQ, "q", "constant")
  S = parent(e4)
  q = gen(S)
  @test e4 - (1+240*q+2160*q^2+6720*q^3+17520*q^4+30240*q^5+60480*q^6+82560*q^7+140400*q^8+181680*q^9+272160*q^10+O(q^11)) == 0
  e6 = eisenstein_series_qexp(6, 11, ZZ, "q", "integral")
  S = parent(e6)
  q = gen(S)
  @test e6 - (1-504*q-16632*q^2-122976*q^3-532728*q^4-1575504*q^5-4058208*q^6-8471232*q^7-17047800*q^8-29883672*q^9-51991632*q^10+O(q^11)) == 0
  e12 = eisenstein_series_qexp(12, 11, QQ, "q", "linear")
  S = parent(e12)
  q = gen(S)
  @test e12 - (691//65520+q+2049*q^2+177148*q^3+4196353*q^4+48828126*q^5+362976252*q^6+1977326744*q^7+8594130945*q^8+31381236757*q^9+100048830174*q^10+O(q^11)) == 0
	println("PASS")
end

function test_eis_series()
	test_eis_series_length()
  test_eis_series_normalisation()
  test_eis_series_coefficients()

	println("")
end
