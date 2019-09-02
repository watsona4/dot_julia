using Pkg; Pkg.activate("..")
using PlotAxes, VegaLite, AxisArrays

x = cumsum(randn(100))
vlplot_axes(x)

x = rand(100,100)
vlplot_axes(x)

x = rand(100,100,3)
vlplot_axes(x)

myexception = nothing
try
  using RCall
catch e
  global myexception
  myexception = e
end
