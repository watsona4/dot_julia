#InspectDR: Store/manipulate info about graph bounds, scales, ...
#-------------------------------------------------------------------------------

#TODO: Move Plot2D here from base.jl, and rename?


#==Main types
===============================================================================#

#TODO: deprecate Plot2DInfo & stick with Graph2DInfo (despite redundancy)???
#Maybe Plot2DInfo just stores array of Graph2DInfo?

#"Evaluated" information about all strips:
#(Cache for bounds, current extents, text formatting, transforms, etc)
mutable struct StripInfo
	graphbb::BoundingBox #Location of graph (device units)
	ext::PExtents2D #Current extents of graph
	yfmt::TickLabelFormatting #y tick label formatting
	yixf::InputXfrm1DSpec #Input transform for y-values
	xf::Transform2D #Transform used to render data
	grid::PlotGrid #Real, displayed ("_eval"-uated) grid - not "coordinate grid"
	#TODO: axis scaling, ...?
end

#"Evaluated" information about all graphs on a plot:
#(Cache for bounds, current extents, text formatting, transforms, etc)
mutable struct Plot2DInfo
#TODO: store BoundingBox for entire plot??
#TODO: store extents???
	xfmt::TickLabelFormatting #x tick label formatting
	xixf::InputXfrm1DSpec #Input transform for x-values
	strips::Vector{StripInfo}
end
Plot2DInfo() = Plot2DInfo(
	TickLabelFormatting(NoRangeDisplayInfo()), InputXfrm1DSpec(:lin), []
)

#Graph-specific version of Plot2DInfo/StripInfo
mutable struct Graph2DInfo
	graphbb::BoundingBox #Location of graph (device units)
	ext::PExtents2D #Current extents of graph

	xfmt::TickLabelFormatting #x tick label formatting
	yfmt::TickLabelFormatting #y tick label formatting

	ixf::InputXfrm2D #Input transform for y-values
	xf::Transform2D #Transform used to render data

	grid::PlotGrid #Real, displayed ("_eval"-uated) grid - not "coordinate grid"
end


#==Accessors
===============================================================================#
Transform2D(pinfo::Plot2DInfo, istrip::Int) = pinfo.strips[istrip].xf
InputXfrm2D(pinfo::Plot2DInfo, istrip::Int) =
	InputXfrm2D(pinfo.xixf, pinfo.strips[istrip].yixf)


#==Constructor-like functions
===============================================================================#
function Graph2DInfo(pinfo::Plot2DInfo, istrip::Int)
	graphbb = pinfo.strips[istrip].graphbb
	ext = pinfo.strips[istrip].ext
	xfmt = pinfo.xfmt
	yfmt = pinfo.strips[istrip].yfmt
	ixf = InputXfrm2D(pinfo, istrip)
	xf = Transform2D(pinfo, istrip)
	grid = pinfo.strips[istrip].grid
	return Graph2DInfo(graphbb, ext, xfmt, yfmt, ixf, xf, grid)
end

function Plot2DInfo(plot::Plot2D)
	xfmt = TickLabelFormatting(NoRangeDisplayInfo())
	if length(plot.strips) > 0
		istrip = 1
		strip = plot.strips[istrip]
		ext = getextents_axis(plot, istrip)
		#Get the rectangular coordinate grid:
		grid = coord_grid(strip.grid, plot.xscale, strip.yscale, ext)
		if !isa(grid.xlines, UndefinedGridLines)
			xfmt = TickLabelFormatting(plot.layout.values.format_xtick, grid.xlines.rnginfo)
		end
	end
	return Plot2DInfo(xfmt, InputXfrm1DSpec(plot.xscale), [])
end

#bb: bounding box of entire plot
function Plot2DInfo(plot::Plot2D, bb::BoundingBox)
	dfltfmt = TickLabelFormatting(NoRangeDisplayInfo()) #WANTCONST
	result = Plot2DInfo(plot)
	databb = databounds(bb, plot.layout.values, grid1(plot))
	nstrips = length(plot.strips)
	graphbblist = graphbounds_list(databb, plot.layout.values, nstrips)
	resize!(result.strips, nstrips)

	for istrip in 1:nstrips #Compute x/y label formats:
		strip = plot.strips[istrip]
		graphbb = graphbblist[istrip]
		ext = getextents_axis(plot, istrip)
		grid = _eval(strip.grid, plot.xscale, strip.yscale, ext)
		cgrid = coord_grid(strip.grid, plot.xscale, strip.yscale, ext)
		yfmt = dfltfmt
		if !isa(cgrid.ylines, UndefinedGridLines)
			yfmt = TickLabelFormatting(plot.layout.values.format_ytick, cgrid.ylines.rnginfo)
		end
		result.strips[istrip] = StripInfo(graphbb, ext, yfmt,
			InputXfrm1DSpec(strip.yscale), Transform2D(ext, graphbb), grid
		)
	end
	return result
end
#Want to define/use coord_grid when displaying coordinates???
#Or maybe we deprecate coord_grid???


#==Helper functions
===============================================================================#
#Get numeric formatting/precision with mouse hover:
function hoverfmt(fmt::TickLabelFormatting)
	result = deepcopy(fmt.fmt)
	#Display a bit more precision than tick labels:
	result.ndigits += 2 #TODO: Better algorithm?
	return result
end


#==Main functions
===============================================================================#
#TODO: move some of the computations from base.jl here?

#Last line
