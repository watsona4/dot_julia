function test_jaccard_distance()
  v = 6

  u = [1; 1; 1; 1; 1; 1]
  nu = [6; 0; 0; 0; 0; 0]
  ku = 1

  a = [1; 1; 1; 1; 2; 2]
  na = [4; 2; 0; 0; 0; 0]
  ka = 2

  b = [1; 2; 3; 1; 2; 3]
  nb = [2; 2; 2; 0; 0; 0]
  kb = 3

  c = [1; 1; 2; 3; 4; 3]
  nc = [2; 1; 2; 1; 0; 0]
  kc = 4

  d = [1; 1; 2; 3; 4; 5]
  nd = [2; 1; 1; 1; 1; 0]
  kd = 5

  t = [1; 2; 3; 4; 5; 6]
  nt = [1; 1; 1; 1; 1; 1]
  kt = 6

  @test Kpax3.jaccard(u, ku, u, ku, v) == 0.0
  @test Kpax3.jaccard_index_basic(u, u, v) == 1.0
  @test Kpax3.jaccard_index_table(u, ku, u, ku, v) == 1.0

  @test isapprox(Kpax3.jaccard(u, ku, a, ka, v), 0.5333333333333333)
  @test isapprox(Kpax3.jaccard(u, ku, b, kb, v), 0.8)
  @test isapprox(Kpax3.jaccard(u, ku, c, kc, v), 0.8666666666666667)
  @test isapprox(Kpax3.jaccard(u, ku, d, kd, v), 0.9333333333333333)
  @test isapprox(Kpax3.jaccard(u, ku, t, kt, v), 1.0)

  @test isapprox(Kpax3.jaccard_index_basic(u, a, v), 0.4666666666666667)
  @test isapprox(Kpax3.jaccard_index_basic(u, b, v), 0.2)
  @test isapprox(Kpax3.jaccard_index_basic(u, c, v), 0.1333333333333333)
  @test isapprox(Kpax3.jaccard_index_basic(u, d, v), 0.0666666666666667)
  @test isapprox(Kpax3.jaccard_index_basic(u, t, v), 0.0)

  @test isapprox(Kpax3.jaccard_index_table(u, ku, a, ka, v), 0.4666666666666667)
  @test isapprox(Kpax3.jaccard_index_table(u, ku, b, kb, v), 0.2)
  @test isapprox(Kpax3.jaccard_index_table(u, ku, c, kc, v), 0.1333333333333333)
  @test isapprox(Kpax3.jaccard_index_table(u, ku, d, kd, v), 0.0666666666666667)
  @test isapprox(Kpax3.jaccard_index_table(u, ku, t, kt, v), 0.0)

  @test isapprox(Kpax3.jaccardlower(na, ka, v), 0.5333333333333333)
  @test isapprox(Kpax3.jaccardlower(nb, kb, v), 0.8)
  @test isapprox(Kpax3.jaccardlower(nc, kc, v), 0.8666666666666667)
  @test isapprox(Kpax3.jaccardlower(nd, kd, v), 0.9333333333333333)
  @test isapprox(Kpax3.jaccardlower(nt, kt, v), 1.0)

  @test Kpax3.jaccard(a, ka, a, ka, v) == 0.0
  @test Kpax3.jaccard_index_basic(a, a, v) == 1.0
  @test Kpax3.jaccard_index_table(a, ka, a, ka, v) == 1.0

  @test isapprox(Kpax3.jaccard(a, ka, u, ku, v), 0.5333333333333333)
  @test isapprox(Kpax3.jaccard(a, ka, b, kb, v), 0.8888888888888889)
  @test isapprox(Kpax3.jaccard(a, ka, c, kc, v), 0.875)
  @test isapprox(Kpax3.jaccard(a, ka, d, kd, v), 0.8571428571428572)
  @test isapprox(Kpax3.jaccard(a, ka, t, kt, v), 1.0)

  @test isapprox(Kpax3.jaccard_index_basic(a, u, v), 0.4666666666666667)
  @test isapprox(Kpax3.jaccard_index_basic(a, b, v), 0.1111111111111111)
  @test isapprox(Kpax3.jaccard_index_basic(a, c, v), 0.125)
  @test isapprox(Kpax3.jaccard_index_basic(a, d, v), 0.1428571428571428)
  @test isapprox(Kpax3.jaccard_index_basic(a, t, v), 0.0)

  @test isapprox(Kpax3.jaccard_index_table(a, ka, u, ku, v), 0.4666666666666667)
  @test isapprox(Kpax3.jaccard_index_table(a, ka, b, kb, v), 0.1111111111111111)
  @test isapprox(Kpax3.jaccard_index_table(a, ka, c, kc, v), 0.125)
  @test isapprox(Kpax3.jaccard_index_table(a, ka, d, kd, v), 0.1428571428571428)
  @test isapprox(Kpax3.jaccard_index_table(a, ka, t, kt, v), 0.0)

  @test Kpax3.jaccard(b, kb, b, kb, v) == 0.0
  @test Kpax3.jaccard_index_basic(b, b, v) == 1.0
  @test Kpax3.jaccard_index_table(b, kb, b, kb, v) == 1.0

  @test isapprox(Kpax3.jaccard(b, kb, u, ku, v), 0.8)
  @test isapprox(Kpax3.jaccard(b, kb, a, ka, v), 0.8888888888888889)
  @test isapprox(Kpax3.jaccard(b, kb, c, kc, v), 1.0)
  @test isapprox(Kpax3.jaccard(b, kb, d, kd, v), 1.0)
  @test isapprox(Kpax3.jaccard(b, kb, t, kt, v), 1.0)

  @test isapprox(Kpax3.jaccard_index_basic(b, u, v), 0.2)
  @test isapprox(Kpax3.jaccard_index_basic(b, a, v), 0.1111111111111111)
  @test isapprox(Kpax3.jaccard_index_basic(b, c, v), 0.0)
  @test isapprox(Kpax3.jaccard_index_basic(b, d, v), 0.0)
  @test isapprox(Kpax3.jaccard_index_basic(b, t, v), 0.0)

  @test isapprox(Kpax3.jaccard_index_table(b, kb, u, ku, v), 0.2)
  @test isapprox(Kpax3.jaccard_index_table(b, kb, a, ka, v), 0.1111111111111111)
  @test isapprox(Kpax3.jaccard_index_table(b, kb, c, kc, v), 0.0)
  @test isapprox(Kpax3.jaccard_index_table(b, kb, d, kd, v), 0.0)
  @test isapprox(Kpax3.jaccard_index_table(b, kb, t, kt, v), 0.0)

  @test Kpax3.jaccard(c, kc, c, kc, v) == 0.0
  @test Kpax3.jaccard_index_basic(c, c, v) == 1.0
  @test Kpax3.jaccard_index_table(c, kc, c, kc, v) == 1.0

  @test isapprox(Kpax3.jaccard(c, kc, u, ku, v), 0.8666666666666667)
  @test isapprox(Kpax3.jaccard(c, kc, a, ka, v), 0.875)
  @test isapprox(Kpax3.jaccard(c, kc, b, kb, v), 1.0)
  @test isapprox(Kpax3.jaccard(c, kc, d, kd, v), 0.5)
  @test isapprox(Kpax3.jaccard(c, kc, t, kt, v), 1.0)

  @test isapprox(Kpax3.jaccard_index_basic(c, u, v), 0.1333333333333333)
  @test isapprox(Kpax3.jaccard_index_basic(c, a, v), 0.125)
  @test isapprox(Kpax3.jaccard_index_basic(c, b, v), 0.0)
  @test isapprox(Kpax3.jaccard_index_basic(c, d, v), 0.5)
  @test isapprox(Kpax3.jaccard_index_basic(c, t, v), 0.0)

  @test isapprox(Kpax3.jaccard_index_table(c, kc, u, ku, v), 0.1333333333333333)
  @test isapprox(Kpax3.jaccard_index_table(c, kc, a, ka, v), 0.125)
  @test isapprox(Kpax3.jaccard_index_table(c, kc, b, kb, v), 0.0)
  @test isapprox(Kpax3.jaccard_index_table(c, kc, d, kd, v), 0.5)
  @test isapprox(Kpax3.jaccard_index_table(c, kc, t, kt, v), 0.0)

  @test Kpax3.jaccard(d, kd, d, kd, v) == 0.0
  @test Kpax3.jaccard_index_basic(d, d, v) == 1.0
  @test Kpax3.jaccard_index_table(d, kd, d, kd, v) == 1.0

  @test isapprox(Kpax3.jaccard(d, kd, u, ku, v), 0.9333333333333333)
  @test isapprox(Kpax3.jaccard(d, kd, a, ka, v), 0.8571428571428572)
  @test isapprox(Kpax3.jaccard(d, kd, b, kb, v), 1.0)
  @test isapprox(Kpax3.jaccard(d, kd, c, kc, v), 0.5)
  @test isapprox(Kpax3.jaccard(d, kd, t, kt, v), 1.0)

  @test isapprox(Kpax3.jaccard_index_basic(d, u, v), 0.0666666666666667)
  @test isapprox(Kpax3.jaccard_index_basic(d, a, v), 0.1428571428571428)
  @test isapprox(Kpax3.jaccard_index_basic(d, b, v), 0.0)
  @test isapprox(Kpax3.jaccard_index_basic(d, c, v), 0.5)
  @test isapprox(Kpax3.jaccard_index_basic(d, t, v), 0.0)

  @test isapprox(Kpax3.jaccard_index_table(d, kd, u, ku, v), 0.0666666666666667)
  @test isapprox(Kpax3.jaccard_index_table(d, kd, a, ka, v), 0.1428571428571428)
  @test isapprox(Kpax3.jaccard_index_table(d, kd, b, kb, v), 0.0)
  @test isapprox(Kpax3.jaccard_index_table(d, kd, c, kc, v), 0.5)
  @test isapprox(Kpax3.jaccard_index_table(d, kd, t, kt, v), 0.0)

  @test Kpax3.jaccard(t, kt, t, kt, v) == 0.0
  @test Kpax3.jaccard_index_basic(t, t, v) == 1.0
  @test Kpax3.jaccard_index_table(t, kt, t, kt, v) == 1.0

  @test isapprox(Kpax3.jaccard(t, kt, u, ku, v), 1.0)
  @test isapprox(Kpax3.jaccard(t, kt, a, ka, v), 1.0)
  @test isapprox(Kpax3.jaccard(t, kt, b, kb, v), 1.0)
  @test isapprox(Kpax3.jaccard(t, kt, c, kc, v), 1.0)
  @test isapprox(Kpax3.jaccard(t, kt, d, kd, v), 1.0)

  @test isapprox(Kpax3.jaccard_index_basic(t, u, v), 0.0)
  @test isapprox(Kpax3.jaccard_index_basic(t, a, v), 0.0)
  @test isapprox(Kpax3.jaccard_index_basic(t, b, v), 0.0)
  @test isapprox(Kpax3.jaccard_index_basic(t, c, v), 0.0)
  @test isapprox(Kpax3.jaccard_index_basic(t, d, v), 0.0)

  @test isapprox(Kpax3.jaccard_index_table(t, kt, u, ku, v), 0.0)
  @test isapprox(Kpax3.jaccard_index_table(t, kt, a, ka, v), 0.0)
  @test isapprox(Kpax3.jaccard_index_table(t, kt, b, kb, v), 0.0)
  @test isapprox(Kpax3.jaccard_index_table(t, kt, c, kc, v), 0.0)
  @test isapprox(Kpax3.jaccard_index_table(t, kt, d, kd, v), 0.0)

  @test Kpax3.jaccard(u, ku, t, kt, v) <= (Kpax3.jaccard(u, ku, b, kb, v) + Kpax3.jaccard(b, kb, t, kt, v))
  @test Kpax3.jaccard(a, ka, b, kb, v) <= (Kpax3.jaccard(a, ka, c, kc, v) + Kpax3.jaccard(c, kc, b, kb, v))
  @test Kpax3.jaccard(b, kb, c, kc, v) <= (Kpax3.jaccard(b, kb, d, kd, v) + Kpax3.jaccard(d, kd, c, kc, v))
  @test Kpax3.jaccard(c, kc, d, kd, v) <= (Kpax3.jaccard(c, kc, a, ka, v) + Kpax3.jaccard(a, ka, d, kd, v))
  @test Kpax3.jaccard(a, ka, b, kb, v) <= (Kpax3.jaccard(a, ka, u, ku, v) + Kpax3.jaccard(u, ku, b, kb, v))
  @test Kpax3.jaccard(a, ka, b, kb, v) <= (Kpax3.jaccard(a, ka, t, kt, v) + Kpax3.jaccard(t, kt, b, kb, v))
  @test Kpax3.jaccard(a, ka, d, kd, v) <= (Kpax3.jaccard(a, ka, u, ku, v) + Kpax3.jaccard(u, ku, d, kd, v))
  @test Kpax3.jaccard(a, ka, d, kd, v) <= (Kpax3.jaccard(a, ka, t, kt, v) + Kpax3.jaccard(t, kt, d, kd, v))

  nothing
end

test_jaccard_distance()
