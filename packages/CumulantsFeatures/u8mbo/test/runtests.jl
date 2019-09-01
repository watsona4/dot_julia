using Test
using Distributed
using LinearAlgebra
using SymmetricTensors
using Cumulants
using CumulantsFeatures
using Combinatorics
using Distributed
using Random
using CumulantsUpdates
import CumulantsFeatures: reduceband, greedestep, unfoldsym, hosvdstep, greedesearchdata, mev, mormbased, hosvdapprox
import CumulantsFeatures: updatemoments

te = [-0.112639 0.124715 0.124715 0.268717 0.124715 0.268717 0.268717 0.046154]
st = (reshape(te, (2,2,2)))
mat = reshape(te[1:4], (2,2))
ar = reshape(collect(1.:27.),(3,3,3))

@testset "unfoldsym reduce" begin
  @test unfoldsym(st) == reshape(te, (2,4))
  stt = SymmetricTensor(st)
  @test unfoldsym(stt) == reshape(te, (2,4))*reshape(te, (2,4))'
  @test reduceband(ar, [true, false, false])  ≈ ones(Float64, (1,1,1))
  @test reduceband(ar, [true, true, true])  ≈ ar
end

Random.seed!(42)
a = rand(SymmetricTensor{Float64, 2}, 3)
b = rand(SymmetricTensor{Float64, 3}, 3)
testf(a,b,bool)= det(a[bool,bool])
@testset "optimisation" begin
  @testset "greedestep" begin
    g = greedestep(Array(a), Array(b), testf, [true, true, true])
    @test g[1] == [true, false, true]
    @test g[3] == 2
    @test g[2] ≈ 0.48918301293211774
  end
  @testset "greedesearch" begin
    g = greedesearchdata(a,b, testf, 3)
    @test g[1][1] == [true, false, true]
    @test g[2][1] == [false, false, true]
    @test g[3][1] == [false, false, false]
    @test g[1][2] ≈ 0.48918301293211774
    @test g[2][2] ≈ 0.9735659798036858
    @test g[3][2] == 1.0
    @test g[1][3] == 2
    @test g[2][3] == 1
    @test g[3][3] == 3
  end
end

@testset "target functions" begin
  Σ = [1. 0.5 0.5; 0.5 1. 0.5; 0.5 0.5 1.]
  @test mev(Σ, ones(2,2,2), [true, true, true]) == 0.5
  c3 = ones(3,3,3)
  @test hosvdapprox(Σ,c3, [true, true, true]) ≈ -33.905320329609154
  c4 = ones(3,3,3,3)
  @test hosvdapprox(Σ,c4, [true, true, true]) ≈ -30.23685187275532
  @test mormbased(Σ,c4, [true, true, true]) ≈ 2.
  c5 = ones(3,3,3,3,3)
  @test hosvdapprox(Σ,c5, [true, true, true]) ≈ -29.34097213814129
end

@testset "hosvdapprox additional tests" begin
  Random.seed!(42)
  c3 = rand(SymmetricTensor{Float64, 3}, 5)
  Σ = rand(SymmetricTensor{Float64, 2}, 5)
  m3 = unfoldsym(c3)
  @test size(m3) == (5,5)
  Σ = Array(Σ)
  @test hosvdapprox(Σ, Array(c3)) ≈ log(det(m3)^(1/2)/det(Σ)^(3/2))
  c4 = rand(SymmetricTensor{Float64, 4}, 5)
  m4 = unfoldsym(c4)
  @test size(m4) == (5,5)
  @test hosvdapprox(Σ, Array(c4)) ≈ log(det(m4)^(1/2)/det(Σ)^(4/2))
  c5 = rand(SymmetricTensor{Float64, 5}, 5)
  m5 = unfoldsym(c5)
  @test size(m5) == (5,5)
  @test hosvdapprox(Σ, Array(c5)) ≈ log(det(m5)^(1/2)/det(Σ)^(5/2))
end

@testset "cumfsel tests" begin
 Random.seed!(43)
  Σ = rand(SymmetricTensor{Float64, 2}, 5)
  c = 0.1*ones(5,5,5)
  c[1,1,1] = 20.
  c[2,2,2] = 10.
  c[3,3,3] = 10.
  for j in permutations([1,2,3])
      c[j...] = 20.
  end
  for j in permutations([1,2,2])
      c[j...] = 20.
  end
  for j in permutations([2,2,3])
      c[j...] = 10.
  end
  for j in permutations([1,3,3])
      c[j...] = 20.
  end
  c = SymmetricTensor(c)
  ret = cumfsel(Σ, c, "hosvd", 5)
  @test ret[3][1] == [true, true, false, false, false]
  @test ret[3][2] ≈ 7.943479150509705
  @test (x->x[3]).(ret) == [4, 5, 3, 2, 1] #from lest important to most important"
  retn = cumfsel(Σ, c, "norm", 4)
  @test retn[3][1] == [true, true, false, false, false]
  @test retn[3][2] ≈ 24.285620999564703
  @test (x->x[3]).(retn) == [4, 5, 3, 2]
  @test cumfsel(Σ, c, "mev", 5)[1][3] == 5
  @test cumfsel(Σ, 5)[1][3] == 5
  @test_throws AssertionError cumfsel(Σ, c, "mov", 5)
  @test_throws AssertionError cumfsel(Σ, c, "hosvd", 7)
  Random.seed!(42)
  x = rand(12,10);
  c = cumulants(x,4);
  f = cumfsel(c[2], c[4], "hosvd")
  @test f[9][1] == [false, false, false, false, false, false, true, false, false, false]
  @test f[9][3] == 9
  @test f[10][3] == 7
end

@testset "detectors" begin
  Random.seed!(42)
  x = vcat(rand(8,2), 5*rand(1,2), 30*rand(1,2))
  @test rxdetect(x, 0.9) == [false, false, false, false, false, false, false, false, false, true]
  @test hosvdc4detect(x, 4., 2; b=2) == [false, false, false, false, false, false, false, false, true, true]
  ls = fill(true, 10)
  ls1 = [true, true, true, true, true, true, true, true, false, false]
  c = cumulants(x, 4)
  @test hosvdstep(x, ls, 4., 2, c[4])[1] == ls1
  @test hosvdstep(x, ls, 3., 1, c[4])[2] ≈ 1.147775879385989
  @test hosvdstep(x, ls, 3., 2, c[4])[2] ≈ 1.2715241637233354
  c = cumulants(x[ls1,:], 4)
  @test hosvdstep(x, ls1, 4., 2, c[4])[1] == ls1
  @test hosvdstep(x, ls1, 4., 2, c[4])[2] ≈ 1.6105157709082383
  m = momentarray(x,4,2)
  m1, t1 = updatemoments(m, size(x,1), x, ls1, ls)
  @test t1 == 8
  @test Array(m1[4]) ≈ Array(moment(x[1:8,:], 4))
end

addprocs(3)
@everywhere using LinearAlgebra
@everywhere testf(a,b,bool)= det(a[bool,bool])
@everywhere using CumulantsFeatures
@testset "greedesearch parallel implementation" begin
  g = greedesearchdata(a,b, testf, 3)
  @test g[1][1] == [true, false, true]
  @test g[2][1] == [false, false, true]
  @test g[3][1] == [false, false, false]
  @test g[1][2] ≈ 0.48918301293211774
  @test g[2][2] ≈ 0.9735659798036858
  @test g[3][2] == 1.0
  @test g[1][3] == 2
  @test g[2][3] == 1
  @test g[3][3] == 3
end
