#Demo 7: Bode Plots
#-------------------------------------------------------------------------------
using InspectDR
using Colors
import Printf: @sprintf



#==Input
===============================================================================#

#Constants
#-------------------------------------------------------------------------------
black = RGB24(0, 0, 0)
white = RGB24(1, 1, 1)
red = RGB24(1, 0, 0)
green = RGB24(0, 1, 0)
blue = RGB24(0, 0, 1)
j = im

#Fonts, Line types, etc:
default_line = line(color=blue, width=3)
markerline = line(style=:dash, width=2.5)
markerline_light = line(style=:dash, width=2.5, color=RGB24(.4,.4,.4))


#Input data
#-------------------------------------------------------------------------------
fmax = 10e9
fstep = 5e6
f = collect(0:fstep:fmax)
fmin_disp = 10e6
G = 20.0
f_p1 = 50e6
f_p2 = .9e9
f_z = Inf #.8e9
f1 = .8e9


#==Helper functions
===============================================================================#
phase(x) = rad2deg.(angle.(x))
function roots(a,b,c)
	r = sqrt(b*b-4*a*c)
	result = (-b .+ [r, -r]) / (2a)
	return (result[1], result[2])
end
xf_o2(f, G, f_z, f_p1, f_p2) = #2nd order transfer function
	G*(1 .+ j*(f./f_z))./( (1 .+ j*(f./f_p1)).*(1 .+ j*(f./f_p2)) )
function f_unitygain_f(f, G, f_z, f_p1, f_p2) #Compute unity gain frequency
	invsq(x) = (result = 1/x; return result*result)
	_z² = invsq(f_z); G² = G*G
	_p1² = invsq(f_p1); _p2² = invsq(f_p2)
	r = roots(_p1²*_p2², _p1²+_p2²-G²*_z², 1-G²) 
	return sqrt(max(r...)) #Select sqrt(positive root)
end
f_3dB(f, G, f_z, f_p1, f_p2) = #Compute 3dB frequency
	f_unitygain_f(f, sqrt(2), f_z, f_p1, f_p2)


#==Calculations
===============================================================================#
X = xf_o2(f, G, f_z, f_p1, f_p2)
f0 = f_unitygain_f(f, G, f_z, f_p1, f_p2)
fBW = f_3dB(f, G, f_z, f_p1, f_p2)
phase0 = phase(xf_o2(f0, G, f_z, f_p1, f_p2))
pmargin = 180+phase0
@show pmargin


#==Generate plot
===============================================================================#
mplot = InspectDR.Multiplot(title="Bode Template Test")
#Bode plot looks better with wider aspect ratio:
mplot.layout[:valloc_plot] = mplot.layout[:valloc_plot]*.6

plot = add(mplot, InspectDR.bodeplot())
	strip_mag, strip_phase = plot.strips

	#Define extents & scales:
	plot.xext_full = InspectDR.PExtents1D(min=fmin_disp) #Avoid issues with log scale
	strip_mag.yext_full = InspectDR.PExtents1D(min=-10)
	strip_phase.yext_full = InspectDR.PExtents1D(min=-180)

	#Add waveforms:
	wfrm = add(plot, f, X, strip=1)
		wfrm.line = default_line
	wfrm = add(plot, f, phase(X), strip=2)
		wfrm.line = default_line

#Add specialized annotation
#-------------------------------------------------------------------------------

#Add vertical markers to both plots:
add(plot, vmarker(f0, markerline, strip=0))
add(plot, vmarker(fBW, markerline, strip=0))

#Add annotation to Magnitude plot:
afont = plot.layout[:font_annotation]
fstr = "f3dB=" * @sprintf("%.1f MHz", fBW/1e6)
	add(plot, atext(fstr, x=fBW, xoffset=-3, yoffset_rel=.5, font=afont, angle=-90, align=:bc, strip=1))
fstr = "f0=" * @sprintf("%.1f MHz", f0/1e6)
	add(plot, atext(fstr, x=f0, xoffset=-3, yoffset_rel=.5, font=afont, angle=-90, align=:bc, strip=1))
add(plot, atext("0dB", y=0, xoffset_rel=0.5, yoffset=3, font=afont, align=:bc, strip=1))
add(plot, hmarker(0, markerline_light, strip=1))

#Add annotation to Phase plot:
fstr = "PM=" * @sprintf("%.1f°", pmargin)
	add(plot, atext(fstr, y=(phase0-180)/2, xoffset_rel=0.5, font=afont, align=:cc, strip=2))
add(plot, hmarker(phase0, markerline, strip=2))


#==Render plot
===============================================================================#
gplot = display(InspectDR.GtkDisplay(), mplot)

mplot.layout[:halloc_plot] = 800; mplot.layout[:valloc_plot] = 500
InspectDR.write_png("export_bode.png", mplot)
#InspectDR.write_svg("export_bode.svg", mplot)
#InspectDR.write_eps("export_bode.eps", mplot)
#InspectDR.write_pdf("export_bode.pdf", mplot)

:DONE
