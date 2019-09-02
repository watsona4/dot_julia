#Demo 3: Monochrome 2x2 array of subplots
#-------------------------------------------------------------------------------
using InspectDR
using Colors


#==Input
===============================================================================#
#Constants
#-------------------------------------------------------------------------------
black = RGB24(0, 0, 0)
gray50 = RGB24(.5, .5, .5)

#Input data
#-------------------------------------------------------------------------------
x=collect(-10:0.1:10)
titles = ["Linear", "Quadratic", "Cubic", "Quartic"]

linetypes = []
for lstyle in [:solid, :dash, :dot, :dashdot]
	push!(linetypes, line(color=black, width=3, style=lstyle))
	push!(linetypes, line(color=gray50, width=3, style=lstyle))
end


#==Generate plot
===============================================================================#
mplot = InspectDR.Multiplot(title="Powers of X")
mplot.layout[:ncolumns] = 2
xlabel = "X-Axis (X-Unit)"
ylabel = "Y-Axis (Y-Unit)"

plotlist = InspectDR.Plot
for i in 1:4
	plot = add(mplot, InspectDR.Plot2D) #Generate empty plot
	plot.layout[:enable_legend] = true
	plot.layout[:halloc_legend] = 80
	a = plot.annotation
		a.xlabel = xlabel
		a.ylabels = [ylabel]
		a.title = titles[i]

	for scalei in 1:8
#		id = "$scalei(x/10)^$i"
		id = "ref×$scalei"
		wfrm = add(plot, x, scalei*((x/10).^i), id=id)
		wfrm.line = linetypes[scalei]
	end
end

#Display
#-------------------------------------------------------------------------------
gplot = display(InspectDR.GtkDisplay(), mplot)


#==Save multi-plot to file
===============================================================================#
InspectDR.write_png("export_monochrome.png", mplot)
InspectDR.write_svg("export_monochrome.svg", mplot)

:DONE
