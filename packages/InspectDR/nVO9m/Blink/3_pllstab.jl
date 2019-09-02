include("../notebook/PhaseLock.jl") #Defines PhaseLock.* & BodePlots.* utilities.
import InspectDR
using NumericIO
using Interact
using Blink

#Convenience aliases:
SI(x) = formatted(x, :SI, ndigits=3)
_throt(x) = throttle(0.1, x) #Default throttling for this example.

#When MIME"image/svg+xml" is disabled, Jupyter eventually requests PNG inline graphics:
#(Not certain if PNG is faster than SVG)
InspectDR.defaults.rendersvg = false

#Create base Observable-s that control plot output:
fmin = Observable(Float64(1e5)) #Minimum plot frequency
fmax = Observable(Float64(1e9)) #Maximum plot frequency
tmax = Observable(Float64(10e-6)) #Maximum plot time
ωnperiods = Observable(Float64(10)) #Maximum plot time (relative to ωn)

KdB = Observable(Float64(150)) #Gain
fp = Observable(Float64(500e3)) #Pole frequency
fz = Observable(Float64(50e6)) #Zero frequency

dispinline = Observable(Bool(true)) #Display inline?

#Compute open-loop characteristics
#Calculations are relatively expensive... throttle all inputs:
G = map(_throt(KdB), _throt(fp), _throt(fz)) do _KdB, _fp, _fz
	PhaseLock.Xf1(K=10.0^(_KdB/20), ωp=2pi*_fp, ωz=2pi*_fz)
end

function frequency_slider(sig::Observable; label::String="")
	rng = 10 .^ range(log10(1), stop=log10(1e9), length=100)
	return slider(rng, value=sig, label=label)
end

#Construct widgets used to control plots:
txt_fmin = spinbox(value=fmin, label="min freq")
txt_fmax = spinbox(value=fmax, label="max freq")
txt_tmax = spinbox(value=tmax, label="max time")
txt_ωnperiods = spinbox(value=ωnperiods, label="ωn periods")

sld_KdB = slider(-10:1.0:400, value=KdB, label="OL gain (dB)")
sld_fp = frequency_slider(fp, label="pole (Hz)")
sld_fz = frequency_slider(fz, label="zero (Hz)")

chk_inline = checkbox(dispinline, label="Display inline")
btn_creategtkplot = button("Create GTK plot")

info_poles = map(G) do _G
	txt(x::String) = "$x" #"\\textrm{$x}" #Not currently using LaTeX
	return HTML(txt("G (open-loop): ") *
		"K=" * SI(20*log10(_G.K)) * txt(" dB") *
		", 𝑓p=" * txt(SI(_G.ωp/(2pi)) * "Hz") *
		", 𝑓z=" * txt(SI(_G.ωz/(2pi)) * "Hz") *
		txt(" (") * "𝑓0=" * txt(SI(PhaseLock.ω_0(_G)/(2pi))) * "Hz)"
	)
end

info_sys = map(G) do _G
	s = PhaseLock.Sys2(_G)
	α = SI(s.α); ζ = SI(s.ζ); ωn = SI(s.ωn)
    return HTML("H (closed-loop): α=$α, ζ=$ζ, <b>ωn=$(ωn)rad/s</b>")
end

#Build widget lists to control plot:
widgetlistA = [txt_fmin, txt_fmax, txt_tmax, txt_ωnperiods, chk_inline, btn_creategtkplot]
widgetlistB = [sld_KdB, sld_fp, sld_fz, info_poles, info_sys]


#Widget-controlled plot:
pobj = PhaseLock.newplot() #Create initial plot object
#Calculations are relatively expensive... throttle all inputs:
updater_plot = map(_throt(fmin), _throt(fmax), _throt(tmax), _throt(ωnperiods), G) do _fmin, _fmax, _tmax, _ωnperiods,_G
	s = PhaseLock.Sys2(_G)
	return PhaseLock.update(pobj, _fmin, _fmax, _tmax, _ωnperiods, _G)
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
