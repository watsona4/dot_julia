module BodePlots

using InspectDR
import InspectDR: Plot2D
import Printf: @sprintf
using NumericIO
using Colors

#Colour constants
#-------------------------------------------------------------------------------
const black = RGB24(0, 0, 0); const white = RGB24(1, 1, 1)
const red = RGB24(1, 0, 0); const green = RGB24(0, 1, 0); const blue = RGB24(0, 0, 1)

#Convenience aliases
#-------------------------------------------------------------------------------
mag(x) = abs(x); phase(x) = rad2deg(angle(x))
SI(x) = formatted(x, :SI, ndigits=3)
const j = im


#==Math: 2nd order transfer functions
===============================================================================#

function roots(a,b,c) #Solves: ax² + bx + c = 0
	r = sqrt(b*b-4*a*c)
	result = (-b .+ [r, -r]) / (2a)
	return (result[1], result[2])
end

#2nd order transfer function:
xf_o2(f, G, f_z, f_p1, f_p2) = #(f_z, f_p1, f_p2: in Hz)
	G*(1 .+ j*(f./f_z))./( (1 .+ j*(f./f_p1)).*(1 .+ j*(f./f_p2)) )

#Compute unity gain frequency
function f_0(f, G, f_z, f_p1, f_p2)
	invsq(x) = (result = 1/x; return result*result)
	_z² = invsq(f_z); G² = G*G
	_p1² = invsq(f_p1); _p2² = invsq(f_p2)
	r = roots(_p1²*_p2², _p1²+_p2²-G²*_z², 1-G²)
	posroot = max(r...) #Select positive root
	return posroot < 0 ? NaN : sqrt(posroot)
end

#Compute 3dB frequency
f_3dB(f, G, f_z, f_p1, f_p2) =
	f_0(f, sqrt(2), f_z, f_p1, f_p2)

#==Main functions
===============================================================================#

#Create new Bode plot:
#-------------------------------------------------------------------------------
function new(::Type{InspectDR.Plot})
	plot = InspectDR.bodeplot()
		strip_mag, strip_phase = plot.strips

	#Define extents & scales:
	strip_mag.yext_full = InspectDR.PExtents1D(-10, 25)
	strip_phase.yext_full = InspectDR.PExtents1D(-180, 0)

	return plot
end

function new()
	w = 500; h = w/1.6 #WANTCONST: Select plot width/height

	mplot = InspectDR.Multiplot()
	mplot.layout[:ncolumns] = 1
	#Bode plot looks better with wider aspect ratio:
	mplot.layout[:halloc_plot] = w; mplot.layout[:valloc_plot] = h

	add(mplot, new(InspectDR.Plot))
	return mplot
end


#Modify previously-generated Bode plot (base algorithm):
#-------------------------------------------------------------------------------
function update(plot::Plot2D, f::Vector, y::Vector)
	ldata = line(color=blue, width=3, style=:solid) #WANTCONST
	strip_mag, strip_phase = plot.strips

	plot.data = [] #Clear old data

	#Reset extents:
	plot.xext = InspectDR.PExtents1D()
	strip_mag.yext = InspectDR.PExtents1D()
	strip_phase.yext = InspectDR.PExtents1D()

	wfrm = add(plot, f, mag.(y), strip=1)
		wfrm.line = ldata
	wfrm = add(plot, f, phase.(y), strip=2)
		wfrm.line = ldata

	return
end

#Update annotation on Bode plot (enabled=false to clear annotation):
#-------------------------------------------------------------------------------
function update_annotation(plot::Plot2D, f0, fBW, phase0, enabled=true)
	lmarker = line(style=:dash, width=2.5) #WANTCONST
	lmarker_light = line(style=:dash, width=2.5, color=RGB24(.4,.4,.4)) #WANTCONST

	plot.userannot = [] #Clear old markers/text annotation

	if !enabled; return; end

	#Add specialized annotation
	afont = plot.layout[:font_annotation]

	#Add vertical markers to both plots:
	isfinite(f0) ? add(plot, vmarker(f0, lmarker, strip=0)) : nothing
	isfinite(fBW) ? add(plot, vmarker(fBW, lmarker, strip=0)) : nothing

	#Add annotation to Magnitude plot:
	add(plot, atext("0dB", y=0, xoffset_rel=0.5, yoffset=3, font=afont, align=:bc, strip=1))
	add(plot, hmarker(0, lmarker_light, strip=1))

	if isfinite(fBW)
		fstr = "f3dB=" * SI(fBW) * "Hz"
		add(plot, atext(fstr, x=fBW, xoffset=-3, yoffset_rel=0.5, font=afont, angle=-90, align=:bc, strip=1))
	end

	#Hack if f0>0: TODO: Fix bug where annotating @ 0 on log plot causes glitch. 
	if isfinite(f0) && f0 > 0
		fstr = "f0=" * SI(f0) * "Hz"
		add(plot, atext(fstr, x=f0, xoffset=-3, yoffset_rel=0.5, font=afont, angle=-90, align=:bc, strip=1))
	end

	#Add annotation to Phase plot:
	if isfinite(phase0)
		pmargin = 180+phase0
		fstr = "PM=" * @sprintf("%.1f°", pmargin)
		add(plot, atext(fstr, y=(phase0-180)/2, xoffset_rel=0.5, font=afont, align=:cc, strip=2))
		add(plot, hmarker(phase0, lmarker, strip=2))
	end

	return
end

#Modify previously-generated Bode plot:
#-------------------------------------------------------------------------------
#(fmin, fmax, f_p1: in Hz)
function update(plot::Plot2D, fmin, fmax, G, f_z, f_p1, f_p2, annot=true)
	npts = 100 #WANTCONST

	_logspace(start, stop, n) = 10 .^ range(start, stop=stop, length=n)
	f = _logspace(log10(fmin), log10(fmax), npts)
	y = xf_o2(f, G, f_z, f_p1, f_p2)
	update(plot, f, y)

	f0 = f_0(f, G, f_z, f_p1, f_p2) #Unity gain frequency
	fBW = f_3dB(f, G, f_z, f_p1, f_p2)
	phase0 = phase(xf_o2(f0, G, f_z, f_p1, f_p2)) #Unity gain phase
	update_annotation(plot, f0, fBW, phase0, annot)

	return
end

#Modify previously-generated Bode plot:
#-------------------------------------------------------------------------------
#(fmin, fmax, f_p1: in Hz)
function update(mplot::InspectDR.Multiplot, fmin, fmax, GdB, f_z, f_p1, f_p2, annot=true)
	plot = mplot.subplots[1] #WANTCONST
	G = 10.0^(GdB/20) #WANTCONST
	update(plot, fmin, fmax, G, f_z, f_p1, f_p2, annot)
	return mplot
end

#==Un-exported interface
===============================================================================
	new()
	update(::InspectDR.Multiplot, fmin, fmax, GdB, f_z, f_p1, f_p2, annot=true)
=#

end #module
