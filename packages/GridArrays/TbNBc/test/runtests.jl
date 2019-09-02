using GridArrays
using Test, LinearAlgebra, DomainSets, Plots
using GridArrays: MaskedGrid, IndexSubGrid, randompoint, element, elements, cartesianproduct, iscomposite


function delimit(s::AbstractString)
    println()
    println("## ",s)
end
interval_grids = (EquispacedGrid, PeriodicEquispacedGrid, MidpointEquispacedGrid, ChebyshevNodes, ChebyshevExtremae, FourierGrid,
                    ChebyshevUNodes, LegendreNodes)
types = (Float64,BigFloat)

function test_grids(T)
    ## Equispaced grids
    len = 21
    a = -T(1.2)
    b = T(3.5)
    g1 = EquispacedGrid(len, Interval(a, b))
    g2 = PeriodicEquispacedGrid(len, Interval(a-1, b+1))
    g3 = g1 × g2
    g4 = g1 × g3

    test_generic_grid(g1)
    test_generic_grid(g2)
    test_generic_grid(g3)
    test_generic_grid(g4)

    # Test a subgrid
    g5 = g1[10:20]
    @test g5[1] == g1[10]
    @test g5[11] == g1[20]
    @test length(g5) == 20-10+1
    test_generic_grid(g5)
    g6 = g1[10:2:20]
    @test g6[2] == g1[12]
    @test length(g6) == 6

    g = EquispacedGrid(len, a, b)
    idx = 5
    @test g[idx] ≈ a + (idx-1) * (b-a)/(len-1)
    @test g[len] ≈ b
    @test_throws BoundsError g[len+1] == b

    # Test iterations
    (l,s) = grid_iterator1(g)
    @assert s ≈ len * (a+b)/2

    ## Periodic equispaced grids
    len = 120
    a = -T(1.2)
    b = T(3.5)
    g = PeriodicEquispacedGrid(len, a, b)

    idx = 5
    @test g[idx] ≈ a + (idx-1) * (b-a)/len
    @test g[len] ≈ b - step(g)
    @test_throws BoundsError g[len+1] == b

    (l,s) = grid_iterator1(g)
    @test s ≈ (len-1)*(a+b)/2 + a

    (l,s) = grid_iterator2(g)
    @test s ≈ (len-1)*(a+b)/2 + a

    ## Tensor product grids
    len = 11
    g1 = PeriodicEquispacedGrid(len, -one(T), one(T))
    g = g1^2
    @test isperiodic(g1)
    @test isperiodic(g)
    @test size(g) == (length(g1),length(g1))
    @test cartesianproduct(g1) ==g1

    g2 = EquispacedGrid(len, -one(T), one(T))
    @test !isperiodic(g2)
    g = g1 × g2
    @test !isperiodic(g)
    @test length(g) == length(g1) * length(g2)
    @test size(g) == (length(g1),length(g2))
    @test size(g,1) == length(g1)

    @test element(g, 1) == g1
    @test element(g, 2) == g2
    @test element(g,1:2) == g
    @test !iscomposite(g1)&& !iscomposite(g1)
    @test iscomposite(g)
    @test support(g) ≈ support(g1)×support(g2)



    idx1 = 5
    idx2 = 9
    x1 = g1[idx1]
    x2 = g2[idx2]
    x = g[idx1,idx2]
    @test x[1] ≈ x1
    @test x[2] ≈ x2

    (l,s) = grid_iterator1(g)
    @test s ≈ -len

    (l,s) = grid_iterator2(g)
    @test s ≈ -len

    # Test a tensor of a tensor
    g3 = g × g2
    idx1 = 5
    idx2 = 7
    idx3 = 4
    x = g3[idx1,idx2,idx3]
    x1 = g1[idx1]
    x2 = g2[idx2]
    x3 = g2[idx3]
    @test x[1] ≈ x1
    @test x[2] ≈ x2
    @test x[3] ≈ x3

    # Test a mapped grid
    m = interval_map(T(0), T(1), T(2), T(3))
    # Make a MappedGrid by hand because mapped_grid would simplify
    mg1 = MappedGrid(PeriodicEquispacedGrid(30, T(0), T(1)), m)
    test_generic_grid(mg1)
    # Does mapped_grid simplify?
    mg2 = mapped_grid(PeriodicEquispacedGrid(30, T(0), T(1)), m)
    @test typeof(mg2) <: PeriodicEquispacedGrid
    @test infimum(support(mg2)) ≈ T(2)
    @test supremum(support(mg2)) ≈ T(3)

    # Apply a second map and check whether everything simplified
    m2 = interval_map(T(2), T(3), T(4), T(5))
    mg3 = mapped_grid(mg1, m2)
    @test infimum(support(mg3)) ≈ T(4)
    @test supremum(support(mg3)) ≈ T(5)
    @test typeof(supergrid(mg3)) <: PeriodicEquispacedGrid

    # Scattered grid
    pts = rand(T, 10)
    sg = ScatteredGrid(pts)
    test_generic_grid(sg)
end

function test_laguerre(T)
    grid = LaguerreNodes(10,rand(T))
    @test infimum(support(LaguerreNodes(0.,rand(10)))) == 0
    @test supremum(support(LaguerreNodes(0.,rand(10)))) == Inf
    test_generic_grid(grid)
end

function test_hermite(T)
    grid = HermiteNodes(10)
    @test DomainSets.GeometricSpace{T}()== support(HermiteNodes(rand(T,10)))
    test_generic_grid(grid)
end

function test_jacobi(T)
    grid = JacobiNodes(10,rand(T),rand(T))
    @test support(JacobiNodes(T(0),T(0),rand(T,10))) == ChebyshevInterval{T}()
    test_generic_grid(grid)
    @test JacobiNodes(10,zero(T),zero(T)) ≈ LegendreNodes(10)
    @test JacobiNodes(10,T(1//2),T(1//2)) ≈ ChebyshevUNodes(10)
    @test JacobiNodes(10,T(-1//2),T(-1//2)) ≈ ChebyshevTNodes(10)
end


for T in types
    delimit(string(T))
    for GRID in interval_grids
        @testset "$(rpad(string(GRID),80))" begin
            g = instantiate(GRID,10,T)
            test_interval_grid(g)
        end
    end

    for grid in (JacobiNodes(10,rand(T),rand(T)),)
        @testset "$(rpad(string(typeof(grid)),80))" begin
            test_interval_grid(grid)
        end
    end

    @testset "HermiteNodes" begin
        test_hermite(T)
    end

    @testset "Laguerre" begin
        test_laguerre(T)
    end

    @testset "Jacobi" begin
        test_jacobi(T)
    end

    @testset "$(rpad("Specific grid tests",80))" begin
        test_grids(T)
    end
end

function test_generic_subgrid(grid, s)
    @test support(grid) ≈ s
    for x in grid
        @test x ∈ support(grid)
    end
    for x in subindices(grid)
        @test issubindex(x, grid)
    end

    cnt = 0
    for i in eachindex(supergrid(grid))
        if issubindex(i, grid)
            cnt += 1
        end
    end
    @test cnt == length(grid)
end

function test_subgrids()
    delimit("Grid functionality")
    @testset  "SubGrids" begin
    n = 20
    grid1 = EquispacedGrid(n, -1.0, 1.0)
    subgrid1 = MaskedGrid(grid1, -0.5..0.7)
    test_generic_subgrid(subgrid1, -0.5..0.7)

    subgrid2 = IndexSubGrid(grid1, 4:12)
    subgrid3 = subgrid(grid1, -0.5..0.7)
    test_generic_subgrid(subgrid3, -0.5..0.7)

    @test subgrid1 == subgrid3
    @test mask(subgrid1) == mask(subgrid3)
    @test subindices(subgrid1) == subindices(subgrid3)

    @test support(subgrid1) ∈ support(grid1)
    @test support(subgrid2) ∈ support(grid1)

    G1 = EquispacedGrid(n, -1.0, 1.0)
    G2 = EquispacedGrid(n, -1.0, 1.0)
    ProductG = G1 × G2

    C = UnitDisk()
    refgrid = MaskedGrid(ProductG, C)
    circle_grid = subgrid(ProductG, C)
    @test circle_grid isa MaskedGrid
    @test refgrid ≈ circle_grid
    test_generic_subgrid(circle_grid, C)
    @testset "Generic MaskedGrid" begin

        @test (length(circle_grid)/length(ProductG)-pi*0.25) < 0.01

        G1s = IndexSubGrid(G1,2:4)
        G2s = IndexSubGrid(G2,3:5)
        ProductGs = G1s × G2s
        @test G1s[1] == G1[2]
        @test G2s[1] == G2[3]
        @test ProductGs[1,1] == [G1[2],G2[3]]
    end

    # subgrid of a subgrid
    g1 = EquispacedGrid(10,-1,1)^2
    @test mask(subgrid(subgrid(g1,(0.0..1.0)^2),UnitSimplex{2}()))==[i+j<6 for i in 1:5 , j in 1:5]

    g1 = EquispacedGrid(10,0,1)^2
    for x in g1[BitArray([i+j<12 for i in 1:10 , j in 1:10])]
        @test x ∈ UnitSimplex{2}()
    end

    C = UnitInterval()^2
    productgrid = subgrid(ProductG, C)
    refgrid = MaskedGrid(ProductG, C)

    @test supergrid(productgrid) == ProductG
    @test productgrid isa TensorSubGrid
    test_generic_subgrid(productgrid, C)
    refgrid = MaskedGrid(ProductG, C)
    @test reshape(refgrid,10,10) == productgrid
    @test subindices(refgrid) == subindices(productgrid)


    # Generic tests for the subgrids
    @testset "result" for (grid,subgrid) in ( (grid1,subgrid1), (grid1,subgrid2), (ProductG, circle_grid))
        # print("Subgrid is ")
        # println(typeof(subgrid))
        # Count the number of elements in the subgrid
        cnt = 0
        for i in 1:length(grid)
            if issubindex(i, subgrid)
                cnt += 1
            end
        end
        @test cnt == length(subgrid)
    end

    g = subgrid(ScatteredGrid(rand(10)), Interval(0,.5))
    @test support(g) ≈ Interval(0,.5)
    for x in g
        @test x ∈ support(g)
    end

    for x in boundary(EquispacedGrid(100,-1,1)^2,UnitDisk())
        @test norm(x)≈1
    end

    for x in  boundary(subgrid(EquispacedGrid(100,-1,1)^2,UnitDisk()),UnitDisk())
        @test norm(x)≈1
    end
end
end

function test_randomgrids()
    println("Random grids:")
    @testset begin
        d = UnitDisk()
        g = randomgrid(d, 10)
        @test length(g) == 10
        @test length(eltype(g)) == dimension(d)
        @test reduce(&, [x ∈ d for x in g])

        g2 = randomgrid(UnitDisk{BigFloat}(), 10)
        @test eltype(g2[1]) == BigFloat

        g3 = randomgrid(0.0..1.0, 10)
        @test length(g3) == 10
        # 1D is a special case where we don't use vectors of length 1
        @test eltype(g3) == Float64

        box1 = UnitInterval()^2
        p1 = randompoint(box1)
        @test length(p1) == dimension(box1)
        @test p1 ∈ box1
        box2 = 0.0..1.0
        p2 = randompoint(box2)
        @test typeof(p2) == Float64
        @test p2 ∈ box2

        g3 = randompoint(UnionDomain(0.0..1.5,1.5..2.0))
        @test typeof(g3) == Float64
        @test g3 ∈ 0.0..2.0

        g3 = randompoint(IntersectionDomain(0.0..1.5,1.0..2.0))
        @test typeof(g3) == Float64
        @test g3 ∈ 1.0..1.5

        g3 = randompoint(DifferenceDomain(0.0..1.5,1.0..2.0))
        @test typeof(g3) == Float64
        @test g3 ∈ 0.0..1.0

    end
end
using StaticArrays


include("test_modcartesianindices.jl")

include("test_boundingbox.jl")
include("test_broadcast.jl")
include("test_gauss.jl")
test_subgrids()
test_randomgrids()


@testset "Plots" begin
    plot(FourierGrid(4))
    plot(FourierGrid(4)× FourierGrid(4) )
    plot(FourierGrid(4)× FourierGrid(4) × FourierGrid(4) )
    plot(FourierGrid(4)× FourierGrid(4) ,rand(4,4))
    plot(FourierGrid(4) ,rand(4))
end
