# Mode convergence

Functionality to investigate convergence is supplied in this packages where the
convergence in time and frequency can be investigated.

```@docs
modeConvergence(X::AbstractArray, PODfun, stops::AbstractArray{<: AbstractRange}, numModes::Int)
```
```@docs
modeConvergence!(loadFun, PODfun, stops::AbstractArray{<: AbstractRange}, numModes::Int)
```

## Example

### Convergence in time
```@example convergence
using PlotlyJS # hide
using ProperOrthogonalDecomposition

t, x = range(0, stop=100, length=100), range(-10, stop=30, length=120)

Xgrid = [i for i in x, j in t]
tgrid = [j for i in x, j in t]

f1 = sech.(Xgrid.-3.5) .* 10.0 .* cos.(0.5 .*tgrid)
f2 = cos.(Xgrid) .* 1.0 .* cos.(2.5 .*tgrid)
f3 = sech.(Xgrid.+5.0) .* 4.0 .* cos.(1.0 .*tgrid)

Y = f1+f2+f3

#Array of ranges we're interested in investigating
ranges = Array{UnitRange{Int64}}(undef,40)         

#Ranges of interest starting from 3 timesteps 
subset = range(3, stop=size(Y,2), length=length(ranges))
for i = 1:length(ranges)
    ranges[i] = 1:round(Int,subset[i])
end

convergence = modeConvergence(Y,PODeigen,ranges,3)


function plotconvergence(subset,convergence) # hide
    x=round.(Int,subset) # hide

    trace1 = scatter(;x=x, y=convergence[1,:], # hide
                        mode="markers", name="Mode 1", # hide
                        marker_size=12) # hide

    trace2 = scatter(;x=x, y=convergence[2,:], # hide
                        mode="markers", name="Mode 2", # hide
                        marker_size=12) # hide

    trace3 = scatter(;x=x, y=convergence[3,:], # hide
                        mode="markers", name="Mode 3", # hide
                        marker_size=12) # hide
    
    data = [trace1, trace2, trace3] # hide
    layout = Layout(height=440, # hide
                    title="Time Convergence", # hide
                    xaxis=attr(title="Time"), # hide
                    yaxis=attr(title="Norm difference "), # hide
                    margin=attr(l=100, r=30, b=50, t=90), # hide
                                ) # hide
    plot(data, layout) # hide
end # hide

p = plotconvergence(subset,convergence) # hide
pkgpath = abspath(joinpath(dirname(Base.find_package("ProperOrthogonalDecomposition")), "..")) # hide
savedir = joinpath(pkgpath,"docs","src","assets","convergenceTime.html") # hide
PlotlyJS.savehtml(p,savedir,:embed) # hide
```
The history of convergence indicates the point at which additional data no longer provides additional
 information to the POD modes.

```@raw html
    <iframe src="../assets/convergenceTime.html" height="540" width="765" frameborder="0" seamless="seamless" scrolling="no"></iframe>
```


### Convergence inplace
Datasets can quickly become large which is why an inplace method is available where
the user supplies a function to load the data.

```@julia
using DelimitedFiles

#Anonymous function with zero arguments
loadFun = ()->readdlm("path/to/data/dataset.csv", ',')

#POD the data inplace and reload it into memory each time.
convergence = modeConvergence!(loadFun,PODeigen!,ranges,3)
```
This can also be done for a weighted POD with
```@julia
convergence = modeConvergence!(loadFun,X->PODeigen!(X,W),ranges,3)
```
!!! note

    The use of a delimited files, such as a `*.csv` in the above example, 
    is not advisable if memory is a concern. Use a binary file format such as HDF5 for example. 

### Convergence in frequency
Just as we can investigate the time history needed for the mode to be converged, 
we can also investigate the sampling frequency needed. This is done by supplying the 
ranges as subsampled sets of the full time history.

```@example convergencefreq
using PlotlyJS # hide
using ProperOrthogonalDecomposition

t, x = range(0, stop=50, length=1000), range(-10, stop=30, length=120)

Xgrid = [i for i in x, j in t]
tgrid = [j for i in x, j in t]

f1 = sech.(Xgrid.-3.5) .* 10.0 .* cos.(0.5 .*tgrid)
f2 = cos.(Xgrid) .* 1.0 .* cos.(2.5 .*tgrid)
f3 = sech.(Xgrid.+5.0) .* 4.0 .* cos.(1.0 .*tgrid)

Y = f1+f2+f3

#Array of ranges we're interested in investigating 
subset = 100:-3:1 #Sub-sampling starts at every 100:th timestep
ranges = Array{StepRange{Int64,Int64}}(undef,length(subset))         

for i = 1:length(ranges)
    ranges[i] = 1:round(Int,subset[i]):length(t)
end

convergence = modeConvergence(Y,PODeigen,ranges,3)


function plotconvergence(subset,convergence) # hide
    x=1 ./((length(t)/last(t)) ./round.(Int,subset)) # hide

    trace1 = scatter(;x=x, y=convergence[1,:], # hide
                        mode="markers", name="Mode 1", # hide
                        marker_size=12) # hide

    trace2 = scatter(;x=x, y=convergence[2,:], # hide
                        mode="markers", name="Mode 2", # hide
                        marker_size=12) # hide

    trace3 = scatter(;x=x, y=convergence[3,:], # hide
                        mode="markers", name="Mode 3", # hide
                        marker_size=12) # hide
    
    data = [trace1, trace2, trace3] # hide
    layout = Layout(height=440, # hide
                    title="Sampling Frequency Convergence", # hide
                    xaxis=attr(title="1/Freq."), # hide
                    yaxis=attr(title="Norm difference "), # hide
                    margin=attr(l=100, r=30, b=50, t=90), # hide
                                ) # hide
    plot(data, layout) # hide
end # hide

p = plotconvergence(subset,convergence) # hide
pkgpath = abspath(joinpath(dirname(Base.find_package("ProperOrthogonalDecomposition")), "..")) # hide
savedir = joinpath(pkgpath,"docs","src","assets","convergenceFreq.html") # hide
PlotlyJS.savehtml(p,savedir,:embed) # hide
```
!!! note

    The data point where `1/f = 1.25` indicates that Mode 2 and Mode 3 are far from
    converged, this sudden jump is likely due to the relative importance of the modes
    switching at this sampling frequency. This does not necessarily mean that the 
    modes themselves are poorly represented.

```@raw html
    <iframe src="../assets/convergenceFreq.html" height="540" width="765" frameborder="0" seamless="seamless" scrolling="no"></iframe>
```