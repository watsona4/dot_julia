# Methods for porting Indicators.jl functions to TS objects from Temporal.jl package
function close_fun(X::TS, f::Function, flds::Vector{Symbol}; args...)
    if size(X,2) == 1
        return ts(f(X.values; args...), X.index, flds)
    elseif size(X,2) > 1 && has_close(X)
        return ts(f(cl(X).values; args...), X.index, flds)
    else
        error("Must be univariate or contain Close/Settle/Last.")
    end
end
function hlc_fun(X::TS, f::Function, flds::Vector{Symbol}; args...)
    if size(X,2) == 3
        return ts(f(X.values; args...), X.index, flds)
    elseif size(X,2) > 3 && has_high(X) && has_low(X) && has_close(X)
        return ts(f(hlc(X).values; args...), X.index, flds)
    else
        error("Argument must have 3 columns or have High, Low, and Close/Settle/Last fields.")
    end
end
function hl_fun(X::TS, f::Function, flds::Vector{Symbol}; args...)
    if size(X,2) == 2
        return ts(f(X.values; args...), X.index, flds)
    elseif size(X,2) > 2 && has_high(X) && has_low(X)
        return ts(f(hl(X).values; args...), X.index, flds)
    else
        error("Argument must have 2 columns or have High and Low fields.")
    end
end

###### run.jl ######
function runcov(x::TS{V,T}, y::TS{V,T}; args...) where {V,T}
    @assert size(x,2) == 1 && size(y,2) == 1 "Arguments x and y must both be univariate (have only one column)."
    z = [x y].values
    return ts(runcov(z[:,1], z[:,2]; args...), x.index, :RunCov)
end
function runcor(x::TS{V,T}, y::TS{V,T}; args...) where {V,T}
    @assert size(x,2) == 1 && size(y,2) == 1 "Arguments x and y must both be univariate (have only one column)."
    z = [x y].values
    ts(runcor(z[:,1], z[:,2]; args...), x.index, :RunCor)
end
mode(X::TS{V,T}) where {V,T} = mode(X.values)
runmean(X::TS{V,T}; args...) where {V,T} = close_fun(X, runmean, [:RunMean]; args...)
runsum(X::TS{V,T}; args...) where {V,T} = close_fun(X, runsum, [:RunSum]; args...)
runmad(X::TS{V,T}; args...) where {V,T} = close_fun(X, runmad, [:RunMAD]; args...)
runvar(X::TS{V,T}; args...) where {V,T} = close_fun(X, runvar, [:RunVar]; args...)
runmax(X::TS{V,T}; args...) where {V,T} = close_fun(X, runmax, [:RunMax]; args...)
runmin(X::TS{V,T}; args...) where {V,T} = close_fun(X, runmin, [:RunMin]; args...)
runsd(X::TS{V,T}; args...) where {V,T} = close_fun(X, runsd, [:RunSD]; args...)
runquantile(X::TS{V,T}; args...) where {V,T} = close_fun(X, runquantile, [:RunQuantile]; args...)
wilder_sum(X::TS{V,T}; args...) where {V,T} = close_fun(X, wilder_sum, [:WilderSum]; args...)
runacf(X::TS{V,T}; n::Int=10, maxlag::Int=n-3, lags::AbstractArray{Int,1}=0:maxlag, cumulative::Bool=true) where {V,T} = close_fun(X, runacf, [Symbol(i) for i in lags]; n=n, maxlag=maxlag, lags=lags, cumulative=cumulative)
runfun(X::TS, f::Function; n::Int=10, cumulative::Bool=true, args...) = TS(runfun(X, f, n=n, cumulative=cumulative, args...), X.index, [:Function])

##### ma.jl ######
sma(X::TS{V,T}; args...) where {V,T} = close_fun(X, sma, [:SMA]; args...)
hma(X::TS{V,T}; args...) where {V,T} = close_fun(X, hma, [:HMA]; args...)
mma(X::TS{V,T}; args...) where {V,T} = close_fun(X, mma, [:MMA]; args...)
swma(X::TS{V,T}; args...) where {V,T} = close_fun(X, swma, [:SWMA]; args...)
kama(X::TS{V,T}; args...) where {V,T} = close_fun(X, kama, [:KAMA]; args...)
alma(X::TS{V,T}; args...) where {V,T} = close_fun(X, alma, [:ALMA]; args...)
trima(X::TS{V,T}; args...) where {V,T} = close_fun(X, trima, [:TRIMA]; args...)
wma(X::TS{V,T}; args...) where {V,T} = close_fun(X, wma, [:WMA]; args...)
ema(X::TS{V,T}; args...) where {V,T} = close_fun(X, ema, [:EMA]; args...)
dema(X::TS{V,T}; args...) where {V,T} = close_fun(X, dema, [:DEMA]; args...)
tema(X::TS{V,T}; args...) where {V,T} = close_fun(X, tema, [:TEMA]; args...)
zlema(X::TS{V,T}; args...) where {V,T} = close_fun(X, zlema, [:ZLEMA]; args...)
mama(X::TS{V,T}; args...) where {V,T} = close_fun(X, mama, [:MAMA,:FAMA]; args...)

##### reg.jl ######
mlr_beta(X::TS{V,T}; args...) where {V,T} = close_fun(X, mlr_beta, [:Intercept,:Slope]; args...)
mlr_slope(X::TS{V,T}; args...) where {V,T} = close_fun(X, mlr_slope, [:Slope]; args...)
mlr_intercept(X::TS{V,T}; args...) where {V,T} = close_fun(X, mlr_intercept, [:Intercept]; args...)
mlr(X::TS{V,T}; args...) where {V,T} = close_fun(X, mlr, [:MLR]; args...)
mlr_se(X::TS{V,T}; args...) where {V,T} = close_fun(X, mlr_se, [:StdErr]; args...)
mlr_ub(X::TS{V,T}; args...) where {V,T} = close_fun(X, mlr_ub, [:MLRUB]; args...)
mlr_lb(X::TS{V,T}; args...) where {V,T} = close_fun(X, mlr_lb, [:MLRLB]; args...)
mlr_bands(X::TS{V,T}; args...) where {V,T} = close_fun(X, mlr_bands, [:MLRLB,:MLR,:MLRUB]; args...)
mlr_rsq(X::TS{V,T}; args...) where {V,T} = close_fun(X, mlr_rsq, [:RSquared]; args...)

##### mom.jl ######
momentum(X::TS{V,T}; args...) where {V,T} = close_fun(X, momentum, [:Momentum]; args...)
roc(X::TS{V,T}; args...) where {V,T} = close_fun(X, roc, [:ROC]; args...)
macd(X::TS{V,T}; args...) where {V,T} = close_fun(X, macd, [:MACD,:Signal,:Histogram]; args...)
rsi(X::TS{V,T}; args...) where {V,T} = close_fun(X, rsi, [:RSI]; args...)
psar(X::TS{V,T}; args...) where {V,T} = hl_fun(X, psar, [:PSAR]; args...)
kst(X::TS{V,T}; args...) where {V,T} = close_fun(X, kst, [:KST]; args...)
wpr(X::TS{V,T}; args...) where {V,T} = hlc_fun(X, wpr, [:WPR]; args...)
adx(X::TS{V,T}; args...) where {V,T} = hlc_fun(X, adx, [:DiPlus,:DiMinus,:ADX]; args...)
cci(X::TS{V,T}; args...) where {V,T} = hlc_fun(X, cci, [:CCI]; args...)
stoch(X::TS{V,T}; args...) where {V,T} = hlc_fun(X, stoch, [:Stochastic,:Signal]; args...)
smi(X::TS{V,T}; args...) where {V,T} = hlc_fun(X, smi, [:SMI,:Signal]; args...)
donch(X::TS{V,T}; args...) where {V,T} = hl_fun(X, donch, [:Low,:Mid,:High]; args...)
aroon(X::TS{V,T}; args...) where {V,T} = hl_fun(X, aroon, [:AroonUp,:AroonDn,:AroonOsc]; args...)

##### vol.jl ######
bbands(X::TS{V,T}; args...) where {V,T} = close_fun(X, bbands, [:LB,:MA,:UB]; args...)
tr(X::TS{V,T}; args...) where {V,T} = hlc_fun(X, tr, [:TR]; args...)
atr(X::TS{V,T}; args...) where {V,T} = hlc_fun(X, atr, [:ATR]; args...)
keltner(X::TS{V,T}; args...) where {V,T} = hlc_fun(X, keltner, [:KeltnerLower,:KeltnerMiddle,:KeltnerUpper]; args...)

##### trendy.jl #####
maxima(X::TS{V,T}; args...) where {V,T} = close_fun(X, maxima, [:Maxima]; args...)
minima(X::TS{V,T}; args...) where {V,T} = close_fun(X, minima, [:Minima]; args...)
support(X::TS{V,T}; args...) where {V,T} = close_fun(X, support, [:Support]; args...)
resistance(X::TS{V,T}; args...) where {V,T} = close_fun(X, resistance, [:Resistance]; args...)

#### utils.jl ####
crossover(x::TS, y::TS) = ts(crossover(x.values, y.values), x.index, [:CrossOver])
crossunder(x::TS, y::TS) = ts(crossunder(x.values, y.values), x.index, [:CrossUnder])

#### chaos.jl ####
hurst(x::TS; args...) = close_fun(x, hurst, [:Hurst]; args...)
rsrange(x::TS; args...) = close_fun(x, rsrange, [:RS]; args...)
