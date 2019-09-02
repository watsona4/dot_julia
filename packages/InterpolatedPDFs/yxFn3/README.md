# InterpolatedPDFs.jl
[![Build Status](https://travis-ci.com/m-wells/InterpolatedPDFs.jl.svg?branch=master)](https://travis-ci.com/m-wells/InterpolatedPDFs.jl)
[![codecov](https://codecov.io/gh/m-wells/InterpolatedPDFs.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/m-wells/InterpolatedPDFs.jl)
[![Coverage Status](https://coveralls.io/repos/github/m-wells/InterpolatedPDFs.jl/badge.svg?branch=master)](https://coveralls.io/github/m-wells/InterpolatedPDFs.jl?branch=master&kill_cache=1)

Simple extension of [Distributions.jl](https://github.com/JuliaStats/Distributions.jl) providing support for interpolated pdfs.
Currently only one type is implemented

```
LinearInterpolatedPDF{T,1,ITP,IT} <: ContinuousUnivariateDistribution
```

A continuous univariate linearly interpolated distribution.
The pdf, cdf, and inverse cdf are interpolated using [Interpolations.jl](https://github.com/JuliaMath/Interpolations.jl).

# Examples
The easiest way to create a distribution is to use `fit_cpl`
```
julia> x = range(0,pi/2,length=10)
0.0:0.17453292519943295:1.5707963267948966

julia> s = acos.(rand(1000));

julia> d = fit_cpl(x,s)
LinearInterpolatedPDF{Float64,1,Interpolations.ScaledInterpolation{Float64,1,Interpolations.BSplineInterpolation{Float64,1,Array{Float64,1},Interpolations.BSpline{Interpolations.Linear},Tuple{Base.OneTo{Int64}}},Interpolations.BSpline{Interpolations.Linear},Tuple{StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}}}},Interpolations.BSpline{Interpolations.Linear}}(
pdf_itp: 10-element extrapolate(scale(interpolate(::Array{Float64,1}, BSpline(Interpolations.Linear())), (0.0:0.17453292519943295:1.5707963267948966,)), Throw()) with element type Float64:
 0.02655632680672288
 0.18866696639956113
 0.37005881440239063
 0.45112960446603656
 0.6649161652243859
 0.8050441586869701
 0.7890753253462918
 0.89708286054468
 1.042727491447746
 1.0151968027736178
cdf_itp: 10-element extrapolate(scale(interpolate(::Array{Float64,1}, BSpline(Interpolations.Linear())), (0.0:0.17453292519943295:1.5707963267948966,)), Throw()) with element type Float64:
 0.0
 0.018781775467173994
 0.06753979792102491
 0.1392020063635268
 0.23659537278378787
 0.36487361041346533
 0.5039867787463332
 0.6511318390125935
 0.8204122265452835
 1.0
invcdf_itp: 10-element extrapolate(interpolate((::Array{Float64,1},), ::Array{Float64,1}, Gridded(Interpolations.Linear())), Throw()) with element type Float64:
 0.0
 0.17453292519943295
 0.3490658503988659
 0.5235987755982988
 0.6981317007977318
 0.8726646259971648
 1.0471975511965976
 1.2217304763960306
 1.3962634015954636
 1.5707963267948966
)
```

After fitting the distribution you can do useful things like
```
julia> pdf(d,1)
0.7933936499734955

julia> cdf(d,0.5)
0.12951248575312788

julia> quantile(d,0.9)
1.4736110218924767

julia> rand(d,10)
10-element Array{Float64,1}:
 0.27565417806686643
 1.074337923663701
 1.237530643864552
 0.4744230962935516
 1.18776692814955
 0.8436400094154567
 1.0835325983972564
 1.1413257453616537
 0.8701141622223004
 1.1702951450424084
```
