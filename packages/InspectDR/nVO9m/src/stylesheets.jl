#InspectDR: Defines stylesheets & presets
#-------------------------------------------------------------------------------

#==Important notes
***IEEE Plots***
  - Write out/export `Multiplot` object instead of `Plot` in order to control
    full plot dimensions instead of just dimensions of data area.
==#


#==Constants: Initial default values
===============================================================================#
#Default values for data area dimensions (used to save single plot):
const DEFAULT_DATA_WIDTH = 500.0
const DEFAULT_DATA_HEIGHT = DEFAULT_DATA_WIDTH / MathConstants.φ #Use golden ratio

#Default values for plot dimensions (used to save multi-plot):
const DEFAULT_PLOT_WIDTH = 600.0
const DEFAULT_PLOT_HEIGHT = DEFAULT_PLOT_WIDTH / MathConstants.φ #Use golden ratio


#==Types
===============================================================================#
mutable struct StyleID{T}; end
StyleID(T::Symbol) = StyleID{T}()

mutable struct PlotSylesheet
	plotlayout::PlotLayout
	mplotlayout::MultiplotLayout
end


#==Useful functions
===============================================================================#
#Try to size allocations & offsets appropriately for font selections:
function autofit2font!(lyt::PlotLayout)
	#Allocations for different elements:
	h_title = lyt.font_title._size
	h_axislabel = lyt.font_axislabel._size
	h_ticklabel = lyt.font_ticklabel._size
	w_axislabel = lyt.font_axislabel._size
	w_ticklabel = lyt.font_ticklabel._size

	lyt.valloc_top = h_title + h_ticklabel/2
	lyt.valloc_mid = h_ticklabel * 1.5
	lyt.valloc_bottom = h_axislabel + 1.75*h_ticklabel

	lyt.halloc_left = w_axislabel + 4.25*w_ticklabel
	lyt.halloc_right = w_ticklabel * 3.75 #Room for x10^EXP

	lyt.voffset_title = h_title*0.5
	lyt.voffset_xticklabel = h_ticklabel*0.5
	lyt.hoffset_yticklabel = w_ticklabel*0.25
	lyt.voffset_xaxislabel = h_axislabel*0.5
	lyt.hoffset_yaxislabel = w_axislabel*0.5

	lyt.halloc_legend = lyt.font_legend._size * (100/12)
	return lyt
end

#Try to size allocations & offsets appropriately for font selections:
function autofit2font!(lyt::MultiplotLayout)
	lyt.valloc_title = lyt.font_title._size * 1.5
	return lyt
end

function overwritefont!(lyt::PlotStyle; fontname=nothing, fontscale=1.0, autofit=true)
	proplist = [:font_title, :font_axislabel, :font_ticklabel, :font_annotation, :font_legend, :font_time]

	if fontname!=nothing
		for prop in proplist
			lyt[prop].name = fontname
		end
	end

	for prop in proplist
		ref = lyt[prop]
		ref._size *= fontscale
		lyt[prop] = ref #Updates layout.overwrite
	end

	if autofit
		autofit2font!(lyt.values)
	end
end


#==Preset Stylesheets
===============================================================================#

#Default ":screen" stylesheet:
#-------------------------------------------------------------------------------

#Default ":screen" PlotLayout stylesheet:
function getstyle(::Type{PlotLayout}, ::StyleID{:screen}, fontname::String, fontscale::Float64,
		notation_x::Symbol, notation_y::Symbol, enable_legend::Bool)
	lyt = PlotLayout()

	lyt.enable_legend = enable_legend
	lyt.enable_timestamp = false

	lyt.font_title = Font(DEFAULT_FONTNAME, 14*fontscale, bold=true)
	lyt.font_axislabel = Font(DEFAULT_FONTNAME, 14*fontscale)
	lyt.font_ticklabel = Font(DEFAULT_FONTNAME, 12*fontscale)
	lyt.font_annotation = Font(DEFAULT_FONTNAME, 12*fontscale)
	lyt.font_time = Font(DEFAULT_FONTNAME, 8*fontscale)
	lyt.font_legend = Font(DEFAULT_FONTNAME, 12*fontscale)

	lyt.valloc_data = DEFAULT_DATA_HEIGHT
	lyt.halloc_data = DEFAULT_DATA_WIDTH

	lyt.halloc_legendlineseg = 20
	lyt.hoffset_legendtext = 0.5
	lyt.valloc_legenditemsp = 0.25

	lyt.voffset_xticklabel = 7
	lyt.hoffset_yticklabel = 3

	function getticklabelstyle(notation::Symbol)
		if :ENG == notation
			TickLabelStyle()
		elseif :SI == notation
			TickLabelStyle(NumericIO.UEXPONENT_SI)
		else
			@warn("Unsupported tick label style: :$notation")
		end
	end
	lyt.format_xtick = getticklabelstyle(notation_x)
	lyt.format_ytick = getticklabelstyle(notation_y)

	lyt.frame_data = AreaAttributes(
		line=InspectDR.line(style=:solid, color=COLOR_BLACK, width=2)
	)

	return autofit2font!(lyt) #Compute offsets
end

#Default ":screen" MultiplotLayout stylesheet:
function getstyle(::Type{MultiplotLayout}, ::StyleID{:screen}, fontname::String, fontscale::Float64,
		notation_x::Symbol, notation_y::Symbol, enable_legend::Bool)
	lyt = MultiplotLayout()

	lyt.ncolumns = 1
	lyt.font_title = Font(DEFAULT_FONTNAME, 20*fontscale, bold=true)

	lyt.valloc_plot = DEFAULT_PLOT_HEIGHT
	lyt.halloc_plot = DEFAULT_PLOT_WIDTH

	return autofit2font!(lyt) #Compute offsets
end

#":screen" stylesheet: High-level interface:
getstyle(::Type{T}, ID::StyleID{:screen}; fontname::String=DEFAULT_FONTNAME, fontscale::Real=1.0,
		notation_x::Symbol=:ENG, notation_y::Symbol=:ENG, enable_legend::Bool=true) where T =
	getstyle(T, ID, fontname, Float64(fontscale), notation_x, notation_y, enable_legend)


#":IEEE" stylesheet:
#-------------------------------------------------------------------------------
#":IEEE" MultiplotLayout stylesheet:
function getstyle(::Type{PlotLayout}, ::StyleID{:IEEE}, ppi::Float64, fontscale::Float64, enable_legend::Bool)
	pt2px = ppi/DTPPOINTS_PER_INCH #WANTCONST
	lyt = PlotLayout()

	#IEEE Plot: Must ensure readable axis & tick labels

	fntaxis = Font(DEFAULT_FONTNAME, fontscale*7*pt2px)
	fnttick = fntaxis
	fntannot = Font(DEFAULT_FONTNAME, fontscale*5*pt2px)
	lyt.font_title = fntaxis
	lyt.font_axislabel = fntaxis
	lyt.font_ticklabel = fnttick
	lyt.font_annotation = fntannot
	lyt.font_time = fntannot
	lyt.font_legend = fntannot

	#Allocations for different elements:
	h_title = lyt.font_title._size
	h_axislabel = lyt.font_axislabel._size
	h_ticklabel = lyt.font_ticklabel._size
	w_axislabel = lyt.font_axislabel._size
	w_ticklabel = lyt.font_ticklabel._size

	#Optimize plot for maximum data area:
	lyt.valloc_top = h_ticklabel/2
	lyt.valloc_mid = h_ticklabel
	lyt.valloc_bottom = h_axislabel + 1.75*h_ticklabel
	lyt.halloc_left = w_axislabel + 2.5*h_ticklabel
	lyt.halloc_right = w_ticklabel * 3.75 #Room for x10^EXP

	lyt.voffset_title = 0
	lyt.voffset_xticklabel = h_ticklabel*0.5
	lyt.hoffset_yticklabel = w_ticklabel*0.25
	lyt.voffset_xaxislabel = h_axislabel*0.5
	lyt.hoffset_yaxislabel = w_axislabel*0.5

	lyt.enable_legend = enable_legend
	lyt.halloc_legend = 50*pt2px
	lyt.halloc_legendlineseg = 10*pt2px
	lyt.valloc_legenditemsp = 0.25
	lyt.hoffset_legendtext = 0.5

	lyt.frame_data.line = line(style=:solid, color=COLOR_BLACK, width=1*pt2px)
	return lyt
end

#":IEEE" MultiplotLayout stylesheet:
#(Write/export `Multiplot` instead of `Plot` to control full plot dimensions - not just data area)
function getstyle(::Type{MultiplotLayout}, ::StyleID{:IEEE}, ppi::Float64, fontscale::Float64, enable_legend::Bool)
	pt2px = ppi/DTPPOINTS_PER_INCH #WANTCONST
	wplot = 3.5*ppi #Inches => Pixels #WANTCONST

	lyt = MultiplotLayout()
	lyt.ncolumns = 1
	lyt.font_title = Font(DEFAULT_FONTNAME, 20*fontscale, bold=true)

	lyt.valloc_title = 0
	lyt.halloc_plot = wplot
	lyt.valloc_plot = wplot/MathConstants.φ #Golden ratio
	return lyt
end

#":IEEE" stylesheet: High-level interface:
getstyle(::Type{T}, ID::StyleID{:IEEE}; ppi::Real=300, fontscale::Real=1.0, enable_legend::Bool=true) where T =
	getstyle(T, ID, Float64(ppi), Float64(fontscale), enable_legend)


#==Preset Stylesheets: high-level interface
===============================================================================#
getstyle(::Type{T}, styleid::Symbol; kwargs...) where T =
	getstyle(T, StyleID(styleid); kwargs...)

function setstyle!(p::Plot, styleid::Symbol; refresh::Bool=true, kwargs...)
	s = getstyle(PlotLayout, StyleID(styleid); kwargs...)
	setstyle!(p.layout, s, refresh=refresh)
end
function setstyle!(p::Multiplot, styleid::Symbol; refresh::Bool=true, kwargs...)
	s = getstyle(MultiplotLayout, StyleID(styleid); kwargs...)
	setstyle!(p.layout, s, refresh=refresh)
end

#Last line
