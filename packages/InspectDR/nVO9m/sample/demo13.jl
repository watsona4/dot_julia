#Demo 13: A simple scatter plot
#-------------------------------------------------------------------------------
using InspectDR
using Colors
using Random

red = RGB24(1, 0, 0)
green = RGB24(0, 1, 0)
blue = RGB24(0, 0, 1)


#==Input
===============================================================================#
x = collect(0:100) #Must vectorize using collect - ranges not yet supported
Random.seed!(11) #Reseed
y = randn(length(x))


#==Generate plot object
===============================================================================#
plot = InspectDR.Plot2D(:lin, :lin,
	title = "Very Minimal Example: Scatter Plot",
	xlabel = "X-Values",
	ylabels = ["Y-Values"]
)
plot.layout[:enable_legend] = true
plot.layout[:halloc_legend] = 150 #Default: 100

#Set grid:
graph = plot.strips[1]
graph.grid = InspectDR.GridRect(vmajor=true, vminor=true, hmajor=true)

wfrm = add(plot, x, y, id="Random Sample")
	#No line on a scatter plot; width used for glyph:
	wfrm.line = line(width=3, style=:none)
	wfrm.glyph = glyph(shape=:o, size=10, color=red, fillcolor=blue)


#==Render plot
===============================================================================#
#Show Gtk GUI
gplot = display(InspectDR.GtkDisplay(), plot)

#Don't need to show GUI if simple plot image is desired:
InspectDR.write_png("export_simpleplot.png", plot)
#InspectDR.write_svg("export_simpleplot.svg", plot)
#InspectDR.write_eps("export_simpleplot.eps", plot)
#InspectDR.write_pdf("export_simpleplot.pdf", plot)

:DONE
