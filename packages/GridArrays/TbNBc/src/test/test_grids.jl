
function test_interval_grid(grid::AbstractGrid, show_timings=false)
    test_generic_grid(grid, show_timings=show_timings)
    T = eltype(grid)
    g1 = rescale(rescale(grid, -T(10), T(3)), infimum(support(grid)), supremum(support(grid)))
    @test support(g1) ≈ support(grid)
    g2 = resize(grid, length(grid)<<1)
    @test length(g2) == length(grid)<<1


    g3 = resize(g1, length(grid)<<1)
    @test length(g3) == length(grid)<<1

    g4 = rescale(rescale(g2, -T(10), T(3)), infimum(support(g2)), supremum(support(g2)))
    @test support(g4) ≈ support(g2)

    if hasextension(grid)
        @test extend(grid,3) isa typeof(grid)
    end

end

function test_generic_grid(grid; show_timings=false)
    io = IOBuffer()
    show(io, grid)
    @test length(take!(io))>0
    L = length(grid)
    @test ndims(grid) == length(grid[1])

    T = eltype(grid)
    FT = float_type(T)

    grid_iterator(grid)

    # Test two types of iterations over a grid.
    # Make sure there are L elements. Do some computation on each point,
    # and make sure the results are the same.
    (l1,sum1) = grid_iterator1(grid)
    @test l1 == L
    (l2,sum2) = grid_iterator2(grid)
    @test l2 == L
    @test sum1 ≈ sum2

    if typeof(grid) <: AbstractGrid1d
        # Make sure that 1d grids return points, not vectors with one point.
        @test eltype(grid) <: Number
    end

    if hasextension(grid)
        g_ext = extend(grid, 2)
        for i in 1:length(grid)
            @test grid[i] ≈ g_ext[2i-1]
        end
    end

    if show_timings
        t = @timed grid_iterator1(grid)
        t = @timed grid_iterator1(grid)
        print_with_color(:blue, "Eachindex: ")
        println(t[3], " bytes in ", t[2], " seconds")
        t = @timed grid_iterator2(grid)
        print_with_color(:blue, "Each x in grid: ")
        println(t[3], " bytes in ", t[2], " seconds")
    end
end

function grid_iterator(grid)
    for (i,j) in zip(1:length(grid), eachindex(grid))
        @test Base.unsafe_getindex(grid, i) == grid[i] == grid[j]
    end
end

function grid_iterator1(grid)
    l = 0
    s = zero(float_type(eltype(grid)))
    for i in eachindex(grid)
        x = grid[i]
        l += 1
        s += sum(x)
    end
    (l,s)
end

function grid_iterator2(grid)
    l = 0
    s = zero(float_type(eltype(grid)))
    for x in grid
        l += 1
        s += sum(x)
    end
    (l,s)
end


instantiate(g::Type{T} where {T <: AbstractGrid}) = error("Instantiate not implemented for $(typeof(g)), implement to use generic testing")
