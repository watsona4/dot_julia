#DEMO1: Sample Multi-Dimensional (Vectorized) calculation:
#-------------------------------------------------------------------------------

using MDDatasets
using InspectDR
using Colors


#==Constants
===============================================================================#
red = RGB24(1, 0, 0)
green = RGB24(0, 1, 0)
blue = RGB24(0, 0, 1)
black = RGB24(0, 0, 0)
grey = RGB24(0.5, 0.5, 0.5)

dfltcolorlist = [red, green, black, blue, grey] #Different color for each
dfltline = line(color=blue, width=3)
redline = line(color=red, width=3)


#==Helper functions
===============================================================================#
#Add DataF1 signal to plot:
function _add(plot, sig::DataF1, args...; line=dfltline, kwargs...)
	wfrm = add(plot, sig.x, sig.y, args...; kwargs...)
	wfrm.line = line
	return wfrm
end

#Add DataRS multi-dimensional signal to plot (1-D sweep only):
#TODO: Use EasyPlot module, once registered
function _add(plot, sig::DataRS, args...; id="", line=dfltline, clist=dfltcolorlist, kwargs...)
	for (data, sweepv, color) in zip(sig.elem, sig.sweep.v, clist)
		wfrm = add(plot, data.x, data.y, args..., id="$id[$sweepv]"; kwargs...)
			wfrm.line = deepcopy(line)
			wfrm.line.color = color
	end
	return
end

#Display plot using "do" syntax:
function displayplot(fn, striplist; title="Plotting variable.y vs variable.x")
	plot = InspectDR.transientplot(striplist, title=title)
	fn(plot)
	display(InspectDR.GtkDisplay(), plot)
end


#==DEMO: Sample Multi-Dimensional (Vectorized) Calculation:
===============================================================================#

#Create (x,y) container pair, and call it "x":
x = DataF1(0:.1:20)
#NOTE: Both x & y coordinates of "x" object initialized as y = x = [supplied range]

#“Extract” maximum x-value from data:
xmax = maximum(x)

#Construct noramlized ramp dataset:
unity_ramp = x/xmax


#Observe x & unity_ramp
#-------------------------------------------------------------------------------
displayplot([:lin, :lin]) do plot
	_add(plot, x, id="x", strip = 1)
	_add(plot, unity_ramp, id="unity_ramp", strip = 2)
	InspectDR.write_png("samplemdcalc_1.png", plot)
end

#Compute cos(kx) & ksinkx = cos'(kx):
coskx = cos((2.5pi/10)*x)
ksinkx = deriv(coskx)

#Compute ramps with different slopes using unity_ramp (previously computed):
#(NOTE: Inner-most sweep, we need to specify leaf element type (DataF1 here))
ramp = fill(DataRS{DataF1}, PSweep("slope", [-1, -0.5, 0, 0.5, 1])) do slope
	return unity_ramp * slope
end
#NOTE: Above expression constructs a multi-dimensional DataRS structure,
#      and fills it with (x,y) values for each of the desired parameter
#      values (the slope).


#Observe coskx, ksinkx & ramp
#-------------------------------------------------------------------------------
displayplot([:lin, :lin]) do plot
	_add(plot, coskx, id="coskx", strip = 1)
	_add(plot, ksinkx, id="ksinkx", line=redline, strip = 1)
	_add(plot, ramp, id="ramp", strip = 2)
	plot.strips[1].yext_full = InspectDR.PExtents1D(min=-1.2, max=1.2)
	plot.strips[2].yext_full = InspectDR.PExtents1D(min=-1.5, max=1.5)
	InspectDR.write_png("samplemdcalc_2.png", plot)
end

#Merge 2 datasets with different # of sweeps (coskx & ramp):
r_cos = coskx+ramp


#Observe r_cos
#-------------------------------------------------------------------------------
displayplot([:lin], title = "r_cos = coskx+ramp") do plot
	_add(plot, r_cos, id="r_cos")
	plot.strips[1].yext_full = InspectDR.PExtents1D(min=-2, max=2)
	InspectDR.write_png("samplemdcalc_3.png", plot)
end

#Shift all ramped sin(x) waveforms to be centered at their mid-points:
midval = value(ramp, x=xmax/2)
#midval = (minimum(ramp) + maximum(ramp)) / 2 #Also possible
c_cos = r_cos - midval #Shift by midval (different for each swept slope of "ramp")


#Observe c_cos
#-------------------------------------------------------------------------------
displayplot([:lin], title = "c_cos = r_cos - value(ramp, x=xmax/2)") do plot
	_add(plot, c_cos, id="c_cos")
	plot.strips[1].yext_full = InspectDR.PExtents1D(min=-1.5, max=1.5)
	InspectDR.write_png("samplemdcalc_4.png", plot)
end


#Last line
