include("../src/delta.jl")

function test_generators_coefficients()
   print("generators.coefficients...")

   delta12 = delta_k_qexp(12, 100)
   @test delta_qexp(100) - delta12 == 0

   delta16 = delta_k_qexp(16, 1)
   @test delta16 == 0

   delta16 = delta_k_qexp(16, 10)
   S = parent(delta16)
   q = gen(S)
   @test delta16 - (q+216*q^2-3348*q^3+13888*q^4+52110*q^5-723168*q^6+2822456*q^7-4078080*q^8-3139803*q^9+O(q^10)) == 0
  
   delta16 = delta_k_qexp(16, 100)
   @test coeff(delta16, 98) == 695238414190488
 
   delta18 = delta_k_qexp(18, 10)
   S = parent(delta18)
   q = gen(S)
   @test delta18 - (q - 528*q^2 - 4284*q^3 + 147712*q^4 - 1025850*q^5 + 2261952*q^6 + 3225992*q^7 - 8785920*q^8 - 110787507*q^9 + O(q^10)) == 0

   delta20 = delta_k_qexp(20, 10)
   S = parent(delta20)
   q = gen(S)
   @test delta20 - (q + 456*q^2 + 50652*q^3 - 316352*q^4 - 2377410*q^5 + 23097312*q^6 - 16917544*q^7 - 383331840*q^8 + 1403363637*q^9 + O(q^10)) == 0

   delta22 = delta_k_qexp(22, 10)
   S = parent(delta22)
   q = gen(S)
   @test delta22 - (q - 288*q^2 - 128844*q^3 - 2014208*q^4 + 21640950*q^5 + 37107072*q^6 - 768078808*q^7 + 1184071680*q^8 + 6140423133*q^9 + O(q^10)) == 0

   delta26 = delta_k_qexp(26, 10)
   S = parent(delta26)
   q = gen(S)
   @test delta26 - (q - 48*q^2 - 195804*q^3 - 33552128*q^4 - 741989850*q^5 + 9398592*q^6 + 39080597192*q^7 + 3221114880*q^8 - 808949403027*q^9 + O(q^10)) == 0

   println("PASS")
end

function test_generators()
   test_generators_coefficients()

   println("")
end
