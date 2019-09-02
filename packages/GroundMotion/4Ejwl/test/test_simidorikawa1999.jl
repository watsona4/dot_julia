## Si-Midorikawa 1999 GMPE tests
@testset "Si-Midorikawa 1999 GMPE PGA" begin
  # init model parameters
  include("../examples/si-midorikawa-1999.conf")
  ## test at epicenter on grid M7.0
  @test gmpe_simidorikawa1999(eq_7,config_simidorikawa1999_crustal_pga,grid_epicenter)[1].pga == 59.04
  ## run PGA modeling on grid withoit minpga Depth <= 30 M6.0
  S_c = gmpe_simidorikawa1999(eq_6,config_simidorikawa1999_crustal_pga,grid)
  @test length(S_c) == TEST_GRID_SIZE
  @test round(sum([S_c[i].pga for i=1:length(S_c)]),digits=2) == 6.98
  S_intp = gmpe_simidorikawa1999(eq_6,config_simidorikawa1999_interplate_pga,grid)
  @test length(S_intp) == TEST_GRID_SIZE 
  @test round(sum([S_intp[i].pga for i=1:length(S_intp)]),digits=2) == 8.38
  S_intra = gmpe_simidorikawa1999(eq_6,config_simidorikawa1999_intraplate_pga,grid)
  @test length(S_intra) == TEST_GRID_SIZE
  @test round(sum([S_intra[i].pga for i=1:length(S_intra)]),digits=2) == 13.9
  ## run PGA modeling on grid with minpga Depth <= 30 M6.0
  S_c = gmpe_simidorikawa1999(eq_6,config_simidorikawa1999_crustal_pga,grid,min_val=0.34)
  @test length(S_c) == WITH_MINPGA
  @test round(sum([S_c[i].pga for i=1:length(S_c)]),digits=2) == 4.61
  ## run PGA modeling on grid with minpga Depth > 30 M6.0
  eq_30 = Earthquake(143.04,51.92,35,6.0)
  S_c = gmpe_simidorikawa1999(eq_30,config_simidorikawa1999_crustal_pga,grid,min_val=0.15)
  @test length(S_c) == WITH_MINPGA
  @test round(sum([S_c[i].pga for i=1:length(S_c)]),digits=2) == 2.04
  ## run PGA modeling for plotting Depth <= 30 M6.0
  S_c = gmpe_simidorikawa1999(eq_6,config_simidorikawa1999_crustal_pga)
  @test length(S_c) == SIMULATION_ARRAY_SIZE
  @test round(sum(S_c),digits=2) == 1096.79
  S_intp = gmpe_simidorikawa1999(eq_6,config_simidorikawa1999_interplate_pga)
  @test round(sum(S_intp),digits=2) == 1318.74
  S_intra = gmpe_simidorikawa1999(eq_6,config_simidorikawa1999_intraplate_pga)
  @test round(sum(S_intra),digits=2) == 2188.89
  ## run PGA modeling for plotting Depth > 30 M6.0
  S_c = gmpe_simidorikawa1999(eq_30,config_simidorikawa1999_crustal_pga)
  @test round(sum(S_c),digits=2) == 722.93
end
