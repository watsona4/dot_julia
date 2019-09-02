using Indicators
using Temporal
using Test
using Random
using Statistics

const global N = 1_000
const global X0 = 50.0
const global SEED = 1

@testset "Utilities" begin
    Random.seed!(SEED)
    @testset "Array" begin
        x = cumsum(randn(N)) .+ X0
        y = x + randn(N)
        cxo = crossover(x, y)
        cxu = crossunder(x, y)
        @test any(cxo)
        @test any(cxu)
        @test !any(cxo .* cxu)  # ensure crossovers and crossunders never coincide
    end
end

# trendy
@testset "Trendlines" begin
    Random.seed!(SEED)
    @testset "Array" begin
        x = cumsum(randn(N))
        tmp = resistance(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = support(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = minima(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = maxima(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
    end
end

# analytical
@testset "Chaos" begin
    Random.seed!(SEED)
    @testset "Array" begin
        x = randn(252)
        # helpers
        a, b = Indicators.divide(x)
        @test [a; b] == x
        x = randn(101)
        a, b = Indicators.divide(x)
        @test [a; b] == x
        # workhorses
        h = hurst(x, n=100)
        @test size(h) == size(x)
        rs = rsrange(x)
        @test size(rs) == size(x)
        x = randn(100)
    end
    @testset "Temporal" begin
        # chaos indicators
        x = TS(randn(N))
        tmp = hurst(x)
        @test size(tmp,1) == size(x,1)
        @test size(tmp,2) == 1
        tmp = rsrange(x)
        @test size(tmp,1) == size(x,1)
        @test size(tmp,2) == 1
    end
end

# moving regressions
@testset "Regressions" begin
    Random.seed!(SEED)
    @testset "Array" begin
        x = cumsum(randn(N))
        tmp = mlr_beta(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 2
        @test sum(isnan.(tmp)) != N
        tmp = mlr_slope(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = mlr_intercept(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = mlr(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = mlr_se(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = mlr_ub(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = mlr_lb(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = mlr_bands(tmp)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 3
        @test sum(isnan.(tmp)) != N
        tmp = mlr_rsq(x, adjusted=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = mlr_rsq(x, adjusted=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
    end
    @testset "Temporal" begin
        x = TS(cumsum(randn(N)))
        # moving regressions
        tmp = mlr_beta(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 2
        tmp = mlr_slope(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = mlr_intercept(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = mlr(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = mlr_se(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = mlr_ub(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = mlr_lb(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = mlr_bands(tmp)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 3
        tmp = mlr_rsq(x, adjusted=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = mlr_rsq(x, adjusted=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
    end
end

@testset "Running Calculations" begin
    Random.seed!(SEED)
    @testset "Array" begin
        x = cumsum(randn(N))
        X = cumsum(randn(N, 4), dims=1)
        tmp = diffn(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = diffn(X)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == size(X,2)
        @test sum(isnan.(tmp)) != N
        tmp = runmean(x, cumulative=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = runmean(x, cumulative=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = runsum(x, cumulative=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = wilder_sum(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = runmad(x, cumulative=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = runmad(x, cumulative=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = runvar(x, cumulative=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = runvar(x, cumulative=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = runsd(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = runcov(x, x.*rand(N), cumulative=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = runcov(x, x.*rand(N), cumulative=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = runcor(x, x.*rand(N), cumulative=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = runcor(x, x.*rand(N), cumulative=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = runmin(x, cumulative=true, inclusive=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = runmin(x, cumulative=true, inclusive=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = runmin(x, cumulative=false, inclusive=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = runmin(x, cumulative=false, inclusive=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = runmax(x, cumulative=true, inclusive=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = runmax(x, cumulative=true, inclusive=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = runmax(x, cumulative=false, inclusive=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = runmax(x, cumulative=false, inclusive=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = mode(map(xi->round(xi), x))
        @test size(tmp, 1) == 1
        @test size(tmp, 2) == 1
        @test !isnan(tmp)
        tmp = runquantile(x, cumulative=true)
        @test !isnan(tmp[2]) && isnan(tmp[1])
        @test tmp[10] == quantile(x[1:10], 0.05)
        tmp = runquantile(x, cumulative=false)
        @test tmp[10] == quantile(x[1:10], 0.05)
        n = 20
        tmp = runacf(x, n=n, maxlag=15, cumulative=true)
        @test all(tmp[n:end,1] .== 1.0)
        tmp = runacf(x, n=n, maxlag=15, cumulative=false)
        @test all(tmp[n:end,1] .== 1.0)
    end
    @testset "Temporal" begin
        # running calculations
        x = TS(cumsum(randn(N)))
        X = TS(cumsum(randn(N, 4), dims=1))
        tmp = runmean(x, cumulative=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runmean(x, cumulative=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runsum(x, cumulative=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = wilder_sum(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runmad(x, cumulative=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runmad(x, cumulative=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runvar(x, cumulative=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runvar(x, cumulative=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runsd(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runcov(X[:,1], X[:,4], cumulative=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runcov(X[:,1], X[:,4], cumulative=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runcor(X[:,1], X[:,4], cumulative=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runcor(X[:,1], X[:,4], cumulative=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runmin(x, cumulative=true, inclusive=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runmin(x, cumulative=true, inclusive=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runmin(x, cumulative=false, inclusive=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runmin(x, cumulative=false, inclusive=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runmax(x, cumulative=true, inclusive=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runmax(x, cumulative=true, inclusive=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runmax(x, cumulative=false, inclusive=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runmax(x, cumulative=false, inclusive=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = runquantile(x, cumulative=true)
        @test !isnan(tmp.values[2,1]) && isnan(tmp.values[1,1])
        @test tmp.values[10,1] == quantile(x.values[1:10,1], 0.05)
        tmp = runquantile(x, cumulative=false)
        @test tmp.values[10,1] == quantile(x.values[1:10,1], 0.05)
        n = 20
        tmp = runacf(x, n=n, maxlag=15, cumulative=true)
        @test all(tmp.values[n:end,1] .== 1.0)
        tmp = runacf(x, n=n, maxlag=15, cumulative=false)
        @test all(tmp.values[n:end,1] .== 1.0)
    end
end

# moving average functions
@testset "Moving Averages" begin
    Random.seed!(SEED)
    @testset "Array" begin
        x = cumsum(randn(N))
        tmp = sma(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = mama(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 2
        @test sum(isnan.(tmp)) != N
        tmp = ema(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = wma(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = hma(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = trima(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = mma(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = tema(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = dema(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = swma(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = kama(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = alma(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = zlema(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
    end
    @testset "Temporal" begin
        x = TS(cumsum(randn(N)))
        # moving average functions
        tmp = sma(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = mama(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 2
        tmp = ema(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = wma(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = hma(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = trima(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = mma(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = tema(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = dema(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = swma(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = kama(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = alma(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = zlema(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
    end
end

# momentum function
@testset "Momentum" begin
    Random.seed!(SEED)
    @testset "Array" begin
        x = cumsum(randn(N))     # close
        Y = cumsum(randn(N, 2), dims=1)  # high-low
        Z = cumsum(randn(N, 3), dims=1)  # high-low-close
        tmp = aroon(Y)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 3
        @test sum(isnan.(tmp)) != N
        tmp = donch(Y)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 3
        @test sum(isnan.(tmp)) != N
        tmp = momentum(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = roc(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = macd(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 3
        @test sum(isnan.(tmp)) != N
        tmp = rsi(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = adx(Z)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 3
        @test sum(isnan.(tmp)) != N
        tmp = adx(Z, wilder=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 3
        @test sum(isnan.(tmp)) != N
        tmp = psar(Y)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = kst(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = wpr(Z)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = cci(Z)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = stoch(Z, kind=:fast)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 2
        @test sum(isnan.(tmp)) != N
        tmp = stoch(Z, kind=:slow)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 2
        @test sum(isnan.(tmp)) != N
        tmp = smi(Z)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 2
        @test sum(isnan.(tmp)) != N
    end
    @testset "Temporal" begin
        x = TS(cumsum(randn(N)))
        Y = TS(cumsum(randn(N, 2), dims=1))
        Z = TS(cumsum(randn(N, 3), dims=1))
        # momentum function
        tmp = aroon(Y)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 3
        tmp = donch(Y)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 3
        tmp = momentum(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = roc(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = macd(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 3
        tmp = rsi(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = adx(Z)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 3
        tmp = adx(Z, wilder=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 3
        tmp = psar(Y)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = kst(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = wpr(Z)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = cci(Z)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = stoch(Z, kind=:fast)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 2
        tmp = stoch(Z, kind=:slow)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 2
        tmp = smi(Z)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 2
    end
end

# volatility functions
@testset "Volatility" begin
    Random.seed!(SEED)
    @testset "Array" begin
        x = cumsum(randn(N))
        X = cumsum(randn(N, 3), dims=1)
        tmp = bbands(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 3
        @test sum(isnan.(tmp)) != N
        tmp = tr(X)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = atr(X)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = keltner(X)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 3
        @test sum(isnan.(tmp)) != N
    end
    @testset "Temporal" begin
        x = TS(cumsum(randn(N)))
        X = TS(cumsum(randn(N, 3), dims=1))
        tmp = bbands(x)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 3
        tmp = tr(X)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = atr(X)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        tmp = keltner(X)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 3
    end
end

# chart patterns functions
@testset "Charting" begin
    Random.seed!(SEED)
    @testset "Array" begin
        X = cumsum(randn(N, 3), dims=1)
        tmp = renko(X, use_atr=true)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
        tmp = renko(X, use_atr=false)
        @test size(tmp, 1) == N
        @test size(tmp, 2) == 1
        @test sum(isnan.(tmp)) != N
    end
end
