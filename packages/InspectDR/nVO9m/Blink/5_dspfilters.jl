using DSP
include("../notebook/DSPFilters.jl") #Defines DSPFilters.* & BodePlots.* utilities.
import InspectDR
using NumericIO
using Interact
using Blink

#=TODO
 - Make fl & fh sliders relative to fmax?
 - Disable unused parameters (depending on filter implementation)
 - Look for off by 1 errors (esp. for FFT vector lengths, etc).
 - Other details look not quite right (@ notches, phase response, ...)
=#

#Convenience aliases:
SI(x) = formatted(x, :SI, ndigits=3)
_throt(x) = throttle(0.1, x) #Default throttling for this example.

#When MIME"image/svg+xml" is disabled, Jupyter eventually requests PNG inline graphics:
#(Not certain if PNG is faster than SVG)
InspectDR.defaults.rendersvg = false

ltype_opt = OrderedDict("Series RLC" => :series, "Shunt RLC" => :shunt)

opt_ftype = ["Highpass", "Lowpass", "Bandstop", "Bandpass"]
opt_fimpl = ["Butterworth", "Elliptic", "ChebyshevPass", "ChebyshevStop"]

#Create base Observable-s that control plot output:
ftype = Observable(String("Lowpass")) #Filter type
fimpl = Observable(String("Elliptic")) #Filter implementation
fmax = Observable(Float64(500)) #Maximum plot frequency
forder = Observable(Int64(6)) #Filter order
fl = Observable(Float64(300)) #Low frequency point
fh = Observable(Float64(400)) #High frequency point
rpass = Observable(Float64(5)) #Pass-band ripple
rstop = Observable(Float64(40)) #Stop-band ripple

dispinline = Observable(Bool(true)) #Display inline?

#Construct widgets used to control plots:
txt_fmax = spinbox(value=fmax, label="max freq")
tgl_ftype = togglebuttons(opt_ftype, value=ftype)
tgl_fimpl = dropdown(opt_fimpl, value=fimpl)
sld_order = slider(2:1:30, value=forder, label="Filter order")
sld_rpass = slider(0.1:.1:20, value=rpass, label="Pass-band ripple (dB)")
sld_rstop = slider(5:1:200, value=rstop, label="Stop-band ripple (dB)")
sld_fl = slider(10:10:1e3, value=fl, label="Low frequency (Hz)")
sld_fh = slider(10:10:1e3, value=fh, label="High frequency (Hz)")

chk_inline = checkbox(dispinline, label="Display inline")
btn_creategtkplot = button("Create GTK plot")

#Build widget lists to control plot:
widgetlistA = [tgl_ftype, tgl_fimpl, sld_order, chk_inline, btn_creategtkplot]
widgetlistB = [sld_rpass, sld_rstop, sld_fl, sld_fh]

#Widget-controlled plot:
pobj = DSPFilters.newplot() #Create initial plot object
#Calculations are relatively expensive... throttle all inputs:
updater_plot = map(_throt(fmax), _throt(ftype), _throt(fimpl), _throt(forder), _throt(fl), _throt(fh), _throt(rpass), _throt(rstop)) do _fmax, _ftype, _fimpl, _forder, _fl, _fh, _rpass, _rstop
    _filttypeid = Symbol(lowercase(_ftype))
    _filtimplid = Symbol(lowercase(_fimpl))
    return DSPFilters.update(pobj, _fmax, _filttypeid, _filtimplid, _forder, _fl, _fh, _rpass, _rstop)
end

#Conditionally display inline plot with throttling to reduce traffic:
inline_plot = map(updater_plot, dispinline) do _plot, _inline
	if _inline
		return _plot
	else
		return nothing
	end
end

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
body!(wnd, vbox()) #first call to body! does not always work.
body!(wnd, vbox(hbox(vbox(widgetlistA...), vbox(widgetlistB...)), vbox(inline_plot)))

:DEMO_READY
