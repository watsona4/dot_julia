include("../src/vm_basis.jl")

function test_dim_Sk()
   print("dimensions.Sk...")

   for k in [-2, 0, 2, 3, 4, 6, 8, 10, 14]
      @test dim_Sk(k) == 0
   end

   for k in [12, 16, 18, 20, 22, 26]
      @test dim_Sk(k) == 1
   end

   @test dim_Sk(24) == 2

   println("PASS")
end

function test_dim_Mk()
   print("dimensions.Mk...")

   for k in [-2, 2, 3]
      @test dim_Mk(k) == 0
   end

   for k in [0, 4, 6, 8, 10, 14]
      @test dim_Mk(k) == 1          
   end

   for k in [12, 16, 18, 20, 22, 26]
      @test dim_Mk(k) == 2
   end

   @test dim_Mk(24) == 3

   println("PASS")
end

function test_dimensions()
   test_dim_Sk()
   test_dim_Mk()

   println("")
end
