if !@isdefined(BodePlots)
include("BodePlots.jl")
end

module TLines

using InspectDR
import InspectDR: Plot2D
using NumericIO
using Colors

const VecOrNum = Union{Vector,Number}
const VecOrReal = Union{Vector,Real}

#Colour constants
#-------------------------------------------------------------------------------
const black = RGB24(0, 0, 0); const white = RGB24(1, 1, 1)
const red = RGB24(1, 0, 0); const green = RGB24(0, 1, 0); const blue = RGB24(0, 0, 1)

#Physics constants
#-------------------------------------------------------------------------------
const μ0 = 4pi*1e-7 #F/m
const ϵ0 = 8.854e-12 #H/m

#Convenience aliases
#-------------------------------------------------------------------------------
mag(x) = abs(x); phase(x) = rad2deg(angle(x))
SI(x) = formatted(x, :SI, ndigits=3)
const j = im


#==Equations
===============================================================================#
#=NOTE:
 - Not particularly optimized for speed.
 - Not particularly complete/well named set of functions.
=#

#Compute propagation constant of a transmission line
function γline(f::VecOrReal; α::VecOrReal=0, μ::Real=μ0, ϵ::Real=ϵ0)
	β = f*(2pi*sqrt(μ*ϵ))
	return α+j*β
end

#Compute reflection coefficient of a given impedance
#Zref: Reference impedance for the reflection coefficient
Γ(Z::VecOrNum; Zref::Real=50.0) = (Z .- Zref) ./ (Z .+ Zref)

#Compute impedance of a loaded transmission line
#ZC: Characteristic impedance (not currently modelling f-dependence)
#ZL: Load impendance (termination)
function Zline(ZC::Number, γ::VecOrNum; ZL::VecOrNum=Inf64, ℓ::Real=0.0)
	tanh_γℓ = tanh.(γ*ℓ)
	return ZC .* (ZL .+ ZC .* tanh_γℓ) ./ (ZC .+ ZL .* tanh_γℓ)
end


#==Main functions
===============================================================================#
function newplot()
	w = 500; h = w/1.6 #WANTCONST: Select plot width/height
	smithext = InspectDR.PExtents1D(min=-1.2,max=1.2) #WANTCONST: Padded a bit

	mplot = InspectDR.Multiplot(title="Loaded Transmission Line")
	mplot.layout[:ncolumns] = 2
	#Bode plot looks better with wider aspect ratio:
#	mplot.layout[:halloc_plot] = w; mplot.layout[:valloc_plot] = h/2
	#... But not Smith chart.

	plot_bode = add(mplot, Main.BodePlots.new(InspectDR.Plot))
	strip_mag, strip_phase = plot_bode.strips
		strip_mag.yext_full = InspectDR.PExtents1D(-20, 0)
		strip_phase.yext_full = InspectDR.PExtents1D(-200, 200)
		plot_bode.annotation.title = "Reflection Coefficient (Γ)"


	plot_smith = add(mplot, InspectDR.smithchart(:Z, ref=50))
	strip = plot_smith.strips[1]
		plot_smith.xext_full = smithext; strip.yext_full = smithext
		a = plot_smith.annotation
			a.title = "Z-Smith Chart"
			a.xlabel = "Real(Γ)"
			a.ylabels = ["Imaginary(Γ)"]

	return mplot
end

#Modify previously-generated plot:
#-------------------------------------------------------------------------------
#(Frequencies: in Hz)
function update(mplot::InspectDR.Multiplot, fmin, fmax, ltype::Symbol, R, L, C, ℓ, ZC, αdB)
	npts_bode = 500 #WANTCONST
	ldata = line(color=blue, width=3, style=:solid) #WANTCONST
	plot_bode = mplot.subplots[1] #WANTCONST
	plot_smith = mplot.subplots[2] #WANTCONST
	αDC = (20/log(10)) * αdB #WANTCONST: Nepers/m

	#Add some frequency dependence to α (makes plot more interesting):
	fref = 10e9; αref = 2*αDC #WANTCONST
	fdepα(f, αDC) = αDC .+ (αref/sqrt(fref)) .* sqrt.(f)

	#How to compute load impedance:
	Zload_shunt(jω,R,L,C) = 1 ./ (1 ./ R .+ 1 ./ (jω*L) .+ jω*C)
	Zload_series(jω,R,L,C) = R .+ jω*L .+ 1 ./ (jω*C)
	Zload = :shunt == ltype ? Zload_shunt : Zload_series

	#Generate Bode plot:
	f = 10 .^ range(log10(fmin), stop=log10(fmax), length=npts_bode)
	jω = j*2pi*f
	y = Γ(Zline(ZC, γline(f, α=fdepα(f, αDC)), ZL=Zload(jω,R,L,C), ℓ=ℓ))
	Main.BodePlots.update(plot_bode, f, y)
	strip_mag, strip_phase = plot_bode.strips
		strip_mag.yext = InspectDR.PExtents1D() #Reset
		strip_phase.yext = InspectDR.PExtents1D() #Reset

	#Generate Smith chart:
	plot_smith.data = [] #Clear old data
	β = imag(γline(fmax))
	Θ = β * ℓ; nrev = Θ/pi #revs around the chart
	npts = max(round(Int, 20*nrev), 200) #Ensure sufficient # of points
	f = collect(range(fmin, stop=fmax, length=npts))
	jω = j*2pi*f
	y = Γ(Zline(ZC, γline(f, α=fdepα(f, αDC)), ZL=Zload(jω,R,L,C), ℓ=ℓ))
	wfrm = add(plot_smith, f, y)
	wfrm.line = ldata

	#Clear old annotation/markers:
	plot_bode.userannot = []

	return mplot
end

end #module
