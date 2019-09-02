#Demo 6: Smith chart for publication (labels etc removed - will be in caption).
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
f = collect(50e6:50e6:10e9)
C1 = 5e-12; GC1 = 100
C2 = .2e-12; RC2 = 10
L = 1.5e-9; RL = 15


#==Equations
===============================================================================#
Γ(Z; Zref::Real=50.0) = (Z .- Zref) ./ (Z .+ Zref)

#Calculations
#-------------------------------------------------------------------------------
ω = 2π*f; j = im
YC1 = (j*ω*C1) .+ 1/GC1
ZC1 = 1 ./ YC1
ZC2 = 1 ./ (j*ω*C2) .+ RC2
ZL = j*ω*L .+ RL


#==Generate plot
===============================================================================#
mplot = InspectDR.Multiplot(title="Smith Chart (Publication Layout)")
smithext = InspectDR.PExtents1D(min=-1.1,max=1.1) #Padded a bit

plot = add(mplot, InspectDR.smithchart(:Z, ref=50, title="", xlabel="", ylabels=String[]))
	strip = plot.strips[1]
	plot.xext_full = smithext; strip.yext_full = smithext
	#plot.layout[:enable_legend] = true
	plot.layout[:halloc_legend] = 110
	lyt = plot.layout

#Zero-out title areas, etc:
	lyt[:halloc_left] = 0
	lyt[:halloc_right] = 0
	lyt[:valloc_top] = 0
	lyt[:valloc_bottom] = 0

#Make data area sqare when saved:
	lyt[:halloc_data] = 500
	lyt[:valloc_data] = 500

	wfrm = add(plot, f, Γ(ZC1), id="cap: $(C1/1e-12)pF")
	wfrm.line = line(color=blue, width=3)
	wfrm = add(plot, f, Γ(ZC2), id="cap: $(C2/1e-12)pF")
	wfrm.line = line(color=red, width=3)
	wfrm = add(plot, f, Γ(ZL), id="ind: $(L/1e-9)nH")
	wfrm.line = line(color=green, width=3)

gplot = display(InspectDR.GtkDisplay(), mplot)
InspectDR.write_png("export_pubsmith.png", plot)
#InspectDR.write_svg("export_pubsmith.svg", plot)
#InspectDR.write_eps("export_pubsmith.eps", plot)
#InspectDR.write_pdf("export_pubsmith.pdf", plot)

:DONE
