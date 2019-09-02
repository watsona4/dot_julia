#Demo 1: Simple sine wave plot
#-------------------------------------------------------------------------------
using InspectDR
using Colors
import NumericIO: UEXPONENT_SI


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
tcycle = 1e-9
npts = 2000 #Relatively large dataset
ncycles = 4
tmax = tcycle*ncycles
Δ = tmax/(npts-1)
t = collect(0:Δ:tmax)
y = sin.(t*(ncycles*2pi/tmax))

t[end] = t[1] #x-values are no longer ordered

#Lower resolution t-vector:
t_lres = collect(0:(tmax/10):tmax)


#==Generate plot
===============================================================================#
plot = InspectDR.transientplot(:lin, title="Sample Plot (λ)")
	InspectDR.overwritefont!(plot.layout, fontname="monospace", fontscale=1.5)
plot.layout[:enable_legend] = true
plot.layout[:halloc_legend] = 150
plot.layout[:enable_timestamp] = true
plot.layout[:format_xtick] = InspectDR.TickLabelStyle(UEXPONENT_SI) #Use SI notation on x-axis

graph = plot.strips[1]
graph.grid = InspectDR.GridRect(vmajor=true, vminor=true, hmajor=true)

style = :dashdot #solid/dashdot/...
wfrm = add(plot, t, y .+1, id="sin(2πt)+1")
	wfrm.line = line(color=blue, width=1, style=style)
wfrm = add(plot, t, y .-1, id="sin(2πt)-1")
	wfrm.line = line(color=red, width=5, style=style)
wfrm = add(plot, t_lres, -2 .+4*(t_lres./tmax), id="-2+4t/tmax")
	wfrm.line = line(color=blue, width=3, style=:dash)
	wfrm.glyph = glyph(shape=:*, size=10)

a = plot.annotation
	a.xlabel = "Time (s)"
	a.ylabels = ["Signal Voltage (V)"]

let wfrm #HIDEWARN_0.7
#Show if uses f1 acceleration:
for wfrm in plot.data
	id = wfrm.id
	f1accel = isa(wfrm.ds, InspectDR.IDataset{true})
	@show id, f1accel
end
end

gplot = display(InspectDR.GtkDisplay(), plot)

InspectDR.write_png("export_plot.png", plot)
InspectDR.write_svg("export_plot.svg", plot)
InspectDR.write_eps("export_plot.eps", plot)
InspectDR.write_pdf("export_plot.pdf", plot)

:DONE
