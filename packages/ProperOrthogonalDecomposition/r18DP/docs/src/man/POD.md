# POD
Each method returns a tuple containing the pod basis of type `PODBasis{T}` and 
the corresponding singular values. The singular values are related to each modes importance
to the dataset. 

## Method of snapshots
The eigen-decomposition based *method of snapshots* is the most commonly used
 method for fluid flow analysis where the number of datapoints is larger than the number of snapshots.

```@docs
PODeigen(X; subtractmean::Bool = false)
```
```@docs
PODeigen!(X; subtractmean::Bool = false)
```

## Singular Value Decomposition based method
The SVD based approach is also available and is more robust against roundoff errors. 
```@docs
PODsvd(X; subtractmean::Bool = false)
```
```@docs
PODsvd!(X; subtractmean::Bool = false)
```

## Example
Here we will artifically create data which is PODed and then extract the first mode.

```@example poddata
t, x = range(0, stop=30, length=50), range(-10, stop=30, length=120)

Xgrid = [i for i in x, j in t]
tgrid = [j for i in x, j in t]

f1 = sech.(Xgrid.-3.5) .* 10.0 .* cos.(0.5 .*tgrid)
f2 = cos.(Xgrid) .* 1.0 .* cos.(2.5 .*tgrid)
f3 = sech.(Xgrid.+5.0) .* 4.0 .* cos.(1.0 .*tgrid)

Y = f1+f2+f3

using PlotlyJS # hide

function plotpoddata(Y) # hide
    trace = surface(x=Xgrid,y=tgrid,z=Y,colorscale="Viridis", cmax=7.5, cmin=-7.5) # hide
    layout = Layout(height=440, # hide
                    scene = (   xaxis=attr(title="Space"), # hide
                                yaxis=attr(title="Time"), # hide
                                zaxis=attr(title="z",range=[-10,10])), # hide
                    margin=attr(l=30, r=30, b=20, t=90), # hide
                    ) # hide
    plot(trace, layout) # hide
end # hide
p = plotpoddata(Y) # hide
pkgpath = abspath(joinpath(dirname(Base.find_package("ProperOrthogonalDecomposition")), "..")) # hide
savedir = joinpath(pkgpath,"docs","src","assets","poddata.html") # hide
PlotlyJS.savehtml(p,savedir,:embed) # hide
```
Our data `Y` looks like this

```@raw html
    <iframe src="../assets/poddata.html" height="540" width="765" frameborder="0" seamless="seamless" scrolling="no"></iframe>
```


Now we POD the data and reconstruct the dataset using only the first mode.
```@example poddata
using ProperOrthogonalDecomposition # hide
res, singularvals  = POD(Y)
reconstructFirstMode = res.modes[:,1:1]*res.coefficients[1:1,:]

p = plotpoddata(reconstructFirstMode) # hide
pkgpath = abspath(joinpath(dirname(Base.find_package("ProperOrthogonalDecomposition")), "..")) # hide
savedir = joinpath(pkgpath,"docs","src","assets","podfirstmode.html") # hide
PlotlyJS.savehtml(p,savedir,:embed) # hide
```

Note that the above used `POD(Y)` which defaults to the SVD based apparoch.
The first mode over the time series looks like this

```@raw html
    <iframe src="../assets/podfirstmode.html" height="540" width="765" frameborder="0" seamless="seamless" scrolling="no"></iframe>
```






