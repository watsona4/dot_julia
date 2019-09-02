#InspectDR: Drawing Smith/polar grids with Cairo layer
#-------------------------------------------------------------------------------

#TODO: Try to collect Smith chart code in this module, if it makes sense.


#==Constants
===============================================================================#
const SMITHLABEL_OFFSET = Float64(2) #Device units from intercept


#==Types
===============================================================================#


#==Base functions
===============================================================================#
function smithlabel(v::Real)
	vint = round(Int, v)
	if vint == v
		return "$vint"
	else
		return "$v"
	end
end

function render_rcircle(ctx::CairoContext, c::DReal)
	pctr = Point2D(c / (1+c), 0)
	radius = 1 / (1+c)
	Cairo.arc(ctx, pctr.x, pctr.y, radius, 0, 2pi)
	Cairo.stroke(ctx)
end
render_rcircles(ctx::CairoContext, clist::Vector{DReal}) =
	(for c in clist; render_rcircle(ctx, c); end)

function render_xcircle(ctx::CairoContext, c::DReal)
	radius = 1/c
	Cairo.arc(ctx, 1, radius, radius, 0, 2pi)
	Cairo.stroke(ctx)
	Cairo.arc(ctx, 1, -radius, radius, 0, 2pi)
	Cairo.stroke(ctx)
end
render_xcircles(ctx::CairoContext, clist::Vector{DReal}) =
	(for c in clist; render_xcircle(ctx, c); end)

#xflip: Mirror x-direction for admittance(Y)-labels
function render_rcirclelabel(ctx::CairoContext, xf::Transform2D, pt::Point2D, xflip::Bool, lbl::String)
	xscale = xflip ? -1 : 1
	xalign = xflip ? ALIGN_LEFT : ALIGN_RIGHT
	pt = map2dev(xf, Point2D(xscale*pt.x, pt.y))
	render(ctx, lbl, Point2D(pt.x-xscale*SMITHLABEL_OFFSET, pt.y+SMITHLABEL_OFFSET),
		align=ALIGN_TOP|xalign
	)
end
function render_rcirclelabel(ctx::CairoContext, xf::Transform2D, xflip::Bool, refscale::Real, c::DReal)
	xintercept = (c-1)/(c+1)
	pt = Point2D(xintercept, 0)
	cstr = smithlabel(c*refscale)
	tstr = "$cstr"
	render_rcirclelabel(ctx, xf, pt, xflip, tstr)
end
render_rcirclelabels(ctx::CairoContext, xf::Transform2D, xflip::Bool, refscale::Real, clist::Vector{DReal}) =
	(for c in clist; render_rcirclelabel(ctx, xf, xflip, refscale::Real, c); end)


#xflip: Mirror x-direction for admittance(Y)-labels
function render_xcirclelabel(ctx::CairoContext, xf::Transform2D, pt::Point2D, xflip::Bool, lbl::String)
	xscale = xflip ? -1 : 1
	corr = -xscale*xf.xs/xf.ys #Correct for aspect ratio
	#Compute text angle:
	Θ = atan(pt.x, pt.y*corr)
	if xflip; Θ+=pi; end

	#Compute text position, including offset:
	pt = Point2D(xscale*pt.x, pt.y)
	vpos = map2dev(xf, Vector2D(pt)) #Directional vector of label position
	voffset = (SMITHLABEL_OFFSET/vecnorm(vpos))*vpos
	pt = map2dev(xf, pt)+voffset
	render(ctx, lbl, pt, angle=Θ, align=ALIGN_BOTTOM|ALIGN_HCENTER)
end
function render_xcirclelabel(ctx::CairoContext, xf::Transform2D, xflip::Bool, refscale::Real, c::DReal)
	radius = 1/c
	#Compute intercept with 0dB circle (r=1):
	y = 2*radius/(1+radius*radius)
	x = 1-y*radius

	cstr = smithlabel(c*refscale)
	tstr = "$(cstr)j"
	render_xcirclelabel(ctx, xf, Point2D(x, y), xflip, tstr)
	tstr = "-$(cstr)j"
	render_xcirclelabel(ctx, xf, Point2D(x, -y), xflip, tstr)
end
render_xcirclelabels(ctx::CairoContext, xf::Transform2D, xflip::Bool, refscale::Real, clist::Vector{DReal}) =
	(for c in clist; render_xcirclelabel(ctx, xf, xflip, refscale, c); end)


#==Extensions to base functionnality
===============================================================================#

#Split complex input data into real/imag components:
function getrealimag(d::Vector{T}) where T<:Number
	x = Array{DReal}(undef, length(d))
	y = Array{DReal}(undef, length(d))
	for i in 1:length(d)
		x[i] = convert(DReal, real(d[i]))
		y[i] = convert(DReal, imag(d[i]))
	end
	return (x, y)
end

function map2axis(input::T, x::InputXfrm1DSpec{:real}, y::InputXfrm1DSpec{:imag}) where T<:IDataset
	(x, y) = getrealimag(input.y)
	return IDataset{false}(x, y) #Assume new re/im data is not sorted.
end


#==High-level rendering functions
===============================================================================#
function render_grid(canvas::PCanvas2D, lyt::PlotLayout, grid::GridSmith)
	ctx = canvas.ctx #WANTCONST
	graphbb = canvas.graphbb #WANTCONST
	xflip = !grid.zgrid #WANTCONST Flip x-axis for admittance(Y)-grid lines

Cairo.save(ctx) #-----
	setclip(ctx, graphbb)

	#Set transform through Cairo to so it can deal with circles:
	setxfrm(ctx, canvas.xf)
	if xflip
		Cairo.scale(ctx, -1, 1)
	end
	setlinestyle(ctx, lyt.line_smithminor)
		render_rcircles(ctx, grid.minorR)
		render_xcircles(ctx, grid.minorX)
	setlinestyle(ctx, lyt.line_smithmajor)
		render_rcircles(ctx, grid.majorR)
Cairo.restore(ctx) #-----

Cairo.save(ctx) #-----
	setclip(ctx, graphbb)

	#Draw X=0 line:
	setlinestyle(ctx, lyt.line_smithminor)
	y = map2dev(canvas.xf, Point2D(0, 0)).y
	drawline(ctx::CairoContext, Point2D(graphbb.xmin, y), Point2D(graphbb.xmax, y))

	#Draw labels:
	setfont(ctx, lyt.font_ticklabel)
	render_rcirclelabels(ctx, canvas.xf, xflip, grid.ref, grid.labelR)
	render_rcirclelabel(ctx, canvas.xf, Point2D(1,0), xflip, "∞")
	render_xcirclelabels(ctx, canvas.xf, xflip, grid.ref, grid.labelX)

Cairo.restore(ctx) #-----
	nothing
end

function render_axes(canvas::PCanvas2D, lyt::PlotLayout, grid::GridSmith, xs::AxisScale, ys::AxisScale, xticklabels::Bool)
	render_graphframe(canvas, lyt.frame_data)

	#Display grid:
	#TODO: make it possible to disable?
	cgrid = coord_grid(grid, xs, ys, canvas.ext)
	render_ticks(canvas, lyt, cgrid, xs, ys, xticklabels)
end

#Last line
