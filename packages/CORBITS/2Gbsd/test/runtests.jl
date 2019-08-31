#!/usr/bin/env julia
 
using Test
 
# write your own tests here
@test 1 == 1

using CORBITS

function test_corbits()
  #@compat is_windows() ? error("# CORBITS won't work on windows") : nothing
  a =  Cdouble[0.05, 0.15]
  r_star = convert(Cdouble,0.005)
  r = Cdouble[0.0001,0.0001]
  ecc = Cdouble[0.02, 0.1]
  Omega = Cdouble[0.0, 0.0]
  omega = Cdouble[ 0.0, 0.5]
  inc = Cdouble[pi/2, pi/2]
  use_pl = Cint[1,1]
  prob_of_transits_approx(a, r_star, r, ecc, Omega, omega, inc, use_pl)
end

isapprox(test_corbits(), 0.03367003367003367, atol= 0.0001)

