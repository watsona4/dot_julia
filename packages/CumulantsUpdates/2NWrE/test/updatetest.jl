Random.seed!(43)

X = randn(100, 20)
Xup = rand(25, 20)
l = size(Xup, 1) + 1
Xprim = vcat(X, Xup)[l:end,:]
@testset "data updat" begin
  @test dataupdat(X, Xup) ≈ Xprim
end


@testset "moment updates" begin
  x = ones(6, 2)
  y = 2*ones(2,2)
  M3 = moment(x, 3)
  M4 = moment(x, 4)
  M3up = momentupdat(M3, x, y)
  @testset "simple test" begin
    Mup = moment(dataupdat(x,y),3)
    @test Array(Mup) ≈ Array(M3up)
  end
  @testset "moment array" begin
    Ma = momentarray(x, 4, 2)
    @test Array(Ma[3]) ≈ Array(M3)
    @test Array(Ma[4]) ≈ Array(M4)
    MM = momentupdat(Ma, x, y)
    @test Array(M3up) ≈Array(MM[3])
  end
end

@testset "moment exceptions" begin
  x = ones(10,4);
  y = 2*ones(5,3);
  m = moment(x, 3);
  @test_throws DimensionMismatch momentupdat(m, x, y)
  y = 2*ones(5,4)
  @test_throws DimensionMismatch momentupdat(m, x[:, 1:3], y)
  y = 2*ones(15,4)
  @test_throws BoundsError momentupdat(m, x, y)
end

@testset "moments to cumulants" begin
  m1 = moment(X, 1)
  m2 = moment(X, 2)
  m3 = moment(X, 3)
  m4 = moment(X, 4)
  m5 = moment(X, 5)
  c = cumulants(X, 5)
  m2c = [m1, m2, m3, m4, m5]
  @testset "moms2cums!" begin
    moms2cums!(m2c)
    @test Array(c[1]) ≈ Array(m2c[1])
    @test Array(c[2]) ≈ Array(m2c[2])
    @test Array(c[3]) ≈ Array(m2c[3])
    @test Array(c[4]) ≈ Array(m2c[4])
    @test Array(c[5]) ≈ Array(m2c[5])
  end
  @testset "cums2moms" begin
    mm = cums2moms(c);
    @test Array(mm[1]) ≈ Array(m1)
    @test Array(mm[2]) ≈ Array(m2)
    @test Array(mm[3]) ≈ Array(m3)
    @test Array(mm[4]) ≈ Array(m4)
    @test Array(mm[5]) ≈ Array(m5)
  end
end

@testset "simple cumulants update" begin
  x = ones(10, 3)
  y = 2*ones(2,3)
  s = DataMoments(x, 6, 2)
  c2 = cumulantsupdate!(s, y)
  xx = dataupdat(x,y)
  c3 = cumulants(xx, 6)
  @test Array(c2[1]) ≈ Array(c3[1])
  @test Array(c2[2]) ≈ Array(c3[2])
  @test Array(c2[3]) ≈ Array(c3[3])
  @test Array(c2[4]) ≈ Array(c3[4])
  @test Array(c2[5]) ≈ Array(c3[5])
  @test Array(c2[6]) ≈ Array(c3[6])
end


@testset "cumulants updates larger data" begin
    c = cumulants(X)
    Xp = dataupdat(X, Xup)
    s = DataMoments(X, 4, 4)
    C = cumulantsupdate!(s, Xup)
    @test s.X ≈ Xp
    @test s.b == 4
    @test s.d == 4
    @test Array(s.M[4]) ≈ Array(moment(Xp, 4))
    CC = cumulants(Xp, 4)
    @test Array(C[3]) ≈ Array(CC[3])
    @test Array(C[4]) ≈ Array(CC[4])
end


@testset "multiprocessing cumulants update" begin
  addprocs(2)
  eval(Expr(:toplevel, :(@everywhere using CumulantsUpdates)))
    Xp = dataupdat(X, Xup)
    s = DataMoments(X, 4, 4)
    C = cumulantsupdate!(s, Xup)
    @test s.X ≈ Xp
    @test s.b == 4
    @test s.d == 4
    @test Array(s.M[4]) ≈ Array(moment(Xp, 4))
    CC = cumulants(Xp, 4)
    @test Array(C[3]) ≈ Array(CC[3])
    @test Array(C[4]) ≈ Array(CC[4])
end

@testset "cumulants update exceptions" begin
  x = ones(10,4);
  y = 2*ones(5,3);
  s = DataMoments(x, 4, 2)
  @test_throws DimensionMismatch cumulantsupdate!(s, y)
  y = 2*ones(15,4)
  @test_throws BoundsError cumulantsupdate!(s, y)
  s1 = DataMoments(x[:, 1:3], 4, 2)
  y = 2*ones(5,4)
  @test_throws UndefVarError cumulantsupdat(s1, y)
end

@testset "save and load" begin
  x = ones(10,4);
  s = DataMoments(x, 4, 2)
  @test savedm(s, "/tmp/cumdata.jld2") == nothing
  s1 = loaddm("/tmp/cumdata.jld2")
  @test s1.X == s.X
  @test s1.d == s.d
  @test s1.b == s.b
  @test Array(s1.M[4]) == Array(s.M[4])
end
