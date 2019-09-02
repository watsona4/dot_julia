## Morikawa and Fujiwara 2013 GMPE tests
@testset "Morikawa and Fujiwara 2013 GMPE PGA" begin
  # init model parameters
  include("../examples/morikawa-fujiwara-2013.conf")
  ## PGA at epicenter on grid M7.0, Dl = 250 (constant)
  @test gmpe_mf2013(eq_7,config_mf2013_crustal_pga,grid_epicenter)[1].pga == 53.28
  ## PGA,PGV,PSA on grid, M6, ASID false, Dl - constant
  S_c = gmpe_mf2013(eq_6,config_mf2013_crustal_pga,grid)
  @test length(S_c) == TEST_GRID_SIZE
  @test typeof(S_c) == Array{GroundMotion.Point_pga_out,1}
  @test round(sum([S_c[i].pga for i=1:length(S_c)]),digits=2) == 3.4
  S_c = gmpe_mf2013(eq_6,config_mf2013_crustal_pgv,grid)
  @test typeof(S_c) == Array{GroundMotion.Point_pgv_out,1}
  @test round(sum([S_c[i].pgv for i=1:length(S_c)]),digits=2) == 4.61
  S_c = gmpe_mf2013(eq_6,config_mf2013_crustal_psa_03,grid)
  @test typeof(S_c) == Array{GroundMotion.Point_psa_out,1}
  S_c = gmpe_mf2013(eq_6,config_mf2013_crustal_psa_10,grid)
  @test round(sum([S_c[i].psa for i=1:length(S_c)]),digits=2) == 5.45
  S_c = gmpe_mf2013(eq_6,config_mf2013_crustal_psa_30,grid)
  @test round(sum([S_c[i].psa for i=1:length(S_c)]),digits=2) == 1.43
  ## PGA modeling on grid M8.5, withoit minpga, ASID false, Dl - constant
  S_c = gmpe_mf2013(eq_85,config_mf2013_crustal_pga,grid)
  @test length(S_c) == TEST_GRID_SIZE
  @test round(sum([S_c[i].pga for i=1:length(S_c)]),digits=2) == 37.6
  ## PGA modeling on grid M8.5, withoit minpga, ASID true, Dl - constant
  S_c = gmpe_mf2013(eq_85,config_mf2013_intraplate_pga_asid,grid)
  @test length(S_c) == TEST_GRID_SIZE
  @test round(sum([S_c[i].pga for i=1:length(S_c)]),digits=2) == 74.4
  ## run PGA modeling on grid M6, withoit minpga, ASID false, Dl on GRID
  S_c = gmpe_mf2013(eq_6,config_mf2013_crustal_pga,grid_dl)
  @test length(S_c) == TEST_GRID_SIZE
  @test round(sum([S_c[i].pga for i=1:length(S_c)]),digits=2) == 506.54
  ## run PGA modeling on grid M8.5, withoit minpga, ASID true, Dl on GRID
  S_c = gmpe_mf2013(eq_85,config_mf2013_intraplate_pga_asid,grid_dl,Xvf=40)
  @test length(S_c) == TEST_GRID_SIZE
  @test round(sum([S_c[i].pga for i=1:length(S_c)]),digits=2) == 4110.09
  ## PGV,PSA modeling on grid M6, withoit minpga, ASID false, Dl on GRID
  S_c = gmpe_mf2013(eq_85,config_mf2013_crustal_pgv,grid_dl)
  @test length(S_c) == TEST_GRID_SIZE
  @test typeof(S_c) == Array{GroundMotion.Point_pgv_out,1}
  @test round(sum([S_c[i].pgv for i=1:length(S_c)]),digits=2) == 2989.47
  S_c = gmpe_mf2013(eq_85,config_mf2013_crustal_psa_03,grid_dl)
  @test length(S_c) == TEST_GRID_SIZE
  @test typeof(S_c) == Array{GroundMotion.Point_psa_out,1}
  @test round(sum([S_c[i].psa for i=1:length(S_c)]),digits=2) == 4177.5
  ## PGA,PGV,PSA without grid Dl and VS30 by default, ASID=false
  S_c = gmpe_mf2013(eq_85,config_mf2013_crustal_pga)
  @test length(S_c) == SIMULATION_ARRAY_SIZE
  @test round(sum(S_c),digits=2) == 5468.53
  S_c = gmpe_mf2013(eq_85,config_mf2013_crustal_pgv)
  @test round(sum(S_c),digits=2) == 7710.7
  S_c = gmpe_mf2013(eq_85,config_mf2013_crustal_psa_03)
  @test round(sum(S_c),digits=2) == 13116.13
  ## PGA without grid Dl=500 VS30 by default, ASID=false
  S_c = gmpe_mf2013(eq_85,config_mf2013_crustal_pga,Dl=500)
  @test round(sum(S_c),digits=2) == 5725.89
  ## PGA without grid Dl by default VS30=500, ASID=false
  S_c = gmpe_mf2013(eq_85,config_mf2013_crustal_pga,VS30=500)
  @test round(sum(S_c),digits=2) == 4790.89
  ## ## PGA without grid Dl and VS30 by default, ASID=true, Xvf=40
  S_c = gmpe_mf2013(eq_85,config_mf2013_intraplate_pga_asid,Xvf=40)
  @test round(sum(S_c),digits=2) == 12845.95
end
