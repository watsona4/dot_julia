function compare_exps(aff1, aff2)
    keys = Symbol.(unique(vcat(aff1.vars, aff2.vars)))
    totals1 = Dict(zip(keys, zeros(length(keys))))
    for (var, coeff) in zip(Symbol.(aff1.vars), aff1.coeffs)
        totals1[var] += coeff
    end

    totals2 = Dict(zip(keys, zeros(length(keys))))
    for (var, coeff) in zip(Symbol.(aff2.vars), aff2.coeffs)
        totals2[var] += coeff
    end

    totals1 == totals2
end


@testset "Transformations" begin
    lfm = LinearFractionalModel(solver=ClpSolver())
    x = @variable(lfm, basename="x")
    y = @variable(lfm, basename="y")
    xplus5 = x + 5.0
    @test compare_exps(xplus5.afftrans, x.var + 5.0 * lfm.t)

    xtimes2 = 2.0 * x
    @test compare_exps(xtimes2.afftrans, 2.0 * x.var)

    lfa = 2.0 * x + 5.0
    @test compare_exps(lfa.afftrans, 2.0 * x.var + 5.0 * lfm.t)

    lfb = 3.0 * y - 1.0
    aplusb = (lfa + lfb)
    @test compare_exps(aplusb.afftrans, 2.0 * x.var + 3.0 * y.var + 4.0 * lfm.t)

    @test compare_exps((2.0 * lfa).afftrans, 4 * x.var + 10 * lfm.t)

    @test compare_exps((4 - lfa).afftrans, -2.0 * x.var - lfm.t)

    ## TODO: add lots more tests for operators
end
