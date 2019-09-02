include("../src/vm_basis.jl")

function test_vm_basis_length()
   print("vm_basis.length...")

   @test length(victor_miller_basis(12)) == dim_Mk(12)
   @test length(victor_miller_basis(12,10,true)) == dim_Sk(12)
   @test length(victor_miller_basis(32)) == dim_Mk(32)
   @test length(victor_miller_basis(32,10,true)) == dim_Sk(32)

   println("PASS")
end

function test_vm_basis_type()
   print("vm_basis.type...")

   @test typeof(victor_miller_basis(12)[1]) == fmpz_rel_series
   @test typeof(victor_miller_basis(32)[2]) == fmpz_rel_series 

   println("PASS")
end

function test_vm_basis_cusp()
   print("vm_basis.cusp...")

   vm1 = victor_miller_basis(36,10,true)
   @test coeff(vm1[1],0) == 0
   @test coeff(vm1[1],1) == 1

   vm2 = victor_miller_basis(36,10,false)
   @test coeff(vm2[1],0) == 1
   @test coeff(vm2[1],1) == 0

   println("PASS")
end

function test_vm_basis_correctness()
   print("vm_basis.correctness...")

   vm1 = victor_miller_basis(12,6,true) 
   S = parent(vm1[1])
   q = gen(S)
   @test vm1[1] - (q-24q^2+252q^3-1472q^4+4830q^5+O(q^6)) == 0

   vm2 = victor_miller_basis(24,6,false)
   S = parent(vm2[1])
   q = gen(S)
   @test vm2[1] - (1+52416000q^3+39007332000q^4+6609020221440q^5+O(q^6)) == 0
   @test vm2[2] - (q+195660q^3+12080128q^4+44656110q^5+O(q^6)) == 0 
   @test vm2[3] - (q^2-48q^3+1080q^4-15040q^5+O(q^6)) == 0

   vm3 = victor_miller_basis(32,6,false)
   S = parent(vm3[1])
   q = gen(S) 
   @test vm3[1] - (1+2611200q^3+19524758400q^4+19715347537920q^5+O(q^6)) == 0
   @test vm3[2] - (q+50220q^3+87866368q^4+18647219790q^5+O(q^6)) == 0
   @test vm3[3] - (q^2+432q^3+39960q^4-1418560q^5+O(q^6)) == 0

   println("PASS")
end

function test_vm_basis()
   test_vm_basis_length()
   test_vm_basis_type()
   test_vm_basis_cusp()
   test_vm_basis_correctness()

   println("")
end
