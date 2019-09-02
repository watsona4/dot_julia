if !@isdefined(BodePlots)
include("BodePlots.jl")
end

module DSPFilters

using DSP
using InspectDR
import InspectDR: Plot2D
using NumericIO
using FFTW
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


#==Equations
===============================================================================#


#==Main functions
===============================================================================#
function newplot()
	w = 500 #WANTCONST
	mplot = InspectDR.Multiplot(title="Filter Response")
	#Mag/phase plots look better with wider aspect ratio:
#	mplot.layout[:halloc_plot] = w; mplot.layout[:valloc_plot] = w/2.3 #Not needed with multi-y strips
	mplot.layout[:ncolumns] = 1

	#Initialize as Bode plot:
	plot_bode = add(mplot, Main.BodePlots.new(InspectDR.Plot))
	strip_mag, strip_phase = plot_bode.strips
		strip_mag.yext_full = InspectDR.PExtents1D(-90, 10)
		strip_phase.yext_full = InspectDR.PExtents1D(-200, 200)
		plot_bode.annotation.title = ""

	#Use linear frequency instead of actual Bode plot:
	plot_bode.xscale = InspectDR.AxisScale(:lin)

	return mplot
end

#Modify previously-generated plot:
#-------------------------------------------------------------------------------
#TODO: Look for off by 1 errors (esp. for FFT vector lengths, etc).
#(Frequencies: in Hz)
function update(mplot::InspectDR.Multiplot, fmax, filttypeid::Symbol, filtimplid::Symbol, order, fl, fh, passrip, stoprip)
	npts = 500 #WANTCONST
	ldata = line(color=blue, width=3, style=:solid) #WANTCONST
	lspec = line(color=red, width=1, style=:solid) #WANTCONST: Spectrum
	plot_bode = mplot.subplots[1] #WANTCONST
	rlow = 1/100; rhigh = 1-rlow #WANTCONST
	limfreqr(ratio) = clamp(ratio, rlow, rhigh)

	if fh < fl #Re-order fl/fh:
		(fl, fh) = (fh, fl)
	end

	#Generate filter type object:
	filttype = nothing 
	if :highpass == filttypeid
		filttype = Highpass(limfreqr(fh/fmax))
	elseif :bandstop == filttypeid
		filttype = Bandstop(limfreqr(fl/fmax), limfreqr(fh/fmax))
	elseif :bandpass == filttypeid
		filttype = Bandpass(limfreqr(fl/fmax), limfreqr(fh/fmax))
	else #:lowpass
		filttype = Lowpass(limfreqr(fl/fmax))
	end

	#Generate filter implementation object
	filtimpl = nothing
	if :elliptic == filtimplid
		filtimpl = Elliptic(order, passrip, stoprip)
	elseif :chebyshevpass == filtimplid
		filtimpl = Chebyshev1(order, passrip)
	elseif :chebyshevstop == filtimplid
		filtimpl = Chebyshev2(order, stoprip)
	else
		filtimpl = Butterworth(order)
	end

	_filt = digitalfilter(filttype, filtimpl)

	#Generate mag/phase plot of discrete-time system:
	#TODO: find proper name for frequency variable.
	fz = collect(range(0, stop=pi, length=npts))
	tf_graph = freqz(_filt, fz)
	f = fz*(fmax/pi)
	Main.BodePlots.update(plot_bode, f, tf_graph)
	plot_bode.xext = InspectDR.PExtents1D() #Reset
	strip_mag, strip_phase = plot_bode.strips
		strip_mag.yext = InspectDR.PExtents1D() #Reset
		strip_phase.yext = InspectDR.PExtents1D() #Reset

	#Overlay spectrum using random data:
	xin = rand(100000)
	xout = filt(_filt, xin)
	spec = rfft(xout)/sqrt(length(xin)/2)
	fz = collect(range(0, stop=pi, length=length(spec)))
	f = fz*(fmax/pi)
	wfrm = add(plot_bode, f, spec, strip=1)
	wfrm.line = lspec

	#Hack to plot spectrum *before* (under) frequency graph:
	plot_bode.data = reverse(plot_bode.data)

	return mplot
end

end #module
