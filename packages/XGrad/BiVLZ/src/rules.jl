
## rules.jl - derivative rules
##
## These rules have been shamelessly stolen from
## https://github.com/JuliaDiff/ReverseDiffSource.jl/blob/master/src/base_rules.jl
##
## NOTE: `ds` stands for a gradient of loss w.r.t. current output variables.
## E.g. if `y = f(x)` and we are currently calculating gradient `dloss / dx`,
## then `ds` will be substituted with `dloss / dy`.


const DIFF_RULES = Array{Pair{Expr,Pair{Symbol,Any}},1}()


macro diffrule(pat, var, rpat)
    pat, rpat = map(sanitize, (pat, rpat))
    push!(DIFF_RULES, pat => (var => rpat))
    nothing
end

# derivation neutral functions
@diffrule colon(x,y)   x     0.0
@diffrule colon(x,y)   y     0.0

@diffrule length(x)    x     0.0

@diffrule size(x)      x     0.0
@diffrule size(x,y)    x     0.0
@diffrule size(x,y)    y     0.0

@diffrule fill(x,y)    x     0.0
@diffrule fill(x,y)    y     0.0

@diffrule similar(x,y) x     0.0
@diffrule similar(x,y) y     0.0

@diffrule zeros(x)     x     0.0

@diffrule ones(x)      x     0.0

@diffrule cell(x)      x     0.0

@diffrule sign(x)      x     0.0

@diffrule reverse(x)   x     0.0

#  tuple  TODO : specialized macro for this kind of function
@diffrule tuple(x)        x     ds[1]
@diffrule tuple(x,y)      x     ds[1]
@diffrule tuple(x,y)      y     ds[2]
@diffrule tuple(x,y,z)    x     ds[1]
@diffrule tuple(x,y,z)    y     ds[2]
@diffrule tuple(x,y,z)    z     ds[3]
@diffrule tuple(x,y,z,t)  x     ds[1]
@diffrule tuple(x,y,z,t)  y     ds[2]
@diffrule tuple(x,y,z,t)  z     ds[3]
@diffrule tuple(x,y,z,t)  t     ds[4]

#  vcat
@diffrule vcat(x)        x     ds[1]
@diffrule vcat(x,y)      x     ds[1]
@diffrule vcat(x,y)      y     ds[2]
@diffrule vcat(x,y,z)    x     ds[1]
@diffrule vcat(x,y,z)    y     ds[2]
@diffrule vcat(x,y,z)    z     ds[3]
@diffrule vcat(x,y,z,t)  x     ds[1]
@diffrule vcat(x,y,z,t)  y     ds[2]
@diffrule vcat(x,y,z,t)  z     ds[3]
@diffrule vcat(x,y,z,t)  t     ds[4]

# reshape
@diffrule reshape(x::AbstractArray, _a, _b)         x    reshape(ds, size(x))
@diffrule reshape(x::AbstractArray, _a, _b)        _a    0.0
@diffrule reshape(x::AbstractArray, _a, _b)        _b    0.0
@diffrule reshape(x::AbstractArray, _d::Tuple)      x    reshape(ds, size(x))
@diffrule reshape(x::AbstractArray, _d::Tuple)     _d    0.0


@diffrule getindex(x::AbstractArray, i)         x    ungetindex(x, ds, i)
@diffrule getindex(x::AbstractArray, i, j)      x    ungetindex(x, ds, i, j)
@diffrule getindex(x::AbstractArray, i, j, k)   x    ungetindex(x, ds, i, j, k)
@diffrule getindex(x::AbstractArray, i)         i    0
@diffrule getindex(x::AbstractArray, i, j)      i    0
@diffrule getindex(x::AbstractArray, i, j)      j    0
@diffrule getindex(x::AbstractArray, i, j, k)   i    0
@diffrule getindex(x::AbstractArray, i, j, k)   j    0
@diffrule getindex(x::AbstractArray, i, j, k)   k    0


# square root
@diffrule sqrt(x::Real)              x     0.5 * x ^ (-0.5) * ds
@diffrule sqrt(x::AbstractVector)    x     0.5 .* x .^ (-0.5) .* ds

# addition
@diffrule +(x::Real         , y::Real )            x     ds
@diffrule +(x::AbstractArray, y::AbstractArray)    x     ds
@diffrule +(x::Real         , y::Real )            y     ds
@diffrule +(x::AbstractArray, y::AbstractArray)    y     ds

# deprecated
# @diffrule +(x::Real         , y::AbstractArray)    x     sum(ds)
# @diffrule +(x::AbstractArray, y       )            x     ds
# @diffrule +(x::AbstractArray, y::Real )            y     sum(ds)
# @diffrule +(x               , y::AbstractArray)    y     ds

# dot addition
@diffrule .+(x::Real, y::Real)                      x     ds
@diffrule .+(x::Real, y::AbstractArray)             x     sum(ds)
@diffrule .+(x::AbstractArray, y::Real)             x     ds
@diffrule .+(x::AbstractVector, y::AbstractMatrix)  x     squeeze_sum(ds, 2)
@diffrule .+(x::AbstractArray, y::AbstractArray)    x     ds

@diffrule .+(x::Real, y::Real)                      y     ds
@diffrule .+(x::Real, y::AbstractArray)             y     ds
@diffrule .+(x::AbstractArray, y::Real)             y     sum(ds)
@diffrule .+(x::AbstractMatrix, y::AbstractVector)  y     squeeze_sum(ds, 2)
@diffrule .+(x::AbstractArray, y::AbstractArray)    y     ds

# unary substraction
@diffrule -(x::Real )                               x     -ds
@diffrule -(x::AbstractArray)                       x     -ds

# binary substraction
@diffrule -(x::Real, y::Real)                       x     ds
# @diffrule -(x::Real, y::AbstractArray)              x     sum(ds)
# @diffrule -(x::AbstractArray, y::Real)              x     ones(size(x)) .* ds
@diffrule -(x::AbstractArray, y::AbstractArray)     x     ds
@diffrule -(x::Real         , y::Real)              y     -ds
# @diffrule -(x::Real, y::AbstractArray)              y     -ones(size(y)) .* ds
# @diffrule -(x::AbstractArray, y::Real)              y     -sum(ds)
@diffrule -(x::AbstractArray, y::AbstractArray)     y     -ds

# dot binary substraction
@diffrule .-(x::Real, y::Real)                      x     ds
@diffrule .-(x::Real, y::AbstractArray)             x     sum(ds)
@diffrule .-(x::AbstractArray, y::Real)             x     ones(size(x)) .* ds
@diffrule .-(x::AbstractVector, y::AbstractMatrix)  x     squeeze_sum(ds, 2)
@diffrule .-(x::AbstractArray, y::AbstractArray)    x     ds
@diffrule .-(x::Real, y::Real)                      y     -ds
@diffrule .-(x::Real, y::AbstractArray)             y     -ones(size(y)) .* ds
@diffrule .-(x::AbstractArray, y::Real)             y     -sum(ds)
@diffrule .-(x::AbstractMatrix, y::AbstractVector)  y     -squeeze_sum(ds, 2)
@diffrule .-(x::AbstractArray, y::AbstractArray)    y     -ds

# sum() and mean()
@diffrule sum(x::Real)                              x     ds
@diffrule sum(x::AbstractArray)                     x     sum_grad(x, ds)
# @diffrule sum(x::AbstractArray, y::Int)             x     ones(size(x)) .* ds
# @diffrule sum(x::AbstractArray, y::Int)             y     0.0

@diffrule mean(x::Real)                             x     ds
@diffrule mean(x::AbstractArray)                    x     ones(size(x)) ./ length(x) .* ds
@diffrule mean(x::AbstractArray, y::Int)            x     ones(size(x)) ./ length(x) .* ds
@diffrule mean(x::AbstractArray, y::Int)            y     0.0

# dot()
@diffrule dot(x::Real, y::Real)                     x     y * ds
@diffrule dot(x::Real, y::Real)                     y     x * ds

@diffrule dot(x::AbstractArray, y::AbstractArray)   x     y.*ds
@diffrule dot(x::AbstractArray, y::AbstractArray)   y     x.*ds

# log() and exp()
@diffrule log(x::Real )                            x     ds / x
@diffrule log(x::AbstractArray)                    x     ds ./ x

@diffrule exp(x::Real )                            x     exp(x) * ds
@diffrule exp(x::AbstractArray)                    x     exp(x) .* ds

@diffrule log1p(x::Real)                           x     ds  / (1 + x)
@diffrule log1p(x::AbstractArray)                  x     ds ./ (1 + x)

@diffrule expm1(x::Real)                           x     (1.0 + expm1(x))  * ds
@diffrule expm1(x::AbstractArray)                  x     (1.0 + expm1(x)) .* ds
# note : derivative uses expm1() and not exp() to reuse the
#   already calculated expm1()

# trig functions
@diffrule sin(x::Real )                            x     cos(x) * ds
@diffrule sin(x::AbstractArray)                    x     cos(x) .* ds

@diffrule cos(x::Real )                            x     -sin(x) * ds
@diffrule cos(x::AbstractArray)                    x     -sin(x) .* ds

@diffrule tan(x::Real )                            x     (1.0 + tan(x)  * tan(x))  * ds
@diffrule tan(x::AbstractArray)                    x     (1.0 + tan(x) .* tan(x)) .* ds

@diffrule sinh(x::Real )                           x     cosh(x) * ds
@diffrule sinh(x::AbstractArray)                   x     cosh(x) .* ds

@diffrule cosh(x::Real )                           x     sinh(x) * ds
@diffrule cosh(x::AbstractArray)                   x     sinh(x) .* ds

@diffrule tanh(x::Real )                           x     (1.0 - tanh(x)  * tanh(x))  * ds
@diffrule tanh(x::AbstractArray)                   x     (1.0 - tanh(x) .* tanh(x)) .* ds

@diffrule asin(x::Real )                           x     ds  / sqrt(1 - x *x)
@diffrule asin(x::AbstractArray)                   x     ds ./ sqrt(1 - x.*x)

@diffrule acos(x::Real )                           x     -ds  / sqrt(1 - x *x)
@diffrule acos(x::AbstractArray)                   x     -ds ./ sqrt(1 - x.*x)

@diffrule atan(x::Real )                           x     ds  / (1 + x *x)
@diffrule atan(x::AbstractArray)                   x     ds ./ (1 + x.*x)


# round, floor, ceil, trunc, mod2pi
@diffrule round(x::Real)                           x     0.0
@diffrule round(x::AbstractArray)                  x     0.0

@diffrule floor(x::Real)                           x     0.0
@diffrule floor(x::AbstractArray)                  x     0.0

@diffrule ceil(x::Real)                            x     0.0
@diffrule ceil(x::AbstractArray)                   x     0.0

@diffrule trunc(x::Real)                           x     0.0
@diffrule trunc(x::AbstractArray)                  x     0.0

@diffrule mod2pi(x::Real)                          x     ds


# abs, max(), min()
@diffrule abs(x::Real)                             x     sign(x) * ds
@diffrule abs2(x::Real)                            x     2.0 .* x .* ds


@diffrule max(x::Real         , y::Real)           x     (x > y) * ds
@diffrule max(x::Real         , y::AbstractArray)  x     sum((x .> y) .* ds)
@diffrule max(x::AbstractArray, y::Real)           x     (x .> y) .* ds
@diffrule max(x::AbstractArray, y::AbstractArray)  x     (x .> y) .* ds

@diffrule max(x::Real         , y::Real)           y     (x < y) * ds
@diffrule max(x::Real         , y::AbstractArray)  y     (x .< y) .* ds
@diffrule max(x::AbstractArray, y::Real)           y     sum((x .< y) .* ds)
@diffrule max(x::AbstractArray, y::AbstractArray)  y     (x .< y) .* ds

@diffrule min(x::Real         , y::Real)           x     (x < y) * ds
@diffrule min(x::Real         , y::AbstractArray)  x     sum((x .< y) .* ds)
@diffrule min(x::AbstractArray, y::Real)           x     (x .< y) .* ds
@diffrule min(x::AbstractArray, y::AbstractArray)  x     (x .< y) .* ds

@diffrule min(x::Real         , y::Real)           y     (x > y) * ds
@diffrule min(x::Real         , y::AbstractArray)  y     (x .> y) .* ds
@diffrule min(x::AbstractArray, y::Real)           y     sum((x .> y) .* ds)
@diffrule min(x::AbstractArray, y::AbstractArray)  y     (x .> y) .* ds

# maximum, minimum
@diffrule maximum(x::Real         )     x     ds
@diffrule maximum(x::AbstractArray)     x     (x .== maximum(x)) .* ds

@diffrule minimum(x::Real         )     x     ds
@diffrule minimum(x::AbstractArray)     x     (x .== minimum(x)) .* ds


# multiplication
@diffrule *(x::Real         , y::Real )            x     y * ds
@diffrule *(x::Real         , y::AbstractArray)    x     sum(y .* ds)
@diffrule *(x::AbstractArray, y::Real )            x     y .* ds
@diffrule *(x::AbstractArray, y::AbstractArray)    x     ds * y'

@diffrule *(x::Real         , y::Real )            y     x * ds
@diffrule *(x::Real         , y::AbstractArray)    y     x .* ds
@diffrule *(x::AbstractArray, y::Real )            y     sum(x .* ds)
@diffrule *(x::AbstractArray, y::AbstractArray)    y     x' * ds

# dot multiplication
@diffrule .*(x::Real, y::Real)                     x     y .* ds
@diffrule .*(x::Real, y::AbstractArray)            x     sum(y .* ds)
@diffrule .*(x::AbstractArray, y::Real)            x     y .* ds
@diffrule .*(x::AbstractVector, y::AbstractMatrix) x     squeeze_sum(ds .* y, 2) # ?
@diffrule .*(x::AbstractArray, y::AbstractArray)   x     y .* ds

@diffrule .*(x::Real, y::Real)                     y     x * ds
@diffrule .*(x::Real, y::AbstractArray)            y     x .* ds
@diffrule .*(x::AbstractArray, y::Real)            y     sum(x .* ds)
@diffrule .*(x::AbstractMatrix, y::AbstractVector) y     squeeze_sum(ds .* x, 2) # ?
@diffrule .*(x::AbstractArray, y::AbstractArray)   y     x .* ds

# power  (both args reals)
@diffrule ^(x::Real, y::Real)                      x     y * x ^ (y-1) * ds
@diffrule ^(x::Real, y::Real)                      y     log(x) * x ^ y * ds

# dot power
@diffrule .^(x::Real         , y::Real )           x     y * x ^ (y-1) * ds
@diffrule .^(x::Real         , y::AbstractArray)   x     sum(y .* x .^ (y-1) .* ds)
@diffrule .^(x::AbstractArray, y::Real )           x     y .* x .^ (y-1) .* ds
@diffrule .^(x::AbstractArray, y::AbstractArray)   x     y .* x .^ (y-1) .* ds

@diffrule .^(x::Real         , y::Real )           y     log(x) * x ^ y * ds
@diffrule .^(x::AbstractArray, y::Real )           y     sum( log(x) .* x .^ y .* ds)
@diffrule .^(x::Real         , y::AbstractArray)   y     log(x) .* x .^ y .* ds
@diffrule .^(x::AbstractArray, y::AbstractArray)   y     log(x) .* x .^ y .* ds

# division
@diffrule /(x::Real          , y::Real )           x     ds / y
@diffrule /(x::AbstractArray , y::Real )           x     ds ./ y

@diffrule /(x::Real          , y::Real )           y     -x * ds / (y * y)
@diffrule /(x::AbstractArray , y::Real )           y     sum(-x .* ds) / (y * y)

# dot division
@diffrule ./(x::Real         , y::Real )           x     ds / y
@diffrule ./(x::Real         , y::AbstractArray)   x     sum(ds ./ y)
@diffrule ./(x::AbstractArray, y::Real )           x     ds ./ y
@diffrule ./(x::AbstractArray, y::AbstractArray)   x     ds ./ y

@diffrule ./(x::Real         , y::Real )           y     -x * ds / (y * y)
@diffrule ./(x::Real         , y::AbstractArray)   y     -x * ds ./ (y .* y)
@diffrule ./(x::AbstractArray, y::Real )           y     -sum(x .* ds) / (y * y)
@diffrule ./(x::AbstractArray, y::AbstractArray)   y     -x .* ds ./ (y .* y)

# transpose
@diffrule transpose(x::Real )                      x     ds
@diffrule transpose(x::AbstractArray)              x     transpose(ds)

# erf, erfc, gamma, beta, lbeta, lgamma
@diffrule erf(x::Real)                       x     2.0/sqrt(π) * exp(-x  * x)  * ds
@diffrule erf(x::AbstractArray)              x     2.0/sqrt(π) .* exp(-x .* x) .* ds

@diffrule erfc(x::Real)                      x     -2.0/sqrt(π) * exp(-x  * x)  * ds
@diffrule erfc(x::AbstractArray)             x     -2.0/sqrt(π) .* exp(-x .* x) .* ds

@diffrule gamma(x::Real)                     x     polygamma(0,x)  * gamma(x)  * ds
@diffrule gamma(x::AbstractArray)            x     polygamma(0,x) .* gamma(x) .* ds

@diffrule lgamma(x::Real)                    x     polygamma(0,x)  * ds
@diffrule lgamma(x::AbstractArray)           x     polygamma(0,x) .* ds

@diffrule beta(x::Real         , y::Real)            x   beta(x,y)  * (digamma(x)-digamma(x+y))  * ds
@diffrule beta(x::AbstractArray, y::AbstractArray)   x   beta(x,y) .* (digamma(x)-digamma(x+y)) .* ds
@diffrule beta(x::Real         , y::Real)            y   beta(x,y)  * (digamma(y)-digamma(x+y))  * ds
@diffrule beta(x::AbstractArray, y::AbstractArray)   y   beta(x,y) .* (digamma(y)-digamma(x+y)) .* ds

@diffrule lbeta(x::Real         , y::Real)            x   (polygamma(0,x)-polygamma(0,x+y))  * ds
@diffrule lbeta(x::AbstractArray, y::AbstractArray)   x   (polygamma(0,x)-polygamma(0,x+y)) .* ds
@diffrule lbeta(x::Real         , y::Real)            y   (polygamma(0,y)-polygamma(0,x+y))  * ds
@diffrule lbeta(x::AbstractArray, y::AbstractArray)   y   (polygamma(0,y)-polygamma(0,x+y)) .* ds
