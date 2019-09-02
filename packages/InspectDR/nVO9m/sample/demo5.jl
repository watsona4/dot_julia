#Demo 5: Logy plots
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

default_line = line(color=blue, width=3)


#Input data
#-------------------------------------------------------------------------------
x = collect(1.0:1.0:100.0)
b = 2.0 #Base
k = 0.2 #Exponential coefficient


#==Generate plot
===============================================================================#
mplot = InspectDR.Multiplot(title="Log-Y Tests")
mplot.layout[:ncolumns] = 1

plot = add(mplot, InspectDR.Plot2D(:lin, [:lin, :log10],
		title="y = $b^($(k)x)", xlabel="x", ylabels=["y", "y"])
	)
	strip_liny, strip_logy = plot.strips

	#Define extents & scales:
	strip_logy.grid = InspectDR.GridRect(vmajor=true, hmajor=true, hminor=true)

let wfrm #HIDEWARN_0.7
for i in 1:length(plot.strips)
	wfrm = add(plot, x, b.^(k*x), strip=i)
		wfrm.line = default_line
end
end

gplot = display(InspectDR.GtkDisplay(), mplot)

:DONE
