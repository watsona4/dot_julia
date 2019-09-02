## AS2008 model tests
@testset "AS2008 GMPE PGA" begin
  # init model parameters
  include("../examples/as2008.conf")
  # test at epicenter with M7.0, VS=350 
  @test gmpe_as2008(eq_7,config_as2008_pga,grid_epicenter)[1].pga == 22.45
  # run PGA modeling on grid without minpga M6.0
  A = gmpe_as2008(eq_6,config_as2008_pga,grid)
  @test length(A) == TEST_GRID_SIZE
  @test round(sum([A[i].pga for i=1:length(A)]),digits=2) == 4.39
  # run PGA modeling on grid with minpga M6.0
  A = gmpe_as2008(eq_6,config_as2008_pga,grid,min_val=0.22)
  @test length(A) == WITH_MINPGA
  @test round(sum([A[i].pga for i=1:length(A)]),digits=2) == 2.86
  # run PGA modeling with M4.0
  A = gmpe_as2008(eq_4,config_as2008_pga,grid)
  @test length(A) == TEST_GRID_SIZE
  @test round(sum([A[i].pga for i=1:length(A)]),digits=2) == 0.21
  # run PGA modeling for plotting M6.0
  A = gmpe_as2008(eq_6,config_as2008_pga)
  @test length(A) == SIMULATION_ARRAY_SIZE
  @test round(sum(A),digits=2) == 573.5
  # run PGA Modeling M=4
  @test round(sum(gmpe_as2008(eq_4,config_as2008_pga)),digits=2) == 84.36
  # run PGA Modeling M=7 
  @test round(sum(gmpe_as2008(eq_7,config_as2008_pga)),digits=2) == 1486.84
  # run PGA Modeling M=7 with VS30 = 900
  @test round(sum(gmpe_as2008(eq_7,config_as2008_pga,VS30=900)),digits=2) == 1031.1
  # run PGA Modeling M=7 with VS30 = 1600 
  @test round(sum(gmpe_as2008(eq_7,config_as2008_pga,VS30=1600)),digits=2) == 817.23
end 
