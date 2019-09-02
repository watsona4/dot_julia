#Demo 12: 
#-------------------------------------------------------------------------------
using InspectDR
using Colors
using Random
import InspectDR: DTPPOINTS_PER_INCH


#==Input
===============================================================================#

#Constants
#-------------------------------------------------------------------------------
black = RGB24(0, 0, 0)
white = RGB24(1, 1, 1)
red = RGB24(1, 0, 0)
green = RGB24(0, 1, 0)
blue = RGB24(0, 0, 1)

ppi = 300
pt2px = ppi/DTPPOINTS_PER_INCH
line_default = line(color=blue, width=1*pt2px)
line_meas = line(style=:none, color=red, width=1.5*pt2px)
line_model = line(style=:solid, color=blue, width=1.5*pt2px)
glyph_meas = glyph(shape=:o, size=3*pt2px)


#Input data
#-------------------------------------------------------------------------------
x = collect(0:100)
xmax = maximum(x)
ymodel = 0.5*x .+ 25

#Generate "Measured" data:
Random.seed!(11) #Reseed
ymeas = randn(length(x))*(xmax/10) .+ ymodel


#==Generate plot
===============================================================================#
mplot = InspectDR.Multiplot(title="")

plot = add(mplot, InspectDR.Plot2D(:lin, :lin,
	title="",
	xlabel="X-Value", ylabels=["Y-Value"])
)
_strip = plot.strips[1]
_strip.yext_full = InspectDR.PExtents1D(min=0, max=100)
plot.layout.values = InspectDR.PlotLayout()

wfrm = add(plot, x, ymeas, id="Measured")
	wfrm.line = line_meas
	wfrm.glyph = glyph_meas
wfrm = add(plot, x, ymodel, id="Model")
	wfrm.line = line_model

#Use IEEE stylesheets:
#NOTE: could also set style of InspectDR.defaults *before* creating plot/mplot.
InspectDR.setstyle!(plot, :IEEE, ppi=ppi, enable_legend=true)
InspectDR.setstyle!(mplot, :IEEE, ppi=ppi)

#Add annotation:
afont = plot.layout[:font_annotation]
ypos = 0.92
fstr = "Plot for IEEE publication @ $ppi DPI"
	add(plot, atext(fstr, xoffset_rel=0.5, yoffset_rel=ypos, font=afont, align=:bc, strip=1))
fstr = "No title - maximizes data area"
	add(plot, atext(fstr, xoffset_rel=0.5, yoffset_rel=ypos, font=afont, align=:tc, strip=1))
fstr = "(caption expected below)"
	add(plot, atext(fstr, xoffset_rel=0.5, yoffset_rel=1-ypos, font=afont, align=:cc, strip=1))

gplot = display(InspectDR.GtkDisplay(), mplot)

#Write from Multiplot to ensure we control dimensions of whole plot
#instead of just data area:
InspectDR.write_png("export_IEEEPlot.png", mplot)

:DONE
