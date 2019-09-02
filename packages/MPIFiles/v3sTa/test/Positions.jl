@testset "Testing Positions submodule" begin
  shp = [3,3,3]
  fov = [3.0,3.0,3.0]Unitful.mm
  ctr = [0.0,0.0,0.0]Unitful.mm
  caG = RegularGridPositions(shp,fov,ctr)
  @test shape(caG) == shp
  @test fieldOfView(caG) == fov
  @test fieldOfViewCenter(caG) == ctr
  @test_throws BoundsError caG[0]
  @test_throws BoundsError caG[28]
  @test caG[1] == [-1,-1,-1]Unitful.mm
  @test caG[2] == [0,-1,-1]Unitful.mm
  @test caG[3] == [1,-1,-1]Unitful.mm
  @test caG[4] == [-1,0,-1]Unitful.mm
  @test caG[27] == [1,1,1]Unitful.mm
  h5open("Positions.h5", "w") do file
    write(file, caG)
  end
  h5open("Positions.h5", "r") do file
    caG1 = Positions(file)
    @test typeof(caG1) <: RegularGridPositions
    @test shape(caG1) == shp
    @test fieldOfView(caG1) == fov
    @test fieldOfViewCenter(caG1) == ctr
  end
  for (i,pos) in enumerate(caG)
    @test posToLinIdx(caG,pos) == i
  end

  chG = ChebyshevGridPositions(shp,fov,ctr)
  @test shape(chG) == shp
  @test fieldOfView(chG) == fov
  @test fieldOfViewCenter(chG) == ctr
  @test_throws BoundsError chG[0]
  @test_throws BoundsError chG[28]
  @test chG[1] ≈ cos(π/6)*3/2*caG[1]
  @test chG[2] ≈ cos(π/6)*3/2*caG[2]
  @test chG[3] ≈ cos(π/6)*3/2*caG[3]
  @test chG[4] ≈ cos(π/6)*3/2*caG[4]
  @test chG[27] ≈ cos(π/6)*3/2*caG[27]
  h5open("Positions.h5", "w") do file
    write(file, chG)
  end
  h5open("Positions.h5", "r") do file
    chG1 = Positions(file)
    @test typeof(chG1) <: ChebyshevGridPositions
    @test shape(chG1) == shp
    @test fieldOfView(chG1) == fov
    @test fieldOfViewCenter(chG1) == ctr
  end

  for grid in [caG,chG]
    mG = MeanderingGridPositions(grid)
    @test length(mG) == prod(shp)
    @test shape(mG) == shp
    @test fieldOfView(mG) == fov
    @test fieldOfViewCenter(mG) == ctr
    @test mG[1] == grid[1]
    @test mG[2] == grid[2]
    @test mG[3] == grid[3]
    @test mG[4] == grid[6]
    @test mG[7] == grid[7]
    @test mG[9] == grid[9]
    @test mG[10] == grid[18]
    @test mG[18] == grid[10]
    @test mG[19] == grid[19]
    @test mG[27] == grid[27]
    @test getPermutation(mG) == [1, 2, 3, 6, 5, 4, 7, 8, 9, 18, 17, 16, 13, 14, 15, 12, 11, 10, 19, 20, 21, 24, 23, 22, 25, 26, 27]
    h5open("Positions.h5", "w") do file
      write(file, mG)
    end
    h5open("Positions.h5", "r") do file
      mG1 = Positions(file)
      @test mG1[1] ≈ grid[1]
      @test shape(mG1) == shp
      @test fieldOfView(mG1) == fov
      @test fieldOfViewCenter(mG1) == ctr
    end
  end
#BG Test
    bgInd = collect(1:4:37)
    bgPos = [10.0,10.0,10.0]Unitful.mm
  for grid in [caG,chG]
    bG = BreakpointGridPositions(grid,bgInd,bgPos)
    @test length(bG) == prod(shp)+length(bgInd)
    @test shape(bG) == shp
    @test fieldOfView(bG) == fov
    @test fieldOfViewCenter(bG) == ctr
    @test bG[1] == bgPos
    @test bG[2] == grid[1]
    @test bG[3] == grid[2]
    @test bG[4] == grid[3]
    @test bG[5] == bgPos
    @test bG[6] == grid[4]
    @test bG[7] == grid[5]
    @test bG[8] == grid[6]
    @test bG[9] == bgPos
    @test bG[10] == grid[7]
    @test bG[11] == grid[8]
    @test bG[12] == grid[9]
    @test bG[13] == bgPos
    @test bG[14] == grid[10]
    @test bG[15] == grid[11]
    @test bG[16] == grid[12]
    @test bG[17] == bgPos
    @test bG[18] == grid[13]
    @test bG[19] == grid[14]
    @test bG[20] == grid[15]
    @test bG[21] == bgPos
    @test bG[22] == grid[16]
    @test bG[23] == grid[17]
    @test bG[24] == grid[18]
    @test bG[25] == bgPos
    @test bG[26] == grid[19]
    @test bG[27] == grid[20]
    @test bG[28] == grid[21]
    @test bG[29] == bgPos
    @test bG[30] == grid[22]
    @test bG[31] == grid[23]
    @test bG[32] == grid[24]
    @test bG[33] == bgPos
    @test bG[34] == grid[25]
    @test bG[35] == grid[26]
    @test bG[36] == grid[27]
    @test bG[37] == bgPos

    h5open("Positions.h5", "w") do file
      write(file, bG)
    end
    h5open("Positions.h5", "r") do file
      bG1 = Positions(file)
      @test bG1[1] ≈ grid[1]
      @test shape(bG1) == shp
      @test fieldOfView(bG1) == fov
      @test fieldOfViewCenter(bG1) == ctr
    end
  end

#BG+Meander Test
    bgInd = collect(1:4:37)
    bgPos = [10.0,10.0,10.0]Unitful.mm
  for grid in [caG,chG]
    mG = MeanderingGridPositions(grid)
    bG = BreakpointGridPositions(mG,bgInd,bgPos)
    @test length(bG) == prod(shp)+length(bgInd)
    @test shape(bG) == shp
    @test fieldOfView(bG) == fov
    @test fieldOfViewCenter(bG) == ctr
    @test bG[1] == bgPos
    @test bG[2] == grid[1]
    @test bG[3] == grid[2]
    @test bG[4] == grid[3]
    @test bG[5] == bgPos
    @test bG[6] == grid[6]
    @test bG[7] == grid[5]
    @test bG[8] == grid[4]
    @test bG[9] == bgPos
    @test bG[10] == grid[7]
    @test bG[11] == grid[8]
    @test bG[12] == grid[9]
    @test bG[13] == bgPos
    @test bG[14] == grid[18]
    @test bG[15] == grid[17]
    @test bG[16] == grid[16]
    @test bG[17] == bgPos
    @test bG[18] == grid[13]
    @test bG[19] == grid[14]
    @test bG[20] == grid[15]
    @test bG[21] == bgPos
    @test bG[22] == grid[12]
    @test bG[23] == grid[11]
    @test bG[24] == grid[10]
    @test bG[25] == bgPos
    @test bG[26] == grid[19]
    @test bG[27] == grid[20]
    @test bG[28] == grid[21]
    @test bG[29] == bgPos
    @test bG[30] == grid[24]
    @test bG[31] == grid[23]
    @test bG[32] == grid[22]
    @test bG[33] == bgPos
    @test bG[34] == grid[25]
    @test bG[35] == grid[26]
    @test bG[36] == grid[27]
    @test bG[37] == bgPos

    h5open("Positions.h5", "w") do file
      write(file, bG)
    end
    h5open("Positions.h5", "r") do file
      bG1 = Positions(file)
      @test bG1[1] ≈ grid[1]
      @test shape(bG1) == shp
      @test fieldOfView(bG1) == fov
      @test fieldOfViewCenter(bG1) == ctr
    end
  end

  positions = [1 2 3 4; 0 1 2 3;-4 -3 -2 -1]Unitful.mm
  aG1 = ArbitraryPositions(positions)
  @test aG1[1] == [1,0,-4]*Unitful.mm
  @test aG1[2] == [2,1,-3]Unitful.mm
  @test aG1[3] == [3,2,-2]Unitful.mm
  @test aG1[4] == [4,3,-1]Unitful.mm
  aG2 = ArbitraryPositions(caG)
  @test aG2[1] == caG[1]
  @test aG2[2] == caG[2]
  @test aG2[27] == caG[27]
  h5open("Positions.h5", "w") do file
    write(file, aG2)
  end
  h5open("Positions.h5", "r") do file
    aG3 = Positions(file)
    @test typeof(aG3) <: ArbitraryPositions
    @test aG3.positions == aG2.positions
  end

  # the same seed yields the same sequence of points
  seed = UInt32(42)
  N = UInt(3)
  domain = AxisAlignedBox(fov,ctr)
  @test domain.fov == fov
  @test domain.center == ctr
  rP1 = UniformRandomPositions(N,seed,domain)
  @test rP1[1] == [0.09954904813158394,-0.13791259323857274,-1.446939519855107]Unitful.mm
  @test rP1[2] == [-0.9812009131891462,1.3767776289892044,1.4206979394110573]Unitful.mm
  @test rP1[3] == [-0.5883911667396526,-0.9692742011014337,1.3707474722677764]Unitful.mm
  @test_throws BoundsError rP1[0]
  @test_throws BoundsError rP1[4]
  h5open("Positions.h5", "w") do file
    write(file, rP1)
  end
  h5open("Positions.h5", "r") do file
    rP2 = Positions(file)
    @test typeof(rP2) <: UniformRandomPositions{AxisAlignedBox}
    @test rP2.N == N
    @test rP2.seed == seed
    @test rP2.domain.fov == fov
    @test rP2.domain.center == ctr
  end
  radius = 10Unitful.mm
  domain = Ball(radius,ctr)
  @test domain.radius == radius
  @test domain.center == ctr
  rP3 = UniformRandomPositions(N,seed,domain)
  @test rP3[1] == [-6.715713750009747,0.4103832286623821,-4.525933276650638]Unitful.mm
  @test_throws BoundsError rP3[0]
  @test_throws BoundsError rP3[4]
  h5open("Positions.h5", "w") do file
    write(file, rP3)
  end
  h5open("Positions.h5", "r") do file
    rP4 = Positions(file)
    @test typeof(rP4) <: UniformRandomPositions{Ball}
    @test rP4.N == N
    @test rP4.seed == seed
    @test rP4.domain.radius == radius
    @test rP4.domain.center == ctr
  end
  #TODO conversion methods dont work. Why?
  #rG = UniformRandomPositions(15,fov,ctr)

  # the following 2 tests fail but should work
  @test_throws DomainError loadTDesign(8,1)
  @test_throws DomainError loadTDesign(10,1)
  t = 1
  N = 2
  radius = 5Unitful.mm
  tDesign = loadTDesign(t,N, radius)
  @test length(tDesign) == N
  @test tDesign.T == t
  @test tDesign.radius == radius
  @test any(tDesign.positions .== [1 -1; 0 0; 0 0])
  @test tDesign[1] == [5,0,0]Unitful.mm
  @test tDesign[2] == [-5,0,0]Unitful.mm
  h5open("Positions.h5", "w") do file
    write(file, tDesign)
  end
  h5open("Positions.h5", "r") do file
    tDesign1 = Positions(file)
    @test typeof(tDesign1) <: SphericalTDesign
    @test tDesign1.radius == tDesign.radius
    @test tDesign1.center == tDesign.center
    @test tDesign1.positions == tDesign.positions
  end

  @test length(caG) == prod(shp)
  @test length(chG) == prod(shp)
  @test length(aG1) == size(positions,2)
  @test length(aG2) == prod(shp)

  for (i,p) in enumerate(caG)
    @test p == caG[i]
  end
end
