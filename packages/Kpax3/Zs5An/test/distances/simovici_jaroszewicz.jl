function test_simovici_jaroszewicz_distance()
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

  d = [1; 2; 3; 4; 5; 1]
  nd = [2; 1; 1; 1; 1; 0]
  kd = 5

  t = [1; 2; 3; 4; 5; 6]
  nt = [1; 1; 1; 1; 1; 1]
  kt = 6

  # β = 2.0
  @test Kpax3.distsj(u, nu, ku, u, nu, ku, v, β=2.0) == 0.0
  @test isapprox(Kpax3.distsj(u, nu, ku, a, na, ka, v, β=2.0), 0.5333333333333333)
  @test isapprox(Kpax3.distsj(u, nu, ku, b, nb, kb, v, β=2.0), 0.7999999999999999)
  @test isapprox(Kpax3.distsj(u, nu, ku, c, nc, kc, v, β=2.0), 0.8666666666666666)
  @test isapprox(Kpax3.distsj(u, nu, ku, d, nd, kd, v, β=2.0), 0.9333333333333333)
  @test isapprox(Kpax3.distsj(u, nu, ku, t, nt, kt, v, β=2.0), 1.0)

  @test Kpax3.distsjlower(nu, ku, v, β=2.0) == 0.0
  @test isapprox(Kpax3.distsjlower(na, ka, v, β=2.0), 0.5333333333333333)
  @test isapprox(Kpax3.distsjlower(nb, kb, v, β=2.0), 0.7999999999999999)
  @test isapprox(Kpax3.distsjlower(nc, kc, v, β=2.0), 0.8666666666666666)
  @test isapprox(Kpax3.distsjlower(nd, kd, v, β=2.0), 0.9333333333333333)
  @test isapprox(Kpax3.distsjlower(nt, kt, v, β=2.0), 1.0)

  @test Kpax3.distsj(a, na, ka, a, na, ka, v, β=2.0) == 0.0
  @test isapprox(Kpax3.distsj(a, na, ka, u, nu, ku, v, β=2.0), 0.5333333333333333)
  @test isapprox(Kpax3.distsj(a, na, ka, b, nb, kb, v, β=2.0), 0.5333333333333333)
  @test isapprox(Kpax3.distsj(a, na, ka, c, nc, kc, v, β=2.0), 0.4666666666666667)
  @test isapprox(Kpax3.distsj(a, na, ka, d, nd, kd, v, β=2.0), 0.5333333333333333)
  @test isapprox(Kpax3.distsj(a, na, ka, t, nt, kt, v, β=2.0), 0.4666666666666667)

  @test Kpax3.distsj(b, nb, kb, b, nb, kb, v, β=2.0) == 0.0
  @test isapprox(Kpax3.distsj(b, nb, kb, u, nu, ku, v, β=2.0), 0.7999999999999999)
  @test isapprox(Kpax3.distsj(b, nb, kb, a, na, ka, v, β=2.0), 0.5333333333333333)
  @test isapprox(Kpax3.distsj(b, nb, kb, c, nc, kc, v, β=2.0), 0.3333333333333333)
  @test isapprox(Kpax3.distsj(b, nb, kb, d, nd, kd, v, β=2.0), 0.2666666666666667)
  @test isapprox(Kpax3.distsj(b, nb, kb, t, nt, kt, v, β=2.0), 0.2)

  @test Kpax3.distsj(c, nc, kc, c, nc, kc, v, β=2.0) == 0.0
  @test isapprox(Kpax3.distsj(c, nc, kc, u, nu, ku, v, β=2.0), 0.8666666666666666)
  @test isapprox(Kpax3.distsj(c, nc, kc, a, na, ka, v, β=2.0), 0.4666666666666667)
  @test isapprox(Kpax3.distsj(c, nc, kc, b, nb, kb, v, β=2.0), 0.3333333333333333)
  @test isapprox(Kpax3.distsj(c, nc, kc, d, nd, kd, v, β=2.0), 0.2)
  @test isapprox(Kpax3.distsj(c, nc, kc, t, nt, kt, v, β=2.0), 0.1333333333333333)

  @test Kpax3.distsj(d, nd, kd, d, nd, kd, v, β=2.0) == 0.0
  @test isapprox(Kpax3.distsj(d, nd, kd, u, nu, ku, v, β=2.0), 0.9333333333333333)
  @test isapprox(Kpax3.distsj(d, nd, kd, a, na, ka, v, β=2.0), 0.5333333333333333)
  @test isapprox(Kpax3.distsj(d, nd, kd, b, nb, kb, v, β=2.0), 0.2666666666666667)
  @test isapprox(Kpax3.distsj(d, nd, kd, c, nc, kc, v, β=2.0), 0.2)
  @test isapprox(Kpax3.distsj(d, nd, kd, t, nt, kt, v, β=2.0), 0.0666666666666667)

  @test Kpax3.distsj(t, nt, kt, t, nt, kt, v, β=2.0) == 0.0
  @test isapprox(Kpax3.distsj(t, nt, kt, u, nu, ku, v, β=2.0), 1.0)
  @test isapprox(Kpax3.distsj(t, nt, kt, a, na, ka, v, β=2.0), 0.4666666666666667)
  @test isapprox(Kpax3.distsj(t, nt, kt, b, nb, kb, v, β=2.0), 0.2)
  @test isapprox(Kpax3.distsj(t, nt, kt, c, nc, kc, v, β=2.0), 0.1333333333333333)
  @test isapprox(Kpax3.distsj(t, nt, kt, d, nd, kd, v, β=2.0), 0.0666666666666667)

  @test Kpax3.distsjupper(nt, kt, v, β=2.0) == 0.0
  @test isapprox(Kpax3.distsjupper(nu, ku, v, β=2.0), 1.0)
  @test isapprox(Kpax3.distsjupper(na, ka, v, β=2.0), 0.4666666666666667)
  @test isapprox(Kpax3.distsjupper(nb, kb, v, β=2.0), 0.2)
  @test isapprox(Kpax3.distsjupper(nc, kc, v, β=2.0), 0.1333333333333333)
  @test isapprox(Kpax3.distsjupper(nd, kd, v, β=2.0), 0.0666666666666667)

  @test Kpax3.distsj(u, nu, ku, t, nt, kt, v, β=2.0) <= (Kpax3.distsj(u, nu, ku, b, nb, kb, v, β=2.0) + Kpax3.distsj(b, nb, kb, t, nt, kt, v, β=2.0))
  @test Kpax3.distsj(a, na, ka, b, nb, kb, v, β=2.0) <= (Kpax3.distsj(a, na, ka, c, nc, kc, v, β=2.0) + Kpax3.distsj(c, nc, kc, b, nb, kb, v, β=2.0))
  @test Kpax3.distsj(b, nb, kb, c, nc, kc, v, β=2.0) <= (Kpax3.distsj(b, nb, kb, d, nd, kd, v, β=2.0) + Kpax3.distsj(d, nd, kd, c, nc, kc, v, β=2.0))
  @test Kpax3.distsj(c, nc, kc, d, nd, kd, v, β=2.0) <= (Kpax3.distsj(c, nc, kc, a, na, ka, v, β=2.0) + Kpax3.distsj(a, na, ka, d, nd, kd, v, β=2.0))
  @test Kpax3.distsj(a, na, ka, b, nb, kb, v, β=2.0) <= (Kpax3.distsj(a, na, ka, u, nu, ku, v, β=2.0) + Kpax3.distsj(u, nu, ku, b, nb, kb, v, β=2.0))
  @test Kpax3.distsj(a, na, ka, b, nb, kb, v, β=2.0) <= (Kpax3.distsj(a, na, ka, t, nt, kt, v, β=2.0) + Kpax3.distsj(t, nt, kt, b, nb, kb, v, β=2.0))
  @test Kpax3.distsj(a, na, ka, d, nd, kd, v, β=2.0) <= (Kpax3.distsj(a, na, ka, u, nu, ku, v, β=2.0) + Kpax3.distsj(u, nu, ku, d, nd, kd, v, β=2.0))
  @test Kpax3.distsj(a, na, ka, d, nd, kd, v, β=2.0) <= (Kpax3.distsj(a, na, ka, t, nt, kt, v, β=2.0) + Kpax3.distsj(t, nt, kt, d, nd, kd, v, β=2.0))

  # β = 3.0
  @test Kpax3.distsj(u, nu, ku, u, nu, ku, v, β=3.0) == 0.0
  @test isapprox(Kpax3.distsj(u, nu, ku, a, na, ka, v, β=3.0), 0.6857142857142857)
  @test isapprox(Kpax3.distsj(u, nu, ku, b, nb, kb, v, β=3.0), 0.9142857142857143)
  @test isapprox(Kpax3.distsj(u, nu, ku, c, nc, kc, v, β=3.0), 0.9428571428571429)
  @test isapprox(Kpax3.distsj(u, nu, ku, d, nd, kd, v, β=3.0), 0.9714285714285714)
  @test isapprox(Kpax3.distsj(u, nu, ku, t, nt, kt, v, β=3.0), 1.0)

  @test Kpax3.distsjlower(nu, ku, v, β=3.0) == 0.0
  @test isapprox(Kpax3.distsjlower(na, ka, v, β=3.0), 0.68571428571428572063)
  @test isapprox(Kpax3.distsjlower(nb, kb, v, β=3.0), 0.91428571428571425717)
  @test isapprox(Kpax3.distsjlower(nc, kc, v, β=3.0), 0.94285714285714294913)
  @test isapprox(Kpax3.distsjlower(nd, kd, v, β=3.0), 0.97142857142857141906)
  @test isapprox(Kpax3.distsjlower(nt, kt, v, β=3.0), 1.0)

  @test Kpax3.distsj(a, na, ka, a, na, ka, v, β=3.0) == 0.0
  @test isapprox(Kpax3.distsj(a, na, ka, u, nu, ku, v, β=3.0), 0.6857142857142857)
  @test isapprox(Kpax3.distsj(a, na, ka, b, nb, kb, v, β=3.0), 0.3428571428571429)
  @test isapprox(Kpax3.distsj(a, na, ka, c, nc, kc, v, β=3.0), 0.3142857142857143)
  @test isapprox(Kpax3.distsj(a, na, ka, d, nd, kd, v, β=3.0), 0.3428571428571429)
  @test isapprox(Kpax3.distsj(a, na, ka, t, nt, kt, v, β=3.0), 0.3142857142857143)

  @test Kpax3.distsj(b, nb, kb, b, nb, kb, v, β=3.0) == 0.0
  @test isapprox(Kpax3.distsj(b, nb, kb, u, nu, ku, v, β=3.0), 0.9142857142857143)
  @test isapprox(Kpax3.distsj(b, nb, kb, a, na, ka, v, β=3.0), 0.3428571428571429)
  @test isapprox(Kpax3.distsj(b, nb, kb, c, nc, kc, v, β=3.0), 0.1428571428571429)
  @test isapprox(Kpax3.distsj(b, nb, kb, d, nd, kd, v, β=3.0), 0.1142857142857143)
  @test isapprox(Kpax3.distsj(b, nb, kb, t, nt, kt, v, β=3.0), 0.0857142857142857)

  @test Kpax3.distsj(c, nc, kc, c, nc, kc, v, β=3.0) == 0.0
  @test isapprox(Kpax3.distsj(c, nc, kc, u, nu, ku, v, β=3.0), 0.9428571428571429)
  @test isapprox(Kpax3.distsj(c, nc, kc, a, na, ka, v, β=3.0), 0.3142857142857143)
  @test isapprox(Kpax3.distsj(c, nc, kc, b, nb, kb, v, β=3.0), 0.1428571428571429)
  @test isapprox(Kpax3.distsj(c, nc, kc, d, nd, kd, v, β=3.0), 0.0857142857142857)
  @test isapprox(Kpax3.distsj(c, nc, kc, t, nt, kt, v, β=3.0), 0.0571428571428571)

  @test Kpax3.distsj(d, nd, kd, d, nd, kd, v, β=3.0) == 0.0
  @test isapprox(Kpax3.distsj(d, nd, kd, u, nu, ku, v, β=3.0), 0.9714285714285714)
  @test isapprox(Kpax3.distsj(d, nd, kd, a, na, ka, v, β=3.0), 0.3428571428571429)
  @test isapprox(Kpax3.distsj(d, nd, kd, b, nb, kb, v, β=3.0), 0.1142857142857143)
  @test isapprox(Kpax3.distsj(d, nd, kd, c, nc, kc, v, β=3.0), 0.0857142857142857)
  @test isapprox(Kpax3.distsj(d, nd, kd, t, nt, kt, v, β=3.0), 0.0285714285714286)

  @test Kpax3.distsj(t, nt, kt, t, nt, kt, v, β=3.0) == 0.0
  @test isapprox(Kpax3.distsj(t, nt, kt, u, nu, ku, v, β=3.0), 1.0)
  @test isapprox(Kpax3.distsj(t, nt, kt, a, na, ka, v, β=3.0), 0.3142857142857143)
  @test isapprox(Kpax3.distsj(t, nt, kt, b, nb, kb, v, β=3.0), 0.0857142857142857)
  @test isapprox(Kpax3.distsj(t, nt, kt, c, nc, kc, v, β=3.0), 0.0571428571428571)
  @test isapprox(Kpax3.distsj(t, nt, kt, d, nd, kd, v, β=3.0), 0.0285714285714286)

  @test Kpax3.distsjupper(nt, kt, v, β=3.0) == 0.0
  @test isapprox(Kpax3.distsjupper(nu, ku, v, β=3.0), 1.0)
  @test isapprox(Kpax3.distsjupper(na, ka, v, β=3.0), 0.3142857142857143)
  @test isapprox(Kpax3.distsjupper(nb, kb, v, β=3.0), 0.0857142857142857)
  @test isapprox(Kpax3.distsjupper(nc, kc, v, β=3.0), 0.0571428571428571)
  @test isapprox(Kpax3.distsjupper(nd, kd, v, β=3.0), 0.0285714285714286)

  @test Kpax3.distsj(u, nu, ku, t, nt, kt, v, β=3.0) <= (Kpax3.distsj(u, nu, ku, b, nb, kb, v, β=3.0) + Kpax3.distsj(b, nb, kb, t, nt, kt, v, β=3.0))
  @test Kpax3.distsj(a, na, ka, b, nb, kb, v, β=3.0) <= (Kpax3.distsj(a, na, ka, c, nc, kc, v, β=3.0) + Kpax3.distsj(c, nc, kc, b, nb, kb, v, β=3.0))
  @test Kpax3.distsj(b, nb, kb, c, nc, kc, v, β=3.0) <= (Kpax3.distsj(b, nb, kb, d, nd, kd, v, β=3.0) + Kpax3.distsj(d, nd, kd, c, nc, kc, v, β=3.0))
  @test Kpax3.distsj(c, nc, kc, d, nd, kd, v, β=3.0) <= (Kpax3.distsj(c, nc, kc, a, na, ka, v, β=3.0) + Kpax3.distsj(a, na, ka, d, nd, kd, v, β=3.0))
  @test Kpax3.distsj(a, na, ka, b, nb, kb, v, β=3.0) <= (Kpax3.distsj(a, na, ka, u, nu, ku, v, β=3.0) + Kpax3.distsj(u, nu, ku, b, nb, kb, v, β=3.0))
  @test Kpax3.distsj(a, na, ka, b, nb, kb, v, β=3.0) <= (Kpax3.distsj(a, na, ka, t, nt, kt, v, β=3.0) + Kpax3.distsj(t, nt, kt, b, nb, kb, v, β=3.0))
  @test Kpax3.distsj(a, na, ka, d, nd, kd, v, β=3.0) <= (Kpax3.distsj(a, na, ka, u, nu, ku, v, β=3.0) + Kpax3.distsj(u, nu, ku, d, nd, kd, v, β=3.0))
  @test Kpax3.distsj(a, na, ka, d, nd, kd, v, β=3.0) <= (Kpax3.distsj(a, na, ka, t, nt, kt, v, β=3.0) + Kpax3.distsj(t, nt, kt, d, nd, kd, v, β=3.0))

  nothing
end

test_simovici_jaroszewicz_distance()
