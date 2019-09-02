include("../src/delta.jl")
include("../src/vm_basis.jl")
include("../src/hecke.jl")
include("../src/prime_range.jl")

function test_hecke_on_qexp()
   print("hecke.qexp...")
	
   delta = delta_qexp(100)
   h1 = hecke_operator_on_qexp(delta, 1, 12, 30)
   @test h1 - delta_qexp(30) == 0
   h2 = truncate(hecke_operator_on_qexp(delta, 3, 12, 10), 7)
   S = parent(h2)
   q = gen(S)
   @test h2 - (252q - 6048q^2 + 63504q^3 - 370944q^4 + 
               1217160q^5 - 1524096q^6 + O(q^7)) == 0

   println("PASS")
end

function test_hecke_on_basis()
   print("hecke.basis...")

   B = victor_miller_basis(32, 10, false)
   H_basis = hecke_operator_on_basis(B, 3, 32)
   b0, b1, b2 = B
   h0 = hecke_operator_on_qexp(b0, 3, 32)
   R = base_ring(h0)
   S = MatrixSpace(R, 3, 3)
   matrix = S([617673396283948 2611200 5615943999897600; 0 50220 965671206912; 0 432 17312940])

   println("PASS")
end

function test_hecke_vm()
   print("hecke.victormiller...")

   B = victor_miller_basis(24, 20, true)
   b1, b2 = B
   h1 = hecke_operator_on_qexp(b1, 3, 24, 7)
   S = parent(h1)
   q = gen(S)
   @test h1 == 195660*q - 982499328*q^2 + 85442803344*q^3 + 1302498570240*q^4 + 
               23514204375720*q^5 - 333538871869440*q^6 + O(q^7)
   h2 = hecke_operator_on_qexp(b2, 3, 24, 7)
   S = parent(h2)
   q = gen(S)
   @test h2 == -48*q + 143820*q^2 - 16295040*q^3 - 424520544*q^4 - 
               4306546080*q^5 + 67844160144*q^6 + O(q^7)

   #test hecke_operator_on_basis
   H_basis = hecke_operator_on_basis(B, 3, 24)
   R = base_ring(h1)
   S = MatrixSpace(R, 2, 2)
   matrix = S([195660 -982499328; -48 143820]) 	

   println("PASS")
end

function test_hecke()
   test_hecke_on_qexp()
   test_hecke_on_basis()
   test_hecke_vm()

   println("")
end

