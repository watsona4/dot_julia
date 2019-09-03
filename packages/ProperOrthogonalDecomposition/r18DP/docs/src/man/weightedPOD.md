# Weighted POD
When performing the POD method it is assumed that the datapoints are equidistantly spaced. 
This assumption makes the method sensistive to the local mesh resolution. To make the method mesh
independent, a vector with weights for each datapoint can be supplied. Typically the weights
are chosen to be the cell volume, although the face area can be used in the case of a plane. 

```@docs
PODeigen(X,W::AbstractVector; subtractmean::Bool = false)
```
```@docs
PODeigen!(X,W::AbstractVector; subtractmean::Bool = false)
```
```@docs
PODsvd(X,W::AbstractVector; subtractmean::Bool = false)
```
```@docs
PODsvd!(X,W::AbstractVector; subtractmean::Bool = false)
```

## Example
Here we create the same data as in the previous example; however, we refine the 
mesh locally, at `x>7.5 && x<=30` and plot the reconstructed data from the first mode.

### Non-uniform grid *without* weights
```@example weightedpod

t, xcoarse = range(0, stop=30, length=50), range(-10, stop=7.5, length=30)
xfine = range(7.5+step(xcoarse), stop=30, length=1000)

x = [xcoarse...,xfine...]
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

using ProperOrthogonalDecomposition # hide
res, singularvals  = POD(Y)
reconstructFirstMode = res.modes[:,1:1]*res.coefficients[1:1,:]
p = plotpoddata(reconstructFirstMode) # hide
pkgpath = abspath(joinpath(dirname(Base.find_package("ProperOrthogonalDecomposition")), "..")) # hide
savedir = joinpath(pkgpath,"docs","src","assets","finemeshfirstmode.html") # hide
PlotlyJS.savehtml(p,savedir,:embed) # hide
```
And the first three singular values.
```@example weightedpod
singularvals[1:3]
```
The first mode has changed due to the local mesh refinement compated to the previously
presented case with equidistant mesh.

```@raw html
    <iframe src="../assets/finemeshfirstmode.html" height="540" width="765" frameborder="0" seamless="seamless" scrolling="no"></iframe>
```

### Non-uniform grid *with* weights

Using the volume weighted formulation removes the mesh depedency and we get the correct
modes back. 
```@example weightedpod
grid_resolution = [repeat([step(xcoarse)],length(xcoarse));
                   repeat([step(xfine)],length(xfine))]
res, singularvals  = POD(Y,grid_resolution)
reconstructFirstMode = res.modes[:,1:1]*res.coefficients[1:1,:]

p = plotpoddata(reconstructFirstMode) # hide
pkgpath = abspath(joinpath(dirname(Base.find_package("ProperOrthogonalDecomposition")), "..")) # hide
savedir = joinpath(pkgpath,"docs","src","assets","finemeshfirstmodeweighted.html") # hide
PlotlyJS.savehtml(p,savedir,:embed) # hide
```
And the first three singular values.
```@example weightedpod
singularvals[1:3]
```
```@raw html
    <iframe src="../assets/finemeshfirstmodeweighted.html" height="540" width="765" frameborder="0" seamless="seamless" scrolling="no"></iframe>
```

### Uniform grid with weights

Compare the singular values from the above two cases with the singular values 
from the weighted POD on the equidistant mesh.
```@example weightedpod
t, x = range(0, stop=30, length=50), range(-10, stop=30, length=120)
grid_resolution = repeat([step(x)],length(x))

Xgrid = [i for i in x, j in t]
tgrid = [j for i in x, j in t]

f1 = sech.(Xgrid.-3.5) .* 10.0 .* cos.(0.5 .*tgrid)
f2 = cos.(Xgrid) .* 1.0 .* cos.(2.5 .*tgrid)
f3 = sech.(Xgrid.+5.0) .* 4.0 .* cos.(1.0 .*tgrid)

Y = f1+f2+f3

res, singularvals  = POD(Y,grid_resolution)
nothing # hide
```
And the first three singular values.
```@example weightedpod
singularvals[1:3]
```








