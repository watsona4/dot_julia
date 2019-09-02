include("../src/eta_quotient.jl")
include("../src/eta_quotient_eigenforms.jl")

function test_eta_quotient_length()
   print("eta_quotient.length...")

   @test eta_quotient([[1,24]]).length == 10
   @test eta_quotient([[1,24]], 100).length == 100

   println("PASS")
end

function test_eta_quotient_correctness()
   print("eta_quotient.correctness...")

   for g in keys(ETA_QUOTIENT_EIGENFORM)
     eta = eta_quotient(g, 20)
     @test eta - ETA_QUOTIENT_EIGENFORM[g] == 0
   end

   eta1 = eta_quotient([[1,24]],100)
   @test eta1 - delta_qexp(100) == 0

   println("PASS")
end

function test_eta_quotient()
   test_eta_quotient_length()
   test_eta_quotient_correctness()

   println("")
end
