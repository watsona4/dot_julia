using InspectDR
using Interact
using Blink
include("../notebook/BodePlots.jl") #Defines BodePlots.* utilities.

#When MIME"image/svg+xml" is disabled, Jupyter eventually requests PNG inline graphics:
#(Not certain if PNG is faster than SVG)
InspectDR.defaults.rendersvg = false

#Create base Observable-s that control plot output:
fmult = Observable(Float64(1e9)) #For all user-input
fmax = Observable(Float64(10)) #Maximum plot frequency
G = Observable(Float64(20)) #Gain (dB)
fz = Observable(Float64(fmax[])) #Zero frequency
fp1 = Observable(Float64(.05)) #Pole 1 frequency
fp2 = Observable(Float64(.9)) #Pole 2 frequency
annot = Observable(Bool(true)) #Annotate plot?
dispinline = Observable(Bool(true)) #Display inline?

#Define desired frequency ranges:
fmult_opt = OrderedDict("kHz" => 1.0e3, "MHz" => 1.0e6, "GHz" => 1.0e9) #Make sure to use Float64
fmult_lookup = OrderedDict([v=>k for (k,v) in fmult_opt]) #For labels

#-------------------------------------------------------------------------------
#(Workaround for updates being supressed on mutable objects)
#-------------------------------------------------------------------------------
#Immutable reference to object for throttle():
#(Workaround for updates being supressed on mutable objects)
struct ThrottleRef
	v
end
Base.:(==)(::ThrottleRef, ::ThrottleRef) = false #Always different (always update)
Base.show(io::IO, m::MIME, r::ThrottleRef) = show(io, m, r.v) #Redirect show to referenced object
Base.showable(m::MIME, r::ThrottleRef) = showable(m, r.v) #Redirect showable to referenced object
#-------------------------------------------------------------------------------

function frequency_slider(sig::Observable, fmax::Observable, fmult::Observable; label::String="")
	_fmin = 1e-3
	rng(_fmax) = 10 .^ range(log10(_fmin), stop=log10(max(_fmin, _fmax)), length=100)
	#NOTE: Limit max value to 2_fmin to avoid issues:
	return map(fmax, fmult) do _fmax, _fmult #Max freq & units on label depend on others
		units = fmult_lookup[_fmult]
		return slider(rng(_fmax), value=sig, label="$label ($units)")
	end
end

#Construct widgets used to control plots:
tgl_fmult = togglebuttons(fmult_opt, value=fmult, label="freq multiplier")
txt_fmax = spinbox(value=fmax, label="max freq")
sld_G = slider(-10:1.0:100, value=G, label="Gain (dB)")
sld_fz = frequency_slider(fz, fmax, fmult, label="zero")
sld_fp1 = frequency_slider(fp1, fmax, fmult, label="pole 1")
sld_fp2 = frequency_slider(fp2, fmax, fmult, label="pole 2")
chk_annot = checkbox(annot, label="Display annotation")
chk_inline = checkbox(dispinline, label="Display inline (throttled for speed)")
btn_creategtkplot = button("Create GTK plot")

#Build widget list to control plot for future code blocks
widgetlist = [tgl_fmult, txt_fmax, sld_G, sld_fz, sld_fp1, sld_fp2, chk_annot, chk_inline, btn_creategtkplot]

#Widget-controlled plot:
pobj = BodePlots.new() #Create initial plot object
updater_plot = map(fmult, fmax, G, fz, fp1, fp2, annot) do s, _fmax, _G, _fz, _fp1, _fp2, a
	BodePlots.update(pobj, s*1e-3, _fmax*s, _G, _fz*s, _fp1*s, _fp2*s, a)
end

#Conditionally display inline plot with throttling to reduce traffic:
throttled_plot = throttle(0.1, map(updater_plot, dispinline) do _plot, _inline
	if _inline
		return ThrottleRef(_plot)
	else
		return nothing
	end
end)

#Provide means to spawn new InspectDR-GTK plot windows:
creator_gtkplot = map(observe(btn_creategtkplot)) do _s
	#Display plot in Gtk GUI:
	gtkgui = display(InspectDR.GtkDisplay(), pobj) #Use same plot object

	#Refresh GUI when plot changes:
	updater_gtkgui = map(updater_plot) do _up
		InspectDR.refresh(gtkgui)
	end
end

#Display main window:
wnd = Window()
body!(wnd, tgl_fmult) #first call to body! does not always work.
body!(wnd, hbox(vbox(widgetlist...), vbox(throttled_plot)))

:DEMO_READY
