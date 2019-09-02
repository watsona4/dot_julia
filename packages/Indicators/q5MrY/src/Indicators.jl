VERSION >= v"0.4.0" && __precompile__(true)

module Indicators
    export
        runmean, runsum, runvar, runsd, runcov, runcor, runmax, runmin, runmad, runquantile, runacf,
        wilder_sum, mode, diffn,
        sma, trima, wma, ema, mma, kama, mama, hma, swma, dema, tema, alma, zlema,
        mlr_beta, mlr_slope, mlr_intercept, mlr, mlr_se, mlr_ub, mlr_lb, mlr_bands, mlr_rsq,
        aroon, donch, momentum, roc, macd, rsi, adx, psar, kst, wpr, cci, stoch, smi,
        bbands, tr, atr, keltner,
        crossover, crossunder,
        renko,
        maxima, minima, support, resistance,
        rsrange, hurst

    include("run.jl")
    include("ma.jl")
    include("reg.jl")
    include("mom.jl")
    include("vol.jl")
    include("trendy.jl")
    include("utils.jl")
    include("patterns.jl")
    include("chaos.jl")

    using Temporal
    include("temporal.jl")
end
