let
    gw = LegacyGridWorld(sx=2, sy=2, rs=[GridWorldState(1,1)], rv=[10.0])

    pvec = fill(GridWorldAction(:left), 5)

    solver = VectorSolver(pvec)

    p = solve(solver, gw)

    io = IOBuffer()
    d = TextDisplay(io)
    display(d, p)
    @test String(take!(io)) == "VectorPolicy{GridWorldState,Symbol}:\n GridWorldState(1, 1, false) -> :left\n GridWorldState(2, 1, false) -> :left\n GridWorldState(1, 2, false) -> :left\n GridWorldState(2, 2, false) -> :left\n GridWorldState(0, 0, true) -> :left"

    for s1 in states(gw)
        @test action(p, s1) == GridWorldAction(:left)
    end

    p2 = VectorPolicy(gw, pvec)
    for s2 in states(gw)
        @test action(p2, s2) == GridWorldAction(:left)
    end

    p3 = ValuePolicy(gw)
    for s2 in states(gw)
        @inferred(action(p3, s2)) isa GridWorldAction
    end

    io = IOBuffer()
    d = TextDisplay(io)
    display(d, p3)
    @test String(take!(io)) == "ValuePolicy{LegacyGridWorld,Array{Float64,2},Symbol}:\n GridWorldState(1, 1, false) -> :up\n GridWorldState(2, 1, false) -> :up\n GridWorldState(1, 2, false) -> :up\n GridWorldState(2, 2, false) -> :up\n GridWorldState(0, 0, true) -> :up"
end
