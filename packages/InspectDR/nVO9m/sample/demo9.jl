#Demo 9: Waveforms with NaN
#-------------------------------------------------------------------------------
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
npts = 1000
T=.1e-6 #Clock period
x = collect(range(0, stop=1e-6, length=npts))
y = sin.(2pi*(x./T))

#Invalidate some data points:
#NOTE: Cannot use F1-acceleration when x has NaN values
x[200] = y[200] = NaN #Causes break
x[460] = NaN
x[505] = NaN
y[580] = NaN

for i in 800:900
	y[i] = NaN
end

#==Generate plot
===============================================================================#
mplot = InspectDR.Multiplot(title="Waveforms with NaN")
mplot.layout[:ncolumns] = 1


plot = add(mplot, InspectDR.transientplot(:lin, title="Transient Data",
	xlabel="Time (s)", ylabels=["Voltage (V)"])
)
	plot.displayNaN = true #Enable hilighting of NaN values (slower)
	wfrm = add(plot, x, y)
	wfrm.line = line(color=blue, width=3)

gplot = display(InspectDR.GtkDisplay(), mplot)

:DONE
