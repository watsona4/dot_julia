#Demo 10: Mixed-signal "Simulation"
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

line_default = line(color=blue, width=3)
line_overlay = line(color=red, width=3)


#Input data
#-------------------------------------------------------------------------------
ppcycle = 40 #Points per cycle (divisible by 4 to get notches)
T=1/60 #Clock period
ncycles = 15
VSUPPLY = 120 #VRMS - mains
VRECT = 80 #Rectifier voltage
τ = T/2 #Time constant for discharge (output load)


#=="Simulation" (really rudimentary to keep things simple)
===============================================================================#
mains_fn(t) = VSUPPLY*sqrt(2)*cos.(2pi*(t./T))
#Find time where mains crosses given threshold:
mains_xfn(thresh) = acos(thresh/(VSUPPLY*sqrt(2)))*(T/(2pi))

function update_discharge(vrect, Δt, i)
	if 0==vrect[i] #On discharge cycle:
		vrect[i] = VRECT*exp(-Δt/τ)
	end
end

#Compute info for a single cycle:
#-------------------------------------------------------------------------------
t = collect(range(0, stop=T, length=ppcycle+1)[1:end-1]) #Time
npts = length(t); hpts = div(npts, 2) #npts should match ppcycle

mains = mains_fn(t)
mains_rect = abs.(mains)
rectactive = mains_rect .> VRECT
rectactive_sig = rectactive * 1.0
vrect = rectactive_sig*VRECT #Voltage @ rectifier
	#Really dumb algorithm:
	d_start = mains_xfn(VRECT) #Start of 1st discharge cycle
#	d_end = d_start+2*(T/4-d_start)
	for i in 1:hpts
		update_discharge(vrect, t[i]-d_start, i)
	end
	d_start += T/2 #Next discharge cycle
	for i in hpts:npts
		update_discharge(vrect, t[i]-d_start, i)
	end

#Extend data for multiple cycles:
#-------------------------------------------------------------------------------
t = collect(range(0, stop=ncycles*T, length=ncycles*ppcycle+1)[1:end-1]) #Time
mains = repeat(mains, outer=ncycles)
mains_rect = repeat(mains_rect, outer=ncycles)
vrect = repeat(vrect, outer=ncycles)
rectactive_sig = repeat(rectactive_sig, outer=ncycles)

gaterange_list = [4.6:6.1, 9.4:12.9] #In # of cycles
gate_b = 1.0 .+ zero(t) #Active low
for gaterange in gaterange_list
	irange = ppcycle*gaterange
	istart = round(Int, minimum(irange))
	istop = round(Int, maximum(irange))
	gate_b[istart:istop] .= 0
end
vrect_gated = vrect.*gate_b


#==Generate plot
===============================================================================#
mplot = InspectDR.Multiplot(title="Mixed-Signal \"Simulation\"")
mplot.layout[:ncolumns] = 1
ext_digital = InspectDR.PExtents1D(-0.2, 1.2) #"Digital" signals
_E = InspectDR.PExtents1D #Succinct alias for extents.

#To be plotted:
siginfolist = [
	("rectifier", vrect, _E(0,1.2*VRECT)),
	("|mains|>thresh", rectactive_sig, ext_digital),
	("|mains|", mains_rect, _E()),
	("mains", mains, _E()),
]

plot = add(mplot, InspectDR.transientplot([:lin for i in siginfolist],
	title="$(VRECT)V Rectifier",
	ylabels=["(V)" for i in siginfolist])
)
plot.layout[:enable_legend] = true
plot.layout[:halloc_legend] = 150

let wfrm #HIDEWARN_0.7
	for (i, siginfo) in enumerate(siginfolist)
		id, sig, ext = siginfo
		plot.strips[i].yext_full = ext
		wfrm = add(plot, t, sig, id=id, strip=i)
			wfrm.line = line_default
#			wfrm.glyph = InspectDR.glyph(shape=:o, size=3)
	end
end

	#Overlay threshold onto |mains|, for convenience
	wfrm = add(plot, t, zero(t) .+ VRECT, id="thresh", strip=3)
		wfrm.line = line_overlay

	#Overlay gate onto gated output:
	wfrm = add(plot, t, gate_b, id="gate_b", strip=2)
		wfrm.line = line_overlay

	#Overlay gated output onto internal:
	wfrm = add(plot, t, vrect_gated, id="output (gated)", strip=1)
		wfrm.line = line_overlay

gplot = display(InspectDR.GtkDisplay(), mplot)

mplot.layout[:halloc_plot] = 700; mplot.layout[:valloc_plot] = 600
InspectDR.write_png("export_rectifier.png", mplot)

:DONE
