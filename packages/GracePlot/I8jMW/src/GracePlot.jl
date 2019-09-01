#GracePlot: Publication-quality plots through Grace/xmgrace
#-------------------------------------------------------------------------------
__precompile__(true)
#=
TAGS:
	#WANTCONST, HIDEWARN_0.7
=#

module GracePlot

const rootpath = realpath(joinpath(dirname(realpath(@__FILE__)),"../."))

#Convenient accessor for sample GracePlot template (parameter) files:
template(name::String) =
	joinpath(GracePlot.rootpath, "sample", "template", "$name.par")


#==Ensure interface (similar to assert)
===============================================================================#
#=Similar to assert.  However, unlike assert, "ensure" is not meant for
debugging.  Thus, ensure is never meant to be compiled out.
=#
function _ensure(cond::Bool, err)
	if !cond; throw(err); end
end


include("graceconst.jl")
include("codegen.jl")
include("units.jl")
include("base.jl")
include("plotmanip.jl")
include("io.jl")


#==Exported symbols
===============================================================================#
export redraw #Whole plot
export autofit #Re-compute axes to fit data
export arrange #Re-tile plot with specified number of rows/cols
export clearall #clearall(Plot): Graphs or clearall(Graph): datasets

export graph #Obtain reference to an individual graph
export add #Add new dataset/graph

export set #Set Plot/Graph/Dataset properties
#   set(::Plot, arg1, arg2, ..., kwarg1=v1, kwarg2=v1, ...)
#      kwargs: active, focus,
#   set(::GraphRef, arg1, arg2, ..., kwarg1=v1, kwarg2=v1, ...)
#      args: paxes()
#      kwargs: title, subtitle, xlabel, ylabel, frameline
#   set(::DatasetRef, arg1, arg2, ..., kwarg1=v1, kwarg2=v1, ...)
#      args: line(), glyph()
export defaults #Creates DefaultAttributes to set default plot attributes
export canvas #Creates CanvasAttributes to resize plot, etc
export limits #Creates CartesianLimAttributes to set view, world, ...
export text #Creates TextAttributes to set titles, etc
export line #Creates LineAttributes to modify line
export glyph #Creates GlyphAttributes to modify glyph
export paxes #Creates AxesAttributes to modify axis (Bad idea to extend Base.axes: when defining zero-argument signature)
export legend #Creates LegendAttributes to edit legend
export addannotation

#==
Other interface tools (symbols not exported to avoid collisions):
	Inch, Meter, TPoint... TODO: move to external module
	Plot: Main plot object.
	new(): Creates a new Plot object.
	kill(graph): Kill already in Base.
	template("<GracePlot-provided template name>")
	Base.get.... get is already part of base, so can't export it...
==#

end #GracePlot

#Last line
