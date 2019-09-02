include("../notebook/TLines.jl") #Defines TLines.* & BodePlots.* utilities.
import InspectDR
using NumericIO
using Interact
using Blink

#NOTE: Zref=50Ω when computing reflection coefficient, Γ

#Convenience aliases:
SI(x) = formatted(x, :SI, ndigits=3)
_throt(x) = throttle(0.1, x) #Default throttling for this example.

#When MIME"image/svg+xml" is disabled, Jupyter eventually requests PNG inline graphics:
#(Not certain if PNG is faster than SVG)
InspectDR.defaults.rendersvg = false

ltype_opt = OrderedDict("Series RLC" => :series, "Shunt RLC" => :shunt)

#Create base Observable-s that control plot output:
ltype = Observable(Symbol(:shunt)) #Load type
fmin = Observable(Float64(1e7)) #Minimum plot frequency
fmax = Observable(Float64(10e9)) #Maximum plot frequency
R = Observable(Float64(40)) #Resistive load (Ω)
L = Observable(Float64(20e-9)) #Inductive load (H)
C = Observable(Float64(0.2e-12)) #Capacitive load (F)
ZC = Observable(Float64(75)) #Characteristic impedance of line (Ω)
α = Observable(Float64(0.2)) #Line attenuation (dB/m) - Nepers/m?
μ = Observable(Float64(TLines.μ0)) #Permeability for line (H/m)
ϵ = Observable(Float64(TLines.ϵ0)) #Permittivity for line (F/m)
ℓ = Observable(Float64(0.1)) #Line length (m)

dispinline = Observable(Bool(true)) #Display inline?

#Construct widgets used to control plots:
tgl_ltype = togglebuttons(ltype_opt, value=ltype, label="Load type")
txt_fmin = spinbox(value=fmin, label="min freq")
txt_fmax = spinbox(value=fmax, label="max freq")
sld_ZC = slider(1:1.0:377, value=ZC, label="ZC (Ω)")

sld_R = slider(10 .^ range(log10(1e-3), stop=log10(1e6), length=100), value=R, label="R-load (Ω)")
sld_L = slider(10 .^ range(log10(1e-15), stop=log10(1e-3), length=100), value=L, label="L-load (H)")
sld_C = slider(10 .^ range(log10(1e-18), stop=log10(1e-3), length=100), value=C, label="C-load (F)")
sld_α = slider(range(0, stop=1, length=100), value=α, label="α-DC line atten (dB/m)")
sld_ℓ = slider(10 .^ range(log10(1e-6), stop=log10(1), length=100), value=ℓ, label="ℓ-line length (m)")

chk_inline = checkbox(dispinline, label="Display inline")
btn_creategtkplot = button("Create GTK plot")

info_params = map(R, L, C, ℓ) do _R, _L, _C, _ℓ
    return HTML(
        "R=" * SI(_R) * "Ω" *
        ", L=" * SI(_L) * "H" *
        ", C=" * SI(_C) * "F" *
        ", ℓ=" * SI(_ℓ) * "m"
    )
end

#Build widget lists to control plot:
widgetlistA = [tgl_ltype, txt_fmin, txt_fmax, sld_ZC, info_params, chk_inline, btn_creategtkplot]
widgetlistB = [sld_R, sld_L, sld_C, sld_α, sld_ℓ]

#Widget-controlled plot:
pobj = TLines.newplot() #Create initial plot object
#Calculations are relatively expensive... throttle all inputs:
updater_plot = map(_throt(fmin), _throt(fmax), _throt(ltype), _throt(R), _throt(L), _throt(C), _throt(ℓ), _throt(ZC), _throt(α)) do _fmin, _fmax, _ltype, _R, _L, _C, _ℓ, _ZC, _α
    TLines.update(pobj, _fmin, _fmax, _ltype, _R, _L, _C, _ℓ, _ZC, _α)
    return pobj
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
