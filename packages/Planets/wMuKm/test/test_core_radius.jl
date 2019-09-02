tol = 1e-10
#
# Sanity check.
#
@test size(Planets.mr_table) == (91,42)
@test haskey(Planets.mr_table,:Mearth)
@test haskey(Planets.mr_table,:rocky)
@test haskey(Planets.mr_table,Symbol("5%fe"))
@test haskey(Planets.mr_table,Symbol("5%h2o"))

@test isa(Planets.mr_table[:Mearth][1], Float64)
@test Planets.mr_table[:Mearth][1] == 0.0625

#
# Test grid points, including edge cases.
#
@test abs(core_radius(0.07179, fe=0.0 )  -  0.4888) < tol
@test abs(core_radius(0.07179, h2o=0.0)  -  0.4888) < tol

@test abs(core_radius(0.07179, fe=1.0 )  -  0.3733) < tol
@test abs(core_radius(0.07179, fe=0.5 )  -  0.4394) < tol
@test abs(core_radius(0.07179, fe=0.05)  -  0.4841) < tol
@test abs(core_radius(0.07179, h2o=.05)  -  0.5041) < tol
@test abs(core_radius(0.07179, h2o=1.0)  -  0.6588) < tol

@test abs(core_radius(1.0, fe=1.0)  -  0.8228) < tol
@test abs(core_radius(1.0, fe=0.0)  -  1.0667) < tol
@test abs(core_radius(1.0, fe=.05)  -  1.0568) < tol
@test abs(core_radius(1.0, fe=0.1)  -  1.0466) < tol
@test abs(core_radius(1.0, fe=0.2)  -  1.0260) < tol
@test abs(core_radius(1.0, fe=0.3)  -  1.0050) < tol
@test abs(core_radius(1.0, fe=0.4)  -  0.9834) < tol
@test abs(core_radius(1.0, fe=.45)  -  0.9723) < tol
@test abs(core_radius(1.0, fe=.35)  -  0.9943) < tol
@test abs(core_radius(1.0, fe=1.0)  -  0.8228) < tol
#
# Test interpolation across columns.
#
@test abs(core_radius(1.0, fe=0.975)  -  0.83350) < tol
@test abs(core_radius(1.0, fe=0.025)  -  1.06175) < tol
#
# Test interpolation across rows.
#
@test abs(core_radius(1.0359, fe=1.0)  -  0.8307) < tol
#
# Test interpolation across columns AND rows.
#
@test abs(core_radius(1.035900, fe =0.975)  -  0.841525) < tol
@test abs(core_radius(0.064745, h2o=0.025)  -  0.480450) < tol
#
# Test extrapolation of mass.
#
M_small = 0.0625
R_small = core_radius(M_small, fe=0.3)
M_large = 32.0
R_large = core_radius(M_large, fe=0.3)
@test abs(core_radius(0.01, fe=0.3)  -  R_small * (0.01/M_small)^(1/3.7)) < tol
@test abs(core_radius(35.0, fe=0.3)  -  R_large * (35.0/M_large)^(1/3.7)) < tol

