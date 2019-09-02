#InspectDR: Top-level interface for Cairo layer
#-------------------------------------------------------------------------------

#Render base annotation (titles, axis labels, ...)
#-------------------------------------------------------------------------------
function render_baseannotation(canvas::PCanvas2D, graphinfo::Graph2DInfo,
		xticklabels::Bool, plot::Plot2D, istrip::Int)
	strip = plot.strips[istrip] #WANTCONST
	if plot.layout.values.enable_legend
		legend_render(canvas, plot, istrip)
	end

	#Draw data area & grid lines
Cairo.save(canvas.ctx)
	drawrectangle(canvas.ctx, canvas.graphbb, plot.layout.values.frame_data)
Cairo.restore(canvas.ctx)
	render_grid(canvas, plot.layout.values, graphinfo.grid)

	render_axes(canvas, plot.layout.values, graphinfo.grid, plot.xscale, strip.yscale, xticklabels)
	return
end
function render_baseannotation(ctx::CairoContext, bb::BoundingBox, plotinfo::Plot2DInfo, 
		databb::BoundingBox, graphbblist::Vector{BoundingBox}, plot::Plot2D)

Cairo.save(ctx)
	drawrectangle(ctx, bb, plot.layout.values.frame_canvas)
Cairo.restore(ctx)

	#Render titles, axis labels, ...
	#TODO: use Plot2DInfo instead of databb/graphbblist??:
	render(ctx, plot.annotation, bb, databb, graphbblist, plot.layout.values)

	nstrips = length(plot.strips)
	for i in 1:nstrips
		graphinfo = Graph2DInfo(plotinfo, i)
		canvas = PCanvas2D(ctx, bb, graphinfo)
		render_xticklabels = (i == nstrips) #Only bottom-most graph
		render_baseannotation(canvas, graphinfo, render_xticklabels, plot, i)
	end
end

#Render actual plot data
#-------------------------------------------------------------------------------
function render_data(canvas::PCanvas2D, plot::Plot2D, istrip::Int)
Cairo.save(canvas.ctx)
	setclip(canvas.ctx, canvas.graphbb)

	render(canvas, plot.display_data, istrip)
	if plot.displayNaN
		rendernans(canvas, plot.data, istrip)
	end
Cairo.restore(canvas.ctx)
end
function render_data(ctx::CairoContext, bb::BoundingBox, plotinfo::Plot2DInfo, plot::Plot2D)
	nstrips = length(plot.strips)
	for i in 1:nstrips
		graphinfo = Graph2DInfo(plotinfo, i)
		canvas = PCanvas2D(ctx, bb, graphinfo)
		render_data(canvas, plot, i)
	end
end

#Render secondary plot annotation & redraw frame:
#-------------------------------------------------------------------------------
function render_userannotation(canvas::PCanvas2D, graphinfo::Graph2DInfo, plot::Plot2D, istrip::Int)
Cairo.save(canvas.ctx)
	setclip(canvas.ctx, canvas.graphbb)
	render(canvas, plot.userannot, graphinfo, istrip)
	render(canvas, plot.parentannot, graphinfo, istrip)
Cairo.restore(canvas.ctx)

	render_graphframe(canvas, plot.layout.values.frame_data) #Redraw frame
	#TODO: should we be more careful about setclip() - instead of redrawing frame?
end
function render_userannotation(ctx::CairoContext, bb::BoundingBox, plotinfo::Plot2DInfo, plot::Plot2D)
	nstrips = length(plot.strips)
	for i in 1:nstrips
		graphinfo = Graph2DInfo(plotinfo, i)
		canvas = PCanvas2D(ctx, bb, graphinfo)
		render_userannotation(canvas, graphinfo, plot, i)
	end
end

#Render entire plot within provided bounding box:
#-------------------------------------------------------------------------------
#TODO: Should base API be written such that user provides databb, and have
#      InspectDR calculate outwards instead?
function render(ctx::CairoContext, plot::Plot2D, bb::BoundingBox)
	lyt = plot.layout.values #WANTCONST
	databb = databounds(bb, lyt, grid1(plot)) #WANTCONST
	nstrips = length(plot.strips) #WANTCONST

	graphbblist = graphbounds_list(databb, lyt, nstrips)
	refreshed = update_ddata(plot) #Also computes new extents
	plotinfo = Plot2DInfo(plot, bb) #Compute new extents before calling.

	_reset(ctx) #Ensure known state.
	render_baseannotation(ctx, bb, plotinfo, databb, graphbblist, plot)
	render_data(ctx, bb, plotinfo, plot)
	render_userannotation(ctx, bb, plotinfo, plot)

	return plotinfo #So parent/caller can position objects/format data
end

#Render entire plot plot using CairoBufferedPlot:
#-------------------------------------------------------------------------------
#TODO: split in parts so that GUI can be refreshed before refreshing data
#TODO: Or maybe send in final context so it can be done here.
function render(bplot::CairoBufferedPlot, plot::Plot2D, bb::BoundingBox, refreshdata::Bool)
	lyt = plot.layout.values #WANTCONST
	databb = databounds(bb, lyt, grid1(plot)) #WANTCONST
	nstrips = length(plot.strips) #WANTCONST
	refreshed = false

	graphbblist = graphbounds_list(databb, lyt, nstrips)
	if refreshdata
		refreshed = update_ddata(plot) #Also computes new extents
		#TODO: don't refresh data if !refresh && bounding box did not change??
	end
	plotinfo = Plot2DInfo(plot, bb) #Compute new extents before calling.

	ctx = CairoContext(bplot.surf)
	_reset(ctx); clear(ctx)
	render_baseannotation(ctx, bb, plotinfo, databb, graphbblist, plot)

	if refreshdata #Update data surface:
		ctxdata = CairoContext(bplot.data)
		_reset(ctxdata); clear(ctxdata)
		render_data(ctxdata, bb, plotinfo, plot)
		Cairo.destroy(ctxdata)
	end

	#Now render data portion onto main context:
	Cairo.set_source_surface(ctx, bplot.data, 0, 0)
	Cairo.paint(ctx) #Applies contents of bplot.data

	render_userannotation(ctx, bb, plotinfo, plot)
	Cairo.destroy(ctx)

	return plotinfo #So parent/caller can position objects/format data
end

#Last line
