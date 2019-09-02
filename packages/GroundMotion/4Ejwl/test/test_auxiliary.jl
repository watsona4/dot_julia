## auxiliary tests
@testset "GRID'S read/convert" begin
  @test typeof(grid) == Array{GroundMotion.Point_vs30,1}
  @test length(grid) == TEST_GRID_SIZE
  # get PGA data grid and test it
  include("../examples/as2008.conf")
  pga_grid = gmpe_as2008(eq_6,config_as2008_pga,grid)
  @test typeof(pga_grid) == Array{GroundMotion.Point_pga_out,1}
  # convert to Point_vs30
  A = convert_to_point_vs30(raw_grid)
  @test length(A) == 17
  # convert to float array
  A = convert_to_float_array(grid)
  @test typeof(A) == Array{Float64,2}
  @test length(A) == 51
  @test round(sum(A[:,3]),digits=2) == 12400.0
  A = convert_to_float_array(grid_dl)
  @test typeof(A) == Array{Float64,2}
  @test length(A) == 68
  @test round(sum(A[:,4]),digits=2) == 15300.0
  A = convert_to_float_array(pga_grid)
  @test typeof(A) == Array{Float64,2}
  @test length(A) == 51
  @test round(sum(A[:,3]),digits=2) == 4.39
end
