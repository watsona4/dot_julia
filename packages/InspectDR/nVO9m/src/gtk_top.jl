#InspectDR: Top/high-level functionnality of Gtk layer
#-------------------------------------------------------------------------------

#==Constants
===============================================================================#
#Hack to keep text height in status label from changing as exponents start
#being included in coordinate values (Noticed on Windows platforms):
#(Causes display glitches/slowdowns)
const TEXTH_HACK_STR = "⁻" #Superscript `-` has bigger height than other chars.
#TODO: find a better way to keep height constant in status bar.

const COORDSTAT_NONE = "$TEXTH_HACK_STR(x, y) = ( , )"


#==Callback wrapper functions (PlotWidget-level)
===============================================================================#
#=COMMENTS
 -Define callback wrapper functions with concrete types to assist with precompile.
 -Remove unecessary arguments/convert to proper types
=#
@guarded function cb_keypress(w::Ptr{Gtk.GObject}, event::Gtk.GdkEventKey, pwidget::PlotWidget)
	handleevent_keypress(pwidget.state, pwidget, event)
	nothing #Known value
end
@guarded function cb_scalechanged(w::Ptr{Gtk.GObject}, pwidget::PlotWidget)
	handleevent_scalechanged(pwidget.state, pwidget)
	nothing #Known value
end
@guarded function cb_mousepress(w::Ptr{Gtk.GObject}, event::Gtk.GdkEventButton, pwidget::PlotWidget)
	handleevent_mousepress(pwidget.state, pwidget, event)
	nothing #Known value
end
@guarded function cb_mouserelease(w::Ptr{Gtk.GObject}, event::Gtk.GdkEventButton, pwidget::PlotWidget)
	handleevent_mouserelease(pwidget.state, pwidget, event)
	nothing #Known value
end
@guarded function cb_mousemove(w::Ptr{Gtk.GObject}, event::Gtk.GdkEventMotion, pwidget::PlotWidget)
	handleevent_mousemove(pwidget.state, pwidget, event)
	nothing #Known value
end
@guarded function cb_mousescroll(w::Ptr{Gtk.GObject}, event::Gtk.GdkEventScroll, pwidget::PlotWidget)
	handleevent_mousescroll(pwidget.state, pwidget, event)
	nothing #Known value
end


#==Callback wrapper functions (GtkPlot-level)
===============================================================================#
@guarded function cb_wnddestroyed(w::Ptr{Gtk.GObject}, gplot::GtkPlot)
	gplot.destroyed = true
	nothing #Known value
end
@guarded function cb_mnufileexport(w::Ptr{Gtk.GObject}, gplot::GtkPlot)
	filepath = Gtk.save_dialog("Export plot...", _Gtk.Null(),
		(_Gtk.FileFilter("*.png,*.svg,*.eps", name="All supported formats"), "*.png", "*.svg", "*.eps")
	)
	if isempty(filepath); return nothing; end

	ext = splitext(filepath)[end]
	mime = get(MAPEXT2MIME, ext, nothing)
	if nothing == mime
		Gtk.warn_dialog("Unrecognized file type: '$ext'")
		return nothing
	end

	try
		_write(filepath, mime, gplot)
	catch
		Gtk.warn_dialog("Write failed: '$filepath'")
	end
	nothing #Known value
end
@guarded function cb_mnufileclose(w::Ptr{Gtk.GObject}, gplot::GtkPlot)
	window_close(gplot.wnd)
	nothing #Known value
end

@guarded function cb_mnudatatraces(w::Ptr{Gtk.GObject}, gplot::GtkPlot)
	tracedialog_show(gplot)
	nothing #Known value
end


#==Higher-level event handlers
===============================================================================#
#plothover event: show plot coordinates under mouse.
#-------------------------------------------------------------------------------
function handleevent_plothover(gplot::GtkPlot, pwidget::PlotWidget, x::Float64, y::Float64)
	plotinfo = pwidget.plotinfo #WANTCONST

	istrip = pwidget.mouseover.istrip
	pos = pwidget.mouseover.pos
	if istrip > 0 && pos != nothing
		xfmt = hoverfmt(plotinfo.xfmt)
		yfmt = hoverfmt(plotinfo.strips[istrip].yfmt)
		xstr = formatted(pos.x, xfmt)
		ystr = formatted(pos.y, yfmt)
		statstr = "$TEXTH_HACK_STR(x, y) = ($xstr, $ystr)"
	else
		statstr = COORDSTAT_NONE
	end

	set_gtk_property!(gplot.status, :label, statstr)
	nothing
end


#==Menu builders:
===============================================================================#
function Gtk_addmenu(parent::Union{_Gtk.Menu, _Gtk.MenuBar}, name::String)
	item = _Gtk.MenuItem(name)
	mnu = _Gtk.Menu(item)
	push!(parent, item)
	return mnu
end
function Gtk_addmenuitem(mnu::_Gtk.Menu, name::String)
	item = _Gtk.MenuItem(name)
	push!(mnu, item)
	return item
end


#=="Constructors"
===============================================================================#

#-------------------------------------------------------------------------------
function PlotWidget(plot::Plot)
	vbox = _Gtk.Box(true, 0)
		can_focus(vbox, true)
#		set_gtk_property!(vbox, "focus-on-click", true)
#		set_gtk_property!(vbox, :focus_on_click, true)
	canvas = Gtk.Canvas()
		set_gtk_property!(canvas, :vexpand, true)
	w_xscale = _Gtk.Scale(false, 1:XAXIS_SCALEMAX)
		xscale = _Gtk.Adjustment(w_xscale)
		set_gtk_property!(xscale, :value, 1)
#		draw_value(w_xscale, false)
		value_pos(w_xscale, Int(GtkPositionType.GTK_POS_RIGHT))
	w_xpos = _Gtk.Scale(false, -.5:XAXIS_POS_STEPRES:.5)
		xpos = _Gtk.Adjustment(w_xpos)
		set_gtk_property!(xpos, :value, 0)
#		draw_value(w_xpos, false)
		value_pos(w_xpos, Int(GtkPositionType.GTK_POS_RIGHT))

	push!(vbox, canvas)
	push!(vbox, w_xpos)
	push!(vbox, w_xscale)

	w = width(canvas); h = height(canvas)
	plotbuf = CairoBufferedPlot(
		Cairo.CairoARGBSurface(w, h), Cairo.CairoARGBSurface(w, h)
	)
	#TODO: how do we get a maximum surface for all monitors?
	#TODO: or can we resize in some intelligent way??
	#plotbuf = Cairo.CairoRGBSurface(1920,1200) #Appears slow for average monitor size???
#	plotbuf = Gtk.cairo_surface_for(canvas) #create similar - does not work here
	curstrip = 1 #TODO: Is this what is desired?

	plotinfo = Plot2DInfo(plot)
	pwidget = PlotWidget(vbox, canvas, plot, plotinfo, ISNormal(),
		w_xscale, xscale, w_xpos, xpos,
		plotbuf, curstrip, GtkMouseOver(),
		CtrlMarkerGroup(plot.layout[:font_annotation]), nothing, true, true,
		#Event handlers:
		nothing
	)

	#Take control of parentannot:
	plot.parentannot = [pwidget.markers]

	#Register callback functions:
	signal_connect(cb_scalechanged, xscale, "value-changed", Nothing, (), false, pwidget)
	signal_connect(cb_scalechanged, xpos, "value-changed", Nothing, (), false, pwidget)
	signal_connect(cb_keypress, vbox, "key-press-event", Nothing, (Ref{Gtk.GdkEventKey},), false, pwidget)
	signal_connect(cb_mousepress, vbox, "button-press-event", Nothing, (Ref{Gtk.GdkEventButton},), false, pwidget)
	signal_connect(cb_mouserelease, vbox, "button-release-event", Nothing, (Ref{Gtk.GdkEventButton},), false, pwidget)
	signal_connect(cb_mousemove, vbox, "motion-notify-event", Nothing, (Ref{Gtk.GdkEventMotion},), false, pwidget)
	signal_connect(cb_mousescroll, vbox, "scroll-event", Nothing, (Ref{Gtk.GdkEventScroll},), false, pwidget)

	#Register event: draw function
	Gtk.@guarded Gtk.draw(pwidget.canvas) do canvas
		#=NOTE:
		PlotWidget should probably be subclassed from GtkCanvas (the draw event
		would then have a reference to the PlotWidget...), but Julia does not
		make this easy.  Instead, this function generates an annonymous function
		that implicitly has a reference to the appropriate PlotWidget instance.
		=#
		if invalidbuffersize(pwidget)
			render(pwidget)
		end
		ctx = getgc(pwidget.canvas)
			w = width(pwidget.canvas); h = height(pwidget.canvas)
			bb = BoundingBox(0, w, 0, h)
		wipe(ctx, bb, COLOR_WHITE)
		Cairo.set_source_surface(ctx, pwidget.plotbuf.surf, 0, 0)
		Cairo.paint(ctx) #Applies contents of plotbuf.surf
		selectionbox_draw(ctx, pwidget) #TODO: use more generic method name??
		#TODO: Can/should we explicitly Cairo.destroy(ctx)???
	end

	return pwidget
end
#Build a PlotWidget & register event handlers for GtkPlot object
function PlotWidget(gplot::GtkPlot, plot::Plot)
	pwidget = PlotWidget(plot)
	pwidget.eh_plothover = HandlerInfo(gplot, handleevent_plothover)
	return pwidget
end

#Synchronize with gplot.src.subplots
function sync_subplots(gplot::GtkPlot)
	wlist = gplot.subplots #widget list
	plist = gplot.src.subplots #(sub)plot list
	resize!(wlist, length(plist))

	for (i, s) in enumerate(plist)
		if !isassigned(wlist, i)
			wlist[i] = PlotWidget(gplot, s)
		else
			if wlist[i].src != s
				Gtk.destroy(wlist[i].widget)
				wlist[i] = PlotWidget(gplot, s)
			end
		end
	end

	#Blindly re-construct grid:
	for i in length(gplot.grd):-1:1
		Gtk.delete!(gplot.grd, gplot.grd[i]) #Does not destroy existing child widgets
	end
	ncols = gplot.src.layout.values.ncolumns #WANTCONST
	for (i, w) in enumerate(wlist)
		row = div(i-1, ncols)+1
		col = i - ((row-1)*ncols)
		gplot.grd[col,row] = w.widget

		#FIXME/HACK: rebuilding grd appears to inhibit the redraw mechanism.
		#Toggling w.canvas -> visible unclogs refresh algorithm somehow.
		set_gtk_property!(w.canvas, :visible, false)
		set_gtk_property!(w.canvas, :visible, true)
	end
	return
end


#-------------------------------------------------------------------------------
function GtkPlot(mp::Multiplot)
	#Generate graphical elements:
	mb = _Gtk.MenuBar()
	mnufile = Gtk_addmenu(mb, "_File")
		mnuexport = Gtk_addmenuitem(mnufile, "_Export")
		push!(mnufile, _Gtk.SeparatorMenuItem())
		mnuquit = Gtk_addmenuitem(mnufile, "_Quit")
	mnudata = Gtk_addmenu(mb, "_Data")
		mnutraces = Gtk_addmenuitem(mnudata, "_Traces")
	grd = Gtk.Grid() #Main grid with different subplots.
		set_gtk_property!(grd, :column_homogeneous, true)
		#set_gtk_property!(grd, :column_spacing, 15) #Gap between
	status = _Gtk.Label("")#"(x,y) =")
		set_gtk_property!(status, :hexpand, true)
		set_gtk_property!(status, :ellipsize, PANGO_ELLIPSIZE_END)
		set_gtk_property!(status, :xalign, 0.0)
		set_gtk_property!(status, :label, COORDSTAT_NONE)
		sbar_frame = _Gtk.Frame(status)
			set_gtk_property!(sbar_frame, "shadow-type", GtkShadowType.GTK_SHADOW_ETCHED_IN)

	vbox = _Gtk.Box(true, 0)
		push!(vbox, mb) #Menu bar
		push!(vbox, grd) #Subplots
		push!(vbox, sbar_frame) #status bar
	wnd = Gtk.Window(vbox, "", 640, 480, true)

	gplot = GtkPlot(false, wnd, grd, [], mp, status)
	refresh_title(gplot)
	sync_subplots(gplot)

	if length(gplot.subplots) > 0
		set_focus(wnd, gplot.subplots[end].widget)
	end

	Gtk.showall(wnd)
	signal_connect(cb_wnddestroyed, wnd, "destroy", Nothing, (), false, gplot)
	signal_connect(cb_mnufileexport, mnuexport, "activate", Nothing, (), false, gplot)
	signal_connect(cb_mnufileclose, mnuquit, "activate", Nothing, (), false, gplot)
	signal_connect(cb_mnudatatraces, mnutraces, "activate", Nothing, (), false, gplot)

	return gplot
end

#-------------------------------------------------------------------------------
function GtkPlot(plot::Plot, args...; kwargs...)
	mp = Multiplot(args...; kwargs...)
	_add(mp, plot)
	return GtkPlot(mp)
end
GtkPlot(args...; kwargs...) = GtkPlot(Plot2D(), args...; kwargs...)


#==High-level interface
===============================================================================#
function clearsubplots(gplot::GtkPlot)
	for s in gplot.subplots
		Gtk.destroy(s.widget)
	end
	gplot.subplots = []
	gplot.src.subplots = []
	return gplot
end

function refresh(gplot::GtkPlot)
	if !gplot.destroyed
		refresh_title(gplot)
		active = active_subplot(gplot)
		set_gtk_property!(gplot.grd, :visible, false) #Suppress gliching
			sync_subplots(gplot)
			map(refresh, gplot.subplots) #Is this necessary?
		set_gtk_property!(gplot.grd, :visible, true)
		set_focus(gplot.subplots[active].widget) #Restore focus after modifying gplot.grd
		Gtk.showall(gplot.grd)
		#TODO: find a way to force GUI to updates here... Animations don't refresh...
		sleep(eps(0.0)) #Ugly Hack: No guarantee this works... There must be a better way.
	end
	return
end

function Base.display(d::GtkDisplay, mp::Multiplot)
	return GtkPlot(mp)
end
function Base.display(d::GtkDisplay, p::Plot)
	return GtkPlot(p)
end

function Base.close(gplot::GtkPlot)
	window_close(gplot.wnd)
	return nothing
end

function clear_data(gplot::GtkPlot; refresh_gui = true)
	clear_data(gplot.src)
	if refresh_gui
		refresh(gplot)
	end
	return
end

#Last line
