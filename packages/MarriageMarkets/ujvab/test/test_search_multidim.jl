# uses variables from setup_tests.jl

# check symmetry
@test srmgmkt.u_m ≈ srmgmkt.u_f #expected symmetry of singles

# check that supermodular surplus results in positive assortative matching
@test srmgmkt.α[1,1,1,1] + srmgmkt.α[end,end,end,end] >
      srmgmkt.α[1,1,end,end] + srmgmkt.α[end,end,1,1] #expected positive assortativity

