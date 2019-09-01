using FameSVD
using LinearAlgebra
using Test

@testset "fsvd test for $T" for T in (Float32, Float64)
  A = randn(T, 100, 100)
  x = fsvd(A)

  tol = T == Float32 ? 1e-5 : 1e-10
  @test (norm(A - (x.U * diagm(0 => x.S) * x.V'), 2) / norm(A, 2)) <= tol
end
