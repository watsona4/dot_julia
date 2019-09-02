#InspectDR: Defaults
#-------------------------------------------------------------------------------


#==Constants
===============================================================================#
#Identifies whether a plot should apply f1 acceleration to drop points:
const PDM_NEVER = PointDropMatrix([false false; false false])
const PDM_ALWAYS = PointDropMatrix([true true; true true])
const PDM_NOGLYPH = PointDropMatrix([false false; true false])
const PDM_HASLINE = PointDropMatrix([false false; true true])
const PDM_DEFAULTS = Dict(
	:never => PDM_NEVER,
	:always => PDM_ALWAYS,
	:noglyph => PDM_NOGLYPH,
	:hasline => PDM_HASLINE,
)


#==Types
===============================================================================#
mutable struct Defaults
	rendersvg::Bool #Might want to dissalow SVG renderings for performance reasons
	pointdropmatrix::PointDropMatrix

	plotlayout::PlotLayout
	mplotlayout::MultiplotLayout
end
Defaults() = Defaults(false, PDM_NEVER, getstyle(PlotLayout, :screen), getstyle(MultiplotLayout, :screen))


#==Data
===============================================================================#
const global defaults = Defaults()


#==Set style of Defaults
===============================================================================#
function setstyle!(d::Defaults, styleid::Symbol; refresh::Bool=true, kwargs...)
	s.plotlayout = getstyle(PlotLayout, StyleID(styleid); kwargs...)
	s.mplotlayout = getstyle(MultiplotLayout, StyleID(styleid); kwargs...)
end


#==Data Initialization
===============================================================================#
#Initialize InspectDR.defaults (To be called in __init__()):
function _initialize(dflt::Defaults)
	local userdefaults = Dict{Symbol, Any}()
	try
		userdefaults = copy(Main.DEFAULTS_INSPECTDR)
	catch
	end

	function condget(dict, key::Symbol, T::Type, default)
		if haskey(dict, key)
			return T(pop!(dict, key))
		else
			return T(default)
		end
	end

	dflt.rendersvg = condget(userdefaults, :rendersvg, Bool, true)
	notation_x = condget(userdefaults, :notation_x, Symbol, :ENG)
	notation_y = condget(userdefaults, :notation_y, Symbol, :ENG)
	droppoints = condget(userdefaults, :droppoints, Symbol, :noglyph)
	dflt.pointdropmatrix = PDM_DEFAULTS[droppoints]

	fontname = condget(userdefaults, :fontname, String, DEFAULT_FONTNAME)
	fontscale = condget(userdefaults, :fontscale, Float64, 1.0)

	#Manually get SUPPORTED defaults for Multiplot layout (seed from :screen):
	mplotlayout = getstyle(MultiplotLayout, :screen,
		fontname=fontname, fontscale=fontscale
	)
	condoverwrite(key::Symbol, T::Type) =
		mplotlayout[key] = condget(userdefaults, key, T, mplotlayout[key])
	condoverwrite(:ncolumns, Int)
	condoverwrite(:valloc_plot, Float64)
	condoverwrite(:halloc_plot, Float64)
	dflt.mplotlayout = mplotlayout

	#Automatically get defaults for Plot layout (seed from :screen):
	plotlayout = getstyle(PlotLayout, :screen,
		fontname=fontname, fontscale=fontscale,
		notation_x=notation_x, notation_y=notation_x, enable_legend=false
	)
	for (k, v) in userdefaults
		try
			plotlayout[k] = v
		catch
			@warn("Cannot set default PlotLayout.$k = $v.")
		end
	end
	dflt.plotlayout = plotlayout

	return
end

#Last line
