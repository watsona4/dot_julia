#Demo 11: Digital buffer "Simulation"
#-------------------------------------------------------------------------------
using InspectDR
using Colors
using Random


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
line_supply = line(color=red, width=5)
line_thresh = line(style=:dash, width=2.5, color=RGB24(.4,.4,.4))


#Input data
#-------------------------------------------------------------------------------
VSUPPLY = 1.0
tbit = 1e-9 #Bit period
osr = 40 #samples per bit

Random.seed!(1234) #Generate consistent "random" patterns
#pat = rand(Bool, 8)*1 #Random bit pattern
pat = [0,0,1,1,0,0,0,1,0,1,0]

nsamples = length(pat)
t = collect(range(0, stop=nsamples*tbit, length=nsamples*osr+1)[1:end-1]) #Time
t_1bit = t[1:osr] #Time for 1 bit


#=="Simulation" (really rudimentary to keep things simple)
===============================================================================#
expdecay(Δt::Vector, V0, V∞, τ) = V∞ .+ (V0-V∞)*exp.(-Δt/τ)

function EmulDigtialWfrm(pat::Vector, τrise, τfall)
	vrise = expdecay(t_1bit, 0, VSUPPLY, τrise)
	vfall = expdecay(t_1bit, VSUPPLY, 0, τfall)
	vsup_1bit = VSUPPLY*fill(1, size(t_1bit))
	nsamples = length(pat)

	#Generate waveform:
	result = Vector{Float64}(undef, nsamples*osr)
	padpat = prepend!(copy(pat), [0])
	delta = padpat[2:end] - padpat[1:end-1] #Difference between consecutive bits (i.e. transitions)
	for ibit in 1:length(pat)
		istart = (ibit-1)*osr
		if +1 == delta[ibit]
			data = vrise
		elseif -1 == delta[ibit]
			data = vfall
		else
			data = pat[ibit]*vsup_1bit
		end

		for ioffset in 1:osr
			result[istart+ioffset] = data[ioffset]
		end
	end

	return result
end

vpath1 = EmulDigtialWfrm(pat, tbit/8, tbit/20)
#Path 2 is properly balanced:
vpath2 = EmulDigtialWfrm(pat, tbit/20, tbit/20)

vgnd = 0*t
vsup = vgnd .+ VSUPPLY


#==Generate plot
===============================================================================#
mplot = InspectDR.Multiplot(title="Digital Buffer \"Simulation\"")
mplot.layout[:ncolumns] = 1
ext_digital = InspectDR.PExtents1D(-0.2, 1.2) #"Digital" signals
v10 = 0.1*VSUPPLY; v90 = 0.9*VSUPPLY #10/90 digital thresholds

#To be plotted:
siginfolist = [
	("path1", vpath1, ext_digital),
	("path2", vpath2, ext_digital),
]

plot = add(mplot, InspectDR.transientplot([:lin for i in siginfolist],
	title="Measure trise/tfall with `r` & `d` keys",
	ylabels=["(V)" for i in siginfolist])
)
plot.layout[:enable_legend] = true
#plot.layout[:halloc_legend] = 150

let wfrm #HIDEWARN_0.7
	for (i, siginfo) in enumerate(siginfolist)
		id, sig, ext = siginfo
		plot.strips[i].yext_full = ext
		plot.strips[i].grid = InspectDR.GridRect() #No grid
#		plot.strips[i].grid = InspectDR.GridRect(vmajor=true, vminor=true, hmajor=false, hminor=false)

		#Draw supply lines under data:
		wfrm = add(plot, t, vgnd, strip=i)
			wfrm.line = line_supply
		wfrm = add(plot, t, vsup, strip=i)
			wfrm.line = line_supply

		#Draw current signal:
		wfrm = add(plot, t, sig, id=id, strip=i)
			wfrm.line = line_default

		#Add threshold markers:
		add(plot, hmarker(v10, line_thresh, strip=i))
		add(plot, hmarker(v90, line_thresh, strip=i))
	end
end

gplot = display(InspectDR.GtkDisplay(), mplot)

mplot.layout[:halloc_plot] = 700; mplot.layout[:valloc_plot] = 450
InspectDR.write_png("export_simdig.png", mplot)

:DONE
