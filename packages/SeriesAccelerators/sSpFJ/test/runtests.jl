using SeriesAccelerators
using Test, BenchmarkTools
import SpecialFunctions: factorial

@testset "Shanks" begin
  summand(x, i) = Float64(x^i / factorial(BigInt(i)))
  accelerator = SeriesAccelerators.shanks
  @test exp(0.0) ≈ accelerator(i->summand(0.0, i), 0, 1)[1] rtol=sqrt(eps())
  @test exp(0.0) ≈ accelerator(i->summand(0.0, i), 0, 2)[1] rtol=sqrt(eps())
  @test exp(1.0) ≈ accelerator(i->summand(1.0, i), 0, 20)[1] rtol=sqrt(eps())
  @test exp(1.0) ≈ accelerator(i->summand(1.0, i), 1, 20)[1] rtol=sqrt(eps())
  @test exp(1.0) ≈ accelerator(i->summand(1.0, i))[1] rtol=sqrt(eps())
  x = -1.0
  @test exp(x) ≈ accelerator(i->summand(x, i), 1, 11)[1] rtol=sqrt(eps())
  @test exp(x) ≈ accelerator(i->summand(x, i))[1] rtol=sqrt(eps())
  x = -2.0
  @test exp(x) ≈ accelerator(i->summand(x, i), 1, 15)[1] rtol=sqrt(eps())
  @test exp(x) ≈ accelerator(i->summand(x, i))[1] rtol=sqrt(eps())
  x = 2.0
  @test exp(x) ≈ accelerator(i->summand(x, i), 0, 15)[1] rtol=sqrt(eps())
  @test exp(x) ≈ accelerator(i->summand(x, i))[1] rtol=sqrt(eps())
end

@testset "van Wijngaarden" begin
  summand(x, i) = x^i / factorial(Float64(i))
  accelerator = SeriesAccelerators.vanwijngaarden
  for x = [0.0, 1.0, -1.0], c ∈ 1:5, i ∈ 1:5
    j = c + i + 3
    result = accelerator(i->summand(x, i), i, j)[1]
  end
  @test exp(0.0) ≈ accelerator(i->summand(0.0, i), 5, 7)[1] rtol=sqrt(eps())
  @test exp(1.0) ≈ accelerator(i->summand(1.0, i), 8, 24)[1] rtol=sqrt(eps())
  @test exp(1.0) ≈ accelerator(i->summand(1.0, i))[1] rtol=sqrt(eps())
  x = -1.0
  @test exp(x) ≈ accelerator(i->summand(x, i), 10, 25)[1] rtol=sqrt(eps())
  @test exp(x) ≈ accelerator(i->summand(x, i))[1] rtol=sqrt(eps())
  x = -2.0
  @test exp(x) ≈ accelerator(i->summand(x, i), 10, 25)[1] rtol=sqrt(eps())
  @test exp(x) ≈ accelerator(i->summand(x, i))[1] rtol=sqrt(eps())
  x = 2.0
  @test exp(x) ≈ accelerator(i->summand(x, i), 10, 25)[1] rtol=sqrt(eps())
  @test exp(x) ≈ accelerator(i->summand(x, i))[1] rtol=sqrt(eps())
end

@testset "Vector results" begin
  summand(x, i) = Float64(x^i / factorial(BigInt(i)))
  accelerator = SeriesAccelerators.shanks
  result = accelerator(i->[summand(0.0, i), 2*summand(0.0, i)], 0, 1)[1]
  @test [exp(0.0), 2*exp(0.0)] ≈ result rtol=sqrt(eps())
  result = accelerator(i->[summand(0.0, i), 2*summand(0.0, i)])[1]
  @test [exp(0.0), 2*exp(0.0)] ≈ result rtol=sqrt(eps())
end

