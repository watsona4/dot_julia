#Demo 2: Reflection coefficients
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
μ0 = 4pi*1e-7 #F/m
ϵ0 = 8.854e-12 #H/m


#Input data
#-------------------------------------------------------------------------------
fmax = 10e9
fstep = 50e6
f = collect(0:fstep:fmax)
ℓ = 50e-3 #Meters
ZL = Float64[1e6, 377, 60.0]
_colors = [blue, red, green]


#==Equations
===============================================================================#
Γ(Z; Zref::Real=50.0) = (Z .- Zref) ./ (Z .+ Zref)
#ZC: Characteristic impedance
#ZL: Load impendance (termination)
function Zline(ℓ::Real, f::Vector, ZL::Number; ZC::Number=50.0, α::Real=0, μ::Real=μ0, ϵ::Real=ϵ0)
	j = im
	β = f*(2pi*sqrt(μ*ϵ))
	γ = α .+ j*β
	tanh_γℓ = tanh.(γ*ℓ)
	return ZC*(ZL .+ ZC*tanh_γℓ)./(ZC .+ ZL*tanh_γℓ)
end
function Γline(ℓ::Real, f::Vector, ZL::Number; ZC::Number=50.0, Zref::Number=50.0, α::Real=0, μ::Real=μ0, ϵ::Real=ϵ0)
	return Γ(Zline(ℓ, f, ZL; ZC=ZC, α=α, μ=μ, ϵ=ϵ), Zref=Zref)
end

#Calculations
#-------------------------------------------------------------------------------
Γload = []
for ZLi in ZL
	_Γ = Γline(ℓ, f, ZLi, ZC=40)
	push!(Γload, _Γ)
end


#==Generate plot
===============================================================================#
mplot = InspectDR.Multiplot(title="Transmission Line Example")
mplot.layout[:ncolumns] = 2

smithext = InspectDR.PExtents1D(min=-1.2,max=1.2) #Padded a bit

plot_linf = InspectDR.Plot2D(:lin, :dB20)
	graph_linf = plot_linf.strips[1]
	graph_linf.yext_full = InspectDR.PExtents1D(max=5)
#	plot_linf.layout[:enable_legend] = true

plot_logf = InspectDR.Plot2D(:log10, :dB20)
	graph_logf = plot_logf.strips[1]
	plot_logf.xext_full = InspectDR.PExtents1D(min=10e6) #Avoid issues with log scale
	graph_logf.yext_full = InspectDR.PExtents1D(max=5)
	graph_logf.grid = InspectDR.GridRect(vmajor=true, vminor=true, hmajor=true)
plot_ysmith = InspectDR.smithchart(:Y, title="Y-Smith Chart")
	graph_ysmith = plot_ysmith.strips[1]
	plot_ysmith.xext_full = smithext
	graph_ysmith.yext_full = smithext
	plot_ysmith.layout[:enable_legend] = true
plot_zsmith = InspectDR.smithchart(:Z, ref=50, title="Z-Smith Chart")
	graph_zsmith = plot_zsmith.strips[1]
	plot_zsmith.xext_full = smithext
	graph_zsmith.yext_full = smithext
	plot_zsmith.layout[:enable_legend] = true

let plot, a #HIDEWARN_0.7
for plot in [plot_linf, plot_logf]
	a = plot.annotation
	a.title = "Reflection Coefficient (Γ)"
	a.xlabel = "Frequency (Hz)"
	a.ylabels = ["Magnitude (dB)"]
end
end

#Select which plots to actually display:
plotlist = [plot_linf, plot_logf, plot_ysmith, plot_zsmith]
#plotlist = [plot_zsmith]

let plot, wfrm #HIDEWARN_0.7
for plot in plotlist
	for i in 1:length(Γload)
		wfrm = add(plot, f, Γload[i], id="ZL=$(ZL[i])")
		wfrm.line = line(color=_colors[i], width=2)
	end

	add(mplot, plot)
end
end

gplot = display(InspectDR.GtkDisplay(), mplot)


#==Save multi-plot to file
===============================================================================#

maximize_square = true
if maximize_square
	#Target plot size to get square Smith plots without gaps:
	#(HACK: Method not suggested)
	lyt = plot_zsmith.layout
		lyt[:halloc_data] = 500
		lyt[:valloc_data] = 500
	bb = InspectDR.plotbounds(lyt.values, InspectDR.grid1(plot_zsmith)) #Required
		mplot.layout[:halloc_plot] = width(bb)
		mplot.layout[:valloc_plot] = height(bb)
end

if false
	#Test several attributes:
	mplot.frame.line.style=:solid
	mplot.frame.line.width=30
	mplot.frame.line.color=red
	mplot.frame.fillcolor=white
end

InspectDR.write_png("export_multiplot.png", mplot)
InspectDR.write_svg("export_multiplot.svg", mplot)
InspectDR.write_eps("export_multiplot.eps", mplot)
InspectDR.write_pdf("export_multiplot.pdf", mplot)

:DONE
