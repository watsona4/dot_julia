
if !@isdefined(BodePlots)
include("BodePlots.jl")
end

module PhaseLock

import Graphics.BoundingBox

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


#==Main types
===============================================================================#

#1st order transfer function:
mutable struct Xf1
	K::Float64
	ωz::Float64
	ωp::Float64
end
Xf1(;K=1, ωz=1, ωp=1) = Xf1(K, ωz, ωp)

#2nd order system (standard form):
mutable struct Sys2
	α::Float64
	ζ::Float64
	ωn::Float64
end
Sys2(;α=1, ζ=1, ωn=1) = Sys2(α, ζ, ωn)

function Sys2(G::Xf1)
	ωn = sqrt(G.K*G.ωp)
	ζ = 0.5*(G.ωp/ωn+ωn/G.ωz)
	α = ωn/(2*ζ*G.K)
	return Sys2(α=α, ζ=ζ, ωn=ωn)
end

#==Math: 2nd order transfer functions
===============================================================================#

#Open-loop transfer function, G(s) (including freq->phase integrator):
xf_ol(ω::Vector, G::Xf1) = (s=j*ω;
	return G.K .* (1 .+ s ./ G.ωz)./(1 .+ s ./ G.ωp) ./ s)

#Compute unity gain frequency of G(s) (including freq->phase integrator):
function ω_0(G::Xf1)
	invsq(x) = (result = 1/x; return result*result)
	K² = G.K*G.K
	a = invsq(G.ωp)
	b = (1-K²*invsq(G.ωz))
	c = -K²
	r = Main.BodePlots.roots(a,b,c) #Roots of ω²

	thresh = deg2rad(1) #WANTCONST: 1 degree
	rvalid = Float64[Inf,Inf]
	for i in 1:2
		val = r[i]
		if abs(angle(val)) < thresh #Positive real root
			rvalid[i] = sqrt(abs(val))
		end
	end

	x1 = minimum(rvalid) #Select first crossing of |G|=1
	#Don't return Inf - Likely Inf because roots are complex:
	return isfinite(x1) ? x1 : NaN
end

function step_err(s::Sys2, t::Vector)
	α = s.α #WANTCONST
	ωn = s.ωn #WANTCONST
	ζ = s.ζ #WANTCONST
	csqrt(x) = sqrt(complex(x))
	ζroot = csqrt(ζ^2-1)
	herr(f) = (ζ*(2α-1)/ζroot+f*1)*exp.(-ωn*t*(ζ+f*ζroot))

	if ζroot == 0 # ζ = 1
		return (1+(1-2α)*(ωn*t)).*exp.(-ωn*t)
	else
		return (herr(1)-herr(-1)) / 2
	end
end

step_resp(s::Sys2, t::Vector) = 1 .- step_err(s, t)

#==Main functions
===============================================================================#
function newplot()
	w = 500; h = w/1.6 #WANTCONST Select plot width/height
	yext_step = InspectDR.PExtents1D(0, 1.6) #WANTCONST

	mplot = InspectDR.Multiplot(title="PLL Characteristics")
	Δh = mplot.layout[:valloc_title]
	mplot.layout[:ncolumns] = 2
	#Bode plot looks better with wider aspect ratio:
	mplot.layout[:halloc_plot] = w; mplot.layout[:valloc_plot] = h/2

	plot_step = add(mplot, InspectDR.Plot2D)
	plot_bode = add(mplot, Main.BodePlots.new(InspectDR.Plot))
	plot_stepnorm = add(mplot, InspectDR.Plot2D)

	#Control where plots render:
	plot_step.plotbb = BoundingBox(0, w, Δh, Δh+h/2)
	plot_stepnorm.plotbb = BoundingBox(0, w, Δh+h/2, Δh+h)
	plot_bode.plotbb = BoundingBox(w, 2w, Δh, Δh+h)

	#Add title to bode plot:
	a = plot_bode.annotation
		a.title = "Open-Loop Characteristics"
	plot_bode.strips[1].yext_full = InspectDR.PExtents1D(-40, 100)

	#Step-response plot:
	a = plot_step.annotation
		a.title = "Step Response"
		a.xlabel = "Time (s)"
		a.ylabels = ["Amplitude"]
	plot_step.strips[1].yext_full = yext_step
#		plot_step.layout.grid = grid(vmajor=true, vminor=true, hmajor=false)

	a = plot_stepnorm.annotation; lyt = plot_stepnorm.layout
		a.title = ""; lyt[:valloc_top] = 8 #subtitle/space
		a.xlabel = "ωn*t (rad)"
		a.ylabels = ["Amplitude"]
	plot_stepnorm.strips[1].yext_full = yext_step
	
	return mplot
end

#Modify previously-generated Bode plot (base algorithm):
#-------------------------------------------------------------------------------
function update_step(plot::InspectDR.Plot2D, t::Vector, y::Vector)
	ldata = line(color=blue, width=3, style=:solid) #WANTCONST

	plot.data = [] #Clear old data

	#Reset extents:
	plot.xext = InspectDR.PExtents1D()
	plot.strips[1].yext = InspectDR.PExtents1D()

	wfrm = add(plot, t, mag.(y))
		wfrm.line = ldata

	return plot
end

#Update annotation on Bode plot (enabled=false to clear annotation):
#-------------------------------------------------------------------------------
function update_bodeannot(plot_bode::Plot2D, G::Xf1, ωn)
	lmarker = line(style=:dash, width=2.5) #WANTCONST
	lmarker_light = line(style=:solid, width=2.5, color=RGB24(.4,.4,.4)) #WANTCONST
	fp = G.ωp/(2pi) #WANTCONST
	fz = G.ωz/(2pi) #WANTCONST
	fn = ωn/(2pi) #WANTCONST
	ω0 = ω_0(G) #WANTCONST
	f0 = ω0/(2pi) #WANTCONST
	phase0 = phase.(xf_ol([ω0], G)[1]) #WANTCONST: Unity gain phase

	#Add specialized annotation
	afont = plot_bode.layout[:font_annotation]

	#Add annotation to Magnitude plot:
#	add(plot_bode, atext("0dB", y=0, xoffset_rel=0.5, yoffset=3, font=afont, align=:bc, strip=1))
	add(plot_bode, hmarker(0, lmarker_light, strip=1))

	polelist = [("fp", fp), ("fz", fz), ("fn", fn), ("f0", f0)]
	#Hack if f0>0: TODO: Fix bug where annotating text @ 0 on log plot causes glitch. 
	for (id, f) in polelist
		if isfinite(f) && f > 0
			fstr = id * "=" * SI(f) * "Hz"
			add(plot_bode, atext(fstr, x=f, xoffset=-3, yoffset_rel=0.5, font=afont, angle=-90, align=:bc, strip=1))

			#Add vertical markers to both plots:
			add(plot_bode, vmarker(f, lmarker, strip=0))
		end
	end

	#Add annotation to Phase plot:
	if isfinite(phase0)
		pmargin = 180+phase0
		fstr = "PM=" * @sprintf("%.1f°", pmargin)
		add(plot_bode, atext(fstr, y=(phase0-180)/2, xoffset_rel=0.5, font=afont, align=:cc, strip=2))
		add(plot_bode, hmarker(phase0, lmarker, strip=2))
	end

	return
end

#Modify previously-generated plot:
#-------------------------------------------------------------------------------
#(Frequencies: in Hz; G: Open-loop characteristics)
#ωnperiods: in # of ωn periods
function update(mplot::InspectDR.Multiplot, fmin, fmax, tmax, ωnperiods, G::Xf1, annot=true)
	npts = 500 #WANTCONST: for plots
	plot_step = mplot.subplots[1] #WANTCONST
	plot_bode = mplot.subplots[2] #WANTCONST
	plot_stepnorm = mplot.subplots[3] #WANTCONST
	sys = Sys2(G) #WANTCONST: Closed-loop response

	f = 10 .^ range(log10(fmin), stop=log10(fmax), length=npts)
	y = xf_ol(2pi*f, G)
	Main.BodePlots.update(plot_bode, f, y)

	#Reset extents/annotation:
	plot_bode.xext = InspectDR.PExtents1D()
	plot_bode.strips[1].yext = InspectDR.PExtents1D()
	plot_bode.userannot = [] #Clear old markers/text annotation
	if annot; update_bodeannot(plot_bode, G, sys.ωn); end

	#Absolute step:
	tstep = tmax/npts
	t = collect(0:tstep:tmax)
	y = abs.(step_resp(sys, t))
	update_step(plot_step, t, y)

	#Relative step:
	xstep = ωnperiods/npts
	x = collect(0:xstep:ωnperiods)
	t = x./(sys.ωn/2pi)
	y = abs.(step_resp(sys, t))
	update_step(plot_stepnorm, x, y)

	return mplot
end

#==Show functions
===============================================================================#

function Base.show(io::IO, s::Sys2)
	print(io, "Sys2(α=", SI(s.α), ", ζ=", SI(s.ζ), ", ωn=", SI(s.ωn), ")")
end


end #module
