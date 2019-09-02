#InspectDR: Event handling with Gtk
#-------------------------------------------------------------------------------

import Gtk: GConstants.GdkModifierType, Gtk.GConstants.GdkScrollDirection


#==Constants
===============================================================================#
const MODIFIER_ALT = GdkModifierType.GDK_MOD1_MASK #Is this bad? How do I query?
const MODIFIER_CTRL = GdkModifierType.GDK_CONTROL_MASK
const MODIFIER_SHIFT = GdkModifierType.GDK_SHIFT_MASK

#Other modifiers are ignored... ex: numlock (Mod2)
const MODIFIERS_SUPPORTED = MODIFIER_ALT|MODIFIER_CTRL|MODIFIER_SHIFT

#Symbols not currently supported by Gtk package:
const GdkKeySyms_Plus = 0xffab
const GdkKeySyms_Minus = 0xffad


#==Main types
===============================================================================#
struct ISNormal <: InputState; end #Default state


#==Helper functions
===============================================================================#
modifiers_pressed(eventstate, modmask) = (modmask == (MODIFIERS_SUPPORTED & eventstate))

#Returns 0 or strip index:
#TODO: refer to graphbblist only - instead of pwidget???
function hittest(pwidget::PlotWidget, x::Float64, y::Float64)
	infolist = pwidget.plotinfo.strips #WANTCONST
	for i = 1:length(infolist)
		if isinside(infolist[i].graphbb, x, y)
			return i
		end
	end
	return 0
end


#==Wrapper functions
===============================================================================#
raiseevent_plothover(pwidget::PlotWidget, event::Gtk.GdkEventMotion) =
	raiseevent(pwidget.eh_plothover, pwidget, event.x, event.y)


#==Low-level event handlers
===============================================================================#
function handleevent_plothover(pwidget::PlotWidget, event::Gtk.GdkEventMotion, istrip::Int)
	x, y = event.x, event.y

	if istrip > 0
		xf = Transform2D(pwidget.plotinfo, istrip)
		pt = map2axis(xf, Point2D(x, y))
		ixf = InputXfrm2D(pwidget.plotinfo, istrip)
		pwidget.mouseover.pos = axis2read(pt, ixf) #TODO: do we want "read"able coords?
	else
		pwidget.mouseover.pos = nothing
	end

	raiseevent_plothover(pwidget, event) #Inform owner
	return
end

#Update pwidget.mouseover & raise event to owner
function handleevent_plothover(pwidget::PlotWidget, event::Gtk.GdkEventMotion)
	x, y = event.x, event.y
	istrip = hittest(pwidget, x, y)
	pwidget.mouseover.istrip = istrip
	handleevent_plothover(pwidget, event, istrip)
	return
end


#Last line
