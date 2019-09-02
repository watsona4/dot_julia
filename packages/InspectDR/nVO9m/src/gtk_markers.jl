#InspectDR: Marker control for plot widgets
#-------------------------------------------------------------------------------


#==Types
===============================================================================#
const MARKER_COLORANT = ARGB32(0, 0, 0, 0.5)
const MARKER_LINE = LineAttributes(:solid, 2.5, MARKER_COLORANT)
const CTRLPOINT_RADIUS = Float64(4)
const CTRLPOINT_ATTR = AreaAttributes(
	line=LineAttributes(:solid, 2.5, MARKER_COLORANT), fillcolor=COLOR_TRANSPARENT
)


#==Types
===============================================================================#
struct ISMovingMarker <: InputState
	istrip::Int
	initpos::Point2D
	marker::CtrlMarker #Ref to marker
end
struct ISMovingΔInfo <: InputState
	istrip::Int
	refpos::Point2D
	initΔ::Vector2D
	marker::CtrlMarker #Ref to marker
end


#==Constructor-like functions
===============================================================================#
function CtrlMarker(x::Real, y::Real, strip::Int, ref=nothing)
	mkr = hvmarker(Point2D(x, y), MARKER_LINE, strip=strip)
	return CtrlMarker(mkr, Vector2D(0,0), BoundingBox(), ref)
end


#==Rendering functions
===============================================================================#
#TODO: move somewhere else?
function render_ctrlpoint(canvas::PCanvas2D, pt::Point2D, ixf::InputXfrm2D)
	ctx = canvas.ctx #WANTCONST
	pt = read2axis(pt, ixf)
	pt = map2dev(canvas.xf, pt)
	setlinestyle(ctx, LineStyle(CTRLPOINT_ATTR.line))
	#TODO: Deprecate workaround if behaviour is changed.
	#NOTE: Will draw line if we don't "move to" 0rad point on arc before drawing:
	#      why is this?  is this a bug? why does this not show up elsewhere?
	Cairo.move_to(ctx, pt.x+CTRLPOINT_RADIUS, pt.y) #Workaround
	cairo_circle(ctx, pt.x, pt.y, CTRLPOINT_RADIUS)
	renderfill(ctx, CTRLPOINT_ATTR.fillcolor)
	Cairo.stroke(ctx)
	return
end

function render_markercoord(canvas::PCanvas2D, pt::Point2D, font::Font,
	xfmt::NumericFormatting, yfmt::NumericFormatting, graphinfo::Graph2DInfo, strip::Int)
	xstr = formatted(pt.x, xfmt)
	ystr = formatted(pt.y, yfmt)
	str = "$xstr, $ystr"
	a = atext(str, x=pt.x, y=pt.y, xoffset=3, yoffset=-3,
		font=font, align=:tl, strip=strip)
	render(canvas, a, graphinfo)
	return
end

function render_Δinfo(canvas::PCanvas2D, p1::Point2D, p2::Point2D, Δinfo::Vector2D,
	font::Font, xfmt::NumericFormatting, yfmt::NumericFormatting, ixf::InputXfrm2D, strip::Int)
	align = ALIGN_TOP | ALIGN_LEFT #WANTCONST
	mfmt = number_fmt(ndigits=4, decfloating=true) #WANTCONST
	boxattr = AreaAttributes(
		line(style=:solid, width=1.5, color=COLOR_BLACK), COLOR_WHITE
	) #WANTCONST
	ctx = canvas.ctx #WANTCONST
	Δx = p2.x - p1.x; Δy = p2.y - p1.y
	m = Δy/Δx
	Δxstr = formatted(Δx, xfmt); Δxstr = "Δx=$Δxstr"
	Δystr = formatted(Δy, yfmt); Δystr = "Δy=$Δystr"
	mstr = formatted(m, mfmt); mstr = "Δy/Δx=$mstr"

	setfont(ctx, font)
	w, h = textextents_wh(ctx, mstr)
	Δh = h*.1 #Vertical gap
	wx, hx = textextents_wh(ctx, Δxstr)
	wy, hy = textextents_wh(ctx, Δxstr)
	w = max(w, wx, wy)
	h += hx + hy + 2*Δh

	#Figure out where to display:
	p1a = read2axis(p1, ixf); 	p2a = read2axis(p2, ixf)
	pdraw = Point2D((p1a.x + p2a.x)/2, (p1a.y + p2a.y)/2)
		pdraw = map2dev(canvas.xf, pdraw)
	x = pdraw.x + Δinfo.x; y = pdraw.y + Δinfo.y
	x -= w/2; y -= h/2
	pad = Δh
	rect = BoundingBox(x-pad, x+w+pad, y-pad, y+h+pad)
	drawrectangle(ctx, rect, boxattr)
	render(ctx, Δxstr, Point2D(x, y), font, align=align)
	y += hx + Δh
	render(ctx, Δystr, Point2D(x, y), font, align=align)
	y += hy + Δh
	render(ctx, mstr, Point2D(x, y), font, align=align)
	return rect #Want to know where we drew the box
end

function render(canvas::PCanvas2D, mg::CtrlMarkerGroup, graphinfo::Graph2DInfo, strip::Int)
	xfmt = hoverfmt(graphinfo.xfmt) #WANTCONST
	yfmt = hoverfmt(graphinfo.yfmt) #WANTCONST
	ixf = graphinfo.ixf #WANTCONST
	for elem in mg.elem
		mstrip = elem.prop.strip
		if 0 == mstrip || mstrip == strip
			render(canvas, elem.prop, graphinfo) #Render crosshairs
			render_markercoord(canvas, elem.prop.pos, mg.fntcoord, xfmt, yfmt, graphinfo, strip)
		end
	end

	#Render Δinfo on top:
	for elem in mg.elem
		mstrip = elem.prop.strip
		if 0 == mstrip || mstrip == strip
			mref = elem.ref
			if mref != nothing
				elem.Δbb = render_Δinfo(canvas, mref.prop.pos, elem.prop.pos, elem.Δinfo,
					mg.fntdelta, xfmt, yfmt, ixf, strip
				)
			end
		end
	end

	#Render control points on top:
	for elem in mg.elem
		mstrip = elem.prop.strip
		if 0 == mstrip || mstrip == strip
			render_ctrlpoint(canvas, elem.prop.pos, ixf)
		end
	end
	return
end


#==Helper functions
===============================================================================#
function hittest(marker::CtrlMarker, xf::Transform2D, ixf::InputXfrm2D, x::Float64, y::Float64)
	Δhit = Float64(CTRLPOINT_RADIUS+CTRLPOINT_ATTR.line.width/2) #WANTCONST

	pt = read2axis(marker.prop.pos, ixf)
	pt = map2dev(xf, pt)
	Δx = abs(x-pt.x); Δy = abs(y-pt.y)
	Δ = sqrt(Δx*Δx + Δy*Δy)
	return (Δ <= Δhit) #Hit successful if clicked on marker.
end
function hittest_Δinfo(marker::CtrlMarker, x::Float64, y::Float64)
	return isinside(marker.Δbb, x, y)
end


#==Action functions for bindkeys
===============================================================================#
function createmarker(pwidget::PlotWidget, ref=nothing)
	istrip = pwidget.mouseover.istrip
	pos = pwidget.mouseover.pos
	mkr = nothing
	if istrip > 0 && pos != nothing
		x, y = pos.x, pos.y
		mkr = CtrlMarker(x, y, istrip, ref)
	end
	return mkr
end

function addrefmarker(pwidget::PlotWidget)
	mkr = createmarker(pwidget)
	if mkr != nothing
		push!(pwidget.markers.elem, mkr)
		pwidget.refmarker = mkr
		refresh(pwidget, refreshdata=false)
	end
	return mkr
end

function addΔmarker(pwidget::PlotWidget, makeref::Bool=false)
	mkr = nothing
	if pwidget.refmarker != nothing
		mkr = createmarker(pwidget, pwidget.refmarker)
		if mkr != nothing
			push!(pwidget.markers.elem, mkr)
			if makeref
				pwidget.refmarker = mkr
			end
			refresh(pwidget, refreshdata=false)
		end
	end
	return mkr
end

#Add a delta marker - and make it the new reference:
addΔmarkerref(pwidget::PlotWidget) = addΔmarker(pwidget, true)


#==Other actions
===============================================================================#
function cancelmove(s::ISMovingMarker, pwidget::PlotWidget)
	s.marker.prop.pos = s.initpos
	setstate_normal(pwidget)
	refresh(pwidget, refreshdata=false)
	return
end
function deletemarker(mkr::CtrlMarker, pwidget::PlotWidget)
	markers = pwidget.markers.elem
	n = length(markers)
	for i in 1:n
		if mkr == markers[i]
			deleteat!(markers, i)
			break
		end
	end
	refresh(pwidget, refreshdata=false)
	return
end
function cancelmove_Δinfo(s::ISMovingΔInfo, pwidget::PlotWidget)
	s.marker.Δinfo = s.initΔ
	setstate_normal(pwidget)
	refresh(pwidget, refreshdata=false)
	return
end
function centerΔinfo(s::ISMovingΔInfo, pwidget::PlotWidget)
	s.marker.Δinfo = Vector2D(0,0)
	setstate_normal(pwidget)
	refresh(pwidget, refreshdata=false)
	return
end


#==Event handlers for selecting markers
===============================================================================#
#Handle mousepress if a CtrlMarker was clicked:
function handleevent_mousepress(pwidget::PlotWidget, markers::CtrlMarkerGroup,
	istrip::Int, x::Float64, y::Float64)
	xf = Transform2D(pwidget.plotinfo, istrip)
	ixf = InputXfrm2D(pwidget.plotinfo, istrip)

	#See if we clicked on a marker:
	for i in 1:length(markers.elem)
		elem = markers.elem[i]
		if hittest(elem, xf, ixf, x, y)
			initpos = elem.prop.pos
			gdk_window_set_cursor(pwidget.canvas, CURSOR_MOVE)
			pwidget.state = ISMovingMarker(istrip, initpos, elem)
			return true
		end
	end

	#Else see if we clicked on a Δ-info box:
	for i in 1:length(markers.elem)
		elem = markers.elem[i]
		if hittest_Δinfo(elem, x, y)
			refpos = Point2D(x, y) - elem.Δinfo
			gdk_window_set_cursor(pwidget.canvas, CURSOR_MOVE)
			pwidget.state = ISMovingΔInfo(istrip, refpos, elem.Δinfo, elem)
			return true
		end
	end

	return false
end


#==Event handlers for state: ISMovingMarker
===============================================================================#
function handleevent_keypress(s::ISMovingMarker, pwidget::PlotWidget, event::Gtk.GdkEventKey)
	if GdkKeySyms.Escape == event.keyval #Cancel move
		cancelmove(s, pwidget)
	elseif GdkKeySyms.Delete == event.keyval
		cancelmove(s, pwidget)
		deletemarker(s.marker, pwidget)
	end
end
function handleevent_mouserelease(::ISMovingMarker, pwidget::PlotWidget, event::Gtk.GdkEventButton)
	if 1==event.button #Done moving
		setstate_normal(pwidget)
	end
end
function handleevent_mousemove(s::ISMovingMarker, pwidget::PlotWidget, event::Gtk.GdkEventMotion)
	handleevent_plothover(pwidget, event, s.istrip)

	xf = Transform2D(pwidget.plotinfo, s.istrip)
	ixf = InputXfrm2D(pwidget.plotinfo, s.istrip)
	pt = map2axis(xf, Point2D(event.x, event.y))
	pt = axis2read(pt, ixf)
	s.marker.prop.pos = pt
	refresh(pwidget, refreshdata=false)
end


#==Event handlers for state: ISMovingΔInfo
===============================================================================#
function handleevent_keypress(s::ISMovingΔInfo, pwidget::PlotWidget, event::Gtk.GdkEventKey)
	if GdkKeySyms.Escape == event.keyval #Cancel move
		cancelmove_Δinfo(s, pwidget)
	elseif Int('0') == event.keyval
		centerΔinfo(s, pwidget)
	end
end
function handleevent_mouserelease(::ISMovingΔInfo, pwidget::PlotWidget, event::Gtk.GdkEventButton)
	if 1==event.button #Done moving
		setstate_normal(pwidget)
	end
end
function handleevent_mousemove(s::ISMovingΔInfo, pwidget::PlotWidget, event::Gtk.GdkEventMotion)
	handleevent_plothover(pwidget, event, s.istrip)

	curpos = Point2D(event.x, event.y)
	s.marker.Δinfo = Vector2D(curpos - s.refpos)
	refresh(pwidget, refreshdata=false)
end


#Last line
