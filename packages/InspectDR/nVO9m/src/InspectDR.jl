#InspectDR:
#-------------------------------------------------------------------------------
#=
TAGS:
	#WANTCONST, HIDEWARN_0.7
=#

const _devmode = false
if _devmode
@warn("Development mode - precompile deactivated.")
end
__precompile__(!_devmode)

module InspectDR

using Colors
using Graphics
using NumericIO
using Pkg
import Printf: @sprintf
import Cairo
import Cairo: CairoContext

const GtkAvailable = true
import Gtk
const _Gtk = Gtk.ShortNames
#=
REMINDER:
Conditional inclusion causes issues with __precompile__() (source: tkelman).
Not worth risking precompile issues just for current troubles with JuliaBox/Gtk.

try
	import Gtk
	eval(:(const _Gtk = Gtk.ShortNames))
	GtkAvailable = true
catch
	@warn("InspectDR: Error loading Gtk.  GUI-based features are unavailable.")
end
=#


#==Constants: Initial default values
===============================================================================#
const DTPPOINTS_PER_INCH = 72 #Typography (desktop publishing) "points per inch"

#Default font:
const DEFAULT_FONTNAME = (@static Sys.iswindows() ? "Cambria" : "Serif")
#Cairo "built-in": Serif, Sans, Serif, Fantasy, Monospace
#NOTE: "Serif" does not work well in Windows.


#==Aliases
===============================================================================#
NullOr{T} = Union{Nothing, T}

include("codegen.jl")
include("styles.jl")
include("math.jl")
include("math_graphics.jl")
include("math_coordinates.jl")
include("numericfmt.jl")
include("events.jl")
include("datasets.jl")
include("grids.jl")
include("base.jl")
include("stylesheets.jl")
include("defaults.jl")
include("graph2d.jl")
include("glyphs.jl")
include("cairo_ext.jl")
include("cairo_base.jl")
include("cairo_annotation.jl")
include("cairo_smithpolar.jl")
include("cairo_legends.jl")
include("cairo_top.jl")
include("cairo_io.jl")
include("templates.jl")
include("compat.jl")

if GtkAvailable
include("gtk_base.jl")
include("gtk_events.jl")
include("gtk_zoom.jl")
include("gtk_markers.jl")
include("gtk_traces.jl")
include("gtk_input.jl")
include("gtk_top.jl")
end

include("show.jl")


#==Comments
================================================================================
-SVG MIME output (using show) does not show up properly in Notebook.  There
 appears to be an issue with determining the extents of the image (bounding box).
-Data area referred to as "graph" area.  This might not be correct.

DReal vs Float64:
	Float64: Used in API dealing with Gtk/Cairo coordinates.
	DReal: Used in API dealing with plot data itself
		(Attempt to reduce code bloat/different code paths by using concrete
		data type in internal data structures/algorithms... despite potential
		inefficiencies).

Transformations between coordinate systems:
         nlxfrm      lxfrm
	data/ -----> axis -----> device
	world                    /view

	where:
		lxfrm is a linear transformation
		nlxfrm is potentially a nonlinear transformation

	- Data coordinates hold whichever units is associated with the data (D).
	- Axis units are transformations of D (ex: D, log(D), dB20(D), ...)
	- Device units can typically be thought of in pixels.

Auxiliary transformations:
	     nlxfrm
	axis -----> readable
                (read)
	Readable coordinates are basically axis coordinates in a readable form.
	Ex (for log10-X scale): X{axis}=2.5 --> X{read}=10^2.5

PExtents2D vs BoundingBox:
	PExtents2D: Extents of data (data coordinate system).
	BoundingBox: Extents of graphical element ("device" coordinate system).

About extents:
	Extents are typically stored using user-level coordinates (USER).
	When drawing the plot, extents are manipulated in a transformed
	coordinate system (XFRM).  For example, XFRM coordinates of a log-x
	plot are given by XFRM=log10(USER).

	ext_data::PExtents2D #Maximum extents of data
	ext_full::PExtents2D #Defines "full" zoom when combined with ext_data
		#Set fields to NaN to keep ext_data values
	ext::PExtents2D #Current/active extents

	setextents(::Plot2D, ::PExtents2D): Also invalidates rendered plot.
	getextents(...): Complementary accessor.

About bounds:
	plotbounds(...): Bounding box of entire plot.
	databounds(...): Bounding box of entire data area (multiple graph strips).
	graphbounds(...): Bounding box of individual graph strip.
=#


#==Exported interface
===============================================================================#
add = _add #Danger: high risk of collision (common name)
export add, line, glyph
export vmarker, hmarker, atext
export clear_data

#==Unexported interface
================================================================================
Supported plot types:
	InspectDR.Multiplot() #Figure supporting multiple plots
	InspectDR.Plot2D <: Plot #2D plot object

Convenience functions:
	write_png(path, ::Plot)
	write_svg(path, ::Plot)
	write_eps(path, ::Plot)
	write_pdf(path, ::Plot)

Other:
	refresh(::PlotWidget)
	refresh(::GtkPlot)
	clearsubplots(::GtkPlot)
=#

#Create new plot window (Is this a good idea?):
#	figure(args...; kwargs...) = GtkPlot(args...; kwargs...)

#Accessors:
if GtkAvailable
	Plot(pwidget::PlotWidget) = pwidget.src
	Plot(gplot::GtkPlot, i::Int) = gplot.subplots[i]
end


#==Already exported
================================================================================
#Displaying a plot object:
	Base.display(d::InspectDR.GtkDisplay, p::Plot) #Gtk mutltiplot window

#Closing a Gtk plot window:
	Base.close(::GtkPlot)

#Writing plot to IO stream:
	Base.show(::IO, ::MIME, ::Plot2D)
for the following MIMEs:
		MIME"image/png"
		MIME"image/svg+xml"
		MIME"image/eps"
		MIME"application/pdf"
=#

function __init__()
	global defaults
	_initialize(defaults)

	if GtkAvailable
		initialize_cursors()
		_setdefaults(keybindings)
	end

	checkcompat_plots()
end

#include("precompile.jl")

end #module
