#Make sure InspectDR does not interpolate in points not in data.
using InspectDR
using Colors


#==Input
===============================================================================#
#Constants
#-------------------------------------------------------------------------------
black = RGB24(0, 0, 0)
white = RGB24(1, 1, 1)
red = RGB24(1, 0, 0)
green = RGB24(0, 1, 0)
blue = RGB24(0, 0, 1)

#Input data
#-------------------------------------------------------------------------------
npts = 335
tmax = 1
Δ = tmax/(npts-1)
t = collect(0:Δ:tmax)-pi*Δ
y = zeros(t)
y[div(length(t), 2)] = 1


#==Generate plot
===============================================================================#
plot = InspectDR.Plot2D(title="Sample Plot (λ)")
strip = plot.strips[1]
plot.xext_full = InspectDR.PExtents1D(0, NaN)
strip.yext_full = InspectDR.PExtents1D(-.2, 1.2)
plot.xres = 100 #coarse resolution
#plot.layout.grid = grid(vmajor=true, vminor=true, hmajor=true)

style = :dashdot #solid/dashdot/...
wfrm = add(plot, t, y, id="y")
	wfrm.line = line(style=:none)
	wfrm.line = line(style=:solid)
	wfrm.glyph = glyph(shape=:o, size=10, color=blue)

a = plot.annotation
a.xlabel = "Time (s)"
a.ylabels = ["Signal Voltage (V)"]

gplot = display(InspectDR.GtkDisplay(), plot)

:Test_Complete
