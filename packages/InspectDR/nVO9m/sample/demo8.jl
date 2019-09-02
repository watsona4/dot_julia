#Demo 8: Glyph test
#-------------------------------------------------------------------------------
using InspectDR
using Colors
import Graphics: width, height


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
x = collect(1:10)
y0 = x.*0
_glyphs = InspectDR.SUPPORTED_GLYPHS
#_colors = Colors.colormap("Oranges", length(_glyphs))
_colors = Colors.distinguishable_colors(length(_glyphs))

#==Generate plot
===============================================================================#
mplot = InspectDR.Multiplot(title="Glyph Tests")
mplot.layout[:ncolumns] = 1

plot = add(mplot, InspectDR.Plot2D())
	strip = plot.strips[1]
	plot.xext_full = InspectDR.PExtents1D(min=0, max=11)
	strip.yext_full = InspectDR.PExtents1D(min=0, max=length(_glyphs)+1)
	plot.layout[:enable_legend] = true

	a = plot.annotation
#	a.title = "Glyph Test"

let wfrm #HIDEWARN_0.7
	for (i, g) in enumerate(_glyphs)
		wfrm = add(plot, x, y0 .+ (length(_glyphs)+1-i), id="$g")
		wfrm.line = line(style=:solid, color=_colors[i], width=2)
		wfrm.glyph = glyph(shape=g, size=10, color=black, fillcolor=_colors[i])
	end
end

gplot = display(InspectDR.GtkDisplay(), mplot)

:DONE
