#InspectDR: Extensions to Cairo layer
#-------------------------------------------------------------------------------

#=
Also provides a higher-level inteface for some basic functions.

NOTE: might be useful to move to a separate module.
=#


#==Constants
===============================================================================#
struct CAlignment #Cairo alignment
	v::Int
end
Base.:|(a::CAlignment, b::CAlignment) = CAlignment(a.v|b.v)

const ALIGN_LEFT = CAlignment(0)
const ALIGN_HCENTER = CAlignment(1)
const ALIGN_RIGHT = CAlignment(2)
const ALIGN_HMASK = 0x3

const ALIGN_BOTTOM = CAlignment(0)
const ALIGN_VCENTER = CAlignment(4)
const ALIGN_TOP = CAlignment(8)
const ALIGN_VMASK = (0x3<<2)

#Symbols not currently supported by Cairo package:
#-------------------------------------------------------------------------------
const PANGO_ELLIPSIZE_END = 3


#==Main types
===============================================================================#


#==Basic rendering
===============================================================================#

#Low-level function to draw circles:
function cairo_circle(ctx::CairoContext, x::Float64, y::Float64, radius::Float64)
	Cairo.arc(ctx, x, y, radius, 0, 2pi)
end

#Reset context to known state:
function _reset(ctx::CairoContext)
	#TODO: reset transforms???
	Cairo.set_source(ctx, COLOR_BLACK)
	Cairo.set_line_width(ctx, 1);
	Cairo.set_dash(ctx, Float64[], 0)

	#Bevel is fastest.  Also not "spiky" like miter (default):
	Cairo.set_line_join(ctx, Cairo.CAIRO_LINE_JOIN_BEVEL)
end

#Set entire context to a single color:
function clear(ctx::CairoContext, color::Colorant=COLOR_TRANSPARENT)
	Cairo.save(ctx)
	Cairo.set_source(ctx, color)
	Cairo.set_operator(ctx, Cairo.OPERATOR_SOURCE)
	Cairo.paint(ctx) #_with_alpha?
	Cairo.restore(ctx)
end

#Draws a rectangle-shaped area with a solid color
function wipe(ctx::CairoContext, bb::BoundingBox, color::Colorant)
	Cairo.set_source(ctx, color)
	Cairo.rectangle(ctx, bb)
	Cairo.fill(ctx)
end

function setclip(ctx::CairoContext, bb::BoundingBox)
	Cairo.rectangle(ctx, bb)
	Cairo.clip(ctx)
end

#Set linestyle/linewidth.
function _setlinestyle(ctx::CairoContext, style::Symbol, linewidth::Float64)

	dashes = Float64[] #default (:solid)
	offset = 0

	if :none == style
		linewidth = 0 #In case
	elseif :dash == style
		dashes = Float64[4,2]
	elseif :dot == style
		dashes = Float64[1,2]
	elseif :dashdot == style
		dashes = Float64[4,2,1,2]
	elseif :solid != style
		@warn("Unrecognized line style: $style")
	end

	Cairo.set_line_width(ctx, linewidth);
	Cairo.set_dash(ctx, dashes.*linewidth, offset)
end

function setlinestyle(ctx::CairoContext, s::LineStyle)
	Cairo.set_source(ctx, s.color)
	_setlinestyle(ctx, s.style, s.width)
end

#Conditionnaly render fill (preserve path for stroke)
#-------------------------------------------------------------------------------
renderfill(ctx::CairoContext, fill::Nothing) = nothing
function renderfill(ctx::CairoContext, fill::Colorant)
	Cairo.save(ctx) #-----
	Cairo.set_source(ctx, fill)
	Cairo.fill_preserve(ctx)
	Cairo.restore(ctx) #-----
end

#Draw a simple line on a CairoContext
#-------------------------------------------------------------------------------
function drawline(ctx::CairoContext, p1::Point2D, p2::Point2D)
	Cairo.move_to(ctx, p1.x, p1.y)
	Cairo.line_to(ctx, p2.x, p2.y)
	Cairo.stroke(ctx)
end

#Draw a rectangle, given AreaAttributes
#-------------------------------------------------------------------------------
function drawrectangle(ctx::CairoContext, bb::BoundingBox, aa::AreaAttributes)
	Cairo.set_source(ctx, aa.fillcolor)
	Cairo.rectangle(ctx, bb)
	Cairo.fill_preserve(ctx)
	setlinestyle(ctx, LineStyle(aa.line))
	Cairo.stroke(ctx)
end


#==Rendering text
===============================================================================#

#Extract text width from result of Cairo.text_extents:
_textwidth(t_ext::Array{Float64}) = t_ext[3]
_textheight(t_ext::Array{Float64}) = t_ext[4]
function textextents_wh(ctx::Cairo.CairoContext, str::AbstractString)
	t_ext = Cairo.text_extents(ctx, str)
	return (_textwidth(t_ext), _textheight(t_ext))
end

#Compute text offsets in order to achieve a particular alignment
function textoffset(t_ext::Array{Float64}, align::CAlignment)
#=
typedef struct {
	double x_bearing, y_bearing;
	double width, height;
	double x_advance, y_advance;
} cairo_text_extents_t;
=#

	halign = align.v & ALIGN_HMASK
	_size = t_ext[3]; bearing = t_ext[1]
	xoff = -bearing #ALIGN_LEFT

	if ALIGN_HCENTER.v == halign
		xoff -= _size/2
	elseif ALIGN_RIGHT.v == halign
		xoff -= _size
	end

	valign = align.v & ALIGN_VMASK
	_size = t_ext[4]; bearing = t_ext[2]
	yoff = -bearing #ALIGN_TOP

	if ALIGN_VCENTER.v == valign
		yoff -= _size/2
	elseif ALIGN_BOTTOM.v == valign
		yoff -= _size
	end

	return tuple(xoff, yoff)
end

#Extract text dimensions (w/h) from cairo_text_extents_t "structure":
text_dims(t_ext::Array{Float64}) = tuple(t_ext[3], t_ext[4]) #w, h

#Set active font on a CairoContext
#-------------------------------------------------------------------------------
function setfont(ctx::CairoContext, font::Font)
	weight = font.bold ? Cairo.FONT_WEIGHT_BOLD : Cairo.FONT_WEIGHT_NORMAL #WANTCONST
	noitalic = Cairo.FONT_SLANT_NORMAL #WANTCONST
	Cairo.set_source(ctx, font.color)
	Cairo.select_font_face(ctx, font.name, noitalic, weight)
	Cairo.set_font_size(ctx, font._size)
end

#Render text using "advanced" properties.
#-------------------------------------------------------------------------------
#angle: radians
function render(ctx::CairoContext, t::String, pt::Point2D,
	align::CAlignment, angle::Float64)
	t_ext = Cairo.text_extents(ctx, t)
	(xoff, yoff) = textoffset(t_ext, align)

	if !isfinite(pt.x) || !isfinite(pt.y)
		return #Seems to muck up context when accidentally drawing @ NaN.
	end

	Cairo.save(ctx) #-----

	Cairo.translate(ctx, pt.x, pt.y)
	if angle != 0 #In case is a bit faster...
		Cairo.rotate(ctx, angle)
	end

	Cairo.move_to(ctx, xoff, yoff)
	Cairo.show_text(ctx, t)

	Cairo.restore(ctx) #-----
	return
end
render(ctx::CairoContext, t::String, pt::Point2D;
	align::CAlignment=ALIGN_BOTTOM|ALIGN_LEFT, angle::Real=0) =
	render(ctx, t, pt, align, Float64(angle))

#Convenience: also set font.
function render(ctx::CairoContext, t::String, pt::Point2D, font::Font;
	align::CAlignment=ALIGN_BOTTOM|ALIGN_LEFT, angle::Real=0)
	setfont(ctx, font)
	render(ctx, t, pt, align, Float64(angle))
end


#Draws number as base, raised to a power (ex: 10^9):
#-------------------------------------------------------------------------------
function render_power(ctx::CairoContext, tbase::String, val::DReal, pt::Point2D, font::Font, align::CAlignment)
	EXP_SCALE = 0.75 #WANTCONST
	EXP_SHIFT = 0.5 #WANTCONST
	fontexp = deepcopy(font)
	fontexp._size = font._size*EXP_SCALE

	setfont(ctx, font)
	(wbase, hbase) = text_dims(Cairo.text_extents(ctx, tbase))
	setfont(ctx, fontexp)
	texp = @sprintf("%0.0f", val)
	(wexp, hexp) = text_dims(Cairo.text_extents(ctx, texp))

	#Compute bounding box:
	voffset_exp = EXP_SHIFT * hbase
	w = wbase+wexp
	h = max(hbase, voffset_exp+hexp)

	halign = align.v & ALIGN_HMASK
	xoff = 0 #ALIGN_LEFT
	if ALIGN_HCENTER.v == halign
		xoff -= w/2
	elseif ALIGN_RIGHT.v == halign
		xoff -= w
	end

	valign = align.v & ALIGN_VMASK
	yoff = 0 #ALIGN_BOTTOM
	if ALIGN_VCENTER.v == valign
		yoff += h/2
	elseif ALIGN_TOP.v == valign
		yoff += h
	end

	pt = Point2D(pt.x + xoff, pt.y + yoff)
	render(ctx, tbase, pt, font, align=ALIGN_LEFT|ALIGN_BOTTOM)

	pt = Point2D(pt.x + wbase, pt.y - voffset_exp)
	render(ctx, texp, pt, fontexp, align=ALIGN_LEFT|ALIGN_BOTTOM)
end

#Last line
